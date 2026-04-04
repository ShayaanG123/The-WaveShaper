%% ENVELOPE_TEST: Hardware-Accurate ADSR Validation
clear; clc; close all;

% --- 1. System Parameters ---
fs = 48000;
duration = 2.5;         % Total buffer length in seconds
f_target = 220;         % Frequency (A3)

% Widths: [ACC, OUT, ADDR, ENV]
widths = [32, 24, 10, 24]; 

% Mix: [Sq, Tri, Saw, Sin, Noi]
mix_coeffs = [0.0, 0.0, 0.0, 1.0, 0.0]; 

% --- 2. ADSR Configuration ---
adsr.A = 0.15;          % 150ms Attack
adsr.D = 0.20;          % 200ms Decay
adsr.S = 0.50;          % 50% Sustain level
adsr.R = 0.60;          % 600ms Release
adsr.gate_time   = 1.2; % Note held for 1.2 seconds
adsr.start_delay = 0.3; % Note starts after 300ms

% --- 3. Run Pipeline ---
% Calls your integrated hardware-accurate function
final_signal = envelope_out(fs, duration, f_target, widths, adsr, mix_coeffs);

% --- 4. Visualization ---
figure('Color', 'k', 'Name', 'Envelope Output Test');

% Generate time vector for plotting (Seconds)
total_samples = length(final_signal);
t = (0:total_samples-1) / fs;

% Define styling
OUT_WIDTH = widths(2);
plot_title = sprintf('Final Enveloped Signal (%d-bit Hardware Model)', OUT_WIDTH);

% Call your specialized plotting function
plot_waveform(t, final_signal, OUT_WIDTH, plot_title);

% Final label adjustments
xlabel('Time (seconds)', 'Color', 'w');
ylabel('24-bit Unsigned Magnitude', 'Color', 'w');