`timescale 1ns / 1ps

module osc_triangle
    (
        input  logic        clk,         // System clock
        input  logic        rst_n,       // Active-low asynchronous reset
        input  logic [31:0] tuning_word, // Controls frequency
        input  logic        enable,      // Clock enable

        output logic [23:0] tri_out      // 24-bit Triangle Wave
    );

    // 32-bit Phase Accumulator
    logic [31:0] phase_acc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // Internal signals for folding
    logic [23:0] raw_ramp;
    
    // Slice the top 24 bits below the MSB (30 down to 7)
    // This ensures we have a full 24-bit resolution ramp for each half-cycle.
    assign raw_ramp = phase_acc[30:7];

    always_comb begin
        if (phase_acc[31]) begin
            // MSB is 1: Falling slope
            // Bitwise NOT creates the downward ramp
            tri_out = ~raw_ramp;
        end else begin
            // MSB is 0: Rising slope
            tri_out = raw_ramp;
        end
    end

endmodule

/*
`timescale 1ns / 1ps

module osc_triangle
    (
        input  logic        clk,
        input  logic        rst_n,
        input  logic [31:0] tuning_word,
        input  logic        enable,

        output logic [23:0] tri_out
    );

    logic [31:0] phase_acc;
    logic [31:0] prev_phase_acc;
    logic overflow;
    logic folded_flag;

    // 1. Standard Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'h0;
            prev_phase_acc <= 32'h0;
            folded_flag <= 1'b0;
        end else if (enable) begin
            phase_acc <= phase_acc + tuning_word;
            prev_phase_acc <= phase_acc;
        end

        if (overflow) folded_flag <= ~folded_flag;
    end

    always_comb begin
        if (phase_acc + tuning_word < phase_acc) overflow = 1;
        else overflow = 0;
    end

    logic [31:0] saw_out;
    assign saw_out = {~phase_acc[31], phase_acc[30:8]};

    always_comb begin
        if (enable) begin
            if (folded_flag) tri_out = saw_out;
            else tri_out = ~saw_out;
        end
        else tri_out = 24'h0;
    end

 endmodule
*/