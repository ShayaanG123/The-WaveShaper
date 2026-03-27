`timescale 1ns / 1ps

module osc_noise
    #(
        parameter int ACC_WIDTH = 32,
        parameter int OUT_WIDTH = 24
    )
    (
        input logic clk,
        input logic rst_n,
        input logic enable,

        output logic [OUT_WIDTH-1:0] noise_out
    );

    logic [ACC_WIDTH-1:0] lfsr_reg;

    // A 32-bit LFSR needs a non-zero starting state (seed)
    // If it hits 0, it stays 0 forever.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 32'hACE1; // Initial Seed
        end else if (enable) begin
            // Galois LFSR using taps for a 32-bit maximal period:
            // Taps: 32, 22, 2, 1 (0x80000007 is a common mask)
            if (lfsr_reg[0]) begin
                lfsr_reg <= (lfsr_reg >> 1) ^ 32'h80000007;
            end else begin
                lfsr_reg <= (lfsr_reg >> 1);
            end

            noise_out <= lfsr_reg[ACC_WIDTH-1 -: OUT_WIDTH];
        end
    end 
 endmodule