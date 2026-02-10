
`timescale 1ns / 1ps
/* * PHASE ACCUMULATOR MATH & LOGIC SUMMARY:
 * ---------------------------------------
 * 1. Frequency Formula: f_out = (tuning_word * f_clk) / 2^N
 * 2. Tuning Word (M):   M = (f_out * 2^N) / f_clk
 * 3. Max Limit:         tuning_word must be < 2^(N-1) (Nyquist Limit).
 */

 module osc_saw
    (
        input logic clk,
        input logic rst_n,
        input logic [31:0] tuning_word, // Determines the frequency of output waveform normalized to clk
        input logic enable,

        output logic [23:0] saw_out
    );

    logic [31:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
        else phase_acc <= phase_acc;
    end

    // Centers the wave around. Converts to signed logic
    assign saw_out = {~phase_acc[31], phase_acc[30:8]};
 endmodule