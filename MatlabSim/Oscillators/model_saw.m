function out = model_saw(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate as signed int32 to match 'logic signed [OUT_WIDTH-1:0]'
    out = zeros(1, total_samples, 'int32');
    
    % Initialize internal phase accumulator (32-bit unsigned)
    phase_acc = uint32(0); 
    
    tuning_word = uint32(tuning_word);
    
    % Use uint64 for the mask to handle the addition before wrapping
    ACC_MASK = uint64(2^ACC_WIDTH - 1);
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            
            % --- 1. Bit-True Reconstruction ---
            % SV: saw_out <= {~phase_acc[ACC_WIDTH-1], phase_acc[ACC_WIDTH-2 -: OUT_WIDTH-1]};
            
            % Extract and Flip MSB
            msb = bitget(phase_acc, ACC_WIDTH);
            flipped_msb = uint32(1 - msb); % 0->1, 1->0
            
            % Extract remaining bits [ACC_WIDTH-2 -: OUT_WIDTH-1]
            % This aligns the bits based on the difference between widths
            shift_val = ACC_WIDTH - OUT_WIDTH;
            lower_bits_mask = uint32(2^(OUT_WIDTH - 1) - 1);
            remaining_bits = bitand(bitshift(phase_acc, -shift_val), lower_bits_mask);
            
            % Reconstruct the bit vector by shifting the flipped MSB into position
            combined = bitshift(flipped_msb, OUT_WIDTH - 1) + remaining_bits;
            
            % Use typecast to interpret the bit pattern as a signed integer
            % This is the "magic" that prevents the +1 mismatch
            out(n) = typecast(combined, 'int32');
            
            % --- 2. Sequential Phase Update ---
            next_phase = uint64(phase_acc) + uint64(tuning_word);
            phase_acc = uint32(bitand(next_phase, ACC_MASK));
        else
            % Reset behavior
            out(n) = int32(0); 
        end
    end
end