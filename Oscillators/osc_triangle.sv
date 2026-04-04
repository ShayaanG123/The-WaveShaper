`timescale 1ns / 1ps

module osc_triangle #(
    parameter int ACC_WIDTH = 32,
    parameter int OUT_WIDTH = 32 
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [ACC_WIDTH-1:0] tuning_word,
    input  logic                 enable,
    output logic signed [OUT_WIDTH-1:0] tri_out
);

    logic [ACC_WIDTH-1:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) phase_acc <= '0;
        else if (enable) phase_acc <= phase_acc + tuning_word;
    end

    logic [ACC_WIDTH-2:0] raw_tri;
    logic [ACC_WIDTH-1:0] full_unsigned_tri;
    logic [OUT_WIDTH-1:0] truncated_tri;

    always_comb begin
        // Fold: MSB determines slope direction
        if (phase_acc[ACC_WIDTH-1]) raw_tri = ~phase_acc[ACC_WIDTH-2:0];
        else                        raw_tri =  phase_acc[ACC_WIDTH-2:0];

        // Scale and Truncate
        full_unsigned_tri = {raw_tri, 1'b0};
        truncated_tri     = full_unsigned_tri[ACC_WIDTH-1 -: OUT_WIDTH];

        // Convert to Signed 2's Complement
        tri_out = {~truncated_tri[OUT_WIDTH-1], truncated_tri[OUT_WIDTH-2:0]};
    end
endmodule