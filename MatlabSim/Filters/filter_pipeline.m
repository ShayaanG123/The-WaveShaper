%% FILTER_TEST: Bit-True Hardware Pipeline (Square to Sine)
clear; clc; close all;

% --- 1. System Parameters ---
fs = 48000;
duration = 1.5;
total_len = round(fs * duration); 
f_target = 110; % Fundamental Frequency (A2)

% Widths: [ACC_WIDTH, OUT_WIDTH] 
widths = [32, 24]; 
OUT_WIDTH = widths(2);

% Mix coefficients: [sq, tri, saw, noi, dummy]
% 1.0 on square wave to test harmonic stripping for the "Square to Sine" demo
mix_coeffs = [1, 0.0, 0.0, 0.0, 0.0]; 

% --- 2. SVF Filter Parameters ---
fc = 110; % Cutoff at Fundamental
Q  = 4.0; % Resonant peak
filter_type = 'bp';

% --- 3. Run Full Pipeline ---
% Now only calling filter_out, which internally calls wave_mixer and Chamber_SVF.
% This ensures bit-true coherency and startup artifacts match RTL. [cite: 199]
final_signal = filter_out(fs, total_len, f_target, widths, mix_coeffs, fc, Q, filter_type);

% --- 4. Calculate Hardware Clipping Bounds ---
POS_MAX = int32(2^(OUT_WIDTH - 1) - 1);
NEG_MAX = int32(-(2^(OUT_WIDTH - 1)));

% Apply Saturation (Explicitly modeling the hardware output register)
final_signal_clipped = max(min(final_signal, POS_MAX), NEG_MAX);

% --- 5. Signal Preparation for Analysis ---
L = min(16384, floor(total_len / 2));
start_idx = round(total_len / 2);
idx = start_idx : (start_idx + L - 1);

% Convert to double for plotting/FFT
sig_filt     = double(final_signal(idx)) - mean(double(final_signal(idx)));
sig_clipped  = double(final_signal_clipped(idx)) - mean(double(final_signal_clipped(idx)));

% --- 6. Generate SVF Impulse Response (Bit-True Hardware Version) ---
impulse_len = 16384;
impulse_hw = zeros(1, impulse_len, 'int32');
impulse_hw(1) = int32(POS_MAX); 

[h_lp, h_bp, h_hp] = Chamber_SVF(impulse_hw, fc, Q, fs, OUT_WIDTH);
switch lower(filter_type)
    case 'hp', h_out = double(h_hp);
    case 'bp', h_out = double(h_bp);
    case 'lp', h_out = double(h_lp);
end

[H_svf, f_svf] = freqz(h_out, 1, impulse_len/2, fs);
mag_svf = 20 * log10(abs(H_svf) + eps) - 20*log10(double(POS_MAX)); 

% --- 7. Visualizations ---
figure('Color', 'k', 'Name', 'Hardware Pipeline Verification', 'Position', [100, 100, 1000, 800]);

% Plot A: Time Domain
subplot(3, 1, 1);
t = (0:L-1) / fs;
zoom_samples = min(round(0.05 * L), L); % Focus in on a few periods
plot(t(1:zoom_samples), sig_clipped(1:zoom_samples), 'Color', [1.0 0.6 0.2], 'LineWidth', 2.0);
title(sprintf('Time Domain: %d-bit Filtered Sine (fc = %d Hz, Q = %.1f)', OUT_WIDTH, fc, Q), 'Color', 'w');
ylabel('Amplitude', 'Color', 'w');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on;

% Plot B: FFT Analysis
subplot(3, 1, 2);
win = hann(L)';
Y_filt = fft(sig_clipped .* win);
P1_filt = abs(Y_filt(1:L/2+1) / L); P1_filt(2:end-1) = 2 * P1_filt(2:end-1);
dB_filt = 20 * log10(P1_filt + 1e-6);
f_vec = fs * (0:(L/2)) / L;
plot(f_vec, dB_filt, 'Color', [1.0 0.6 0.2], 'LineWidth', 1.5);
title('Frequency Domain: Harmonic Stripping Analysis', 'Color', 'w');
ylabel('Magnitude (dB)', 'Color', 'w');
xlim([0, 2000]); ylim([-120, max(dB_filt)+10]); 
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on;

% Plot C: Bode Plot (Bit-True)
subplot(3, 1, 3);
semilogx(f_svf, mag_svf, 'Color', [0.2 0.8 0.5], 'LineWidth', 2.0);
title(['Chamberlin SVF ', upper(filter_type), ' Hardware Frequency Response'], 'Color', 'w');
xlabel('Frequency (Hz)', 'Color', 'w'); ylabel('Magnitude (dB)', 'Color', 'w');
xlim([20, 20000]); ylim([-60, 20]);
xline(fc, '--w', 'Cutoff (fc)', 'LabelVerticalAlignment', 'bottom');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on;

fprintf('\n--- TEST SUMMARY ---\n');
fprintf('Output Peak: %d\n', max(final_signal));
fprintf('Success: Data generated for Slide T5.\n');

% --- 8. Metric Verification (T5 Results) ---
% Extract magnitude response in dB
[H_svf, f_svf] = freqz(h_out, 1, impulse_len/2, fs);
mag_svf = 20 * log10(abs(H_svf) + eps) - 20 * log10(double(POS_MAX)); 

% Find the resonant peak (represents cutoff for LP/HP and center for BP)
[max_mag, peak_idx] = max(mag_svf);
achieved_freq = f_svf(peak_idx);

% Calculate the Error Percentage against desired target
error_pct = abs(achieved_freq - fc) / fc * 100;

fprintf('\n--- T5 HARDWARE VERIFICATION SUMMARY ---\n');
fprintf('Filter Mode:        %s\n', upper(filter_type));

switch lower(filter_type)
    case 'lp'
        fprintf('Desired Cutoff:     %d Hz\n', fc);
        fprintf('Achieved Cutoff:    %.2f Hz\n', achieved_freq);
    case 'hp'
        fprintf('Desired Cutoff:     %d Hz\n', fc);
        fprintf('Achieved Cutoff:    %.2f Hz\n', achieved_freq);
    case 'bp'
        fprintf('Desired Center:     %d Hz\n', fc);
        fprintf('Achieved Center:    %.2f Hz\n', achieved_freq);
end

fprintf('Percent Error:      %.2f%%\n', error_pct);

% Pass/Fail based on the 5% accuracy criterion in the presentation 
if error_pct <= 5
    fprintf('Pass Criterion:     PASS (Goal: ±5%%)\n');
else
    fprintf('Pass Criterion:     FAIL (Check F_int scaling)\n');
end