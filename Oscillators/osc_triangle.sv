`timescale 1ns / 1ps

module osc_triangle #(
    parameter int ACC_WIDTH = 32,
    parameter int OUT_WIDTH = 24
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [ACC_WIDTH-1:0] tuning_word,
    input  logic                 enable,
    output logic signed [OUT_WIDTH-1:0] tri_out // Properly signed 2's complement
);

    logic [ACC_WIDTH-1:0] phase_acc;

    // 1. Standard Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // 2. Triangle Wave Generation Logic
    logic [ACC_WIDTH-2:0] raw_tri;
    logic [ACC_WIDTH-1:0] full_unsigned_tri;
    logic [OUT_WIDTH-1:0] truncated_tri;

    always_comb begin
        // A. Fold the phase to create a triangle shape.
        if (phase_acc[ACC_WIDTH-1]) begin
            raw_tri = ~phase_acc[ACC_WIDTH-2:0];
        end else begin
            raw_tri = phase_acc[ACC_WIDTH-2:0];
        end

        // B. Scale it back up.
        full_unsigned_tri = {raw_tri, 1'b0};

        // C. Truncate to the requested output width.
        truncated_tri = full_unsigned_tri[ACC_WIDTH-1 -: OUT_WIDTH];

        // D. Convert to 2's Complement
        // Invert the MSB to center the wave precisely on zero
        tri_out = {~truncated_tri[OUT_WIDTH-1], truncated_tri[OUT_WIDTH-2:0]};
    end

endmodule
