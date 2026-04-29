import waveshaper_types::*;

module top(
      ///////// CLOCK /////////
      input              CLOCK2_50,
      input              CLOCK3_50,
      input              CLOCK4_50,
      input              CLOCK_50,

      ///////// KEY /////////
      input    [ 3: 0]   KEY,

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LED /////////
      output   [ 9: 0]   LEDR,

      ///////// Seg7 /////////
      output   [ 6: 0]   HEX0,
      output   [ 6: 0]   HEX1,
      output   [ 6: 0]   HEX2,
      output   [ 6: 0]   HEX3,
      output   [ 6: 0]   HEX4,
      output   [ 6: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [15: 0]   DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_UDQM,
      output             DRAM_CS_N,
      output             DRAM_WE_N,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,

      ///////// Audio /////////
      inout              AUD_BCLK,
      output             AUD_XCK,
      inout              AUD_ADCLRCK,
      input              AUD_ADCDAT,
      inout              AUD_DACLRCK,
      output             AUD_DACDAT,

      ///////// I2C for Audio /////////
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      ///////// GPIO /////////
      inout    [35: 0]   GPIO,

      ///////// HPS /////////
      inout              HPS_CONV_USB_N,
      output      [14:0] HPS_DDR3_ADDR,
      output      [2:0]  HPS_DDR3_BA,
      output             HPS_DDR3_CAS_N,
      output             HPS_DDR3_CKE,
      output             HPS_DDR3_CK_N,
      output             HPS_DDR3_CK_P,
      output             HPS_DDR3_CS_N,
      output      [3:0]  HPS_DDR3_DM,
      inout       [31:0] HPS_DDR3_DQ,
      inout       [3:0]  HPS_DDR3_DQS_N,
      inout       [3:0]  HPS_DDR3_DQS_P,
      output             HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_N,
      output             HPS_DDR3_RESET_N,
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_N,
      output             HPS_ENET_GTX_CLK,
      inout              HPS_ENET_INT_N,
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_ENET_RX_CLK,
      input       [3:0]  HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output      [3:0]  HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      inout       [3:0]  HPS_FLASH_DATA,
      output             HPS_FLASH_DCLK,
      output             HPS_FLASH_NCSO,
      inout              HPS_GSENSOR_INT,
      inout              HPS_I2C1_SCLK,
      inout              HPS_I2C1_SDAT,
      inout              HPS_I2C2_SCLK,
      inout              HPS_I2C2_SDAT,
      inout              HPS_I2C_CONTROL,
      inout              HPS_KEY,
      inout              HPS_LCM_BK,
      inout              HPS_LCM_D_C,
      inout              HPS_LCM_RST_N,
      output             HPS_LCM_SPIM_CLK,
      output             HPS_LCM_SPIM_MOSI,
      output             HPS_LCM_SPIM_SS,
      input              HPS_LCM_SPIM_MISO,
      inout              HPS_LED,
      inout              HPS_LTC_GPIO,
      output             HPS_SD_CLK,
      inout              HPS_SD_CMD,
      inout       [3:0]  HPS_SD_DATA,
      output             HPS_SPIM_CLK,
      input              HPS_SPIM_MISO,
      output             HPS_SPIM_MOSI,
      inout              HPS_SPIM_SS,
      input              HPS_UART_RX,
      output             HPS_UART_TX,
      input              HPS_USB_CLKOUT,
      inout       [7:0]  HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP
  );

  // Output signal from Altera University Program IP block when
  // the sample queue is not full.
  logic sample_fifo_ready;

  // 24-bit two's complement.
  logic [SMPL_WIDTH-1:0] audio_output;

  // Input signal to Altera University Program IP block when
  // the next sample is ready/valid.
  logic end_env_valid_aggregate;

  // HPS Parallel I/O
  logic [31:0] pio_stream;
  logic [23:0] pio_payload;
  logic midi_valid, serial_valid;

  // Reset button.
  logic rst_n;
  assign rst_n = KEY[0];

  // Digital synthesis parameters.
  logic           voice_enable  [NUM_VOICES-1:0];
  osc_params_t    osc_params    [NUM_VOICES-1:0];
  adsr_params_t   adsr_params   [NUM_VOICES-1:0];
  filter_params_t filter_params [NUM_VOICES-1:0];
  fx_e            fx_select;

  // Unsigned output of all voices.
  logic [SMPL_WIDTH:0] voice_out   [NUM_VOICES-1:0];
  logic                voice_valid [NUM_VOICES-1:0];


  // "BRAIN" that maps controls to audio synthesis modules.
  midi #(.NUM_CHANNELS(NUM_VOICES)) midi_core (
    .clock            (CLOCK_50),
    .rst_n            (rst_n),
    .midi_command     (pio_payload),
    .midi_valid       (midi_valid),

    .note_active      (voice_enable),
    .osc_p_array      (osc_params),
    .fil_p_array      (filter_params),
    .env_p_array      (adsr_params)
 );

  audio_sink sink (
      .sys_clk_clk     (CLOCK_50),
      .reset_reset     (~rst_n),
      .audio_ready     (sample_fifo_ready),
      .audio_valid     (SW[0] & end_env_valid_aggregate),
      .audio_data      (audio_output),
      .aud_clk_clk     (AUD_XCK),
      .wolfson_BCLK    (AUD_BCLK),
      .wolfson_DACDAT  (AUD_DACDAT),
      .wolfson_DACLRCK (AUD_DACLRCK)
  );

  av_config wolfson_config (
      .clk_clk              (CLOCK_50),
      .i2c_config_SDAT      (FPGA_I2C_SDAT),
      .i2c_config_SCLK      (FPGA_I2C_SCLK),
      .reset_reset_n        (rst_n)
  );

  hps army (
    .clk_clk            (CLOCK_50),
    .memory_mem_a       (HPS_DDR3_ADDR),
    .memory_mem_ba      (HPS_DDR3_BA),
    .memory_mem_ck      (HPS_DDR3_CK_P),
    .memory_mem_ck_n    (HPS_DDR3_CK_N),
    .memory_mem_cke     (HPS_DDR3_CKE),
    .memory_mem_cs_n    (HPS_DDR3_CS_N),
    .memory_mem_ras_n   (HPS_DDR3_RAS_N),
    .memory_mem_cas_n   (HPS_DDR3_CAS_N),
    .memory_mem_we_n    (HPS_DDR3_WE_N),
    .memory_mem_reset_n (HPS_DDR3_RESET_N),
    .memory_mem_dq      (HPS_DDR3_DQ),
    .memory_mem_dqs     (HPS_DDR3_DQS_P),
    .memory_mem_dqs_n   (HPS_DDR3_DQS_N),
    .memory_mem_odt     (HPS_DDR3_ODT),
    .memory_mem_dm      (HPS_DDR3_DM),
    .memory_oct_rzqin   (HPS_DDR3_RZQ),
    .reset_reset_n      (rst_n),
    .serial_data_export (pio_stream)
 );

  hps_comm bridge(
    .clock        (CLOCK_50),
    .rst_n        (rst_n),
    .in_word      (pio_stream),
    .payload      (pio_payload),
    .midi_valid   (midi_valid),
    .serial_valid (serial_valid)
  );

    genvar v_idx;
    generate
        for (v_idx = 0; v_idx < NUM_VOICES; v_idx++) begin: per_voice
            voice v(
                .clk       (CLOCK_50),
                .enable    (voice_enable[v_idx]),
                .rst_n     (rst_n),
                .osc_p     (osc_params[v_idx]),
                .adsr_p    (adsr_params[v_idx]),
                .filt_p    (filter_params[v_idx]),
                .valid     (voice_valid[v_idx]),
                .probe_out (),
                .voice_out (voice_out[v_idx])
            );
        end: per_voice
    endgenerate

  // Aggregate quantities from all voices into a single stream
  // for the audio output.
  always_comb begin
    end_env_valid_aggregate = '0;
    audio_output = '0;
    for (int i = 0; i < NUM_VOICES; i++) begin
      end_env_valid_aggregate |= voice_valid[i];
      audio_output += voice_out[i];
    end
  end

