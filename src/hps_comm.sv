module hps_comm(
  input logic clock,
  input logic rst_n,
  input logic [31:0] in_word,
  output logic [23:0] payload,
  output logic midi_valid,
  output logic serial_valid
  );

  assign payload = in_word[31:8];

  logic status_bit;
  assign status_bit = in_word[24];

  logic is_midi, is_serial;
  assign is_midi = in_word[25];
  assign is_serial = in_word[26];

  logic prev_status_bit0;
  logic prev_status_bit1;
  logic valid;

  always_ff @(posedge clock or negedge rst_n) begin
    if (!rst_n) begin
      prev_status_bit0 <= 1'b0;
      prev_status_bit1 <= 1'b0;
    end else begin
      prev_status_bit0 <= status_bit;
      prev_status_bit1 <= prev_status_bit0;

    end
  end

  assign valid = prev_status_bit1 ^ prev_status_bit0;

  assign midi_valid   = is_midi   & valid;
  assign serial_valid = is_serial & valid;
endmodule : hps_comm

