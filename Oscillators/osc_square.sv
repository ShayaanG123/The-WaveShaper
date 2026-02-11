`timescale 1ns / 1ps
/* * PHASE ACCUMULATOR MATH & LOGIC SUMMARY:
 * ---------------------------------------
 * 1. Frequency Formula: f_out = (tuning_word * f_clk) / 2^N
 * 2. Tuning Word (M):   M = (f_out * 2^N) / f_clk
 * 3. Max Limit:         tuning_word must be < 2^(N-1) (Nyquist Limit).
 */

 module osc_sqr
    (
        parameter WIDTH = 16,
        parameter DUTY = 32'h7FFF, //seems reasonable that intmax is halfway
        input logic clk,
        input logic rst_n,
        input logic [31:0] tuning_word, // Determines the frequency of output waveform normalized to clk
        input logic enable,

        output logic [23:0] sqr_out
    );
    
    logic [31:0] phase_acc;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
        else phase_acc <= phase_acc;
    end


//set magnitude of square
    always_comb begin

        if (phase_acc > duty) assign sqr_out = 16'hFFFF;

        else  assign sqr_out = 16'h0;
    end
 endmodule
