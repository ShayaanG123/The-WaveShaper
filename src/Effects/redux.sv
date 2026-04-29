`timescale 1ns / 1ps

module redux #(
    parameter int AUDIO_WIDTH = 32,
    parameter int BIT_CRUSH   = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  logic signed [AUDIO_WIDTH-1:0] signal_in,
    output logic signed [AUDIO_WIDTH-1:0] signal_out
);

    // =========================================================
    // CONFIGURATION (MASK)
    // =========================================================
    // Creates a mask of all 1s, then shifts left to zero out the LSBs.
    localparam logic [AUDIO_WIDTH-1:0] BIT_CRUSH_MASK = {AUDIO_WIDTH{1'b1}} << BIT_CRUSH;

    // =========================================================
    // INTERNAL SIGNALS
    // =========================================================
    logic signed [AUDIO_WIDTH-1:0] signal_out_next;

    // =========================================================
    // COMBINATIONAL LOGIC
    // =========================================================
    always_comb begin
        // Apply the mask to truncate the lower bits
        signal_out_next = signal_in & BIT_CRUSH_MASK;
    end

    // =========================================================
    // SEQUENTIAL LOGIC
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_out <= '0;
        end else if (en) begin
            signal_out <= signal_out_next;
        end
    end

endmodule