%% Mixer Verification Hex Generation Script
% Configuration
ACC_WIDTH     = 32;
OUT_WIDTH     = 24; 
fs            = 48000;
total_samples = 1024;

% Target Frequencies (Unique for each oscillator to ease verification)
f_saw   = 440; 
f_sq    = 880; 
f_tri   = 220;

% Calculate tuning words
tw_saw = uint32(round((f_saw * 2^ACC_WIDTH) / fs));
tw_sq  = uint32(round((f_sq  * 2^ACC_WIDTH) / fs));
tw_tri = uint32(round((f_tri * 2^ACC_WIDTH) / fs));

base_path = '/Users/shayaangandhi/Documents/The-WaveShaper/Mixer/Matlab_Verification/Matlab_Hex';
if ~exist(base_path, 'dir'), mkdir(base_path); end

%% 1. Generate Unique Waveforms
% Activating 3 oscillators, keeping 2 grounded (Sine/Noise)
in_saw    = model_saw(total_samples, 1, total_samples, tw_saw, ACC_WIDTH, OUT_WIDTH);
in_square = model_square(total_samples, 1, total_samples, tw_sq, ACC_WIDTH, OUT_WIDTH);
in_tri    = model_triangle(total_samples, 1, total_samples, tw_tri, ACC_WIDTH, OUT_WIDTH);
in_sine   = zeros(1, total_samples, 'int32');
in_noise  = zeros(1, total_samples, 'int32');

% --- FIX: Casting to double for arithmetic, then back to int32 ---
% This ensures MATLAB handles the 24-bit 2's complement math like the FPGA
sign_extend = @(x) int32(double(x) - (double(x) >= 2^23) * 2^24);

in_saw    = sign_extend(in_saw);
in_square = sign_extend(in_square);
in_tri    = sign_extend(in_tri);

% Pack into a cell array for easy looping
signals = {in_saw, in_square, in_sine, in_tri, in_noise};
names   = {'saw', 'square', 'sine', 'tri', 'noise'};

mask = uint64(2^OUT_WIDTH - 1);
format_spec = ['%0' num2str(ceil(OUT_WIDTH/4)) 'x\n'];

% Export Individual Golden Input Hexes
for c = 1:5
    fid = fopen(fullfile(base_path, sprintf('mixer_in_%s_golden.hex', names{c})), 'w');
    data = signals{c};
    for i = 1:length(data)
        % typecast ensures the signed int32 is written as unsigned hex bits
        val = typecast(int32(data(i)), 'uint32');
        fprintf(fid, format_spec, bitand(uint64(val), mask));
    end
    fclose(fid);
    fprintf('Generated: mixer_in_%s_golden.hex\n', names{c});
end

%% 2. Generate Mixer Output Golden
GAIN_SH = 16;
% [Saw, Square, Sine, Tri, Noise]
% 0.5 Gain for active channels = 1.5x total gain (triggers saturation)
coefs = [32768, 32768, 0, 32768, 0]; 

% --- FIX: Hardware Routing Delay ---
% Shift the inputs by 1 sample to model the register-to-register capture delay
% This makes the Golden Model match the RTL's 1-cycle stagger.
delay_input = @(x) [int32(0), x(1:end-1)];

% Use @wave_mixer (hardware-compliant model) with delayed inputs
generate_mixer_hex(@wave_mixer, ...
    fullfile(base_path, 'mixer_golden.hex'), ...
    OUT_WIDTH, ...
    delay_input(in_saw), ...
    delay_input(in_square), ...
    delay_input(in_sine), ...
    delay_input(in_tri), ...
    delay_input(in_noise), ...
    coefs, OUT_WIDTH, GAIN_SH);

fprintf('\n--- Mixer Generation Complete ---\n');