%% Chamberlin_SVF_perf.m
% Ideal, continuous floating-point simulation of a Chamberlin SVF
clear; clc; close all;

% --- 1. Simulation Parameters ---
fs        = 48000;       % Sample Rate (Hz)
total_len = 1024;        % Number of samples
f_target  = 110;         % Oscillator Frequency (Hz)
fc        = 110;         % Filter Cutoff (Hz)
Q         = 4.0;         % Filter Resonance

% --- 2. Generate Ideal Input Signal ---
% Creating an ideal square wave using the sign function oscillating at f_target
t = (0:total_len-1) / fs;
x = sign(sin(2 * pi * f_target * t)); 

% --- 3. Calculate Ideal Filter Coefficients ---
% These are the exact floating-point equivalents of your F_coeff and Damp
F_ideal = 2 * sin(pi * fc / fs);
q_ideal = 1 / Q;

% --- 4. Pre-allocate Output Arrays ---
HP = zeros(1, total_len);
BP = zeros(1, total_len);
LP = zeros(1, total_len);

% Internal state variables (Delay registers Z^-1)
lp_state = 0;
bp_state = 0;

% --- 5. Pure Floating-Point Processing Loop ---
fprintf('Running Ideal Floating-Point SVF...\n');

for n = 1:total_len
    
    % Core Chamberlin SVF topology
    % Notice how directly this maps to: HP = Input - LP - (Damp * BP)
    hp_val = x(n) - lp_state - (q_ideal * bp_state);
    
    % First Integrator
    bp_val = bp_state + (F_ideal * hp_val);
    
    % Second Integrator
    lp_val = lp_state + (F_ideal * bp_val);
    
    % Store the current outputs
    HP(n) = hp_val;
    BP(n) = bp_val;
    LP(n) = lp_val;
    
    % Update the delay states for the next clock cycle (n+1)
    lp_state = lp_val;
    bp_state = bp_val;
end

% --- 6. Plot the Ideal Waveforms ---
figure('Name', 'Ideal Floating-Point Chamberlin SVF', 'Position', [100, 100, 800, 700]);

subplot(3, 1, 1);
plot(LP, 'LineWidth', 1.5, 'Color', '#0072BD');
title('Ideal Low-Pass (LP)');
ylabel('Amplitude');
grid on;

subplot(3, 1, 2);
plot(BP, 'LineWidth', 1.5, 'Color', '#D95319');
title('Ideal Band-Pass (BP)');
ylabel('Amplitude');
grid on;

subplot(3, 1, 3);
plot(HP, 'LineWidth', 1.5, 'Color', '#EDB120');
title('Ideal High-Pass (HP)');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

fprintf('Plot generated successfully.\n');