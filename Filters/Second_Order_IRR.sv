`timescale 1ns / 1ps

module iir_biquad
    #(
        parameter int DATA_WIDTH = 24,
        parameter int COEF_WIDTH = 32
    )
    (
        input  logic                         clk,
        input  logic                         rst_n,
        input  logic                         enable,

        // Audio signals must be signed to handle bipolar waveforms properly
        input  logic signed [DATA_WIDTH-1:0] x_in,

        // Coefficients are signed. Range depends on your fixed-point Q format.
        // Standard convention expects denominator as: 1 + a1*z^-1 + a2*z^-2
        input  logic signed [COEF_WIDTH-1:0] b0,
        input  logic signed [COEF_WIDTH-1:0] b1,
        input  logic signed [COEF_WIDTH-1:0] b2,
        input  logic signed [COEF_WIDTH-1:0] a1,
        input  logic signed [COEF_WIDTH-1:0] a2,

        output logic signed [DATA_WIDTH-1:0] y_out,
        output logic                         out_valid
    );

    // 1. Bit Growth Calculations
    localparam int PROD_WIDTH = DATA_WIDTH + COEF_WIDTH;
    
    // Sum width = Product width + 3 extra bits (to safely add/sub 5 numbers)
    localparam int SUM_WIDTH = PROD_WIDTH + 3;

    // Delay lines (State Variables: z^-1 and z^-2)
    logic signed [DATA_WIDTH-1:0] x_z1, x_z2;
    logic signed [DATA_WIDTH-1:0] y_z1, y_z2;

    // Internal pipeline registers
    logic signed [PROD_WIDTH-1:0] prod_b0, prod_b1, prod_b2;
    logic signed [PROD_WIDTH-1:0] prod_a1, prod_a2;
    logic signed [SUM_WIDTH-1:0]  filter_sum;

    // 2. State Update and Multiplier Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_z1    <= '0;
            x_z2    <= '0;
            y_z1    <= '0;
            y_z2    <= '0;
            prod_b0 <= '0;
            prod_b1 <= '0;
            prod_b2 <= '0;
            prod_a1 <= '0;
            prod_a2 <= '0;
        end else if (enable) begin
            // Shift input delay line
            x_z1 <= x_in;
            x_z2 <= x_z1;
            
            // Shift output delay line. 
            // Note: y_out is the fully summed result from the 2nd stage.
            y_z1 <= y_out;
            y_z2 <= y_z1;

            // Feedforward Multipliers
            prod_b0 <= x_in * b0;
            prod_b1 <= x_z1 * b1;
            prod_b2 <= x_z2 * b2;
            
            // Feedback Multipliers
            // We multiply against the PREVIOUS sample's output (y_out) for a1
            prod_a1 <= y_out * a1; 
            prod_a2 <= y_z1  * a2;
        end
    end

    // 3. Adder Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_sum <= '0;
            y_out      <= '0;
            out_valid  <= 1'b0;
        end else if (enable) begin
            // Sum feedforward and subtract feedback
            filter_sum <= prod_b0 + prod_b1 + prod_b2 - prod_a1 - prod_a2; 
            
            // Scale the output back down to DATA_WIDTH.
            // Note: If your IIR coefficients exceed 1.0 (e.g., Q2.30 format), 
            // you may need to shift the extraction range left by 1 or 2 bits.
            y_out <= filter_sum[COEF_WIDTH + DATA_WIDTH - 1 -: DATA_WIDTH];
            
            out_valid <= 1'b1; 
        end else begin
            out_valid <= 1'b0; // Pulse valid to indicate sample is ready
        end
    end

endmodule