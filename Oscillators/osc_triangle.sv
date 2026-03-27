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
    logic [OUT_WIDTH-1:0] ramp; 

    // 1. Combinational Ramp Extraction
    // Always perfectly in sync with the current phase_acc
    assign ramp = phase_acc[ACC_WIDTH-2 -: OUT_WIDTH];

    // 2. Synchronous Output and Phase Update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
            tri_out   <= '0;
        end else if (enable) begin
            tri_out <= (phase_acc[ACC_WIDTH-1] == 1'b0) ? ramp : ~ramp;
            
            phase_acc <= phase_acc + tuning_word;
        end else begin
            phase_acc <= phase_acc;
            tri_out   <= '0;
        end
    end

endmodule