module top(input logic CLOCK_50,
           input logic [3:0] KEY,
			  output logic [9:0] LEDR,
			  inout wire FPGA_I2C_SDAT,
			  output logic FPGA_I2C_SCLK,
			  output logic AUD_XCK,
			  input logic AUD_BCLK,
			  output reg AUD_DACDAT,
			  input logic AUD_DACLRCK
);
  logic reset;
  assign reset = ~KEY[0];

  logic signed [31:0] DA_MUSIC;
  logic aclk;
  
  logic [7:0] A,D,S,R;
  assign A = 8'hff;
  assign D = 8'h00;
  assign S = 8'hff;
  assign R = 8'hff;

  clock_count rollover_counter(.clk(CLOCK_50), .reset(reset), .aclk(aclk));
  
  logic signed [31:0] osc_out;
  osc_saw #(
        .ACC_WIDTH(32),
        .OUT_WIDTH(32))
		  x(.clk(aclk), .rst_n(~reset), .tuning_word(32'd19351404), // .tuning_word(32'd38702809), 
              .enable(1'b1), .saw_out(osc_out));

  logic [23:0] env;

  ADSR_envelope_onevoice #(.BIT_DEPTH(24), .OPTION_DEPTH(8))
                        eg (.clk(aclk), .rst_l(~reset), .gate(~KEY[1]),
                        .attack_time(A), .decay_time(D), .sustain_level(S),
                        .release_time(R), .control_wave(env));
  logic signed [56:0] result, result2;
  assign result = osc_out * $signed({1'b0 ,env});
  assign result2 = osc_out * 24'hFFFFFF;
  //= (({24'h0, osc_out} * {24'h0, env} >>> 24);

  assign DA_MUSIC = osc_out;
  
  always_ff @(posedge CLOCK_50) begin
	if (aclk) begin
		DA_MUSIC <= (result >>> 24);//(result2 >>> 24);//(({24'h0, osc_out} * {24'h0, env} >>> 24);
	end
	else begin
		DA_MUSIC <= DA_MUSIC;
	end
end
  audio_sink SINKSUNK(.clk(CLOCK_50),
                      .reset(reset),
                      .active(1'b1),
                      .audio_stream(DA_MUSIC),
			             .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
			             .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
							 .AUD_XCK(AUD_XCK),
			             .AUD_BCLK(AUD_BCLK),
			             .AUD_DACDAT(AUD_DACDAT),
			             .AUD_DACLRCK(AUD_DACLRCK),
							 .left_ready(LEDR[0]),
							 .right_ready(LEDR[1])
  );

endmodule: top