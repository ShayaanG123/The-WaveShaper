`timescale 1ns / 1ps

module osc_sine
    (
        input logic clk,
        input logic rst_n,
        input logic [31:0] tuning_word,
        input logic enable,

        output logic [23:0] sine_out
    );

    // Parameters for LUT size
    localparam ADDR_WIDTH = 10; // 1024 entries
    localparam DATA_WIDTH = 24;
    localparam PI = 3.14159265358979323846;

    logic [31:0] phase_acc;
    logic [DATA_WIDTH-1:0] sine_lut [0:(2**ADDR_WIDTH)-1];

    // 1. Generate the Sine Table at Compile/Elaboration time
    // Note that this is should actually be in BRAM during synthesis
    initial begin
        for (int i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
            // Calculate sine and scale to 24-bit signed range
            // (2^23 - 1) is the max positive value for signed 24-bit
            sine_lut[i] = $signed( (2**(DATA_WIDTH-1) - 1) * $sin(2.0 * PI * i / (2**ADDR_WIDTH)) );
        end
    end

    // 2. Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // 3. Address the LUT using the top bits of the accumulator
    // We use a register for the output to ensure VCS/Synthesis infers a BRAM
    always_ff @(posedge clk) begin
        if (enable) begin
            sine_out <= sine_lut[phase_acc[31:32-ADDR_WIDTH]];
        end
    end

 endmodule