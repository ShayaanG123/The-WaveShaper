import waveshaper_types::*;

// dabujabe:
// The below HDL is 100% AI-generated (Gemini), prompted
// with a near-identical previous iteration of the file,
// lacking the nicer typesetting and the parameter typedefs.

module midi_cc_router #(
    parameter int NUM_CHANNELS = NUM_VOICES,
    parameter int OPTION_DEPTH = OPT_DEPTH
) (
    input  logic clock,
    input  logic rst_n,
    input  logic [7:0] cc_num,
    input  logic [7:0] cc_value,
    input  logic cc_valid,

    output adsr_params_t   env_p_array   [NUM_CHANNELS-1:0],
    output coefs_t         osc_coefs_array  [NUM_CHANNELS-1:0],
    output filter_params_t fil_p_array [NUM_CHANNELS-1:0]
);

    always_ff @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                if (i == 0) begin
                    env_p_array[i]   <= '{default: '0};
                    osc_coefs_array[i]  <= '{default: '0};
                    fil_p_array[i] <= '{kind: LOW_P, default: '0};
                end else begin
                    env_p_array[i]   <= '{attack_time: 8'd64, decay_time: 8'd64, sustain_ampl: 8'd127, release_time: 8'd64};
                    osc_coefs_array[i]  <= '{default: '0};
                    fil_p_array[i] <= '{kind: LOW_P, default: '0};
                end
            end
        end else if (cc_valid) begin
            case (cc_num)
                // ADSR
                8'h0C: env_p_array[0].attack_time  <= cc_value;
                8'h0D: env_p_array[0].decay_time   <= cc_value;
                8'h0E: env_p_array[0].sustain_ampl <= cc_value;
                8'h0F: env_p_array[0].release_time <= cc_value;

                // Coefficients
                8'h1E: osc_coefs_array[0].sq <= cc_value;
                8'h1F: osc_coefs_array[0].sw <= cc_value;
                8'h20: osc_coefs_array[0].tr <= cc_value;
                8'h21: osc_coefs_array[0].sn <= cc_value;

                // Filter
                8'h22: fil_p_array[0].res_freq <= cc_value;
                8'h23: fil_p_array[0].damp     <= cc_value;
            endcase
        end
    end

endmodule : midi_cc_router

