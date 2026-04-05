%% ENVELOPE_TEST: Hardware-Accurate ADSR Validation (with Filter)
clear; clc; close all;

% --- 1. System Parameters ---
fs = 48000;
duration = 2.5;         % Total buffer length in seconds
f_target = 220;         % Frequency (A3)

% Widths: [ACC, OUT, ADDR, ENV]
widths = [32, 24, 10, 24]; 

% Mix: [Sq, Tri, Saw, Sin, Noi]
% Using Sawtooth (Index 3) to better hear the filter's effect
mix_coeffs = [0.0, 0.0, 1.0, 0.0, 0.0]; 

% --- 2. ADSR Configuration ---
adsr.A = 0.15;          % 150ms Attack
adsr.D = 0.20;          % 200ms Decay
adsr.S = 0.50;          % 50% Sustain level
adsr.R = 0.60;          % 600ms Release
adsr.gate_time   = 1.2; % Note held for 1.2 seconds
adsr.start_delay = 0.3; % Note starts after 300ms

% --- 3. Filter Configuration (New Section) ---
% Define a Low Pass Filter at 2000Hz
fc = 2000;
[b, a] = butter(2, fc/(fs/2), 'low'); 
a_coeffs = a(2:3); % Extract [a1, a2] for hardware model

% --- 4. Run Pipeline ---
% Updated call: now passes filter coefficients to envelope_out
final_signal = envelope_out(fs, duration, f_target, widths, adsr, mix_coeffs, b, a_coeffs);

% --- 5. Visualization ---
figure('Color', 'k', 'Name', 'Filtered & Enveloped Output Test');
total_samples = length(final_signal);
t = (0:total_samples-1) / fs;

OUT_WIDTH = widths(2);
plot_title = sprintf('Final Filtered + Enveloped Signal (%d-bit Hardware Model)', OUT_WIDTH);

% Call your specialized plotting function
plot_waveform(t, final_signal, OUT_WIDTH, plot_title);

% Final label adjustments
xlabel('Time (seconds)', 'Color', 'w');
ylabel('Signed Magnitude (Centered)', 'Color', 'w');
