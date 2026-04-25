%% saw_filter_hex.m
% Generates golden hex references for Input, LP, BP, and HP
clear; clc; close all;

%% --- 1. Simulation Parameters ---
fs           = 48000;
total_len    = 1024;
f_target     = 110;
fc           = 110;
Q            = 4.0;
types        = {'lp', 'bp', 'hp'}; 
osc_type     = 'saw'; 

%% --- 2. Widths & Coefficients ---
widths       = [32, 32, 10]; 
OUT_WIDTH    = widths(2);
mix_coeffs   = [0, 0, 1.0, 0, 0]; % Mapping for SAW in your pipeline

%% --- 3. Directory Setup ---
hex_dir = '/Users/shayaangandhi/Documents/The-WaveShaper/Filters/Matlab_Verification/Matlab_Hex/';
copy_dest_dir = '/Users/shayaangandhi/Documents/The-WaveShaper/MatlabSim/Filters/SV_Verification/';
if ~exist(hex_dir, 'dir'), mkdir(hex_dir); end
if ~exist(copy_dest_dir, 'dir'), mkdir(copy_dest_dir); end

%% --- 4. Generate Raw Input for Verification ---
% Call your bit-true model_saw directly to ensure no floating point noise
tuning_word = uint32(round((f_target / fs) * 2^32));
raw_input = model_saw(total_len, 1, total_len, tuning_word, 32, 32);

input_file = 'saw_input_golden.hex';
write_hex(fullfile(hex_dir, input_file), raw_input, OUT_WIDTH);
copyfile(fullfile(hex_dir, input_file), fullfile(copy_dest_dir, input_file));
fprintf('Generated and Copied Input Verification Hex: %s\n', input_file);

%% --- 5. Generation Loop for Filter Modes ---
figure(1); clf;
for t = 1:length(types)
    current_type = types{t};
    fprintf('Generating Sawtooth -> %s Filter Pipeline...\n', upper(current_type));
    
    % Pass the raw_input into your filter function 
    % (Ensure your filter_out can accept pre-generated signals or use identical logic)
    [lp, bp, hp] = Chamber_SVF(raw_input, fc, Q, fs, OUT_WIDTH);
    
    if strcmpi(current_type, 'lp'), data = lp;
    elseif strcmpi(current_type, 'bp'), data = bp;
    else, data = hp; end
    
    file_name = sprintf('saw_filter_%s_golden.hex', current_type);
    write_hex(fullfile(hex_dir, file_name), data, OUT_WIDTH);
    copyfile(fullfile(hex_dir, file_name), fullfile(copy_dest_dir, file_name));
    
    % Plotting
    subplot(3, 1, t);
    plot(double(data), 'LineWidth', 1.2);
    title(['Sawtooth Golden: ', upper(current_type)]);
    grid on;
end
fprintf('\nSUCCESS: All files deployed.\n');

%% --- Helper Function for Hex Export ---
function write_hex(file_path, data, width)
    fid = fopen(file_path, 'w');
    if fid == -1, error('File error: %s', file_path); end
    hex_chars = ceil(width / 4);
    format_spec = ['%0' num2str(hex_chars) 'x\n'];
    mask = bitshift(int64(1), width) - 1;
    for i = 1:length(data)
        val = int64(data(i));
        fprintf(fid, format_spec, uint64(bitand(val, mask)));
    end
    fclose(fid);
end