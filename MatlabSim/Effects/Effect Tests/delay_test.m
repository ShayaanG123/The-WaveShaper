%% DELAY_TEST: Hardware-Accurate Echo Validation
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;        % Or 48000 depending on your OS stability
duration    = 3.0;          % 3 seconds to hear the echoes fade out
total_len   = round(fs * duration);
f_target    = 440;          % A4
ACC_WIDTH   = 32;
OUT_WIDTH   = 24;
ADDR_WIDTH  = 10;

% Mix: 50% Square, 50% Sawtooth (A bright, classic synth pluck)
% [sq, tri, saw, sin, noi]
mix_coeffs = [0.5, 0.0, 0.5, 0.0, 0.0]; 

% --- 2. Generate Dry Signal ---
disp('Generating Dry Pluck...');
dry_unsigned = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, mix_coeffs);

% --- 3. Hardware Pre-Processing (Unsigned to Signed) ---
midpoint = 2^(OUT_WIDTH - 1);
dry_signed = int32(double(dry_unsigned) - midpoint);

% HARDWARE GATE: Mute the oscillator after 0.2 seconds to create a short "Pluck"
gate_off_sample = round(0.2 * fs);
dry_signed(gate_off_sample:end) = 0; 
dry_unsigned(gate_off_sample:end) = midpoint; 

% --- 4. Apply Delay Effect ---
disp('Applying Digital Delay...');
delay_time_ms = 350.0; % 350 milliseconds (standard rhythmic echo)
feedback_amt  = 0.6;   % 60% of the signal is fed back
mix_wet       = 0.5;   % 50/50 mix

delay_signed = apply_delay(dry_signed, fs, delay_time_ms, feedback_amt, mix_wet);

% --- 5. Post-Processing (Signed to Unsigned) ---
delay_out = uint32(double(delay_signed) + midpoint);

% --- 6. Visualization & Playback ---
t = (0:total_len-1) / fs;
figure('Color', 'k', 'Name', 'Delay Effect Validation');

% Plot 1: The Dry Pluck
subplot(2,1,1);
plot_waveform(t, dry_unsigned, OUT_WIDTH, 'Dry Signal');
xlim([0, duration]);

% Plot 2: The Delayed Output
subplot(2,1,2);
plot_waveform(t, delay_out, OUT_WIDTH, 'Wet Signal (Echoes fading via Feedback)');
xlim([0, duration]);
xlabel('Time (seconds)', 'Color', 'w');

% --- Audio Playback using sound() within a try-catch ---
max_val = 2^(OUT_WIDTH - 1) - 1;

audio_dry_float = double(dry_signed) / max_val;
audio_float = double(delay_signed) / max_val;

try
    % Normalize
    if max(abs(audio_dry_float)) > 0
        audio_dry_float = audio_dry_float / max(abs(audio_dry_float)) * 0.95;
    end
    if max(abs(audio_float)) > 0
        audio_float = audio_float / max(abs(audio_float)) * 0.95;
    end

    disp('Playing Dry Audio...');
    sound(audio_dry_float, fs);
    pause(duration + 0.5); 
    
    disp('Playing Delayed Audio...');
    sound(audio_float, fs);
    pause(duration);

catch
    fprintf('\n--- macOS Audio Error ---\n');
    disp('MATLAB was unable to access the sound hardware.');
    disp('Check Audio MIDI Setup or run "clear sound".');
end