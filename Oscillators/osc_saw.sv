
`timescale 1ns / 1ps
/* * PHASE ACCUMULATOR MATH & LOGIC SUMMARY:
 * ---------------------------------------
 * 1. Frequency Formula: f_out = (tuning_word * f_clk) / 2^N
 * 2. Tuning Word (M):   M = (f_out * 2^N) / f_clk
 * 3. Max Limit:         tuning_word must be < 2^(N-1) (Nyquist Limit).
 */

 module osc_saw
    #(
        parameter int ACC_WIDTH = 32,
        parameter int OUT_WIDTH = 24
    )
    (
        input logic clk,
        input logic rst_n,
        input logic [ACC_WIDTH-1:0] tuning_word, // Determines the frequency of output waveform normalized to clk
        input logic enable,

        output logic [OUT_WIDTH-1:0] saw_out
    );

    logic [ACC_WIDTH-1:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
            saw_out <= phase_acc[ACC_WIDTH-1 -: OUT_WIDTH];
        end
        else phase_acc <= phase_acc;
    end 

 endmodule