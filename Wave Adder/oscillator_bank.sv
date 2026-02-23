`timescale 1ns / 1ps

module synth_osc_bank
    #(
        parameter int ACC_WIDTH  = 32,
        parameter int OUT_WIDTH  = 24,
        parameter int COEF_WIDTH = 32
    )
    (
        input  logic                  clk,
        input  logic                  rst_n,
        input  logic                  enable,
        
        // Shared frequency control for pitched oscillators
        input  logic [ACC_WIDTH-1:0]  tuning_word,

        // Mixer volume controls
        input  logic [COEF_WIDTH-1:0] saw_coef,
        input  logic [COEF_WIDTH-1:0] square_coef,
        input  logic [COEF_WIDTH-1:0] sine_coef,
        input  logic [COEF_WIDTH-1:0] tri_coef,
        input  logic [COEF_WIDTH-1:0] noise_coef,

        // Final mixed audio out
        output logic signed [OUT_WIDTH-1:0] wave_out,
        output logic                        out_valid
    );

    // --- Internal Routing Wires ---
    logic signed [OUT_WIDTH-1:0] saw_wire;
    logic signed [OUT_WIDTH-1:0] sq_wire;
    logic signed [OUT_WIDTH-1:0] sine_wire;
    logic signed [OUT_WIDTH-1:0] tri_wire;
    logic signed [OUT_WIDTH-1:0] noise_wire;

    // --- 1. Sawtooth Oscillator ---
    osc_saw #(
        .ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(OUT_WIDTH)
    ) u_saw (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .tuning_word(tuning_word),
        .saw_out(saw_wire)
    );

    // --- 2. Square Oscillator ---
    osc_square #(
        .ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(OUT_WIDTH)
    ) u_square (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .tuning_word(tuning_word),
        .sq_out(sq_wire)
    );

    // --- 3. Sine Oscillator ---
    osc_sine #(
        .ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(OUT_WIDTH)
    ) u_sine (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .tuning_word(tuning_word),
        .sine_out(sine_wire)
    );

    // --- 4. Triangle Oscillator ---
    osc_triangle #(
        .ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(OUT_WIDTH)
    ) u_tri (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .tuning_word(tuning_word),
        .tri_out(tri_wire)
    );

    // --- 5. Noise Generator ---
    osc_noise #(
        .ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(OUT_WIDTH)
    ) u_noise (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .noise_out(noise_wire)
    );

    // --- 6. The DSP Mixer ---
    wave_adder #(
        .OUT_WIDTH(OUT_WIDTH), .COEF_WIDTH(COEF_WIDTH)
    ) u_mixer (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        
        // Audio Inputs
        .saw_out(saw_wire),
        .square_out(sq_wire),
        .sine_out(sine_wire),
        .tri_out(tri_wire),
        .noise_out(noise_wire),
        
        // Coefficient Inputs
        .saw_coef(saw_coef),
        .square_coef(square_coef),
        .sine_coef(sine_coef),
        .tri_coef(tri_coef),
        .noise_coef(noise_coef),
        
        // Mixed Output
        .wave_out(wave_out),
        .out_valid(out_valid)
    );

endmodule