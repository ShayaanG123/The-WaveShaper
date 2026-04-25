`timescale 1ns / 1ps

module adsr
    #(
        parameter int AUDIO_WIDTH = 24,
        parameter int ENV_WIDTH   = 32, // Width for the envelope counter
        parameter int ENV_FRACT   = 16  // Q16 format: 65536 = 1.0 gain
    )
    (
        input  logic clk,
        input  logic rst_n,
        input  logic enable,

        // -- Trigger --
        input  logic gate, // 1 = Note On (Key Pressed), 0 = Note Off (Key Released)

        // -- ADSR Coefficients (Unsigned, representing step size per sample) --
        input  logic [ENV_WIDTH-1:0] attack_step,
        input  logic [ENV_WIDTH-1:0] decay_step,
        input  logic [ENV_WIDTH-1:0] release_step,
        // Sustain level is an amplitude target, not a step rate (Q16 format, max 65536)
        input  logic [ENV_WIDTH-1:0] sustain_level,

        // -- Audio IO --
        input  logic signed [AUDIO_WIDTH-1:0] audio_in,
        output logic signed [AUDIO_WIDTH-1:0] audio_out,
        output logic                          out_valid
    );

    // Envelope Maximum is exactly 1.0 in Q16
    localparam logic [ENV_WIDTH-1:0] MAX_ENV = (1 << ENV_FRACT);

    // --- State Machine Definitions ---
    typedef enum logic [2:0] {
        IDLE    = 3'd0,
        ATTACK  = 3'd1,
        DECAY   = 3'd2,
        SUSTAIN = 3'd3,
        RELEASE = 3'd4
    } adsr_state_t;

    adsr_state_t state;

    // Internal Envelope Value (Unsigned)
    logic [ENV_WIDTH-1:0] env_val;
    
    // Pipeline Registers
    logic signed [AUDIO_WIDTH-1:0] audio_reg;
    logic enable_d1;

    // Bit-Growth for Multiplier (Audio + Envelope)
    localparam int PROD_WIDTH = AUDIO_WIDTH + ENV_WIDTH + 1; 
    // ==========================================
    // STAGE 1: ADSR State Machine & Envelope Gen
    // ==========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            env_val   <= '0;
            audio_reg <= '0;
        end else if (enable) begin
            // Register input audio to align with envelope calculation
            audio_reg <= audio_in;

            // Global Gate Check: If gate drops, ALWAYS go to release
            if (state != IDLE && state != RELEASE && !gate) begin
                state <= RELEASE;
            end else begin
                case (state)
                    IDLE: begin
                        env_val <= '0;
                        if (gate) state <= ATTACK;
                    end

                    ATTACK: begin
                        // Prevent overflow: check if next step exceeds MAX
                        if ((MAX_ENV - env_val) <= attack_step) begin
                            env_val <= MAX_ENV;
                            state   <= DECAY;
                        end else begin
                            env_val <= env_val + attack_step;
                        end
                    end

                    DECAY: begin
                        // Prevent underflow to sustain level
                        if (env_val <= (sustain_level + decay_step)) begin
                            env_val <= sustain_level;
                            state   <= SUSTAIN;
                        end else begin
                            env_val <= env_val - decay_step;
                        end
                    end

                    SUSTAIN: begin
                        // Hold steady. Global check handles the release transition.
                        env_val <= sustain_level; 
                    end

                    RELEASE: begin
                        // Prevent underflow to 0
                        if (env_val <= release_step) begin
                            env_val <= '0;
                            state   <= IDLE;
                        end else begin
                            env_val <= env_val - release_step;
                        end
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end

    // ==========================================
    // STAGE 2: Apply Envelope to Audio (FIXED)
    // ==========================================
    
    // Explicitly sized wires to prevent SystemVerilog LHS truncation rules
    logic signed [PROD_WIDTH-1:0] full_product;
    logic signed [PROD_WIDTH-1:0] shifted_product;

    always_comb begin
        // 1. Safe Signed Multiplication
        // audio_reg is Signed 24-bit.
        // env_val is Unsigned 32-bit. 
        // {1'b0, env_val} forces a 0 into the MSB, expanding it to 33 bits.
        // $signed() casts it to a Signed 33-bit number (guaranteed positive).
        // The result safely expands into the 57-bit (PROD_WIDTH) full_product.
        full_product = audio_reg * $signed({1'b0, env_val});
        
        // 2. Arithmetic Right Shift
        // Because full_product is explicitly signed, >>> safely pulls the sign 
        // bit down to preserve the negative audio waveforms.
        shifted_product = full_product >>> ENV_FRACT;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            audio_out <= '0;
        end else if (enable) begin
            // 3. Clean Truncation
            // Because the envelope maxes out at 1.0, the valid audio data has 
            // shifted safely back down into the bottom 24 bits.
            audio_out <= shifted_product[AUDIO_WIDTH-1:0];
        end
    end
    // ==========================================
    // STAGE 3: Valid Signal Pipeline
    // ==========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_d1 <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            enable_d1 <= enable;
            // Valid pulses exactly when audio_out updates
            out_valid <= enable_d1;
        end
    end

endmodule