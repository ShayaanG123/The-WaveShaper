`timescale 1ns / 1ps

module osc_saw #(
    parameter int ACC_WIDTH = 32,
    parameter int OUT_WIDTH = 32
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [ACC_WIDTH-1:0] tuning_word, 
    input  logic                 enable,
    output logic signed [OUT_WIDTH-1:0] saw_out
);

    logic [ACC_WIDTH-1:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
            saw_out   <= '0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
            // Flip MSB to transform unsigned ramp to signed biphasic ramp
            saw_out <= {~phase_acc[ACC_WIDTH-1], phase_acc[ACC_WIDTH-2 -: OUT_WIDTH-1]};
        end
    end 
endmodule