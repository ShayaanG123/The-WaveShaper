`timescale 1ns / 1ps

module audio_tick_gen (
    input  logic CLOCK_50,
    input  logic reset,
    output logic tick_48k
);

    // 50,000,000 / 48,000 = 1041.666...
    // We count 1042 cycles (0 to 1041)
    localparam int TICK_COUNT = 1042;
    
    // 11 bits can hold up to 2047, which fits 1041 easily
    logic [10:0] counter;

    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            counter  <= '0;
            tick_48k <= 1'b0;
        end else begin
            if (counter >= TICK_COUNT - 1) begin
                counter  <= '0;
                tick_48k <= 1'b1; // Fire the strobe
            end else begin
                counter  <= counter + 1'b1;
                tick_48k <= 1'b0; // Stay low otherwise
            end
        end
    end

endmodule