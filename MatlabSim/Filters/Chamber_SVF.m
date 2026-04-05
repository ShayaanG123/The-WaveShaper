% Chamberlin State Variable Filter (SVF) Simulation
clear; clc; close all;

%% 1. System Parameters
fs = 48000;             % Sample rate (Hz)
duration = 0.05;        % Duration in seconds
t = 0:(1/fs):(duration - 1/fs); 
N = length(t);

%% 2. Generate Input Signal (Sawtooth Wave)
% A 220 Hz sawtooth wave to provide rich harmonics for filtering
f_sig = 220; 
x = sawtooth(2 * pi * f_sig * t);

%% 3. Filter Parameters
fc = 1200;              % Cutoff frequency (Hz)
Q = 4.0;                % Resonance (Higher Q = sharper resonance)

% Calculate tuning coefficients
% F controls the cutoff frequency
F = 2 * sin(pi * fc / fs); 
% Damp controls the resonance (damping factor)
damp = 1 / Q;              

%% 4. Initialize State Variables (Hardware Registers)
% In RTL, these will be your flip-flop registers holding the previous sample
lp_state = 0; 
bp_state = 0;

%% 5. Pre-allocate Output Arrays for Plotting
hp_out = zeros(1, N);
bp_out = zeros(1, N);
lp_out = zeros(1, N);

%% 6. Process Audio (The Hardware Loop)
for n = 1:N
    % Fetch the current input sample
    input_sample = x(n);
    
    % 1. Calculate High-Pass output
    % HP = Input - Previous LP - (Damping * Previous BP)
    hp = input_sample - lp_state - (damp * bp_state);
    
    % 2. Calculate Band-Pass output
    % BP = Previous BP + (F * Current HP)
    bp = bp_state + (F * hp);
    
    % 3. Calculate Low-Pass output
    % LP = Previous LP + (F * Current BP)
    lp = lp_state + (F * bp);
    
    % Store outputs for plotting
    hp_out(n) = hp;
    bp_out(n) = bp;
    lp_out(n) = lp;
    
    % Update State Variables for the next clock cycle (z^-1)
    lp_state = lp;
    bp_state = bp;
end

%% 7. Plotting Results
figure('Name', 'Chamberlin SVF Outputs', 'NumberTitle', 'off');

% Time Domain Plot (Low-Pass Example)
subplot(2,1,1);
plot(t(1:500), x(1:500), 'Color', [0.7 0.7 0.7], 'DisplayName', 'Input (Sawtooth)');
hold on;
plot(t(1:500), lp_out(1:500), 'b', 'LineWidth', 1.5, 'DisplayName', 'Low-Pass Output');
title(sprintf('Time Domain: Cutoff = %d Hz, Q = %.1f', fc, Q));
xlabel('Time (s)');
ylabel('Amplitude');
legend;
grid on;

% Frequency Domain Plot (Magnitude Response of all three outputs)
% Calculate FFT
NFFT = 2^nextpow2(N);
f_axis = fs/2 * linspace(0, 1, NFFT/2+1);

X_fft = fft(x, NFFT);
LP_fft = fft(lp_out, NFFT);
BP_fft = fft(bp_out, NFFT);
HP_fft = fft(hp_out, NFFT);

% Convert to dB
X_mag = 20*log10(abs(X_fft(1:NFFT/2+1)) + eps);
LP_mag = 20*log10(abs(LP_fft(1:NFFT/2+1)) + eps);
BP_mag = 20*log10(abs(BP_fft(1:NFFT/2+1)) + eps);
HP_mag = 20*log10(abs(HP_fft(1:NFFT/2+1)) + eps);

subplot(2,1,2);
semilogx(f_axis, X_mag, 'Color', [0.7 0.7 0.7], 'DisplayName', 'Input Spectrum');
hold on;
semilogx(f_axis, LP_mag, 'b', 'LineWidth', 1.5, 'DisplayName', 'Low-Pass');
semilogx(f_axis, BP_mag, 'r', 'LineWidth', 1.5, 'DisplayName', 'Band-Pass');
semilogx(f_axis, HP_mag, 'g', 'LineWidth', 1.5, 'DisplayName', 'High-Pass');
title('Frequency Response');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
xlim([20 20000]);
ylim([-40 60]);
legend;
grid on;