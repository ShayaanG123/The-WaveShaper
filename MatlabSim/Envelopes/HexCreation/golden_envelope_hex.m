%% ADSR Verification Hex Generation Script
% Configuration
ACC_WIDTH     = 32;
OUT_WIDTH     = 24; 
ENV_FRACT     = 16;
fs            = 48000;
total_samples = 2048; % Longer sample to see the full envelope

% ADSR Coefficients (Q16 Format)
% MAX_ENV is 65536. 
attack_step   = 200;   % Fast attack
decay_step    = 50;    % Slow decay
sustain_level = 32768; % Sustain at 50% volume (0.5 in Q16)
release_step  = 100;   % Medium release

base_path = '/Users/shayaangandhi/Documents/The-WaveShaper/Envelope/Matlab_Verification/Matlab_Hex';
if ~exist(base_path, 'dir'), mkdir(base_path); end

%% 1. Generate Input Audio (Sawtooth)
f_saw   = 440; 
tw_saw  = uint32(round((f_saw * 2^ACC_WIDTH) / fs));
in_saw  = model_saw(total_samples, 1, total_samples, tw_saw, ACC_WIDTH, OUT_WIDTH);

% Fix the signed math representation
sign_extend = @(x) int32(double(x) - (double(x) >= 2^23) * 2^24);
in_saw = sign_extend(in_saw);

%% 2. Generate Gate Signal
% Press key at sample 100, release key at sample 1200
gate_in = zeros(1, total_samples, 'int8');
gate_in(100:1200) = 1;

%% 3. Apply Hardware-Compliant ADSR
adsr_out = apply_adsr(in_saw, gate_in, attack_step, decay_step, sustain_level, release_step, OUT_WIDTH, ENV_FRACT);

%% 4. Export Hex Files
mask = uint64(2^OUT_WIDTH - 1);
audio_fmt = ['%0' num2str(ceil(OUT_WIDTH/4)) 'x\n'];
gate_fmt  = '%01x\n';

% Export Audio Input
fid = fopen(fullfile(base_path, 'adsr_in_audio_golden.hex'), 'w');
for i = 1:length(in_saw)
    fprintf(fid, audio_fmt, bitand(uint64(typecast(int32(in_saw(i)), 'uint32')), mask));
end
fclose(fid);

% Export Gate Input
fid = fopen(fullfile(base_path, 'adsr_in_gate_golden.hex'), 'w');
for i = 1:length(gate_in)
    fprintf(fid, gate_fmt, gate_in(i));
end
fclose(fid);

% Export ADSR Output
fid = fopen(fullfile(base_path, 'adsr_out_golden.hex'), 'w');
for i = 1:length(adsr_out)
    fprintf(fid, audio_fmt, bitand(uint64(typecast(int32(adsr_out(i)), 'uint32')), mask));
end
fclose(fid);

fprintf('--- ADSR Generation Complete ---\n');