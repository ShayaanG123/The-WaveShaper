%% FILTER_TEST: Full Synth Signal Chain Validation
clear; clc; close all;

% --- 1. Parameters ---
fs = 48000;
duration = 1.5;
total_len = round(fs * duration); % Convert seconds to samples
f_target = 110; % Low A (lots of harmonics for the filter)

% Updated widths for mixer: [ACC, OUT, ADDR]
widths = [32, 24, 10]; 

% Mix coefficients: [sq, tri, saw, sin, noi]
% Using a Sawtooth (1.0) to provide a rich harmonic bed for the filter
mix_coeffs = [0.0, 0.0, 1.0, 0.0, 0.0]; 

% --- 2. Filter Coefficients (Standard Bandpass) ---
% f_low  = 1000; 
% f_high = 5000;
% Wn = [f_low, f_high] / (fs/2);
% [b, a] = butter(1, Wn, 'bandpass'); 
% a_coeffs = a(2:3); % MATLAB's 'a' is [1, a1, a2]. Your hardware expects [a1, a2].

fc = 2500;              % Cutoff frequency (Hz)
Wn = fc / (fs/2);       % Normalized cutoff frequency
[b, a] = butter(2, Wn, 'low'); 
a_coeffs = a(2:3);

% --- 2a. Visualize Response ---
frequency_response(b, a_coeffs, fs);

% --- 3. Run Full Pipeline ---
% 1. Get the RAW signal directly from the mixer for our "Before" FFT
raw_signal = mixer_out(fs, total_len, f_target, widths(1), widths(2), widths(3), mix_coeffs);

% 2. Run the main filter function for our "After" signal
final_signal = filter_out(fs, total_len, f_target, widths, mix_coeffs, b, a_coeffs);

% --- 4. Time-Domain Visualization ---
figure('Color', 'k', 'Name', 'Filtered Synth Output');
t = (0:length(final_signal)-1) / fs;
plot_waveform(t, final_signal, widths(2), 'Final Filtered Output (24-bit BP)');
xlabel('Time (seconds)', 'Color', 'w');

% --- 5. Frequency-Domain Visualization (FFT Before & After) ---
figure('Color', 'k', 'Name', 'Spectrum: Before vs After Filter');

% Grab a chunk of the signal from the middle to avoid any startup transients
% We use a power of 2 for a faster FFT (16384 samples is about 0.34 seconds)
L = 16384; 
start_idx = round(total_len / 2);
idx = start_idx : (start_idx + L - 1);

% Extract segments and convert to double for math
sig_raw  = double(raw_signal(idx));
sig_filt = double(final_signal(idx));

% Remove DC offsets (crucial for the raw unsigned signal)
sig_raw  = sig_raw - mean(sig_raw);
sig_filt = sig_filt - mean(sig_filt);

% Apply Hanning Window to clean up spectral leakage
win = hann(L)';
sig_raw  = sig_raw .* win;
sig_filt = sig_filt .* win;

% Calculate FFTs
Y_raw  = fft(sig_raw);
Y_filt = fft(sig_filt);

% Normalize and convert to Single-Sided Magnitude (dB)
P2_raw  = abs(Y_raw / L);
P1_raw  = P2_raw(1:L/2+1);
P1_raw(2:end-1) = 2 * P1_raw(2:end-1);
dB_raw  = 20 * log10(P1_raw + 1e-6);

P2_filt = abs(Y_filt / L);
P1_filt = P2_filt(1:L/2+1);
P1_filt(2:end-1) = 2 * P1_filt(2:end-1);
dB_filt = 20 * log10(P1_filt + 1e-6);

% Frequency vector for X-axis
f_vec = fs * (0:(L/2)) / L;

% Plot Overlay
hold on;
% Plot Raw Signal in a faded gray/blue so it sits in the background
plot(f_vec, dB_raw, 'Color', [0.4 0.6 0.8 0.5], 'LineWidth', 1.5, 'DisplayName', 'Raw Sawtooth');
% Plot Filtered Signal in a bright color on top
plot(f_vec, dB_filt, 'Color', [1.0 0.6 0.2 0.9], 'LineWidth', 1.5, 'DisplayName', 'Bandpass Filtered');
hold off;

grid on;
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');
title('Fourier Analysis: Filter Effect on Harmonics', 'Color', 'w');
xlabel('Frequency (Hz)', 'Color', 'w');
ylabel('Magnitude (dB)', 'Color', 'w');
xlim([0, 10000]); % Zoom in on the relevant harmonics
ylim([-80, max(dB_raw)+10]); % Set floor to -80dB to ignore extreme background noise
legend('TextColor', 'w', 'Color', 'k');