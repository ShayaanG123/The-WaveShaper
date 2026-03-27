%% MASTER_PIPELINE_TEST: The Complete Synthesizer
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;
duration    = 3.0; 
f_target    = 110; % A3
widths      = [32, 24, 10, 24]; % [ACC, OUT, ADDR, ENV]

% Mix: 50% Square, 50% Triangle for a hollow, vintage synth lead
mix_coeffs = [0.5, 0.5, 0.0, 0.0, 0.0]; 

% ADSR Configuration
adsr.A = 0.2;
adsr.D = 0.30;
adsr.S = 0.4;
adsr.R = 0.8;
adsr.gate_time = 1.5; 
adsr.start_delay = 0.1;

% --- 2. Filter Configuration ---
% Bandpass Filter (1kHz to 5kHz)
f_low  = 1000; 
f_high = 5000;
Wn = [f_low, f_high] / (fs/2);

% Generate Butterworth coefficients
[b_coeffs, a] = butter(1, Wn, 'bandpass'); 
a_coeffs = a(2:3); % Extract [a1, a2] for hardware model compatibility

% --- 3. Define the Effects Chain ---
OUT_WIDTH = widths(2);

% --- Effect Definitions (Anonymous functions for pipeline mapping) ---
% Format: @(w) function_name(input_waveform, parameters..., OUT_WIDTH)

% 1. Distortion (Soft Clipping)
% Parameters: (signal, gain, type, OUT_WIDTH)
fx_dist   = @(w) apply_distortion(w, 5.0, 'soft', widths(2));

% 2. Chorus (Modulated Delay)
% Parameters: (signal, fs, max_delay_ms, depth, rate_hz, mix)
fx_chorus = @(w) apply_chorus(w, fs, 30.0, 0.8, 0.5, 0.6);

% 3. Echo/Delay (Feedback Delay Line)
% Parameters: (signal, fs, delay_ms, feedback, mix)
fx_delay  = @(w) apply_delay(w, fs, 600.0, 0.4, 0.5);

% 4. Reverb (Algorithmic / Schroeder)
% Parameters: (signal, fs, decay_time, mix)
fx_reverb = @(w) apply_reverb(w, fs, 0.7, 0.4);

% 5. Bit-Crusher (Sample Rate and Bit Depth Reduction)
% Parameters: (signal, target_bits, downsample_factor, OUT_WIDTH, mix)
fx_redux  = @(w) apply_redux(w, 8, 4, widths(2), 0.5);

% --- Selection ---
effect_chain = {fx_delay, fx_delay, fx_delay, fx_delay};

% --- 4. Execute the Pipeline ---
disp('--- STARTING SYNTH PIPELINE ---');

% Ensure effect_out is updated to accept b_coeffs and a_coeffs
% It should pass these directly into envelope_out()
final_signed = effect_out(fs, duration, f_target, widths, adsr, ...
                          mix_coeffs, b_coeffs, a_coeffs, effect_chain);

disp('--- PIPELINE COMPLETE ---');

% --- 5. Visualization & Playback ---
t = (0:length(final_signed)-1) / fs;
figure('Color', 'k', 'Name', 'Master Output');

% Plotting the 24-bit Signed signal
plot_waveform(t, final_signed, OUT_WIDTH, 'Final Synth Output (Filtered + Enveloped + FX)');
xlim([0, duration]);
xlabel('Time (seconds)', 'Color', 'w');

% Normalize for MATLAB audio playback (-1.0 to 1.0)
max_val = 2^(OUT_WIDTH - 1);
audio_float = double(final_signed) / max_val; 

try
    disp('Playing Master Audio...');
    % Clipping protection
    audio_float = max(min(audio_float, 1), -1);
    sound(audio_float, fs);
catch
    disp('Audio playback error. Check hardware settings.');
end