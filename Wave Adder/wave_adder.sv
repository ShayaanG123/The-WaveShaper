module wave_adder
    #(
        parameter int OUT_WIDTH = 24,
        parameter int COEF_WIDTH = 32
    )
    (
        input  logic                  clk,
        input  logic                  rst_n,
        input  logic                  enable,

        // Audio is signed (two's complement)
        input  logic signed [OUT_WIDTH-1:0]  saw_out,
        input  logic signed [OUT_WIDTH-1:0]  square_out,
        input  logic signed [OUT_WIDTH-1:0]  sine_out,
        input  logic signed [OUT_WIDTH-1:0]  tri_out,
        input  logic signed [OUT_WIDTH-1:0]  noise_out,

        // Coefficients are unsigned (0 to Max representing 0.0 to ~1.0)
        input  logic [COEF_WIDTH-1:0] saw_coef,
        input  logic [COEF_WIDTH-1:0] square_coef,
        input  logic [COEF_WIDTH-1:0] sine_coef,
        input  logic [COEF_WIDTH-1:0] tri_coef,
        input  logic [COEF_WIDTH-1:0] noise_coef,

        output logic signed [OUT_WIDTH-1:0]  wave_out,
        output logic                         out_valid
    );

    // 1. Bit Growth Calculations
    // Product width = Audio bits + Coef bits + 1 (to force coef to be positive signed)
    localparam int PROD_WIDTH = OUT_WIDTH + COEF_WIDTH + 1;
    
    // Sum width = Product width + 3 extra bits (to safely add 5 numbers without overflow)
    localparam int SUM_WIDTH = PROD_WIDTH + 3;

    // Internal pipeline registers
    logic signed [PROD_WIDTH-1:0] saw_prod, square_prod, sine_prod, tri_prod, noise_prod;
    logic signed [SUM_WIDTH-1:0]  mixer_sum;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            saw_prod    <= '0;
            square_prod <= '0;
            sine_prod   <= '0;
            tri_prod    <= '0;
            noise_prod  <= '0;
        end else if (enable) begin
            // By prepending a 1'b0 to the coefficient, we ensure the multiplier 
            // treats it as a positive number rather than a negative two's complement value.
            saw_prod    <= saw_out    * $signed({1'b0, saw_coef});
            square_prod <= square_out * $signed({1'b0, square_coef});
            sine_prod   <= sine_out   * $signed({1'b0, sine_coef});
            tri_prod    <= tri_out    * $signed({1'b0, tri_coef});
            noise_prod  <= noise_out  * $signed({1'b0, noise_coef});
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mixer_sum <= '0;
            wave_out  <= '0;
            out_valid <= 1'b0;
        end else if (enable) begin
            // Note that we could move this to an always_comb block, but it would increase critical path
            mixer_sum <= saw_prod + square_prod + sine_prod + tri_prod + noise_prod; 
            
            // Scale the output back down to OUT_WIDTH.
            // Since we multiplied by a COEF_WIDTH fraction, the base audio scale 
            // has shifted up by COEF_WIDTH bits. We slice the top bits to normalize.
            wave_out  <= mixer_sum[SUM_WIDTH-1 -: OUT_WIDTH];
            
            // Valid goes high to indicate data is ready (2 clock cycles latency)
            out_valid <= 1'b1; 
        end
    end

endmodule
