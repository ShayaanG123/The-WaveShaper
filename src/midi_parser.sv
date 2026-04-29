module midi_parser #(
  parameter int NUM_CHANNELS = 4
) (
  input logic clock,
  input logic rst_n,
  input logic [24:0] midi_command,
  input logic midi_valid,

  output  logic [7:0] note [NUM_CHANNELS-1:0],
  output  logic [7:0] velocity [NUM_CHANNELS-1:0],
  output logic note_active [NUM_CHANNELS-1:0],

  output logic [7:0] cc_num,
  output logic [7:0] cc_value,
  output logic cc_valid
  );

  logic [7:0] midi_status,
              midi_data_1,
              midi_data_2;

  // Little endian
  assign { midi_data_2, midi_data_1, midi_status } = midi_command;

  logic [3:0] midi_idx;
  assign midi_idx = midi_command[19:16];

  always_ff @(posedge clock or negedge rst_n) begin
    if (!rst_n) begin
      cc_valid <= 1'b0;

      for (int i = 0; i < NUM_CHANNELS; i++) begin
        note_active[i] <= 1'b0;
        note[i] <= 8'h0;
		velocity[i] <= 8'h0;
      end
    end else if (midi_valid) begin
      case (midi_status[7:4])
          4'h9: begin
              cc_valid <= 1'b0;
              note_active[midi_idx] <= 1'b1;
              velocity[midi_idx]    <= midi_data_2;
              note[midi_idx]        <= midi_data_1;
          end
          4'h8: begin
              cc_valid <= 1'b0;
              note_active[midi_idx] <= 1'b0;
          end
          4'hB: begin
            cc_valid <= 1'b1;
            cc_num   <= midi_data_1;
            cc_value <= midi_data_2;
          end
      endcase
    end
  end
endmodule : midi_parser

