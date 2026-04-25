%% FILTER_TEST: Bit-True Hardware Pipeline (Square to Sine)
clear; clc; close all;

% --- 1. System Parameters ---
fs = 48000;
duration = 1.5;
total_len = round(fs * duration); 
f_target = 110; % Fundamental Frequency (A2)

% Widths: [ACC_WIDTH, OUT_WIDTH] 
% Note: Using 24-bit for OUT_WIDTH is standard for high-quality audio hardware
widths = [32, 32]; 
OUT_WIDTH = widths(2);

% Mix coefficients: [sq, tri, saw, sin, noi]
% 1.0 on square wave to test harmonic stripping
mix_coeffs = [1, 0.0, 0.0, 0.0, 0.0]; 

% --- 2. SVF Filter Parameters ---
fc = 110; % Cutoff at Fundamental
Q  = 4.0; % Resonant peak
filter_type = 'lp';

% --- 3. Run Full Pipeline ---
% 1. Generate Raw Signal from Mixer
% (Ensures 2's complement signed int32 output)
raw_signal = mixer_out(fs, total_len, f_target, widths(1), widths(2), mix_coeffs);

% 2. Run the Hardware-Coherent Filter Function
% This call will trigger the fprintf statements inside Chamber_SVF
final_signal = filter_out(fs, total_len, f_target, widths, mix_coeffs, fc, Q, filter_type);

% 3. Calculate Hardware Clipping Bounds
POS_MAX = int32(2^(OUT_WIDTH - 1) - 1);
NEG_MAX = int32(-(2^(OUT_WIDTH - 1)));

% Apply Saturation (Explicitly modeling the hardware output register)
final_signal_clipped = max(min(final_signal, POS_MAX), NEG_MAX);

% --- 4. Signal Preparation for Analysis ---
L = min(16384, floor(total_len / 2));
start_idx = round(total_len / 2);
idx = start_idx : (start_idx + L - 1);

% Convert to double and remove DC for plotting/FFT
sig_raw      = double(raw_signal(idx)) - mean(double(raw_signal(idx)));
sig_filt     = double(final_signal(idx)) - mean(double(final_signal(idx)));
sig_clipped  = double(final_signal_clipped(idx)) - mean(double(final_signal_clipped(idx)));

% --- 5. Generate SVF Impulse Response (Bit-True Hardware Version) ---
impulse_len = 16384;
% Create a hardware-scale impulse at 100% amplitude
impulse_hw = zeros(1, impulse_len, 'int32');
impulse_hw(1) = int32(POS_MAX); 

% Call bit-true function for the Bode Plot
[h_lp, h_bp, h_hp] = Chamber_SVF(impulse_hw, fc, Q, fs, OUT_WIDTH);

switch lower(filter_type)
    case 'hp', h_out = double(h_hp);
    case 'bp', h_out = double(h_bp);
    case 'lp', h_out = double(h_lp);
end

% Calculate Frequency Response
[H_svf, f_svf] = freqz(h_out, 1, impulse_len/2, fs);
mag_svf = 20 * log10(abs(H_svf) + eps);

% Normalize relative to the impulse magnitude to show actual gain/loss
mag_svf = mag_svf - 20*log10(double(POS_MAX)); 

% --- 6. Visualizations ---
figure('Color', 'k', 'Name', 'Hardware Pipeline Verification', 'Position', [100, 100, 1000, 800]);

% Plot A: Time Domain
subplot(3, 1, 1);
t = (0:L-1) / fs;
zoom_samples = min(round(0.1 * total_len), total_len);

plot(t(1:zoom_samples), sig_raw(1:zoom_samples), 'Color', [0.4 0.6 0.8 0.6], 'LineWidth', 1.5, 'DisplayName', 'Input Square');
hold on;
plot(t(1:zoom_samples), sig_clipped(1:zoom_samples), 'Color', [1.0 0.6 0.2], 'LineWidth', 2.0, 'DisplayName', 'Filtered Sine (HW)');
hold off;
title(sprintf('Time Domain: %d-bit HW Pipeline (fc = %d Hz, Q = %.1f)', OUT_WIDTH, fc, Q), 'Color', 'w');
ylabel('Amplitude', 'Color', 'w');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on; legend('TextColor', 'w', 'Color', 'k');

% Plot B: FFT Analysis
subplot(3, 1, 2);
win = hann(L)';
Y_raw  = fft(sig_raw .* win);
Y_filt = fft(sig_clipped .* win);

P1_raw  = abs(Y_raw(1:L/2+1) / L); P1_raw(2:end-1) = 2 * P1_raw(2:end-1);
dB_raw  = 20 * log10(P1_raw + 1e-6);
P1_filt = abs(Y_filt(1:L/2+1) / L); P1_filt(2:end-1) = 2 * P1_filt(2:end-1);
dB_filt = 20 * log10(P1_filt + 1e-6);

f_vec = fs * (0:(L/2)) / L;
plot(f_vec, dB_raw, 'Color', [0.4 0.6 0.8 0.6], 'LineWidth', 1.5, 'DisplayName', 'Square Spectrum');
hold on;
plot(f_vec, dB_filt, 'Color', [1.0 0.6 0.2], 'LineWidth', 1.5, 'DisplayName', 'Filtered Spectrum');
hold off;
title('Frequency Domain: Harmonic Stripping', 'Color', 'w');
ylabel('Magnitude (dB)', 'Color', 'w');
xlim([0, 2000]); ylim([-120, max(dB_raw)+10]); 
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on; legend('TextColor', 'w', 'Color', 'k');

% Plot C: Bode Plot (Bit-True)
subplot(3, 1, 3);
semilogx(f_svf, mag_svf, 'Color', [0.2 0.8 0.5], 'LineWidth', 2.0);
title(['Chamberlin SVF ', upper(filter_type), ' Hardware Response'], 'Color', 'w');
xlabel('Frequency (Hz)', 'Color', 'w'); ylabel('Magnitude (dB)', 'Color', 'w');
xlim([20, 20000]); ylim([-60, 20]);
xline(f_target, '--w', 'Fundamental', 'LabelVerticalAlignment', 'bottom');
xline(f_target*3, '--r', '3rd Harm', 'LabelVerticalAlignment', 'bottom');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on;

% --- 7. Console Summary & Export ---
fprintf('\n--- TEST SUMMARY ---\n');
fprintf('Mean Offset: %.4f\n', mean(double(final_signal)));
fprintf('Input Peak:  %d\n', max(raw_signal));
fprintf('Output Peak: %d\n', max(final_signal));

% Write input to text file for SV Testbench Verification
fileID = fopen('svf_input.txt', 'w');
fprintf(fileID, '%d\n', raw_signal); 
fclose(fileID);
disp('Success: svf_input.txt generated for RTL simulation.');