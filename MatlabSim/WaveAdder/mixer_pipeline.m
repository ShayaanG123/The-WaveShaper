%% Digital Synth Hardware-Accurate Pipeline
% Golden Reference for SystemVerilog Implementation
clear; clc; close all;

% 1. Hardware Parameters
fs          = 48000;    % Sampling Frequency (Hz)
total_len   = 2000;     % Total samples to generate
freq_hz     = 440;      % Oscillator Frequency (A4)

ACC_WIDTH   = 32;       % Phase Accumulator Bit Width
OUT_WIDTH   = 24;       % Waveform Output Bit Width
ADDR_WIDTH  = 10;       % Sine LUT Address Width (2^10 entries)

% 2. Mix Coefficients (Summing to 1.0)
% Order: [Square, Triangle, Sawtooth, Sine, Noise]
mix_coeffs = [0.0, 0.0, 0.0, 0.95, 0.05]; 

% 3. Run the Synth Core
% Calls the wrapper function that generates and mixes the waves
synth_out = mixer_out(fs, total_len, freq_hz, ...
                           ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, ...
                           mix_coeffs);

% 4. Visualization (Using custom plot_waveform function)
figure('Color', 'k', 'Name', 'Digital Synth Golden Reference');

% Time vector (Converted to seconds for plot_waveform)
t = (0:total_len-1) / fs;

% Define the plot title and a bright Cyan color [R G B]
plot_title = sprintf('Mixed Synth Output (%d-bit Unsigned)', OUT_WIDTH);

% Call your specialized plotting function
plot_waveform(t, synth_out, OUT_WIDTH, plot_title);

% Adding X-Label manually since it's the bottom plot
xlabel('Time (seconds)', 'Color', 'w');

% 5. Optional: Analyze the Spectrum
% Uncomment to verify harmonic content
% figure('Color', 'k');
% [pxx, f] = periodogram(double(synth_out), rectwin(total_len), total_len, fs);
% plot(f, 10*log10(pxx), 'Color', [1 0.5 0]); 
% set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
% grid on; title('Power Spectral Density', 'Color', 'w');