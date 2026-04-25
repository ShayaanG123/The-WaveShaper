`timescale 1ns / 1ps

module square_filter_tb;

    // --- Parameters ---
    localparam int AUDIO_WIDTH        = 32;
    localparam int COEF_WIDTH         = 24;
    localparam int COEF_FRACT         = 22;
    localparam int INTERNAL_PRECISION = 8;
    localparam int ACC_WIDTH          = 32;
    localparam int NUM_SAMPLES        = 1024;

    // --- Signals ---
    logic clk, rst_n, en;
    logic [ACC_WIDTH-1:0] tuning_word;
    logic signed [AUDIO_WIDTH-1:0] square_raw;
    logic signed [COEF_WIDTH-1:0] F_coeff, Damp;
    logic signed [AUDIO_WIDTH-1:0] HP, LP, BP, Notch;

    // --- Golden Reference Memory ---
    // Added missing declarations for HP and BP
    logic [AUDIO_WIDTH-1:0] lp_golden_ref [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] bp_golden_ref [0:NUM_SAMPLES-1];
    logic [AUDIO_WIDTH-1:0] hp_golden_ref [0:NUM_SAMPLES-1];

    // Error Tracking
    int lp_errors = 0, bp_errors = 0, hp_errors = 0;
    int fd_lp, fd_hp, fd_bp;
    string path = "/afs/ece.cmu.edu/usr/shayaang/Private/18500/MatlabSim/Filters/SV_Verification/";

    // --- Instantiations ---
    osc_square #(.ACC_WIDTH(ACC_WIDTH), .OUT_WIDTH(AUDIO_WIDTH)) osc_inst (
        .clk(clk), .rst_n(rst_n), .tuning_word(tuning_word), .enable(en), .sq_out(square_raw)
    );

    Chamberlin_SVF #(
        .AUDIO_WIDTH(AUDIO_WIDTH), .COEF_WIDTH(COEF_WIDTH), 
        .COEF_FRACT(COEF_FRACT), .INTERNAL_PRECISION(INTERNAL_PRECISION)
    ) filter_inst (
        .clk(clk), .rst_n(rst_n), .en(en), .F(F_coeff), .Damp(Damp),
        .signal_in(square_raw), .HP(HP), .LP(LP), .BP(BP), .Notch(Notch)
    );

    // --- Clock Generation ---
    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        en = 0;
        forever begin
            #(20833); @(posedge clk); en = 1;
            @(posedge clk); en = 0;
        end
    end

    // --- Verification Sequence ---
    initial begin
        // 1. Load ALL golden files
        $readmemh("/afs/ece.cmu.edu/usr/shayaang/Private/18500/Filters/Matlab_Verification/Matlab_Hex/square_filter_lp_golden.hex", lp_golden_ref);
        $readmemh("/afs/ece.cmu.edu/usr/shayaang/Private/18500/Filters/Matlab_Verification/Matlab_Hex/square_filter_bp_golden.hex", bp_golden_ref);
        $readmemh("/afs/ece.cmu.edu/usr/shayaang/Private/18500/Filters/Matlab_Verification/Matlab_Hex/square_filter_hp_golden.hex", hp_golden_ref);

        // 2. Open log files
        fd_lp = $fopen({path, "sv_lp_out.txt"}, "w");
        fd_hp = $fopen({path, "sv_hp_out.txt"}, "w");
        fd_bp = $fopen({path, "sv_bp_out.txt"}, "w");

        if (!fd_lp || !fd_hp || !fd_bp) begin
            $display("FATAL: File handle error.");
            $finish;
        end

        // 3. Reset and Init
        rst_n = 0;
        tuning_word = 32'd9842749; // 110Hz
        F_coeff = 24'd60393;
        Damp    = 24'd1048576;
        #100 rst_n = 1;

        $display("--- Starting Integrated LP/BP/HP Verification ---");

        // 4. Verification Loop
        for (int i = 0; i < NUM_SAMPLES; i++) begin
            @(posedge en);
            @(negedge clk); // Sample after logic settles

            $fdisplay(fd_lp, "%08h", LP);
            $fdisplay(fd_hp, "%08h", HP);
            $fdisplay(fd_bp, "%08h", BP);

            // Detailed Comparison
            if (LP !== lp_golden_ref[i]) begin
                $display("[LP ERR] Sample %0d | RTL: %h | Golden: %h", i, LP, lp_golden_ref[i]);
                lp_errors++;
            end
            if (BP !== bp_golden_ref[i]) begin
                $display("[BP ERR] Sample %0d | RTL: %h | Golden: %h", i, BP, bp_golden_ref[i]);
                bp_errors++;
            end
            if (HP !== hp_golden_ref[i]) begin
                $display("[HP ERR] Sample %0d | RTL: %h | Golden: %h", i, HP, hp_golden_ref[i]);
                hp_errors++;
            end
        end

        // 5. Final Report
        $display("\n--- Verification Report ---");
        $display("LP Mismatches: %0d", lp_errors);
        $display("BP Mismatches: %0d", bp_errors);
        $display("HP Mismatches: %0d", hp_errors);
        
        if ((lp_errors + bp_errors + hp_errors) == 0)
            $display("SUCCESS: All filter modes match Golden Reference.");
        else
            $display("FAILURE: Check logs for details.");

        $fclose(fd_lp); $fclose(fd_hp); $fclose(fd_bp);
        $finish;
    end

endmodule