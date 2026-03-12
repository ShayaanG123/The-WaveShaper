`timescale 1ns / 1ps

/* * PHASE ACCUMULATOR MATH & LOGIC SUMMARY:
 * ---------------------------------------
 * 1. Frequency Formula: f_out = (tuning_word * f_clk) / 2^N
 * 2. Tuning Word (M):   M = (f_out * 2^N) / f_clk
 * 3. Max Limit:         tuning_word must be < 2^(N-1) (Nyquist Limit).
 */

module osc_square
    #(
        parameter int ACC_WIDTH = 32,
        parameter int OUT_WIDTH = 24
    )
    (
        input logic clk,
        input logic rst_n,
        input logic [ACC_WIDTH-1:0] tuning_word, 
        input logic enable,

        output logic [OUT_WIDTH-1:0] sq_out
    );

    logic [ACC_WIDTH-1:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
        end 
        else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
        else begin 
            phase_acc <= phase_acc;
        end
    end

    
    localparam [OUT_WIDTH-1:0] MAX_VAL = {OUT_WIDTH{1'b1}}; // 0xFFFFFF for 24-bit
    localparam [OUT_WIDTH-1:0] MIN_VAL = {OUT_WIDTH{1'b0}}; // 0x000000 for 24-bit

    // Check MSB (Indictor of first half of bits)
    assign sq_out = (phase_acc[ACC_WIDTH-1] == 1'b0) ? MAX_VAL : MIN_VAL;

 endmodule