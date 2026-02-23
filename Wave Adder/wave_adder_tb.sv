`timescale 1ns / 1ps

module tb_synth_osc_bank();

    // --- Testbench Parameters ---
    localparam int ACC_WIDTH  = 32;
    localparam int OUT_WIDTH  = 24;
    localparam int COEF_WIDTH = 32;

    // --- Signals ---
    logic                  clk;
    logic                  rst_n;
    logic                  enable;
    logic [ACC_WIDTH-1:0]  tuning_word;

    // Coefficients (Volume Controls)
    logic [COEF_WIDTH-1:0] saw_coef;
    logic [COEF_WIDTH-1:0] square_coef;
    logic [COEF_WIDTH-1:0] sine_coef;
    logic [COEF_WIDTH-1:0] tri_coef;
    logic [COEF_WIDTH-1:0] noise_coef;

    // Outputs
    logic signed [OUT_WIDTH-1:0] wave_out;
    logic                        out_valid;

    // --- Device Under Test (DUT) ---
    synth_osc_bank #(
        .ACC_WIDTH(ACC_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .COEF_WIDTH(COEF_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .tuning_word(tuning_word),
        .saw_coef(saw_coef),
        .square_coef(square_coef),
        .sine_coef(sine_coef),
        .tri_coef(tri_coef),
        .noise_coef(noise_coef),
        .wave_out(wave_out),
        .out_valid(out_valid)
    );

    // --- Clock Generation ---
    // 100 MHz System Clock (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Simulation Sequence ---
    initial begin
        // 1. Initialize all inputs to zero
        rst_n       = 1'b0;
        enable      = 1'b0;
        tuning_word = '0;
        saw_coef    = '0;
        square_coef = '0;
        sine_coef   = '0;
        tri_coef    = '0;
        noise_coef  = '0;

        // 2. Hold reset for a few cycles, then release
        #20;
        rst_n = 1'b1;
        #20;

        // 3. Set a fast pitch so we can see the waves easily in simulation
        // (If this were 440Hz at 100MHz clock, TW would be tiny and take too long to simulate)
        tuning_word = 32'h00A0_0000; 
        enable      = 1'b1;

        $timeformat(-9, 0, " ns", 10);
        $display("--------------------------------------------------");
        $display("Starting Synthesizer Bank Simulation...");
        $display("--------------------------------------------------");

        // --- TEST 1: Sawtooth Only ---
        $display("[%0t] Test 1: Sawtooth Wave (100%% Volume)", $time);
        saw_coef    = 32'hFFFF_FFFF; 
        #10000;
        saw_coef    = '0;

        // --- TEST 2: Square Only ---
        $display("[%0t] Test 2: Square Wave (100%% Volume)", $time);
        square_coef = 32'hFFFF_FFFF;
        #10000;
        square_coef = '0;

        // --- TEST 3: Sine Only ---
        $display("[%0t] Test 3: Sine Wave (100%% Volume)", $time);
        sine_coef   = 32'hFFFF_FFFF;
        #10000;
        sine_coef   = '0;

        // --- TEST 4: Triangle Only ---
        $display("[%0t] Test 4: Triangle Wave (100%% Volume)", $time);
        tri_coef    = 32'hFFFF_FFFF;
        #10000;
        tri_coef    = '0;

        // --- TEST 5: Noise Only ---
        $display("[%0t] Test 5: White Noise (100%% Volume)", $time);
        noise_coef  = 32'hFFFF_FFFF;
        #10000;
        noise_coef  = '0;

        // --- TEST 6: 50/50 Split (2 Oscillators summing to 1.0) ---
        // 0x80000000 + 0x7FFFFFFF = 0xFFFFFFFF
        $display("[%0t] Test 7: Saw & Square Split (Sum = 100%%)", $time);
        saw_coef    = 32'h8000_0000;
        square_coef = 32'h7FFF_FFFF;
        sine_coef   = '0;
        tri_coef    = '0;
        noise_coef  = '0;
        #10000;

        // --- TEST 7: Perfect 5-Way Split (Summing to 1.0) ---
        // 0x33333333 * 5 = 0xFFFFFFFF
        $display("[%0t] Test 8: 5-Way Even Split (Sum = 100%%)", $time);
        saw_coef    = 32'h3333_3333;
        square_coef = 32'h3333_3333;
        sine_coef   = 32'h3333_3333;
        tri_coef    = 32'h3333_3333;
        noise_coef  = 32'h3333_3333;
        #10000;

        // --- TEST 8: The "Everything" Mix ---
        // Pushing all 5 oscillators at 50% volume to test the mixer's summing capability
        $display("[%0t] Test 6: Full Polyphonic Mix (All Oscs at 50%%)", $time);
        saw_coef    = 32'h7FFF_FFFF;
        square_coef = 32'h7FFF_FFFF;
        sine_coef   = 32'h7FFF_FFFF;
        tri_coef    = 32'h7FFF_FFFF;
        noise_coef  = 32'h7FFF_FFFF;
        #10000;

        // Stop simulation
        $display("[%0t] Simulation Complete.", $time);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule