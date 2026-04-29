module midi #(
  parameter int NUM_CHANNELS = 4
) (
  input logic clock,
  input logic rst_n,
  input logic [31:0] midi_command,
  input logic midi_valid,
  output logic note_active  [NUM_CHANNELS-1:0],
  output osc_params_t osc_p_array  [NUM_CHANNELS-1:0],
  output filter_params_t fil_p_array  [NUM_CHANNELS-1:0],
  output adsr_params_t env_p_array  [NUM_CHANNELS-1:0]
  );

  logic [7:0] cc_num;
  logic [7:0] cc_value;
  logic cc_valid;

  // Oscillator weights are determined by CC
  // commands, whereas their presence and
  // velocities are determined by Note On/Off.
  // We can't just map to a single port.
  coefs_t      osc_weightings [NUM_CHANNELS-1:0];
  logic [7:0]  osc_note_nums  [NUM_CHANNELS-1:0];
  logic [7:0]  osc_velocities [NUM_CHANNELS-1:0];

  midi_parser #(.NUM_CHANNELS(NUM_CHANNELS)) parser (
    .clock(clock),
    .rst_n(rst_n),
    .midi_command(midi_command),
    .midi_valid(midi_valid),
    .note_active(note_active),
    .note(osc_note_nums),
    .velocity(osc_velocities),
    .cc_num(cc_num),
    .cc_value(cc_value),
    .cc_valid(cc_valid)
  );

  midi_cc_router #(.NUM_CHANNELS(NUM_CHANNELS)) router(
    .clock             (clock),
    .rst_n             (rst_n),
    .cc_num            (cc_num),
    .cc_value          (cc_value),
    .cc_valid          (cc_valid),
    .osc_coefs_array   (osc_weightings),
    .fil_p_array       (fil_p_array),
    .env_p_array       (env_p_array)
  );

  always_comb begin
    for (int i = 0; i < NUM_CHANNELS; i++) begin
        osc_p_array[i] = '{
            coefs:    osc_weightings[i],
            note_idx: osc_note_nums[i],
            velocity: osc_velocities[i]
        };
    end
  end

endmodule : midi

