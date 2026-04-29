`timescale 1ns / 1ps

module Chamberlin_SVF
#(
    parameter int AUDIO_WIDTH        = SMPL_WIDTH,
    parameter int COEF_WIDTH         = 24, // Q2.22 format
    parameter int COEF_FRACT         = 22, // fractional bits
    parameter int INTERNAL_PRECISION = 8   // extra state precision (still used in REG_WIDTH only)
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  filter_params_t                params,

    input  logic signed [COEF_WIDTH-1:0]  F,
    input  logic signed [COEF_WIDTH-1:0]  Damp,
    input  logic signed [AUDIO_WIDTH-1:0] signal_in,

    output logic signed [AUDIO_WIDTH-1:0] HP,
    output logic signed [AUDIO_WIDTH-1:0] LP,
    output logic signed [AUDIO_WIDTH-1:0] BP,
    output logic signed [AUDIO_WIDTH-1:0] Notch
);

    // =========================================================
    // CONFIGURATION
    // =========================================================
    localparam int REG_WIDTH  = AUDIO_WIDTH + INTERNAL_PRECISION;
    localparam int PROD_WIDTH = REG_WIDTH + COEF_WIDTH;

    // Correct rounding
    localparam logic signed [PROD_WIDTH-1:0] ROUND_VAL = (64'sd1 <<< (COEF_FRACT - 1));

    // Saturation limits (audio domain)
    localparam logic signed [REG_WIDTH-1:0] POS_MAX = (2**(AUDIO_WIDTH - 1)) - 1;
    localparam logic signed [REG_WIDTH-1:0] NEG_MAX = -(2**(AUDIO_WIDTH - 1));

    // =========================================================
    // STATE REGISTERS
    // =========================================================
    logic signed [REG_WIDTH-1:0] lp_reg, bp_reg;

    // =========================================================
    // INTERNAL SIGNALS
    // =========================================================
    logic signed [REG_WIDTH-1:0] x_ext;

    logic signed [REG_WIDTH-1:0] hp_next, bp_next, lp_next, notch_next;
    logic signed [REG_WIDTH-1:0] hp_wrapped;

    logic signed [PROD_WIDTH-1:0] damp_prod, bp_prod, lp_prod;
    logic signed [REG_WIDTH-1:0]  damp_term, bp_term, lp_term;

    // =========================================================
    // INPUT (NO SCALING — FIXED)
    // =========================================================
    // Sign-extend input to REG_WIDTH
    assign x_ext = {{(REG_WIDTH - AUDIO_WIDTH){signal_in[AUDIO_WIDTH-1]}}, signal_in};

    // =========================================================
    // CORE FILTER
    // =========================================================
    always_comb begin
        // --- High-Pass ---
        damp_prod = Damp * bp_reg;
        damp_term = (damp_prod + ROUND_VAL) >>> COEF_FRACT;
        hp_next   = x_ext - lp_reg - damp_term;

        // Explicit wrap (truncate to REG_WIDTH)
        hp_wrapped = hp_next;

        // --- Band-Pass ---
        bp_prod = F * hp_wrapped;
        bp_term = (bp_prod + ROUND_VAL) >>> COEF_FRACT;
        bp_next = bp_reg + bp_term;

        // --- Low-Pass ---
        lp_prod = F * bp_next;
        lp_term = (lp_prod + ROUND_VAL) >>> COEF_FRACT;
        lp_next = lp_reg + lp_term;

        // --- Notch ---
        notch_next = hp_next + lp_next;
    end

    // =========================================================
    // STATE UPDATE
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bp_reg <= '0;
            lp_reg <= '0;
        end else if (en) begin
            bp_reg <= bp_next;
            lp_reg <= lp_next;
        end
    end

    // =========================================================
    // SATURATION FUNCTION
    // =========================================================
    function automatic logic signed [AUDIO_WIDTH-1:0]
    saturate(input logic signed [REG_WIDTH-1:0] val);
        if (val > POS_MAX)
            return POS_MAX[AUDIO_WIDTH-1:0];
        else if (val < NEG_MAX)
            return NEG_MAX[AUDIO_WIDTH-1:0];
        else
            return val[AUDIO_WIDTH-1:0];
    endfunction

    // =========================================================
    // OUTPUTS (NO DOWNSHIFT — FIXED)
    // =========================================================
    assign HP    = saturate(hp_next);
    assign BP    = saturate(bp_next);
    assign LP    = saturate(lp_next);
    assign Notch = saturate(notch_next);

endmodule
