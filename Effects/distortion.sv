`timescale 1ns / 1ps

module distortion #(
    parameter int AUDIO_WIDTH = 32,
    parameter int GAIN_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  logic signed [AUDIO_WIDTH-1:0] signal_in,
    input  logic signed [GAIN_WIDTH-1:0]  gain,
    output logic signed [AUDIO_WIDTH-1:0] signal_out
);

    // =========================================================
    // CONFIGURATION & LIMITS
    // =========================================================
    localparam int PROD_WIDTH = AUDIO_WIDTH + GAIN_WIDTH;

    // Sized explicitly to PROD_WIDTH to ensure the 'if' comparisons evaluate the full 64-bit product
    // Use a signed cast instead of a width-specifier literal
    // Inside distortion.sv
    localparam logic signed [PROD_WIDTH-1:0] POS_MAX = (2**(AUDIO_WIDTH - 1)) - 1;
    localparam logic signed [PROD_WIDTH-1:0] NEG_MAX = -(2**(AUDIO_WIDTH - 1));

    // =========================================================
    // INTERNAL SIGNALS
    // =========================================================
    logic signed [PROD_WIDTH-1:0]  gain_prod;
    logic signed [AUDIO_WIDTH-1:0] signal_out_next;

    // =========================================================
    // SATURATION FUNCTION
    // =========================================================
    function automatic logic signed [AUDIO_WIDTH-1:0]
    saturate(input logic signed [PROD_WIDTH-1:0] val);
        if (val > POS_MAX)
            return POS_MAX[AUDIO_WIDTH-1:0];
        else if (val < NEG_MAX)
            return NEG_MAX[AUDIO_WIDTH-1:0];
        else
            return val[AUDIO_WIDTH-1:0];
    endfunction

    // =========================================================
    // COMBINATIONAL LOGIC
    // =========================================================
    always_comb begin
        gain_prod       = signal_in * gain;
        signal_out_next = saturate(gain_prod);
    end

    // =========================================================
    // SEQUENTIAL LOGIC
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_out <= '0;
        end else if (en) begin
            signal_out <= signal_out_next;
        end
    end

endmodule