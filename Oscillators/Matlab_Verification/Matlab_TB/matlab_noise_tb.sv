`timescale 1ns / 1ps

module tb_osc_noise;

    // Parameters matching the osc_square module
    localparam int ACC_WIDTH = 32;
    localparam int OUT_WIDTH = 24;

    // Testbench Signals
    logic clk;
    logic rst_n;
    logic [ACC_WIDTH-1:0] tuning_word;
    logic enable;
    logic [OUT_WIDTH-1:0] noise_out;

    // Array to hold the 1000 samples from MATLAB
    // Size is [23:0] to match OUT_WIDTH, array length is 1000
    logic [OUT_WIDTH-1:0] golden_ref [0:1023];

    // Error tracking
    int errors = 0;

    // Device Under Test (DUT) Instantiation
    osc_noise #(
        .ACC_WIDTH(ACC_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .noise_out(noise_out)
    );

    // Clock Generation (100MHz / 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Your Verification Block
    initial begin
        $readmemh("/afs/ece.cmu.edu/usr/shayaang/Private/18500/Oscillators/Matlab_Verification/Matlab_Hex/noise_golden.hex", golden_ref);

        // Initial state
        rst_n = 0;
        enable = 0;


        #100 rst_n = 1;
        #20 enable = 1;

        for (int i = 0; i < 1024; i++) begin
            @(posedge clk);
            #1; // Small delay to allow combinational logic to settle

            if (noise_out !== golden_ref[i]) begin
                $display("MISMATCH @ Sample %0d | RTL: %h | Golden: %h", i, noise_out, golden_ref[i]);
                errors++;
            end
        end

        if (errors == 0) begin
            $display("SUCCESS: All 1024 samples match the MATLAB golden reference!");
        end else begin
            $display("FAILURE: %0d mismatches found during verification.", errors);
        end

        $display("Verification Complete.");
        $finish;
    end

endmodule
