function out = model_square(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate the output array as uint32 for exact bit-matching
    out = zeros(1, total_samples, 'uint32');
    
    % Initialize internal phase accumulator
    phase_acc = uint32(0); 
    
    % Define the unsigned boundary values
    MAX_VAL = uint32(2^OUT_WIDTH - 1);
    MIN_VAL = uint32(0);
    
    % Cast tuning word to ensure proper integer overflow math
    tuning_word = uint32(tuning_word);
    
    for n = 1:total_samples
        % The 'enable' window
        if (n >= start_step) && (n <= stop_step)
            
            % 1. Combinational Output Logic (Matches your 'assign sq_out')
            % MATLAB's bitget is 1-indexed, so ACC_WIDTH (e.g., 32) grabs the MSB
            if bitget(phase_acc, ACC_WIDTH) == 0
                out(n) = MAX_VAL;
            else
                out(n) = MIN_VAL;
            end
            
            % 2. Sequential Register Update (Matches your 'always_ff')
            % Standard uint32 addition naturally wraps at 2^32 just like the FPGA
            next_phase = double(phase_acc) + double(tuning_word);
            phase_acc = uint32(mod(next_phase, 2^ACC_WIDTH));
            
        else
            % When disabled, output drops to 0. 
            % phase_acc is not updated, mimicking the 'enable' hold state.
            out(n) = MIN_VAL; 
        end
    end
end