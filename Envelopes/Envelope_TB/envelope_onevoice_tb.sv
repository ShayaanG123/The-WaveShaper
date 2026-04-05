`default_nettype none
timeunit 1ns; 
timeprecision 100ps;

module tb_ADSR();

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic [7:0] attack_time, decay_time, sustain_level, release_time;
    logic        gate;
    logic [23:0] control_wave;

    // Instantiate the Unit Under Test (UUT)
    ADSR_envelope_onevoice uut(
        .clk(clk),
        .rst_l(rst_n),
        .attack_time(attack_time),
        .decay_time(decay_time),
        .sustain_level(sustain_level),
        .release_time(release_time),
        .gate(gate),
        .control_wave(control_wave)
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
        gate = 0;
        
        attack_time = 8'h0f; 
        sustain_level = 8'h7f; 
        decay_time = 8'h0f; 
        release_time = 8'h0f; 

        // 2. Observe the EG
        #6;
        rst_n = 1;
        #53;
        gate = 1;
        #64000002; 
        gate = 0;
        #3000000;
        gate = 1;
        #32000000;
        $display("Simulation Finished");
        $finish;
    end

endmodule
