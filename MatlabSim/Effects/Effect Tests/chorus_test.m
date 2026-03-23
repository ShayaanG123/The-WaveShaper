%% CHORUS_TEST: Hardware-Accurate Delay Modulation Validation
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;
duration    = 2.0;          % Seconds
total_len   = round(fs * duration);
f_target    = 220;          % A3 (Low frequency shows pitch wobble well)

ACC_WIDTH   = 32;
OUT_WIDTH   = 24;
ADDR_WIDTH  = 10;

% Mix: 100% Sawtooth (Harmonically rich for better Chorus "shimmer")
% [sq, tri, saw, sin, noi]
mix_coeffs = [0.0, 0.0, 0.0, 1.0, 0.0]; 

% --- 2. Generate Dry Signal ---
disp('Generating Dry Oscillator Signal...');
% Using your mixer_out function
dry_unsigned = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, mix_coeffs);

% --- 3. Hardware Pre-Processing (Unsigned to Signed) ---
% Chorus/Delay RAM buffers must handle signed audio to prevent DC bias issues.
midpoint = 2^(OUT_WIDTH - 1);
dry_signed = int32(double(dry_unsigned) - midpoint);

% --- 4. Apply Chorus Effect ---
disp('Applying Modulated Delay (Chorus)...');
% Chorus Parameters
base_delay_ms = 25.0;  % Base delay (20-30ms is standard for Chorus)
depth_ms      = 3.0;   % LFO sweep depth (+/- 3ms)
lfo_rate_hz   = 4;   % Speed of the sweep
mix_wet       = 0.5;   % 50/50 Dry/Wet mix for maximum thickness

% Calling the function we built in the previous step
chorus_signed = apply_chorus(dry_signed, fs, base_delay_ms, depth_ms, lfo_rate_hz, mix_wet);

% --- 5. Post-Processing (Signed to Unsigned) ---
% Convert back to unsigned for your standard pipeline visualization
chorus_out = uint32(double(chorus_signed) + midpoint);

% --- 6. Visualization & Playback ---
t = (0:total_len-1) / fs;
figure('Color', 'k', 'Name', 'Chorus Effect Validation');

% Plot 1: The Dry Signal (Zoomed in to see waveform)
subplot(2,1,1);
plot_waveform(t, dry_unsigned, OUT_WIDTH, 'Dry Signal');
xlim([0.5, 0.52]); % Zoom into a 20ms window to see the saw teeth

% Plot 2: The Chorus Output (Zoomed in)
subplot(2,1,2);
plot_waveform(t, chorus_out, OUT_WIDTH, 'Wet Signal (Chorus Applied)');
xlim([0.5, 0.52]);
xlabel('Time (seconds)', 'Color', 'w');

% Audio Playback
max_val = 2^(OUT_WIDTH - 1) - 1;
audio_float = double(chorus_signed) / max_val;
audio_float = audio_float / max(abs(audio_float)); % Normalize for speakers

% Audio Playback

try
    % Normalize both signals to a peak of 0.99 for safety
    audio_dry_float = audio_dry_float / max(abs(audio_dry_float)) * 0.99;
    audio_float = audio_float / max(abs(audio_float)) * 0.99;

    disp('Playing Dry Audio...');
    sound(audio_dry_float, fs);
    
    % sound() is non-blocking, so we MUST pause for the length of the clip
    % plus a small gap (0.5s) before starting the next sound.
    pause(duration + 0.5); 
    
    disp(['Playing Distorted Audio (', dist_type, ')...']);
    sound(audio_float, fs);
    
    % Final pause to ensure the distorted audio finishes before the script ends
    pause(duration);

catch
    fprintf('\n--- macOS Audio Error ---\n');
end