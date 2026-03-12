% Parameters
fs = 48000;          % Sample rate (Hz)
f_target = 440;      % Target frequency (A4)
bits = 32;           % Accumulator bit-width
duration = 0.1;      % Seconds
num_samples = fs * duration;

% Calculate Tuning Word (M)
M = round((f_target * 2^bits) / fs);

% Pre-allocate
phase_acc = 0;
output = zeros(1, num_samples);

for n = 1:num_samples
    % 1. Update Phase (with overflow/wrap-around)
    % In MATLAB, we use mod to simulate N-bit rollover
    phase_acc = mod(phase_acc + M, 2^bits);
    
    % 2. Normalize phase to [0, 1] for lookup or math
    norm_phase = phase_acc / 2^bits;
    
    % 3. Generate Waveform (Sawtooth example)
    output(n) = 2 * norm_phase - 1; 
end

% Plotting for verification
plot(output(1:500));
title('Simulated Sawtooth Oscillator');