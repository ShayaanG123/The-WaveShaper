module midi_to_tuning_word (
    input  logic [6:0]  midi_number, 
    output logic [31:0] tuning_word
);

    logic [3:0] octave;
    logic [3:0] semitone;
    
    always_comb begin
        octave   = midi_number / 12; 
        semitone = midi_number % 12;
    end

    // Formula: M = round( (440 * 2^((semitone - 9)/12) * 2^32) / 48000 )
    logic [31:0] base_m;
    
    always_comb begin
        case (semitone)
            4'd0:  base_m = 32'd23409476; // C5
            4'd1:  base_m = 32'd24799445; // C#5
            4'd2:  base_m = 32'd26274013; // D5
            4'd3:  base_m = 32'd27836366; // D#5
            4'd4:  base_m = 32'd29491659; // E5
            4'd5:  base_m = 32'd31245286; // F5
            4'd6:  base_m = 32'd33103168; // F#5
            4'd7:  base_m = 32'd35071595; // G5
            4'd8:  base_m = 32'd37157014; // G#5
            4'd9:  base_m = 32'd39370534; // A5  (440.00 Hz ideal)
            4'd10: base_m = 32'd41712042; // A#5
            4'd11: base_m = 32'd44192610; // B5
            default: base_m = 32'd0;      // Safe fallback
        endcase
    end

    // 3. Shift for the correct octave
    always_comb begin
        if (octave >= 5) begin
            tuning_word = base_m << (octave - 5);
        end else begin
            tuning_word = base_m >> (5 - octave);
        end
    end

endmodule