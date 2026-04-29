`timescale 1ns / 1ps

module matlab_chorus_tb;

    // --- Parameters (Matching MATLAB Generation) ---
    localparam int AUDIO_WIDTH = 32;
    localparam int ADDR_WIDTH  = 10;
    localparam int ACC_WIDTH   = 32;
    localparam int NUM_SAMPLES = 1024;

    // --- Signals ---
    logic clk, rst_n, en;
    logic [ACC_WIDTH-1:0] tuning_word_saw;
    logic [ACC_WIDTH-1:0] tuning_word_lfo;
    
    logic signed [AUDIO_WIDTH-1:0] saw_raw;
    logic signed [AUDIO_WIDTH-1:0] lfo_tri_out;
    logic signed [AUDIO_WIDTH-1:0] chorus_out;

    // --- Golden Reference Memory ---
    logic [AUDIO_WIDTH-1:0] input_golden_ref  [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] chorus_golden_ref [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] lfo_golden_ref    [0:NUM_SAMPLES-1]; // NEW: LFO Ref

    // Error Tracking
    int input_errors  = 0;
    int chorus_errors = 0;
    int lfo_errors    = 0; // NEW: LFO Error counter
    int fd_out;
    
    // Path for ECE AFS Servers
    string path = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/MatlabSim/Effects/SV_Verification/";
    string hex_path = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/Effects/Matlab_Verification/Matlab_Hex/";

    // --- 1. Instantiate Audio Source (Sawtooth) ---
    osc_saw #(
        .ACC_WIDTH(ACC_WIDTH), 
        .OUT_WIDTH(AUDIO_WIDTH)
    ) audio_src (
        .clk(clk), 
        .rst_n(rst_n), 
        .tuning_word(tuning_word_saw), 
        .enable(en), 
        .saw_out(saw_raw)
    );

    // --- 2. Instantiate LFO Source (Triangle) ---
    osc_triangle #(
        .ACC_WIDTH(ACC_WIDTH), 
        .OUT_WIDTH(AUDIO_WIDTH)
    ) lfo_src (
        .clk(clk), 
        .rst_n(rst_n), 
        .tuning_word(tuning_word_lfo), 
        .enable(en), 
        .tri_out(lfo_tri_out)
    );

    // --- 3. Instantiate Chorus (DUT) ---
    chorus #(
        .AUDIO_WIDTH(AUDIO_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .signal_in(saw_raw),
        .lfo_tri(lfo_tri_out), 
        .signal_out(chorus_out)
    );

    // --- 4. Clock and Enable Generation ---
    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        en = 0;
        forever begin
            #(20833); @(posedge clk); en = 1;
            @(posedge clk); en = 0;
        end
    end

    // --- 5. Main Verification Sequence ---
    initial begin
        // Load Hex Files
        $readmemh({hex_path, "effect_input_saw_golden.hex"}, input_golden_ref);
        $readmemh({hex_path, "chorus_golden.hex"}, chorus_golden_ref);
        $readmemh({hex_path, "lfo_tri_golden.hex"}, lfo_golden_ref); // NEW: Load LFO hex

        fd_out = $fopen({path, "sv_chorus_out.txt"}, "w");
        if (!fd_out) begin
            $display("FATAL: Could not open output log file.");
            $finish;
        end

        // Setup Tuning Words
        tuning_word_saw = 32'd39370534; // 440Hz @ 48kHz
        tuning_word_lfo = 32'd89478;    // 1Hz @ 48kHz

        // Reset Sequence
        rst_n = 0;
        #100 rst_n = 1;

        $display("--- Starting CHORUS Verification ---");
        $display("LFO Freq: 1Hz | Base Delay: 256 | Depth: 31");

        for (int i = 0; i < NUM_SAMPLES; i++) begin
            @(posedge en);
            @(negedge clk); 

            // Log output
            $fdisplay(fd_out, "%08h", chorus_out);

            // 1. Verify Audio Input Source
            if (saw_raw !== input_golden_ref[i]) begin
                $display("[INPUT ERR] Sample %0d | RTL Saw: %h | Golden: %h", i, saw_raw, input_golden_ref[i]);
                input_errors++;
            end

            // 2. Verify LFO (NEW)
            if (lfo_tri_out !== lfo_golden_ref[i]) begin
                $display("[LFO ERR] Sample %0d | RTL LFO: %h | Golden: %h", i, lfo_tri_out, lfo_golden_ref[i]);
                lfo_errors++;
            end

            // 3. Verify Chorus Output
            if (chorus_out !== chorus_golden_ref[i]) begin
                $display("[CHORUS ERR] Sample %0d | RTL: %h | Golden: %h", i, chorus_out, chorus_golden_ref[i]);
                chorus_errors++;
            end
        end

        // Final Report
        $display("\n--- CHORUS Verification Report ---");
        $display("Input Mismatches: %0d", input_errors);
        $display("LFO Mismatches:   %0d", lfo_errors);
        $display("Chorus Mismatches: %0d", chorus_errors);
        
        if ((input_errors + lfo_errors + chorus_errors) == 0)
            $display("SUCCESS: Chorus and LFO match Golden Reference.");
        else
            $display("FAILURE: Check LFO synchronization or Chorus pointer math.");

        $fclose(fd_out);
        $finish;
    end

endmodule