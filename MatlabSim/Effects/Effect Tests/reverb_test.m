%% REVERB_TEST: Hardware-Accurate Algorithmic Reverb Validation
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;
duration    = 2.0;          % Seconds
total_len   = round(fs * duration);
f_target    = 220;          % A3
ACC_WIDTH   = 32;
OUT_WIDTH   = 24;
ADDR_WIDTH  = 10;

% Mix: 50% Sawtooth, 50% Noise (Wide spectrum shows off reverb best)
% [sq, tri, saw, sin, noi]
mix_coeffs = [0.0, 0.0, 0.0, 1.0, 0.0]; 

% --- 2. Generate Dry Signal ---
disp('Generating Dry Oscillator Signal...');
% Using your mixer_out function
dry_unsigned = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, mix_coeffs);

% --- 3. Hardware Pre-Processing (Unsigned to Signed) ---
% Reverb RAM buffers must handle signed audio to prevent DC bias stacking up.
midpoint = 2^(OUT_WIDTH - 1);
dry_signed = int32(double(dry_unsigned) - midpoint);

% HARDWARE GATE: Mute the oscillator after 0.5 seconds to hear the Reverb "Tail"
gate_off_sample = round(0.5 * fs);
dry_signed(gate_off_sample:end) = 0; 
dry_unsigned(gate_off_sample:end) = midpoint; % Unsigned silence is exactly at the midpoint

% --- 4. Apply Reverb Effect ---
disp('Applying Algorithmic Reverb...');
% Reverb Parameters
room_size = 0.85;  % Feedback gain (0.85 = Large Hall)
mix_wet   = 0.40;  % Dry/Wet mix (40% Wet)

% Calling the reverb function
reverb_signed = apply_reverb(dry_signed, fs, room_size, mix_wet);

% --- 5. Post-Processing (Signed to Unsigned) ---
% Convert back to unsigned for your standard pipeline visualization
reverb_out = uint32(double(reverb_signed) + midpoint);

% --- 6. Visualization & Playback ---
t = (0:total_len-1) / fs;
figure('Color', 'k', 'Name', 'Reverb Effect Validation');

% Plot 1: The Dry Signal
subplot(2,1,1);
plot_waveform(t, dry_unsigned, OUT_WIDTH, 'Dry Signal (Cut off at 0.5s)');
xlim([0, duration]); % Show the full 2 seconds to see the empty space

% Plot 2: The Reverb Output
subplot(2,1,2);
plot_waveform(t, reverb_out, OUT_WIDTH, 'Wet Signal (Reverb Tail Applied)');
xlim([0, duration]); % Show the full 2 seconds to see the echoes fading out
xlabel('Time (seconds)', 'Color', 'w');

% Audio Playback prep
max_val = 2^(OUT_WIDTH - 1) - 1;

% Normalizing Wet
audio_float = double(reverb_signed) / max_val;
audio_float = audio_float / max(abs(audio_float)); 

% Normalizing Dry (Using signed so it centers at 0 on speakers to prevent pop)
audio_dry_float = double(dry_signed) / max_val;
if max(abs(audio_dry_float)) > 0
    audio_dry_float = audio_dry_float / max(abs(audio_dry_float)); 
end

if any(isnan(audio_float)) || any(isinf(audio_float))
    error('Reverb Exploded! Your room_size or gain is too high.');
end
fprintf('Max signal amplitude: %.2f\n', max(abs(audio_float)));


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