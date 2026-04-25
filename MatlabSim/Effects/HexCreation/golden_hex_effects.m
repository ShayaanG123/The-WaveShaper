%% Effect Golden Hex Generation Script
% Configuration
ACC_WIDTH     = 32;
OUT_WIDTH     = 32;
ADDR_WIDTH    = 10; % Matching your SV parameter
fs            = 48000;
f_target      = 440; 
total_samples = 1024;

% Calculate tuning word (Exact match to SV TB)
tuning_word = uint32(round((f_target * 2^ACC_WIDTH) / fs));

% Define paths
base_path = '/Users/shayaangandhi/Documents/The-WaveShaper/Effects/Matlab_Verification/Matlab_Hex';
if ~exist(base_path, 'dir'), mkdir(base_path); end

%% 1. Generate and Export Raw Input Signal
raw_input = model_saw(total_samples, 1, total_samples, tuning_word, ACC_WIDTH, OUT_WIDTH);

fid = fopen(fullfile(base_path, 'effect_input_saw_golden.hex'), 'w');
mask = uint64(2^OUT_WIDTH - 1);
format_spec = ['%0' num2str(OUT_WIDTH/4) 'x\n'];
for i = 1:length(raw_input)
    val = typecast(int32(raw_input(i)), 'uint32');
    fprintf(fid, format_spec, bitand(uint64(val), mask));
end
fclose(fid);
fprintf('Generated Input Verification Hex: effect_input_saw_golden.hex\n');

%% 2. Distortion (input, gain, width)
% FIXED: Added OUT_WIDTH as the 3rd argument
generate_effect_hex(@apply_distortion, ...
    fullfile(base_path, 'distortion_golden.hex'), ...
    OUT_WIDTH, raw_input, 5, OUT_WIDTH);

%% 3. Redux (input, bit_crush, width)
% FIXED: Added OUT_WIDTH as the 3rd argument
generate_effect_hex(@apply_redux, ...
    fullfile(base_path, 'redux_golden.hex'), ...
    OUT_WIDTH, raw_input, 8, OUT_WIDTH);

%% 4. Echo
generate_effect_hex(@apply_delay, ...
    fullfile(base_path, 'echo_golden.hex'), ...
    OUT_WIDTH, raw_input, OUT_WIDTH, ADDR_WIDTH);

%% 5. Chorus
lfo_freq = 1; 
lfo_tuning_word = uint32(round((lfo_freq * 2^ACC_WIDTH) / fs));
lfo_tri = model_triangle(total_samples, 1, total_samples, lfo_tuning_word, ACC_WIDTH, OUT_WIDTH);

% A. Generate the Chorus Audio Golden
generate_effect_hex(@apply_chorus, ...
    fullfile(base_path, 'chorus_golden.hex'), ...
    OUT_WIDTH, raw_input, lfo_tri, OUT_WIDTH, ADDR_WIDTH);

% B. Generate and Export LFO Verification Hex
% This lets you check if your RTL osc_triangle matches MATLAB exactly
fid_lfo = fopen(fullfile(base_path, 'lfo_tri_golden.hex'), 'w');
mask = uint64(2^OUT_WIDTH - 1);
format_spec = ['%0' num2str(OUT_WIDTH/4) 'x\n'];

for i = 1:length(lfo_tri)
    % Cast to uint32 to handle signed 2's complement correctly for hex
    val_lfo = typecast(int32(lfo_tri(i)), 'uint32');
    fprintf(fid_lfo, format_spec, bitand(uint64(val_lfo), mask));
end
fclose(fid_lfo);

fprintf('Generated LFO Verification Hex: lfo_tri_golden.hex\n');


%% 6. Reverb (NEW)
% Uses the hardware-compliant apply_reverb function
generate_effect_hex(@apply_reverb, ...
    fullfile(base_path, 'reverb_golden.hex'), ...
    OUT_WIDTH, raw_input, OUT_WIDTH, ADDR_WIDTH);

fprintf('\n--- Effects & Input Generation Complete ---\n');