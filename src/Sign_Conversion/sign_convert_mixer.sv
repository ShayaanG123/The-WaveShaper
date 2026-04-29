`timescale 1ns / 1ps

module unsigned_to_signed
    #(
        parameter int OUT_WIDTH = 24
    )
    (
        // Inputs from the unsigned stage
        input  logic [OUT_WIDTH-1:0]        wave_out,
        input  logic                        out_valid,

        // Signed outputs for the biquad or next stage
        output logic signed [OUT_WIDTH-1:0] wave_out_signed,
        output logic                        out_valid_signed
    );

    // Inverting the MSB converts an unsigned signal to two's complement.
    // This is mathematically equivalent to subtracting 2^(OUT_WIDTH-1).
    assign wave_out_signed = { ~wave_out[OUT_WIDTH-1], wave_out[OUT_WIDTH-2:0] };
    
    // The valid signal just passes straight through
    assign out_valid_signed = out_valid;

endmodule