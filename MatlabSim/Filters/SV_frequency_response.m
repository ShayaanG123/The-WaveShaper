%% VERIFY_LP_HARDWARE_SAFE.m
% Purpose:
% Safely load simulation output, verify validity, and plot
% both time-domain samples and frequency spectrum.

clear; clc; close all;

%% 1. Load Data
filename = 'sv_filtered_output.txt';

if ~isfile(filename)
    error('File not found. Check your simulation folder.');
end

raw_data = readmatrix(filename);

% Ensure column vector and remove invalid entries
raw_data = raw_data(:);
raw_data = raw_data(~isnan(raw_data));

%% 2. Validate Data
if isempty(raw_data)
    error('DATA ERROR: File is empty or contains only NaNs.');
end

if all(raw_data == 0)
    error('DATA ERROR: All samples are zero. Check your VCS simulation.');
end

%% 3. FFT Setup
fs = 48000;                 % Sampling frequency (Hz)
x = double(raw_data);       % Convert to double
L = length(x);              % Signal length

% Apply window (use hanning for compatibility)
w = hanning(L);
x_windowed = x .* w;

% Compute FFT
Y = fft(x_windowed);

% Single-sided magnitude spectrum
P2 = abs(Y / L);
P1 = P2(1:floor(L/2) + 1);
P1(2:end-1) = 2 * P1(2:end-1);

% Convert to dB (avoid log(0))
mag = 20 * log10(P1 + 1e-12);

% Normalize to 0 dB peak
mag = mag - max(mag);

% Frequency axis
f = fs * (0:floor(L/2))' / L;

%% 4. Plotting (Safe Rendering)
figure(1);
clf;

% ---- Time Domain Plot ----
subplot(2,1,1);
num_samples_to_plot = min(1000, L);
plot(1:num_samples_to_plot, x(1:num_samples_to_plot));
title('Check: Raw Input Samples');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% ---- Frequency Domain Plot ----
subplot(2,1,2);
plot(f, mag);
title('Check: Frequency Spectrum');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
xlim([0 5000]);
grid on;

%% 5. Debug Statistics
fprintf('--- Debug Stats ---\n');
fprintf('Sample Count: %d\n', L);
fprintf('Max Value:    %f\n', max(x));
fprintf('Min Value:    %f\n', min(x));
fprintf('Mean Value:   %f\n', mean(x));
fprintf('Std Dev:      %f\n', std(x));