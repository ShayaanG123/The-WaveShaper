`timescale 1ns / 1ps

module osc_triangle
    #(
        parameter int ACC_WIDTH = 32,
        parameter int OUT_WIDTH = 24
    )
    (
        input  logic                 clk,
        input  logic                 rst_n,
        input  logic [ACC_WIDTH-1:0] tuning_word,
        input  logic                 enable,

        output logic [OUT_WIDTH-1:0] tri_out
    );

    logic [ACC_WIDTH-1:0] phase_acc;

    // 1. Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // 2. Folding Logic
    // We use the MSB (phase_acc[31]) to determine the slope direction.
    // We slice the next OUT_WIDTH bits to form the ramp.
    logic [OUT_WIDTH-1:0] ramp;
    assign ramp = phase_acc[ACC_WIDTH-2 -: OUT_WIDTH];

    always_comb begin
        if (phase_acc[ACC_WIDTH-1] == 1'b0) begin
            // First 180 degrees
            tri_out = ramp;
        end else begin
            // Second 180 degrees
            tri_out = ~ramp;
        end
    end

endmodule