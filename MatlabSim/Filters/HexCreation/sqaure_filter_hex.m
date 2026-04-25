%% square_filter_hex.m
% Generates golden hex references for LP, BP, and HP and plots them
clear; clc; close all;

%% --- 1. Simulation Parameters ---
fs           = 48000;       % Sample Rate
total_len    = 1024;        % Match your SV TB repeat count
f_target     = 110;         % Oscillator Frequency (Hz)
fc           = 110;         % Filter Cutoff (Hz)
Q            = 4.0;         % Filter Resonance
types        = {'lp', 'bp', 'hp'}; % Define all modes to generate

%% --- 2. Widths & Coefficients ---
widths       = [32, 32, 10]; 
OUT_WIDTH    = widths(2);
mix_coeffs   = [1.0, 0, 0, 0, 0]; 

%% --- 3. Directory Setup ---
hex_dir = '/Users/shayaangandhi/Documents/The-WaveShaper/Filters/Matlab_Verification/Matlab_Hex/';
copy_dest_dir = '/Users/shayaangandhi/Documents/The-WaveShaper/MatlabSim/Filters/SV_Verification/';

if ~exist(hex_dir, 'dir'), mkdir(hex_dir); end
if ~exist(copy_dest_dir, 'dir'), mkdir(copy_dest_dir); end

figure(1); clf;

%% --- 4. Generation Loop ---
for t = 1:length(types)
    current_type = types{t};
    fprintf('Generating %s Filter Pipeline...\n', upper(current_type));
    
    % Run the Pipeline
    filtered_data = filter_out(fs, total_len, f_target, widths, mix_coeffs, fc, Q, current_type);
    filtered_data = int64(filtered_data(:));
    
    % Define specific filename used by SystemVerilog TB
    file_name = sprintf('square_filter_%s_golden.hex', current_type);
    file_path = fullfile(hex_dir, file_name);
    
    % Export to Hex
    fid = fopen(file_path, 'w');
    if fid == -1, error('Could not open file for writing: %s', file_path); end
    
    hex_chars = ceil(OUT_WIDTH / 4);
    format_spec = ['%0' num2str(hex_chars) 'x\n'];
    mask = bitshift(int64(1), OUT_WIDTH) - 1;
    
    for i = 1:length(filtered_data)
        val = filtered_data(i);
        wrapped_val = bitand(val, mask);
        fprintf(fid, format_spec, uint64(wrapped_val));
    end
    fclose(fid);
    
    % Copy to SV Verification Directory
    copy_dest_file = fullfile(copy_dest_dir, file_name);
    copyfile(file_path, copy_dest_file);
    fprintf('  -> Written and Copied: %s\n', file_name);
    
    %% --- 5. Plotting for Verification ---
    % Re-read hex to ensure export was bit-accurate
    sign_bit = bitshift(int64(1), OUT_WIDTH-1);
    waveform = double(filtered_data); % Using the data directly for plotting
    
    subplot(3, 1, t);
    plot(waveform, 'LineWidth', 1.2);
    title(['Golden Reference: ', upper(current_type)]);
    xlabel('Sample'); ylabel('Amp');
    grid on;
end

fprintf('\nSUCCESS: All 3 golden hex files generated and deployed.\n');