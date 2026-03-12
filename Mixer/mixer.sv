`timescale 1ns / 1ps

module mixer
    #(
        parameter int OUT_WIDTH = 24,
        parameter int COEF_WIDTH = 32
    )
    (
        input  logic                  clk,
        input  logic                  rst_n,
        input  logic                  enable,

        // Audio is now strictly unsigned (0 to 2^OUT_WIDTH - 1)
        input  logic [OUT_WIDTH-1:0]  saw_out,
        input  logic [OUT_WIDTH-1:0]  square_out,
        input  logic [OUT_WIDTH-1:0]  sine_out,
        input  logic [OUT_WIDTH-1:0]  tri_out,
        input  logic [OUT_WIDTH-1:0]  noise_out,

        // Coefficients are unsigned (0 to Max representing 0.0 to ~1.0)
        input  logic [COEF_WIDTH-1:0] saw_coef,
        input  logic [COEF_WIDTH-1:0] square_coef,
        input  logic [COEF_WIDTH-1:0] sine_coef,
        input  logic [COEF_WIDTH-1:0] tri_coef,
        input  logic [COEF_WIDTH-1:0] noise_coef,

        output logic [OUT_WIDTH-1:0]  wave_out,
        output logic                  out_valid
    );

    // 1. Bit Growth Calculations
    // Product width = Audio bits + Coef bits 
    // (Removed the +1 because we no longer need the signed bit padding)
    localparam int PROD_WIDTH = OUT_WIDTH + COEF_WIDTH;
    
    // Sum width = Product width + 3 extra bits (to safely add 5 numbers without internal overflow)
    localparam int SUM_WIDTH = PROD_WIDTH + 3;

    // Internal pipeline registers (now unsigned)
    logic [PROD_WIDTH-1:0] saw_prod, square_prod, sine_prod, tri_prod, noise_prod;
    logic [SUM_WIDTH-1:0]  mixer_sum;

    // 2. Multiplier Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            saw_prod    <= '0;
            square_prod <= '0;
            sine_prod   <= '0;
            tri_prod    <= '0;
            noise_prod  <= '0;
        end else if (enable) begin
            // Pure unsigned multiplication. Simple and clean.
            saw_prod    <= saw_out    * saw_coef;
            square_prod <= square_out * square_coef;
            sine_prod   <= sine_out   * sine_coef;
            tri_prod    <= tri_out    * tri_coef;
            noise_prod  <= noise_out  * noise_coef;
        end
    end

    // 3. Adder Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mixer_sum <= '0;
            wave_out  <= '0;
            out_valid <= 1'b0;
        end else if (enable) begin
            mixer_sum <= saw_prod + square_prod + sine_prod + tri_prod + noise_prod; 
            
            // Scale the output back down to OUT_WIDTH.
            // Get MSB of product which starts at COEF_WIDTH + OUT_WIDTH - 1
            //Bits above were used to prevent overflow
            wave_out  <= mixer_sum[COEF_WIDTH + OUT_WIDTH - 1 -: OUT_WIDTH];
            
            // Valid goes high to indicate data is ready
            out_valid <= 1'b1; 
        end
    end

endmodule