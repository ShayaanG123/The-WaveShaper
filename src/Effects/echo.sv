module echo #(
    parameter int AUDIO_WIDTH = 24,
    parameter int ADDR_WIDTH  = 15 // Updated to match 32,768 word RAM
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    input  logic signed [AUDIO_WIDTH-1:0] signal_in,
    output logic signed [AUDIO_WIDTH-1:0] signal_out
);

    // --- Localparams for Saturation ---
    localparam logic signed [AUDIO_WIDTH-1:0] MAX_VAL = {1'b0, {(AUDIO_WIDTH-1){1'b1}}};
    localparam logic signed [AUDIO_WIDTH-1:0] MIN_VAL = {1'b1, {(AUDIO_WIDTH-1){1'b0}}};

    logic [31:0] ram_data_in;
    logic [31:0] ram_data_out;
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;

    // Latency alignment register
    logic signed [AUDIO_WIDTH-1:0] signal_in_reg;

    assign ram_data_in = {signal_in, {(32-AUDIO_WIDTH){1'b0}}};
    
    // 12000 samples = 250ms delay at 48kHz sample rate. 
    // Max possible is 32767 (~680ms).
    assign rd_ptr = wr_ptr - 15'd12000; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            signal_in_reg <= '0;
        end else if (en) begin
            wr_ptr <= wr_ptr + 1'b1;
            signal_in_reg <= signal_in; // Matches RAM 1-cycle read latency
        end
    end

    // Instance updated for 15-bit address bus
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

    assign wet_signal = ram_data_out[31 : 32-AUDIO_WIDTH];
     
    always_comb begin
         // Safe signed addition with overflow bit
         mixed_full = $signed({signal_in_reg[AUDIO_WIDTH-1], signal_in_reg}) + 
                      $signed({wet_signal[AUDIO_WIDTH-1], wet_signal});

         // Bulletproof Saturation
         if (mixed_full > $signed({1'b0, MAX_VAL})) begin
              signal_out = MAX_VAL;
         end else if (mixed_full < $signed({1'b1, MIN_VAL[AUDIO_WIDTH-1:0]})) begin
              signal_out = MIN_VAL;
         end else begin
              signal_out = mixed_full[AUDIO_WIDTH-1:0];
         end
    end

endmodule