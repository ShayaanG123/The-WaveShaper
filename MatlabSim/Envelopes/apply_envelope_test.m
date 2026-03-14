%% Digital Synth Pipeline: Complete Integration Test
clear; clc;
% Add your subfolders if needed
addpath(genpath('..')); 

% --- 1. Global System Parameters ---
fs = 48000;             % System sample rate
duration = 3.0;         % Total testbench time in seconds
total_samples = round(duration * fs);

WAVE_WIDTH = 24;        % Bit width for audio buses
ENV_WIDTH  = 24;        % Bit width for envelope multiplier
OUT_WIDTH  = 24;        % Final output width
ACC_WIDTH  = 32;        % Phase accumulator width
ADDR_WIDTH = 10;        % LUT address width

f_target = 440;         % A4
M = round((f_target * 2^ACC_WIDTH) / fs); % Tuning word

% --- 2. Envelope & Timing Calculations ---
% ADSR Parameters (in seconds)
A = 0.1; 
D = 0.2; 
S = 0.5; 
R = 0.4; 
gate_time = 1.0; % Note held for 1 second

% Generate the normalized envelope float array
env_array = generate_adsr(A, D, S, R, gate_time, fs);

% Calculate exact step boundaries for the hardware modules
start_time = 0.5; % Trigger the note 0.5 seconds into the buffer
on_step   = round(start_time * fs) + 1;
stop_step = on_step + length(env_array) - 1;

% The oscillators must keep running until the envelope has completely faded out
off_step  = stop_step; 

% --- 3. Generate Raw DDS Waveforms ---
% Using your custom hardware models
disp('Generating DDS Oscillators...');
out_sq  = model_square(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_saw = model_saw(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_tri = model_triangle(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH);
out_sin = model_sine(total_samples, on_step, off_step, M, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH);
out_noi = model_noise(total_samples, on_step, off_step, ACC_WIDTH, OUT_WIDTH);

% --- 4. Mix the Waveforms ---
% Define fractional mix coefficients (must sum to <= 1.0)
c1 = 0.0;   % 0% Square
c2 = 0.0;   % 00% Sawtooth (Bright base)
c3 = 0.0;   % 0% Triangle
c4 = 1;   % 100% Sine (Fundamental body)
c5 = 0.0;   % 00% Noise (Breath/Attack character)

disp('Mixing waveforms...');
mixer_out = wave_mixer(out_sq, out_saw, out_tri, out_sin, out_noi, ...
                       c1, c2, c3, c4, c5, OUT_WIDTH);

% --- 5. Apply the Hardware Envelope ---
disp('Applying envelope...');
final_out = apply_envelope(mixer_out, env_array, on_step, stop_step, ...
                           WAVE_WIDTH, ENV_WIDTH, OUT_WIDTH);

% --- 6. Visualization & Playback ---
t = (0:total_samples-1) / fs;
max_uint24 = 2^OUT_WIDTH - 1;

figure('Name', 'Complete Synth Pipeline Validation', 'Position', [100, 100, 800, 600]);

% Plot 1: The Raw Mixer Output
subplot(3,1,1);
plot(t, mixer_out);
title('wave\_mixer Output (Sine + Saw + Noise)');
ylabel('Amplitude');
ylim([0 max_uint24]);
grid on;

% Plot 2: The Envelope Map
subplot(3,1,2);
% Create a padded envelope array matching the total time for visualization
env_plot = zeros(1, total_samples);
env_plot(on_step:stop_step) = env_array;
plot(t, env_plot, 'LineWidth', 2, 'Color', '#D95319'); % Distinct color
title('ADSR Envelope Timeline');
ylabel('Multiplier (0-1)');
ylim([0 1.1]);
grid on;

% Plot 3
subplot(3,1,3);
plot(t, final_out);
title('Final Output after apply\_envelope');
xlabel('Time (seconds)');
ylabel('Amplitude');
ylim([0 max_uint24]);
grid on;

disp('Playing generated audio...');
% Convert 24-bit unsigned int back to normalized float (-1.0 to 1.0) for speakers
audio_float = (double(final_out) / max_uint24) * 2 - 1;
% Strip DC offset to prevent speaker pop
audio_float = audio_float - mean(audio_float); 
sound(audio_float, fs);