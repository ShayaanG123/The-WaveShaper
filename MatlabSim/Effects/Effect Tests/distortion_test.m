%% DISTORTION_TEST: Hardware-Accurate Waveshaping Validation
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;
duration    = 2.0;          
total_len   = round(fs * duration);
f_target    = 220;          % A3
ACC_WIDTH   = 32;
OUT_WIDTH   = 24;
ADDR_WIDTH  = 10;

% Mix: 100% Sine Wave (Best for showing distortion harmonics)
% [sq, tri, saw, sin, noi]
mix_coeffs = [0.0, 0.0, 0.0, 1.0, 0.0]; 

% --- 2. Generate Dry Signal ---
disp('Generating Dry Sine Wave...');
dry_unsigned = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, mix_coeffs);

% --- 3. Hardware Pre-Processing (Unsigned to Signed) ---
midpoint = 2^(OUT_WIDTH - 1);
dry_signed = int32(double(dry_unsigned) - midpoint);

% --- 4. Apply Distortion Effect ---
disp('Applying Distortion...');

drive_amount = 8.0;       % 8x Gain multiplier (heavy distortion)
dist_type    = 'hard';    % Try changing to 'soft' or 'foldback'!

dist_signed = apply_distortion(dry_signed, drive_amount, dist_type, OUT_WIDTH);

% --- 5. Post-Processing (Signed to Unsigned) ---
dist_out = uint32(double(dist_signed) + midpoint);

% --- 6. Visualization & Playback ---
t = (0:total_len-1) / fs;
figure('Color', 'k', 'Name', 'Distortion Effect Validation');

% Plot 1: The Dry Signal
subplot(2,1,1);
plot_waveform(t, dry_unsigned, OUT_WIDTH, 'Dry Signal');
xlim([0.1, 0.12]); % Zoom in to see exactly what is happening to the wave

% Plot 2: The Distorted Output
subplot(2,1,2);
plot_waveform(t, dist_out, OUT_WIDTH, ['Wet Signal (', upper(dist_type), ' Clipping)']);
xlim([0.1, 0.12]);
xlabel('Time (seconds)', 'Color', 'w');

% --- Audio Playback ---
max_val = 2^(OUT_WIDTH - 1) - 1;

% Normalize for safe playback
audio_dry_float = double(dry_signed) / max_val;
audio_dry_float = audio_dry_float / max(abs(audio_dry_float)); 

audio_float = double(dist_signed) / max_val;
audio_float = audio_float / max(abs(audio_float)); 

% Using Audioplayer to bypass macOS locks
% --- Audio Playback using sound() within a try-catch ---
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