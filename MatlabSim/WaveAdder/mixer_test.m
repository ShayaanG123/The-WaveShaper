% Add the current directory and all its subfolders to the path
addpath(genpath('..'));

% Hardware Params
fs = 48000;
ACC_WIDTH = 32;
OUT_WIDTH = 24;
ADDR_WIDTH = 10;
total_len = 2000;
M = round((440 * 2^ACC_WIDTH) / fs);

% Generate Waves
w_sq  = model_square(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
w_tri = model_triangle(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
w_saw = model_saw(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
w_sin = model_sine(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH);
w_noi = model_noise(total_len, 1, total_len, ACC_WIDTH, OUT_WIDTH);

% Mix Coefficients (Summing to 1.0)
c_sq = 0.0; c_tri = 0.0; c_saw = 0.0; c_sin = 0.99; c_noi = 0.01;

% Mix!
synth_out = wave_mixer(w_sq, w_tri, w_saw, w_sin, w_noi, c_sq, c_tri, c_saw, c_sin, c_noi, OUT_WIDTH);

% Plot
plot(synth_out);
title('Mixed Synthesizer Output (24-bit Unsigned)');
grid on;
ylim([-1e6, 2^OUT_WIDTH + 1e6]);