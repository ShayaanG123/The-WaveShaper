module Chamberlin_SVF
#(
    parameter int AUDIO_WIDTH = 24,
    parameter int COEF_WIDTH  = 16,
    parameter int ACC_WIDTH   = 40,
    parameter int Q_FRACT     = 15
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  logic signed [COEF_WIDTH-1:0]  F,
    input  logic signed [COEF_WIDTH-1:0]  Damp,
    input  logic signed [AUDIO_WIDTH-1:0] signal_in,

    output logic signed [AUDIO_WIDTH-1:0] HP,
    output logic signed [AUDIO_WIDTH-1:0] LP,
    output logic signed [AUDIO_WIDTH-1:0] BP,
    output logic signed [AUDIO_WIDTH-1:0] Notch
);

    // =========================================================
    // WIDE STATE
    // =========================================================
    logic signed [ACC_WIDTH-1:0] BP_reg, LP_reg;

    // =========================================================
    // FULL-PRECISION SIGNALS
    // =========================================================
    logic signed [ACC_WIDTH-1:0] hp_full, bp_full, lp_full;
    logic signed [ACC_WIDTH-1:0] signal_ext;

    // Extend input to ACC_WIDTH
    assign signal_ext = {{(ACC_WIDTH-AUDIO_WIDTH){signal_in[AUDIO_WIDTH-1]}}, signal_in};

    // =========================================================
    // CORE FILTER (NO TRUNCATION INSIDE LOOP)
    // =========================================================
    always_comb begin
        // High-pass
        hp_full = signal_ext
                - LP_reg
                - (($signed(Damp) * BP_reg) >>> Q_FRACT);

        // Band-pass
        bp_full = BP_reg
                + (($signed(F) * hp_full) >>> Q_FRACT);

        // Low-pass
        lp_full = LP_reg
                + (($signed(F) * bp_full) >>> Q_FRACT);
    end

    // =========================================================
    // STATE UPDATE
    // =========================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            BP_reg <= '0;
            LP_reg <= '0;
        end else if (en) begin
            BP_reg <= bp_full;
            LP_reg <= lp_full;
        end
    end

    // =========================================================
    // OUTPUT TRUNCATION (ONLY PLACE WE REDUCE WIDTH)
    // =========================================================
    logic signed [ACC_WIDTH-1:0] notch_full;
    assign notch_full = hp_full + lp_full;

    assign HP    = hp_full[ACC_WIDTH-1 -: AUDIO_WIDTH];
    assign BP    = bp_full[ACC_WIDTH-1 -: AUDIO_WIDTH];
    assign LP    = lp_full[ACC_WIDTH-1 -: AUDIO_WIDTH];
    assign Notch = notch_full[ACC_WIDTH-1 -: AUDIO_WIDTH];

endmodule