//  hex_decoder(.hex_digit(adsr_params[0].attack_time[7:4]), .hex_out(HEX1));
//  hex_decoder(.hex_digit(adsr_params[0].attack_time[3:0]), .hex_out(HEX0));
//
//  hex_decoder(.hex_digit(adsr_params[0].sustain_ampl[7:4]), .hex_out(HEX5));
//  hex_decoder(.hex_digit(adsr_params[0].sustain_ampl[3:0]), .hex_out(HEX4));
//  hex_decoder(.hex_digit(adsr_params[0].decay_time[7:4]),   .hex_out(HEX2));
//  hex_decoder(.hex_digit(adsr_params[0].decay_time[3:0]),   .hex_out(HEX3));

//  logic [7:0] alert;
//
//  always_ff @(posedge CLOCK_50) begin
//    if (!rst_n) begin
//	   alert <= '0;
//	 end else if (pio_stream != 32'h0) begin
//	   alert <= 8'hff;
//	 end
//  end
//
  logic [23:0] disp;
  assign disp = (SW[1]) ? ({ adsr_params[0].attack_time, adsr_params[0].sustain_ampl, adsr_params[0].decay_time}) : (pio_payload);
  hex_decoder h0 (.hex_digit(disp[3:0]),   .hex_out(HEX0));
  hex_decoder h1 (.hex_digit(disp[7:4]),   .hex_out(HEX1));

  hex_decoder h2 (.hex_digit(disp[11:8]),  .hex_out(HEX2));
  hex_decoder h3 (.hex_digit(disp[15:12]), .hex_out(HEX3));

  hex_decoder h4 (.hex_digit(disp[19:16]), .hex_out(HEX4));
  hex_decoder h5 (.hex_digit(disp[23:20]), .hex_out(HEX5));

endmodule: top
