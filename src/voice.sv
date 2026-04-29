`timescale 1ns / 1ps
import waveshaper_types::*;

module voice(input clk,
             input rst_n,
             input osc_params_t    osc_p,
             input adsr_params_t   adsr_p,
             input filter_params_t filt_p,
             input enable,
             output valid,
             output probe_out,
             output voice_out);
    // TODO: this lol
    assign probe_out = '0;

    logic signed [23:0] osc_out;
	 logic osc_valid;
    logic signed [23:0] filter_out;
    logic signed [23:0] adsr_out;

    synth_osc_bank #(
      .ACC_WIDTH(32),
      .OUT_WIDTH(24),
      .COEF_WIDTH(32)
    ) osc_bank (
        .clk       (clk),
        .rst_n     (rst_n),
        .enable    (enable),
        .params    (osc_p),
        .wave_out  (osc_out),
        .out_valid (osc_valid)
    );

    assign voice_out = osc_out;
    assign valid = osc_valid;

    // Chamberlin_SVF #(
    //   .AUDIO_WIDTH(OUT_WIDTH),
    //   .COEF_WIDTH(24),
    //   .COEF_FRACT(22),
    //   .INTERNAL_PRECISION(8)
    // ) filter (
    //   .clk          (clk),
    //   .rst_n        (rst_n),
    //   .en           (osc_valid[v_idx]),
    //   .signal_in    (osc_out),
    //   .params       ()
    //   .filter_out   (notch_out),
    //   .filter_valid (filter_valid[v_idx])
    // );

    // adsr #(
    //   .AUDIO_WIDTH(24),
    //   .ENV_WIDTH(OPT_DEPTH),
    //   .ENV_FRACT(OPT_DEPTH / 2)
    // ) adsr_envelope(
    //     .clk       (),
    //     .rst_n     (),
    //     .enable    (),
    //     .gate      (),
    //     .params    (),
    //     .audio_in  (),
    //     .audio_out (),
    //     .out_valid ()
    // );
endmodule: voice
