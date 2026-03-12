function out = model_saw(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate the output array as uint32 for exact bit-matching
    out = zeros(1, total_samples, 'uint32');
    
    % Initialize internal phase accumulator
    phase_acc = uint32(0); 
    
    OUT_MASK = uint32(2^OUT_WIDTH - 1);

    shift_val = -(ACC_WIDTH - OUT_WIDTH);
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            % Slice the top bits (e.g., bits 31 down to 8)
            out(n) = bitand(bitshift(phase_acc, shift_val), OUT_MASK);
            
            % Update with wrap-around
            next_phase = double(phase_acc) + double(tuning_word);
            phase_acc = uint32(mod(next_phase, 2^ACC_WIDTH));
        else
            out(n) = uint32(0);
        end
    end
end