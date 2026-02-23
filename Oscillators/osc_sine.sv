`timescale 1ns / 1ps

module osc_sine
    #(
        parameter int ACC_WIDTH = 32,
        parameter int OUT_WIDTH = 24
    )
    (
        input logic                  clk,
        input logic                  rst_n,
        input logic [ACC_WIDTH-1:0]  tuning_word,
        input logic                  enable,

        output logic [OUT_WIDTH-1:0] sine_out
    );

    // Parameters for LUT size
    localparam int ADDR_WIDTH = 10; // 1024 entries
    localparam real PI = 3.14159265358979323846;

    logic [ACC_WIDTH-1:0] phase_acc;
    // Use OUT_WIDTH for the LUT data width
    logic [OUT_WIDTH-1:0] sine_lut [0:(2**ADDR_WIDTH)-1];

    // 1. Generate the Sine Table
    initial begin
        for (int i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
            // Scale to OUT_WIDTH signed range
            // Use (2**(OUT_WIDTH-1) - 1) for the peak amplitude
            sine_lut[i] = $signed( (2.0**(OUT_WIDTH-1) - 1.0) * $sin(2.0 * PI * i / (2.0**ADDR_WIDTH)) );
        end
    end

    // 2. Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0; // Correctly fills ACC_WIDTH
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // 3. Address the LUT
    // Slice top ADDR_WIDTH bits: [MSB : MSB - (ADDR_WIDTH-1)]
    always_ff @(posedge clk) begin
        if (enable) begin
            sine_out <= sine_lut[phase_acc[ACC_