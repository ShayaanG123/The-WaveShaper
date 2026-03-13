`timescale 1ns / 1ps

module tb_osc_square();

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic [31:0] tuning_word;
    logic        enable;
    logic [23:0] sq_out;

    // Instantiate the Unit Under Test (UUT)
    osc_square uut (
        .clk(clk),
        .rst_n(rst_n),
        .tuning_word(tuning_word),
        .enable(enable),
        .sq_out(sq_out)
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
        
        // Tuning word calculation:
        // If clk = 100MHz, and we want ~1MHz output:
        // M = (1MHz * 2^32) / 100MHz = 42,949,672 (approx 0x028F5C28)
        tuning_word = 32'h028F5C28; 

        // 1. Reset sequence
        #20 rst_n = 1;
        #20 enable = 1;
        
        // 2. Observe the ramp for a while
        #5000;

        // 3. Change frequency (Double it to ~2MHz)
        tuning_word = 32'h051EB851;
        #5000;

        // 1. Reset sequence
        #20 rst_n = 1;
        #20 enable = 1;
        
        // 2. Observe the ramp for a while
        #5000;

        tuning_word = 32'h80000000;
        #5000;

        // 4. Test disable
        enable = 0;
        #1000;
        
        $display("Simulation Finished");
        $finish;
    end

endmodule