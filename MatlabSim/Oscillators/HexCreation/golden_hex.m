% Configuration
ACC_WIDTH = 32;
OUT_WIDTH = 32;
fs = 48000;
f_target = 440;
total_samples = 1024;

% Calculate tuning word
tuning_word = round((f_target * 2^ACC_WIDTH) / fs);

% Define path
base_path = '/Users/shayaangandhi/Documents/The-WaveShaper/Oscillators/Matlab_Verification/Matlab_Hex';

%% Generate Square Wave
generate_golden_hex(@model_square, ...
                     fullfile(base_path, 'square_golden.hex'), ...
                     tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH);

%% Generate Sawtooth Wave
generate_golden_hex(@model_saw, ...
                     fullfile(base_path, 'saw_golden.hex'), ...
                     tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH);

%% Generate Sine Wave
generate_golden_hex(@model_sine, ...
                     fullfile(base_path, 'sine_golden.hex'), ...
                     tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH);
%% Generate Triangle
generate_golden_hex(@model_triangle, ...
                     fullfile(base_path, 'triangle_golden.hex'), ...
                     tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH);
%% Generate Noise
generate_golden_hex(@model_noise, ...
                     fullfile(base_path, 'noise_golden.hex'), ...
                     tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH);