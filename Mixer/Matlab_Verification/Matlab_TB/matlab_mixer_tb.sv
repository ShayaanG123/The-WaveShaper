`timescale 1ns / 1ps

module matlab_mixer_tb;

    // --- Parameters (Matching MATLAB Generation) ---
    localparam int AUDIO_WIDTH = 24; // Updated to 24-bit for FPGA compliance
    localparam int COEF_WIDTH  = 32;
    localparam int GAIN_SH     = 16;
    localparam int ACC_WIDTH   = 32;
    localparam int NUM_SAMPLES = 1024;

    // --- Signals ---
    logic clk, rst_n, en;
    
    // Tuning Words (Matching MATLAB)
    logic [ACC_WIDTH-1:0] tw_saw = 32'd39370534; // 440Hz
    logic [ACC_WIDTH-1:0] tw_sq  = 32'd78741067; // 880Hz
    logic [ACC_WIDTH-1:0] tw_tri = 32'd19685267; // 220Hz
    
    // Oscillator Outputs
    logic signed [AUDIO_WIDTH-1:0] saw_raw, sq_raw, tri_raw;
    
    // Coefficients
    logic signed [COEF_WIDTH-1:0] coef_0p5 = 32'd32768; // 0.5 in Q16
    
    // Mixer Outputs
    logic signed [AUDIO_WIDTH-1:0] mixer_out;
    logic out_valid;

    // --- Golden Reference Memory ---
    logic [AUDIO_WIDTH-1:0] in_saw_ref   [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] in_sq_ref    [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] in_sine_ref  [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] in_tri_ref   [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] in_noise_ref [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] mixer_gold   [0:NUM_SAMPLES-1];

    // Error Tracking
    int err_count = 0;
    int fd_out;
    
    // Paths
    string path     = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/Mixer/SV_Verification/";
    string hex_path = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/Mixer/Matlab_Verification/Matlab_Hex/";

    // --- 1. Instantiate Oscillators ---
    osc_saw #(.ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(AUDIO_WIDTH)) saw_gen (
        .clk(clk), .rst_n(rst_n), .enable(en),
        .tuning_word(tw_saw), .saw_out(saw_raw)
    );

    osc_square #(.ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(AUDIO_WIDTH)) sq_gen (
        .clk(clk), .rst_n(rst_n), .enable(en),
        .tuning_word(tw_sq), .sq_out(sq_raw)
    );

    osc_triangle #(.ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(AUDIO_WIDTH)) tri_gen (
        .clk(clk), .rst_n(rst_n), .enable(en),
        .tuning_word(tw_tri), .tri_out(tri_raw)
    );

    // --- 2. Instantiate Mixer (DUT) ---
    mixer #(
        .OUT_WIDTH(AUDIO_WIDTH),
        .COEF_WIDTH(COEF_WIDTH),
        .GAIN_SH(GAIN_SH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(en),
        
        .saw_out(saw_raw),
        .square_out(sq_raw),
        .sine_out(24'sh0),   // Sine grounded in this test
        .tri_out(tri_raw),
        .noise_out(24'sh0),  // Noise grounded in this test

        .saw_coef(coef_0p5),
        .square_coef(coef_0p5),
        .sine_coef(32'sh0), 
        .tri_coef(coef_0p5),
        .noise_coef(32'sh0),

        .wave_out(mixer_out),
        .out_valid(out_valid)
    );

    // --- 3. Clock and Enable ---
    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        en = 0;
        forever begin
            #(20833); @(posedge clk); en = 1;
            @(posedge clk); en = 0;
        end
    end

    // --- 4. Main Verification ---
    initial begin
        // Load Hex Files
        $readmemh({hex_path, "mixer_in_saw_golden.hex"},    in_saw_ref);
        $readmemh({hex_path, "mixer_in_square_golden.hex"}, in_sq_ref);
        $readmemh({hex_path, "mixer_in_sine_golden.hex"},   in_sine_ref);
        $readmemh({hex_path, "mixer_in_tri_golden.hex"},    in_tri_ref);
        $readmemh({hex_path, "mixer_in_noise_golden.hex"},  in_noise_ref);
        $readmemh({hex_path, "mixer_golden.hex"},           mixer_gold);

        fd_out = $fopen({path, "sv_mixer_out.txt"}, "w");
        
        rst_n = 0;
        #100 rst_n = 1;

        $display("--- Starting MULTI-CHANNEL MIXER Verification ---");

        for (int i = 0; i < NUM_SAMPLES; i++) begin
            @(posedge en);
            @(negedge clk); 

            // Input Verification (Check oscillators before mixing)
            if (saw_raw !== in_saw_ref[i]) begin
                $display("[ERR SAW] Sample %0d | RTL: %h | Gold: %h", i, saw_raw, in_saw_ref[i]);
                err_count++;
            end
            if (sq_raw !== in_sq_ref[i]) begin
                $display("[ERR SQ] Sample %0d | RTL: %h | Gold: %h", i, sq_raw, in_sq_ref[i]);
                err_count++;
            end
            if (tri_raw !== in_tri_ref[i]) begin
                $display("[ERR TRI] Sample %0d | RTL: %h | Gold: %h", i, tri_raw, in_tri_ref[i]);
                err_count++;
            end

            // Output Verification
            if (mixer_out !== mixer_gold[i]) begin
                $display("[ERR MIXER] Sample %0d | RTL: %h | Gold: %h", i, mixer_out, mixer_gold[i]);
                err_count++;
            end
        end

        $display("\nVerification Finished. Total Errors: %0d", err_count);
        if (err_count == 0) $display("SUCCESS: Mixer and Inputs match Golden Reference.");
        
        $fclose(fd_out);
        $finish;
    end

endmodule