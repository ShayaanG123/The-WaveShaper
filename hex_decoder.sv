module hex_decoder (
    input  logic [3:0] hex_digit, // 4-bit Hex input (0-F)
    output logic [6:0] hex_out    // 7-segment output (Active-Low)
);

    always_comb begin
        case (hex_digit)
            // Segments:      gfe_dcba
            4'h0: hex_out = 7'b100_0000; // 0
            4'h1: hex_out = 7'b111_1001; // 1
            4'h2: hex_out = 7'b010_0100; // 2
            4'h3: hex_out = 7'b011_0000; // 3
            4'h4: hex_out = 7'b001_1001; // 4
            4'h5: hex_out = 7'b001_0010; // 5
            4'h6: hex_out = 7'b000_0010; // 6
            4'h7: hex_out = 7'b111_1000; // 7
            4'h8: hex_out = 7'b000_0000; // 8
            4'h9: hex_out = 7'b001_1000; // 9
            4'hA: hex_out = 7'b000_1000; // A
            4'hB: hex_out = 7'b000_0011; // b
            4'hC: hex_out = 7'b100_0110; // C
            4'hD: hex_out = 7'b010_0001; // d
            4'hE: hex_out = 7'b000_0110; // E
            4'hF: hex_out = 7'b000_1110; // F
            default: hex_out = 7'b111_1111; // All OFF
        endcase
    end

endmodule