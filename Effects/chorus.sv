module chorus #(
    parameter int AUDIO_WIDTH = 24, 
    parameter int ADDR_WIDTH  = 15  // Updated to match your new RAM
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  logic signed [AUDIO_WIDTH-1:0] signal_in,  // Dry Audio
    input  logic signed [AUDIO_WIDTH-1:0] lfo_tri,    // Triangle wave (LFO)
    output logic signed [AUDIO_WIDTH-1:0] signal_out  // Combined Dry + Wet
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

    // --- LFO Scaling ---
    // Now that we have 15 bits, we can allow a wider modulation depth.
    // This takes a 6-bit slice of the LFO to allow for a 0-63 sample wiggle.
    logic [ADDR_WIDTH-1:0] lfo_offset;
    assign lfo_offset = {{(ADDR_WIDTH-6){1'b0}}, lfo_tri[AUDIO_WIDTH-2 : AUDIO_WIDTH-7]}; 

    // --- Pointer Logic ---
    // Using a base delay of 512 samples (~10.6ms at 48kHz)
    assign rd_ptr = wr_ptr - (15'd512 + lfo_offset);

    // Left-justify audio into the 32-bit RAM word
    assign ram_data_in = {signal_in, {(32-AUDIO_WIDTH){1'b0}}};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            signal_in_reg <= '0;
        end else if (en) begin
            wr_ptr <= wr_ptr + 1'b1;
            signal_in_reg <= signal_in; // Align dry with wet
        end
    end

    // --- Updated RAM Instance (Matches your 15-bit I/O) ---
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
    logic signed [AUDIO_WIDTH:0]   mixed_full; 

    // Extract audio from top of 32-bit RAM word
    assign wet_signal = ram_data_out[31 : 32-AUDIO_WIDTH];

    always_comb begin
        // Sign-extend to catch overflow before saturation
        mixed_full = $signed({signal_in_reg[AUDIO_WIDTH-1], signal_in_reg}) + 
                     $signed({wet_signal[AUDIO_WIDTH-1], wet_signal});

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