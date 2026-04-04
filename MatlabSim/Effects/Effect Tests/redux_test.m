%% REDUX_TEST: Hardware-Accurate Bitcrusher Validation
clear; clc; close all;

% --- 1. Global Hardware Parameters ---
fs          = 48000;        % Locked to 48kHz
duration    = 2.0;          
total_len   = round(fs * duration);
f_target    = 220;          % A3
ACC_WIDTH   = 32;
OUT_WIDTH   = 24;
ADDR_WIDTH  = 10;

% Mix: 100% Triangle Wave
% [sq, tri, saw, sin, noi]
mix_coeffs = [0.0, 1.0, 0.0, 0.0, 0.0]; 

% --- 2. Generate Dry Signal ---
disp('Generating Dry Triangle Wave...');
dry_unsigned = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, mix_coeffs);

% --- 3. Hardware Pre-Processing (Unsigned to Signed) ---
midpoint = 2^(OUT_WIDTH - 1);
dry_signed = int32(double(dry_unsigned) - midpoint);

% --- 4. Apply Redux Effect ---
disp('Applying Redux (Bitcrushing)...');
target_bit_depth  = 5;    % Crush down to 5-bit audio!
downsample_factor = 12;   % Divide sample rate by 12 (Effective fs = 4000Hz)
mix_wet           = 1.0;  % 100% Wet (Bitcrushers are rarely mixed dry)

redux_signed = apply_redux(dry_signed, target_bit_depth, downsample_factor, OUT_WIDTH, mix_wet);

% --- 5. Post-Processing (Signed to Unsigned) ---
redux_out = uint32(double(redux_signed) + midpoint);

% --- 6. Visualization & Playback ---
t = (0:total_len-1) / fs;
figure('Color', 'k', 'Name', 'Redux Effect Validation');

% Plot 1: The Dry Signal
subplot(2,1,1);
plot_waveform(t, dry_unsigned, OUT_WIDTH, 'Dry Signal (Pure Triangle)');
xlim([0.1, 0.12]); % Zoom in to see the smooth slopes

% Plot 2: The Redux Output
subplot(2,1,2);
plot_waveform(t, redux_out, OUT_WIDTH, sprintf('Wet Signal (Bits: %d, Decimation: %dx)', target_bit_depth, downsample_factor));
xlim([0.1, 0.12]);
xlabel('Time (seconds)', 'Color', 'w');

% --- Audio Playback using sound() within a try-catch ---
max_val = 2^(OUT_WIDTH - 1) - 1;

audio_dry_float = double(dry_signed) / max_val;
audio_float = double(redux_signed) / max_val;

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
    
    disp('Playing Bitcrushed Audio...');
    sound(audio_float, fs);
    pause(duration);

catch
    fprintf('\n--- macOS Audio Error ---\n');
    disp('MATLAB was unable to access the sound hardware.');
    disp('Check Audio MIDI Setup or run "clear sound".');
end