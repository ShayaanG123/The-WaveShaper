`timescale 1ns / 1ps

module osc_square #(
    parameter int ACC_WIDTH = 32,
    parameter int OUT_WIDTH = 32 
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [ACC_WIDTH-1:0] tuning_word, 
    input  logic                 enable,
    output logic signed [OUT_WIDTH-1:0] sq_out
);

    logic [ACC_WIDTH-1:0] phase_acc;

    // Headroom-aware peaks (25% volume) to prevent DAC "Muting/Spiking"
    // localparam logic signed [OUT_WIDTH-1:0] POS_PEAK = 32'h1FFFFFFF; 
    // localparam logic signed [OUT_WIDTH-1:0] NEG_PEAK = 32'hE0000000;

    localparam logic signed [OUT_WIDTH-1:0] POS_PEAK = 24'h1fffff; 
    localparam logic signed [OUT_WIDTH-1:0] NEG_PEAK = 24'he00000;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
            sq_out    <= '0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
            sq_out    <= (phase_acc[ACC_WIDTH-1] == 1'b0) ? POS_PEAK : NEG_PEAK;
        end
    end
endmodule