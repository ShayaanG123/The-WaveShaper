`timescale 1ns / 1ps

module tb_osc_noise();

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic        enable;
    logic [23:0] noise_out;

    // Instantiate the Unit Under Test (UUT)
    osc_noise uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .noise_out(noise_out)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        // For DVE (Standard)
        $vcdplusfile("waveforms.vpd");
        $vcdpluson();
        
        // OR: For Verdi (Recommended if available)
        // $fsdbDumpfile("waveforms.fsdb");
        // $fsdbDumpvars(0, tb_osc_saw);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        enable = 0;

        // 1. Reset sequence
        #20 rst_n = 1;
        #20 enable = 1;
        
        // 2. Observe the ramp for a while
        #10000;

        // 4. Test disable
        enable = 0;
        #1000;
        
        $display("Simulation Finished");
        $finish;
    end

endmodule