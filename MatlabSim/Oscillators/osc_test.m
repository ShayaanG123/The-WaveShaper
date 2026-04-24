%% Synthesizer Oscillator Verification Script
% Clear workspace and add subfolders to path
clear; clc; close all;
addpath(genpath('.')); 

% --- Global Parameters ---
fs = 48000;
f_target = 440; % A4
ACC_WIDTH = 32;
OUT_WIDTH = 24;
total_samples = 10000;
on_step = 1;
off_step = total_samples;

% Calculate tuning word (M)
M = round((f_target * 2^ACC_WIDTH) / fs);

% Set Y-Axis Limits for 24-bit Unsigned
y_lims = [-1e6, 2^OUT_WIDTH + 1e6];

% --- Generate Signals ---
out_sq  = model_square(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_saw = model_saw(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_tri = model_triangle(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_sin = model_sine(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_noi = model_noise(total_samples, on_step, off_step, ACC_WIDTH, OUT_WIDTH);

% ==========================================
% FIGURE 1: TIME DOMAIN
% ==========================================
figure('Name', 'Oscillator Library Verification - Time Domain', 'Position', [100, 100, 800, 800]);
subplot(5,1,1); plot(out_sq); ylim(y_lims); title('Square Wave'); grid on;
subplot(5,1,2); plot(out_saw); ylim(y_lims); title('Sawtooth Wave'); grid on;
subplot(5,1,3); plot(out_tri); ylim(y_lims); title('Triangle Wave'); grid on;
subplot(5,1,4); plot(out_sin); ylim(y_lims); title('Sine Wave'); grid on;
subplot(5,1,5); plot(out_noi); ylim(y_lims); title('White Noise (LFSR)'); grid on;
xlabel('Sample Index (n)');

% ==========================================
% FIGURE 2: FREQUENCY DOMAIN (FFT)
% ==========================================
figure('Name', 'Oscillator Library Verification - Frequency Domain', 'Position', [920, 100, 800, 800]);
% Extract only the "active" portion of the note to avoid transient spectral smearing
active_idx = on_step : off_step;
L = length(active_idx);
f_vec = fs * (0:(L/2)) / L; % Frequency vector for X-axis

% Plot FFTs using the local helper function (defined at the bottom)
subplot(5,1,1); plot_fft(out_sq(active_idx), f_vec, L, 'Square Wave Spectrum (Odd Harmonics)');
subplot(5,1,2); plot_fft(out_saw(active_idx), f_vec, L, 'Sawtooth Wave Spectrum (All Harmonics)');
subplot(5,1,3); plot_fft(out_tri(active_idx), f_vec, L, 'Triangle Wave Spectrum (Odd Harmonics, steep roll-off)');
subplot(5,1,4); plot_fft(out_sin(active_idx), f_vec, L, 'Sine Wave Spectrum (Fundamental Only)');
subplot(5,1,5); plot_fft(out_noi(active_idx), f_vec, L, 'White Noise Spectrum (Flat)');
xlabel('Frequency (Hz)');

% ==========================================
% SECTION 3: PITCH ACCURACY (CENTS)
% ==========================================
fprintf('\n--- PITCH ACCURACY VERIFICATION ---\n');
fprintf('Target Frequency: %d Hz\n', f_target);
fprintf('Target Goal:      ±2 Cents\n\n');

% Calculate for the deterministic periodic waveforms
measure_pitch(out_sq(active_idx), fs, f_target, 'Square');
measure_pitch(out_saw(active_idx), fs, f_target, 'Sawtooth');
measure_pitch(out_tri(active_idx), fs, f_target, 'Triangle');
measure_pitch(out_sin(active_idx), fs, f_target, 'Sine');
fprintf('-----------------------------------\n');


% ==========================================
% LOCAL HELPER FUNCTIONS
% ==========================================
function plot_fft(signal, f_vec, L, plot_title)
    % 1. Remove DC offset (mean) so the 0 Hz bin doesn't dominate
    signal_centered = double(signal) - mean(double(signal));
    
    % 2. Calculate FFT and normalize
    Y = fft(signal_centered);
    P2 = abs(Y / L);
    
    % 3. Extract single-sided spectrum
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2 * P1(2:end-1);
    
    % 4. Convert to Decibels (dB) for standard audio visualization
    P1_dB = 20 * log10(P1 + 1e-6); 
    
    % Plot
    plot(f_vec, P1_dB);
    title(plot_title);
    grid on;
    xlim([0, 10000]); % Limit to 10kHz to easily see lower harmonics
    ylabel('Magnitude (dB)');
end

function measure_pitch(signal, fs, f_target, wave_name)
    % Use zero-padding to achieve ultra-high frequency resolution
    % 2^20 samples gives ~0.045 Hz resolution
    N_fft = 2^20; 
    
    % Remove DC offset
    signal_centered = double(signal) - mean(double(signal));
    
    % Calculate high-resolution FFT
    Y = fft(signal_centered, N_fft);
    P2 = abs(Y / N_fft);
    P1 = P2(1:floor(N_fft/2)+1);
    
    % Ignore DC and find the peak fundamental frequency
    P1(1:10) = 0; % Blank out near-DC bins
    [~, max_idx] = max(P1);
    
    % Convert index back to Hz
    f_measured = (max_idx - 1) * fs / N_fft;
    
    % Calculate pitch error in cents
    cents_error = 1200 * log2(f_measured / f_target);
    
    % Print Results
    fprintf('%-10s -> Measured: %8.4f Hz | Error: %6.2f Cents ', wave_name, f_measured, cents_error);
    if abs(cents_error) <= 2.0
        fprintf('[PASS]\n');
    else
        fprintf('[FAIL]\n');
    end
end