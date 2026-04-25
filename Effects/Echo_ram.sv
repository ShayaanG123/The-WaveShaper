module Echo_RAM (
    input  logic [9:0]  rdaddress,
    input  logic [9:0]  wraddress,
    input  logic        clock,
    input  logic        rst_n,    // Added reset port
    input  logic [31:0] data,
    input  logic        wren,
    output logic [31:0] q
);

    logic [31:0] mem [1023:0];
    logic [31:0] q_reg;

    always_ff @(posedge clock) begin
        if (!rst_n) begin
            q_reg <= 32'h0;
            // High-level modeling tip: Some tools prefer a loop for array reset
            for (integer i = 0; i < 1024; i = i + 1) begin
                mem[i] <= 32'h0;
            end
        end else begin
            if (wren) begin
                mem[wraddress] <= data;
            end
            q_reg <= mem[rdaddress];
        end
    end

    assign q = q_reg;

endmodule