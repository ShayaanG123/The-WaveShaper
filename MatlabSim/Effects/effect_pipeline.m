%% MASTER_PIPELINE_TEST: The Complete Synthesizer
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;
duration    = 3.0; % Long enough to hear the delays and reverbs fade
f_target    = 220; % A3
widths      = [32, 24, 10, 24]; % [ACC, OUT, ADDR, ENV]

mix_coeffs = [1.0, 0.0, 0.0, 0.0, 0.0]; 

% ADSR: Watery / Fluid droplet
adsr.A = 0.05;        % Slight fade-in to avoid sharp clicks
adsr.D = 0.00;        % Quick decay for a "drip" feel
adsr.S = 0.1;         % Moderate sustain for the body of the water
adsr.R = 0.0;         % Smooth release as the ripple fades
adsr.gate_time = 1.5; 
adsr.start_delay = 0.1;

% Filter Coefficients (Pass-through / Null filter for this test)
% b_coeffs = [1, 0, 0]; 
% a_coeffs = [0, 0];

fc = 12000; 
f_low  = 1000; 
f_high = 5000;

% Normalize both frequencies
Wn = [f_low, f_high] / (fs/2);
% If you want HPF or LPF change 'bandpass' to lowpass or highpass
% Also change n from 1 to 2 and Wn = fc / (fs/2);

[b_coeffs, a] = butter(1, Wn, 'bandpass'); % Generate standard Butterworth coeffs
a_coeffs = a(2:3); % MATLAB's 'a' includes a0=1, we only need [a1, a2]

% --- 2. Define the Effects Chain ---
% We use anonymous functions @(w) to represent the 'waveform' input variable.
% This allows us to hardcode the other parameters for each specific effect.

OUT_WIDTH = widths(2);

% Effect 1: Light Overdrive (Soft Clipping)
fx_dist   = @(w) apply_distortion(w, 2.5, 'soft', OUT_WIDTH);

% Effect 2: Wide Chorus
fx_chorus = @(w) apply_chorus(w, fs, 30.0, 0.8, 5.0, 0.7);

% Effect 3: Rhythmic Delay (300ms)
fx_delay  = @(w) apply_delay(w, fs, 300.0, 0.5, 0.4);

% Effect 4: Large Hall Reverb
fx_reverb = @(w) apply_reverb(w, fs, 0.4, 0.6);

% Pack them into a cell array in the exact order you want them executed
effect_chain = {};%{fx_chorus, fx_reverb};

% --- 3. Execute the Pipeline ---
disp('--- STARTING SYNTH PIPELINE ---');
final_unsigned = effect_out(fs, duration, f_target, widths, adsr, mix_coeffs, b_coeffs, a_coeffs, effect_chain);
disp('--- PIPELINE COMPLETE ---');

% --- 4. Visualization & Playback ---
t = (0:length(final_unsigned)-1) / fs;
figure('Color', 'k', 'Name', 'Master Output');

plot_waveform(t, final_unsigned, OUT_WIDTH, 'Final Synth Output (Dist -> Chorus -> Delay -> Reverb)');
xlim([0, duration]);
xlabel('Time (seconds)', 'Color', 'w');

% Audio Playback (Using the Try/Catch Audioplayer block for safety)
midpoint = 2^(OUT_WIDTH - 1);
final_signed = int32(double(final_unsigned) - midpoint);
max_val = 2^(OUT_WIDTH - 1) - 1;

audio_float = double(final_signed) / max_val;
% Normalize 
if max(abs(audio_float)) > 0
    audio_float = audio_float / max(abs(audio_float)) * 0.95;
end

try
    disp('Playing Master Audio...');
    sound(audio_float, fs);
    pause(duration + 0.5);
catch
    disp('macOS Audio Error. Check Audio MIDI Setup.');
end