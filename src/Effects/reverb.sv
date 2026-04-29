module reverb #(
    parameter int AUDIO_WIDTH = 24,
    parameter int ADDR_WIDTH  = 15, // Updated for the new RAM
    // 23017 is a large prime number for a deep, non-resonant tail
    parameter int DELAY_SAMPLES = 23017 
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  logic signed [AUDIO_WIDTH-1:0] signal_in,  // Dry Audio
    output logic signed [AUDIO_WIDTH-1:0] signal_out  // Reverb Tail + Dry
);

    // --- Localparams for Saturation ---
    localparam logic signed [AUDIO_WIDTH-1:0] MAX_VAL = {1'b0, {(AUDIO_WIDTH-1){1'b1}}};
    localparam logic signed [AUDIO_WIDTH-1:0] MIN_VAL = {1'b1, {(AUDIO_WIDTH-1){1'b0}}};

    logic [31:0] ram_data_out;
    logic [31:0] ram_data_in;
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    
    // Delay register to align Dry signal with RAM output latency
    logic signed [AUDIO_WIDTH-1:0] signal_in_reg;

    // --- Pointer Logic ---
    // Ensure the subtraction is 15-bit
    assign rd_ptr = wr_ptr - DELAY_SAMPLES[ADDR_WIDTH-1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            signal_in_reg <= '0;
        end else if (en) begin
            wr_ptr <= wr_ptr + 1'b1;
            signal_in_reg <= signal_in; // Align dry with wet
        end
    end

    // THE FEEDBACK LOOP: We write the *output* back into the RAM, not the input.
    assign ram_data_in = {signal_out, {(32-AUDIO_WIDTH){1'b0}}};

    // --- RAM Instance ---
    Echo_RAM ram_inst (
        .clock     (clk),
        .data      (ram_data_in),
        .rdaddress (rd_ptr),
        .wraddress (wr_ptr),
        .wren      (en),
        .q         (ram_data_out)
    );

    // --- Internal Mixing & Saturation Logic ---
    logic signed [AUDIO_WIDTH-1:0] wet_signal;
    logic signed [AUDIO_WIDTH-1:0] feedback_attenuated;
    logic signed [AUDIO_WIDTH:0]   mixed_full; 

    // Extract audio from top of 32-bit RAM word
    assign wet_signal = ram_data_out[31 : 32-AUDIO_WIDTH];

    // Reverb Decay (Attenuation): Shift right by 1 = 50% decay.
    // Manually maintaining sign bit for safety
    assign feedback_attenuated = {wet_signal[AUDIO_WIDTH-1], wet_signal[AUDIO_WIDTH-1:1]};

    always_comb begin
        // Sign-extend both operands to AUDIO_WIDTH+1 bits
        mixed_full = $signed({signal_in_reg[AUDIO_WIDTH-1], signal_in_reg}) + 
                     $signed({feedback_attenuated[AUDIO_WIDTH-1], feedback_attenuated});

        // Saturation logic
        if (mixed_full > $signed({1'b0, MAX_VAL})) begin
            signal_out = MAX_VAL;
        end else if (mixed_full < $signed({1'b1, MIN_VAL[AUDIO_WIDTH-1:0]})) begin
            signal_out = MIN_VAL;
        end else begin
            signal_out = mixed_full[AUDIO_WIDTH-1:0];
        end
    end

endmodule