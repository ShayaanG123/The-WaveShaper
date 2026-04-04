module osc_sine #(
    parameter int ACC_WIDTH = 32,
    parameter int OUT_WIDTH = 32,
    parameter int ROM_WIDTH = 32  
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [ACC_WIDTH-1:0]   tuning_word,
    input  logic                   enable,
    output logic signed [OUT_WIDTH-1:0] sine_out
);

    logic [ACC_WIDTH-1:0] phase_acc;
    logic [ROM_WIDTH-1:0] rom_q;
    logic [7:0] rom_addr;

    // 1. Phase Accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            phase_acc <= '0;
        else if (enable) 
            phase_acc <= phase_acc + tuning_word;
    end

    // 2. Drive the ROM address directly from the accumulator
    assign rom_addr = phase_acc[31:24];

    // 3. Quartus IP ROM (Latency is usually 1 or 2 cycles)
    sine_rom u_sine_rom (
        .address ( rom_addr ),
        .clock   ( clk ),
        .q       ( rom_q )
    );

    // 4. Output Register: Capture the ROM result
    // We don't use 'if (enable)' here because the ROM output 
    // arrives 1-2 cycles AFTER the enable pulse.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            sine_out <= '0;
        else 
            sine_out <= rom_q; 
    end

endmodule