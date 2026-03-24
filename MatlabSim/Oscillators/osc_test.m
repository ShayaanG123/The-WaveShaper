%% Synthesizer Oscillator Verification Script
% Clear workspace and add subfolders to path
clear; clc;
addpath(genpath('.')); 

% --- Global Parameters ---
fs = 48000;
f_target = 440; % A4
ACC_WIDTH = 32;
OUT_WIDTH = 24;
ADDR_WIDTH = 10;
total_samples = 10000;
on_step = 50;
off_step = 8000;

% Calculate tuning word (M)
M = round((f_target * 2^ACC_WIDTH) / fs);

% Set Y-Axis Limits for 24-bit Unsigned
y_lims = [-1e6, 2^OUT_WIDTH + 1e6];

% Note that the oscillators look smooth because MATLAB connects the points
figure('Name', 'Oscillator Library Verification');

% --- 1. Square Wave ---
subplot(5,1,1);
out_sq = model_square(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
plot(out_sq);
ylim(y_lims);
title('Square Wave'); grid on;

max_val = 2^(OUT_WIDTH - 1) - 1;
out_sq_float = double(out_sq) / max_val;
sound(out_sq_float, fs);

% --- 2. Sawtooth Wave ---
subplot(5,1,2);
out_saw = model_saw(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
plot(out_saw);
ylim(y_lims);
title('Sawtooth Wave'); grid on;

% --- 3. Triangle Wave ---
subplot(5,1,3);
out_tri = model_triangle(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
plot(out_tri);
ylim(y_lims);
title('Triangle Wave'); grid on;

% --- 4. Sine Wave (LUT Based) ---
subplot(5,1,4);
out_sin = model_sine(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH);
plot(out_sin);
ylim(y_lims);
title('Sine Wave'); grid on;

% --- 5. Noise (LFSR) ---
subplot(5,1,5);
out_noi = model_noise(total_samples, on_step, off_step, ACC_WIDTH, OUT_WIDTH);
plot(out_noi);
ylim(y_lims);
title('White Noise (LFSR)'); grid on;

% Label the bottom axis
xlabel('Sample Index (n)');