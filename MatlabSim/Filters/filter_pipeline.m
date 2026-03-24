%% FILTER_TEST: Full Synth Signal Chain Validation
clear; clc; close all;

% --- 1. Parameters ---
fs = 48000;
duration = 1.5;
total_len = round(fs * duration); % Convert seconds to samples
f_target = 110; % Low A (lots of harmonics for the filter)

% Updated widths for mixer: [ACC, OUT, ADDR]
% Note: The previous 4th element (ENV) is no longer used in mixer_out
widths = [32, 24, 10]; 

% Mix coefficients: [sq, tri, saw, sin, noi]
% Using a Sawtooth (1.0) is better for filter testing than a Square (1.0) 
% because it has every harmonic, making the filter's effect more obvious.
mix_coeffs = [0.0, 0.0, 1.0, 0.0, 0.0]; 

% --- 2. Filter Coefficients (Standard Bandpass) ---
f_low  = 1000; 
f_high = 5000;
Wn = [f_low, f_high] / (fs/2);

[b, a] = butter(1, Wn, 'bandpass'); 
% MATLAB's 'a' is [1, a1, a2]. Your hardware function expects [a1, a2].
a_coeffs = a(2:3); 

% --- 2a. Visualize Response ---
% Ensure your frequency_response function is compatible with this coeff format
frequency_response(b, a_coeffs, fs);

% --- 3. Run Full Pipeline ---
% Calling the updated filter_out which now uses mixer_out internally
final_signal = filter_out(fs, total_len, f_target, widths, mix_coeffs, b, a_coeffs);

% --- 4. Visualization ---
figure('Color', 'k', 'Name', 'Filtered Synth Output');
t = (0:length(final_signal)-1) / fs;

% Use your plot_waveform function
% widths(2) is OUT_WIDTH (24-bit)
plot_waveform(t, final_signal, widths(2), 'Final Filtered Output (24-bit BP)');
xlabel('Time (seconds)', 'Color', 'w');