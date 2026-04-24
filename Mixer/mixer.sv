`timescale 1ns / 1ps

module mixer
    #(
        parameter int OUT_WIDTH = 24, // Defaulted to 32 to match the rest of your system
        parameter int COEF_WIDTH = 32,
        parameter int GAIN_SH = 16 
    )
    (
        input  logic                  clk,
        input  logic                  rst_n,
        input  logic                  enable,

        // 1. Audio is SIGNED 2's complement
        input  logic signed [OUT_WIDTH-1:0]  saw_out,
        input  logic signed [OUT_WIDTH-1:0]  square_out,
        input  logic signed [OUT_WIDTH-1:0]  sine_out,
        input  logic signed [OUT_WIDTH-1:0]  tri_out,
        input  logic signed [OUT_WIDTH-1:0]  noise_out,

        // 2. Coefficients are SIGNED Fixed-Point
        input  logic signed [COEF_WIDTH-1:0] saw_coef,
        input  logic signed [COEF_WIDTH-1:0] square_coef,
        input  logic signed [COEF_WIDTH-1:0] sine_coef,
        input  logic signed [COEF_WIDTH-1:0] tri_coef,
        input  logic signed [COEF_WIDTH-1:0] noise_coef,

        output logic signed [OUT_WIDTH-1:0]  wave_out,
        output logic                         out_valid
    );

    // --- Bit Growth Calculations ---
    localparam int PROD_WIDTH = OUT_WIDTH + COEF_WIDTH;
    localparam int SUM_WIDTH = PROD_WIDTH + 3;

    // --- Hardware Saturation Limits (Truly Bulletproof) ---
    // First, define a 1 that is explicitly the width of our adder tree
    localparam logic signed [SUM_WIDTH-1:0] ONE = 1;
    
    // Now shift that wide '1'. No truncation, no unsigned zero-extension.
    localparam logic signed [SUM_WIDTH-1:0] POS_MAX = (ONE << (OUT_WIDTH - 1)) - 1;
    localparam logic signed [SUM_WIDTH-1:0] NEG_MAX = -(ONE << (OUT_WIDTH - 1));

    // Internal pipeline registers
    logic signed [PROD_WIDTH-1:0] saw_prod, square_prod, sine_prod, tri_prod, noise_prod;
    
    // Combinational routing wires
    logic signed [SUM_WIDTH-1:0]  mixer_sum;
    logic signed [SUM_WIDTH-1:0]  shifted_sum;

    // Valid signal pipeline register
    logic enable_d1;

    // ==========================================
    // STAGE 1: Multiplier Stage
    // ==========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            saw_prod    <= '0;
            square_prod <= '0;
            sine_prod   <= '0;
            tri_prod    <= '0;
            noise_prod  <= '0;
        end else if (enable) begin
            saw_prod    <= saw_out    * saw_coef;
            square_prod <= square_out * square_coef;
            sine_prod   <= sine_out   * sine_coef;
            tri_prod    <= tri_out    * tri_coef;
            noise_prod  <= noise_out  * noise_coef;
        end
    end

    // ==========================================
    // STAGE 2: Adder Tree & Saturation Stage
    // ==========================================
    always_comb begin
        // Sum all products
        mixer_sum = saw_prod + square_prod + sine_prod + tri_prod + noise_prod; 
        
        // Arithmetic Right Shift
        shifted_sum = mixer_sum >>> GAIN_SH;
    end

    // Clocked Output and Saturation Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave_out  <= '0;
        end else if (enable) begin
            if (shifted_sum > POS_MAX) begin
                wave_out <= POS_MAX[OUT_WIDTH-1:0];
            end else if (shifted_sum < NEG_MAX) begin
                wave_out <= NEG_MAX[OUT_WIDTH-1:0];
            end else begin
                wave_out <= shifted_sum[OUT_WIDTH-1:0];
            end
        end
    end

    // ==========================================
    // STAGE 3: Valid Signal Pipeline
    // ==========================================
    // This runs continuously on clk to generate a 1-cycle pulse
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_d1 <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            enable_d1 <= enable;
            // Pulse out_valid exactly one clock cycle after the Stage 1 registers capture data
            // (Which aligns perfectly with when Stage 2 logic settles and is clocked into wave_out)
            out_valid <= enable_d1; 
        end
    end

endmodule