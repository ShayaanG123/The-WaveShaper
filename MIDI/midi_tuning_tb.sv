`timescale 1ns / 1ps

module tb_midi_to_tuning_word;

    logic [6:0]  midi_number;
    logic [31:0] clock_freq;
    logic [31:0] tuning_word;

    midi_to_tuning_word dut (
        .midi_number(midi_number),
        .clock_freq(clock_freq),
        .tuning_word(tuning_word)
    );

    real actual_hz;
    real expected_hz;

    // 48 kHz is the standard for most audio DACs
    localparam logic [31:0] CLK_48K = 32'd48000;

    task test_note(input logic [6:0] note, input logic [31:0] clk);
        begin
            midi_number = note;
            clock_freq  = clk;
            #10; 

            // Calculate actual Hz based on the REAL 48kHz clock
            actual_hz = (real'(tuning_word) * real'(clk)) / (2.0**32.0);
            expected_hz = 440.0 * (2.0**((real'(note) - 69.0)/12.0));

            $display("MIDI: %3d | Note: %s | Out: %8.2f Hz (Ideal: %8.2f Hz) | Error: %8.2f Hz", 
                      note, get_note_name(note), actual_hz, expected_hz, actual_hz - expected_hz);
        end
    endtask

    // Helper function for pretty printing
    function string get_note_name(logic [6:0] n);
        string names[12] = '{"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
        return names[n % 12];
    endfunction

    initial begin
        $display("======================================================================================");
        $display("Simulating with 48 kHz Clock (Note: 48000 is NOT a power of 2!)");
        $display("======================================================================================");

        test_note(7'd69, CLK_48K); // A4 (Expect ~644 Hz instead of 440 Hz)
        test_note(7'd60, CLK_48K); // Middle C
        test_note(7'd72, CLK_48K); // C5
        test_note(7'd36, CLK_48K); // C2

        $display("======================================================================================");
        $display("OBSERVATION: If Error is high, your shift-based math is flooring 48000 to 32768.");
        $display("======================================================================================");
        $finish; 
    end

endmodule