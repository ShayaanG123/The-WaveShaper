function out = model_triangle(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate the output array as uint32
    out = zeros(1, total_samples, 'uint32');
    
    % Initialize internal phase accumulator
    phase_acc = uint32(0);
    
    % Mask to ensure we only keep the bits we want for the output (e.g., 0xFFFFFF)
    OUT_MASK = uint32(2^OUT_WIDTH - 1);
    
    % Calculate the shift required to get the ramp bits.
    % To get a full-scale triangle, we use the OUT_WIDTH bits below the MSB.
    % For ACC_WIDTH=32 and OUT_WIDTH=24, this shift is 7.
    shift_val = -(ACC_WIDTH - 1 - OUT_WIDTH);

    for n = 1:total_samples
        % The 'enable' window
        if (n >= start_step) && (n <= stop_step)
            
            % 1. Extract the raw ramp bits [ACC_WIDTH-2 -: OUT_WIDTH]
            % We shift right and mask to get the 24 bits below the MSB
            ramp = bitand(bitshift(phase_acc, shift_val), OUT_MASK);
            
            % 2. Folding Logic (Matches your 'always_comb' block)
            % Check MSB (the 32nd bit)
            if bitget(phase_acc, ACC_WIDTH) == 0
                % First half of cycle: Rising slope (0 to Max)
                out(n) = ramp;
            else
                % Second half of cycle: Falling slope (Max to 0)
                % XOR with OUT_MASK is the bit-true version of ~ramp
                out(n) = bitxor(ramp, OUT_MASK);
            end
            
            % 3. Update phase with manual wrap-around
            next_phase = double(phase_acc) + double(tuning_word);
            phase_acc = uint32(mod(next_phase, 2^ACC_WIDTH));
            
        else
            % Output is zero outside the start/stop window
            out(n) = uint32(0);
        end
    end
end