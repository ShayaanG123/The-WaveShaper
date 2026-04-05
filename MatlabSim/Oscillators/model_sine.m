function out = model_sine(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate output
    out = zeros(1, total_samples, 'uint32');
    phase_acc = uint32(0);
    
    % 1. Create the Bit-True LUT
    % Standard FPGAs often use a 1024-entry (10-bit) LUT
    ADDR_WIDTH = 10;
    lut_size = 2^ADDR_WIDTH;
    n_lut = 0:(lut_size-1);
    
    % Amplitude for 24-bit unsigned: 
    % We want to center the sine wave at (2^24 / 2)
    max_val = 2^OUT_WIDTH - 1;
    mid_point = max_val / 2;
    amplitude = max_val / 2;
    
    % Generate the LUT: Mid + Amp * sin(...)
    % We use uint32(round(...)) to mimic fixed-point storage
    sine_lut = uint32(round(mid_point + amplitude * sin(2 * pi * n_lut / lut_size)));
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            
            % 2. Extract LUT Index (Truncation)
            % Shift right to get the top ADDR_WIDTH bits
            % e.g., for 32-bit ACC and 10-bit ADDR, shift by 22
            idx = bitshift(phase_acc, -(ACC_WIDTH - ADDR_WIDTH));
            
            % 3. Output from LUT
            % +1 because MATLAB is 1-indexed, but our idx is 0-1023
            out(n) = sine_lut(idx + 1);
            
            % 4. Update phase with wrap-around
            next_phase = double(phase_acc) + double(tuning_word);
            phase_acc = uint32(mod(next_phase, 2^ACC_WIDTH));
        else
            out(n) = uint32(0);
        end
    end
end