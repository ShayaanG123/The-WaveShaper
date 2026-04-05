//copyright
`default_nettype none
module osc_test(
    input logic CLOCK_50,
    input logic [3:0] KEY,
    input logic [9:0] SW,
    output logic [9:0] LEDR
    );
    logic [25:0] ctr;
    always_ff @(posedge CLOCK_50) begin
        ctr <= ctr + 1;
    end

    assign LEDR[0] = ctr[25];

endmodule 
