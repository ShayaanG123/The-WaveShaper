%% FILTER_TEST: Full Synth Signal Chain Validation
clear; clc; close all;

% --- 1. Parameters ---
fs = 48000;
duration = 1.5;
f_target = 110; % Low A (lots of harmonics for the filter)
widths = [32, 24, 10, 24]; % [ACC, OUT, ADDR, ENV]

mix_coeffs = [1.0, 0.0, 0.0, 0.0, 0.0]; 

% ADSR
adsr.A = 0.0; adsr.D = 0.0; adsr.S = 0.7; adsr.R = 0.0;
adsr.gate_time = 0.8; adsr.start_delay = 0.1;

% --- 2. Filter Coefficients (Standard LPF at 1kHz, Q=0.707) ---
% In SystemVerilog, these will be sent via SPI/AXI
fc = 12000; 
f_low  = 1000; 
f_high = 5000;

% Normalize both frequencies
Wn = [f_low, f_high] / (fs/2);
% If you want HPF or LPF change 'bandpass' to lowpass or highpass
% Also change n from 1 to 2 and Wn = fc / (fs/2);

[b, a] = butter(1, Wn, 'bandpass'); % Generate standard Butterworth coeffs
a_coeffs = a(2:3); % MATLAB's 'a' includes a0=1, we only need [a1, a2]

% Null Filter / Pass-through
b_null = [1, 0, 0];
a_null = [0, 0]; % Remember your function takes [a1, a2]

% --- 2a. Visualize Response ---
frequency_response(b, a_coeffs, fs);

% --- 3. Run Full Pipeline ---
final_signal = filter_out(fs, duration, f_target, widths, adsr, mix_coeffs, b, a_coeffs);

% --- 4. Visualization ---
figure('Color', 'k', 'Name', 'Filtered Synth Output');
t = (0:length(final_signal)-1) / fs;

% Use your plot_waveform function
plot_waveform(t, final_signal, widths(2), 'Final Filtered Output (24-bit LPF)');
xlabel('Time (seconds)', 'Color', 'w');