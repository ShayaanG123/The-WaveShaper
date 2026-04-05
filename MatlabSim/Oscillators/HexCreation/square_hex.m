%% 1. Configuration Parameters
% Hardware and System Settings
ACC_WIDTH = 32;         % Phase accumulator bit-width
OUT_WIDTH = 24;         % Output signal bit-width
fs = 48000;             % System sample rate (Hz)

% Testbench Stimulus Settings
f_target = 440;         % Target frequency (Hz)
total_samples = 1024;   % Number of samples to generate

%% 2. File I/O Setup
% Define the absolute path to ensure MATLAB finds the folder safely
output_path = '/Users/shayaangandhi/Documents/The-WaveShaper/Oscillators/Matlab_Verification/Matlab_Hex';
file_name = 'square_golden.hex';
full_file_path = fullfile(output_path, file_name);

% Safety check: Create the directory if it does not already exist
if ~exist(output_path, 'dir')
    mkdir(output_path);
    fprintf('Created missing directory: %s\n', output_path);
end

%% 3. Model Execution
% Calculate tuning word: f_out = (tuning_word * fs) / 2^ACC_WIDTH
tuning_word = round((f_target * 2^ACC_WIDTH) / fs);

% Generate the golden reference data
out_data = model_square(total_samples, 1, total_samples, tuning_word, ACC_WIDTH, OUT_WIDTH);

%% 4. Data Export
% Open the file for writing
fid = fopen(full_file_path, 'w');
if fid == -1
    error('Could not open file. Check permissions for: %s', output_path);
end

% Write data to hex format
% Note: %06x ensures the 24-bit output matches OUT_WIDTH exactly
for i = 1:length(out_data)
    fprintf(fid, '%06x\n', out_data(i));
end

fclose(fid);
fprintf('Success! Golden file written to: %s\n', full_file_path);