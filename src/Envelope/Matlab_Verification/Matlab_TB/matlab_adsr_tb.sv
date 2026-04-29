`timescale 1ns / 1ps

module matlab_adsr_tb;

    // --- Parameters ---
    localparam int AUDIO_WIDTH = 24;
    localparam int ENV_WIDTH   = 32;
    localparam int ENV_FRACT   = 16;
    localparam int NUM_SAMPLES = 2048;

    // --- Signals ---
    logic clk, rst_n, en;
    logic gate_sig;
    logic signed [AUDIO_WIDTH-1:0] audio_sig;
    
    // ADSR Coefficients
    logic [ENV_WIDTH-1:0] a_step  = 32'd200;
    logic [ENV_WIDTH-1:0] d_step  = 32'd50;
    logic [ENV_WIDTH-1:0] s_level = 32'd32768; 
    logic [ENV_WIDTH-1:0] r_step  = 32'd100;
    
    logic signed [AUDIO_WIDTH-1:0] audio_out;
    logic out_valid;

    // --- Golden Reference Memory ---
    logic signed [AUDIO_WIDTH-1:0] in_audio_ref [0:NUM_SAMPLES-1];
    logic        [0:0]             in_gate_ref  [0:NUM_SAMPLES-1];
    logic signed [AUDIO_WIDTH-1:0] out_golden   [0:NUM_SAMPLES-1];

    int err_count = 0;
    int input_err_count = 0;
    int fd_out;
    
    // --- PATHS (Unchanged) ---
    string path     = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/MatlabSim/Envelopes/SV_Verification/";
    string hex_path = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/Envelope/Matlab_Verification/Matlab_Hex/";

    // --- 1. Instantiate ADSR (DUT) ---
    adsr #(
        .AUDIO_WIDTH(AUDIO_WIDTH),
        .ENV_WIDTH(ENV_WIDTH),
        .ENV_FRACT(ENV_FRACT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(en),
        .gate(gate_sig),
        .attack_step(a_step),
        .decay_step(d_step),
        .sustain_level(s_level),
        .release_step(r_step),
        .audio_in(audio_sig),
        .audio_out(audio_out),
        .out_valid(out_valid)
    );

    // --- 2. Clock and Enable ---
    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        en = 0;
        forever begin
            #(20833); @(posedge clk); en = 1;
            @(posedge clk); en = 0;
        end
    end

    // --- 3. Main Verification ---
    initial begin
        // Load Hex Files
        $readmemh({hex_path, "adsr_in_audio_golden.hex"}, in_audio_ref);
        $readmemh({hex_path, "adsr_in_gate_golden.hex"},  in_gate_ref);
        $readmemh({hex_path, "adsr_out_golden.hex"},      out_golden);

        fd_out = $fopen({path, "sv_adsr_out.txt"}, "w");
        if (!fd_out) begin
            $display("FATAL: Could not open output log file at %s", path);
            $finish;
        end
        
        // Initial state
        gate_sig  = 0;
        audio_sig = 0;
        rst_n = 0;
        #100 rst_n = 1;

        $display("--- Starting ADSR Envelope Verification ---");

        for (int i = 0; i < NUM_SAMPLES; i++) begin
            // Drive inputs
            gate_sig  = in_gate_ref[i];
            audio_sig = in_audio_ref[i];

            @(posedge en);

            // --- INPUT VERIFICATION ---
            // Check that the audio driven to the DUT matches the reference
            if (audio_sig !== in_audio_ref[i]) begin
                if (input_err_count < 10) // Limit console spam
                    $display("[ERR INPUT] Sample %0d | Driven: %h | Ref: %h", i, audio_sig, in_audio_ref[i]);
                input_err_count++;
            end

            @(negedge clk); // Wait for pipeline registers to update

            // Log output
            $fdisplay(fd_out, "%06x", audio_out);

            // --- OUTPUT VERIFICATION ---
            if (audio_out !== out_golden[i]) begin
                if (err_count < 10) // Limit console spam
                    $display("[ERR OUTPUT] Sample %0d | RTL: %h | Gold: %h", i, audio_out, out_golden[i]);
                err_count++;
            end
        end

        $display("\n--- Verification Results ---");
        $display("Total Input Mismatches:  %0d", input_err_count);
        $display("Total Output Mismatches: %0d", err_count);
        
        if (err_count == 0 && input_err_count == 0) 
            $display("SUCCESS: ADSR perfectly matches Golden Reference.");
        else
            $display("FAILURE: Mismatches detected in verification.");
        
        $fclose(fd_out);
        $finish;
    end

endmodule