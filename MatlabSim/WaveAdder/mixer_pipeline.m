%% Digital Synth Hardware-Accurate Pipeline
clear; clc; close all;

% 1. Hardware Parameters
fs          = 48000;    
total_len   = 2000;     
freq_hz     = 440;      
ACC_WIDTH   = 32;       % 32-bit for both DDS and Galois LFSR [cite: 19, 99]
OUT_WIDTH   = 24;       % 24-bit output for WM8731 CODEC [cite: 5, 29]
GAIN_SH     = 2;        

% 2. Mix Coefficients [Square, Triangle, Sawtooth, Noise, Dummy]
% Example: Blending Square and Noise [cite: 20, 36]
mix_coeffs = [1.0, 0.0, 0.0, 0.0, 0.0]; 

% 3. Calculate Tuning Word for DDS Oscillators
tuning_word = uint32(round((freq_hz * 2^ACC_WIDTH) / fs));

% 4. Generate Hardware-Coherent Waveforms
% Each model matches the specific algorithm in your presentation [cite: 19, 85]
w_sq  = model_square(total_len, 1, total_len, tuning_word, ACC_WIDTH, OUT_WIDTH);
w_tri = model_triangle(total_len, 1, total_len, tuning_word, ACC_WIDTH, OUT_WIDTH);
w_saw = model_saw(total_len, 1, total_len, tuning_word, ACC_WIDTH, OUT_WIDTH);
w_noi = model_noise(total_len, 1, total_len, ACC_WIDTH, OUT_WIDTH);

w_zero = zeros(1, total_len, 'int32'); 

% 5. Run the Pipelined Wave Mixer
% Includes the RTL startup artifact (out(2) = 'c00000')
synth_out = wave_mixer(w_sq, w_tri, w_saw, w_noi, w_zero, ...
                       mix_coeffs, OUT_WIDTH, GAIN_SH);

% 6. Visualization for Presentation
t = (0:total_len-1) / fs;
figure('Color', 'k', 'Name', 'WaveShaper Golden Model');
plot_waveform(t, synth_out, OUT_WIDTH, 'Mixed Synth Output (Signed 24-bit)');