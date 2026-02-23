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
    logic [ACC_WIDTH-1:0] prev_phase_acc;
    logic                 overflow;
    logic                 folded_flag;

    // 1. Standard Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc      <= '0;
            prev_phase_acc <= '0;
            folded_flag    <= 1'b0;
        end else if (enable) begin
            phase_acc      <= phase_acc + tuning_word;
            prev_phase_acc <= phase_acc;
        end

        if (overflow) folded_flag <= ~folded_flag;
    end

    always_comb begin
        if (phase_acc + tuning_word < phase_acc) overflow = 1;
        else overflow = 0;
    end

    logic [ACC_WIDTH-1:0] saw_out;
    // Maintains the 8-bit shift logic relative to the 32-bit baseline
    assign saw_out = {~phase_acc[ACC_WIDTH-1], phase_acc[ACC_WIDTH-2:ACC_WIDTH-24]};

    always_comb begin
        if (enable) begin
            if (folded_flag) tri_out = saw_out[OUT_WIDTH-1:0];
            else tri_out = ~saw_out[OUT_WIDTH-1:0];
        end
        else tri_out = '0;
    end

 endmodule
 

/*
`timescale 1ns / 1ps

module osc_triangle
    #(
        parameter int ACC_WIDTH = 32,
        parameter int OUT_WIDTH = 24
    )
    (
        input  logic                 clk,         // System clock
        input  logic                 rst_n,       // Active-low asynchronous reset
        input  logic [ACC_WIDTH-1:0] tuning_word, // Controls frequency
        input  logic                 enable,      // Clock enable

        output logic [OUT_WIDTH-1:0] tri_out      // Parameterized Triangle Wave
    );

    // Phase Accumulator
    logic [ACC_WIDTH-1:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // Internal signals for folding
    logic [OUT_WIDTH-1:0] raw_ramp;
    
    // Sl