function out = model_triangle(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    out = zeros(1, total_samples, 'int32');
    phase_acc = uint64(0); 
    
    ACC_MASK = bitshift(uint64(1), ACC_WIDTH) - 1;
    TRI_MASK = bitshift(uint64(1), ACC_WIDTH - 1) - 1;
    offset = bitshift(uint64(1), OUT_WIDTH - 1);

    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            
            % --- 1. Update Phase FIRST (Mirrors RTL being one cycle ahead) ---
            % This ensures the very first sample in the enable window 
            % reflects the first addition of the tuning word.
            phase_acc = bitand(phase_acc + uint64(tuning_word), ACC_MASK);

            % --- 2. Calculate output based on NEW phase ---
            msb = bitget(phase_acc, ACC_WIDTH);
            lower_bits = bitand(phase_acc, TRI_MASK);
            
            if msb == 1
                raw_tri = bitxor(lower_bits, TRI_MASK);
            else
                raw_tri = lower_bits;
            end
            
            full_unsigned_tri = bitshift(raw_tri, 1);
            trunc_shift = ACC_WIDTH - OUT_WIDTH;
            truncated_tri = bitshift(full_unsigned_tri, -trunc_shift);
            
            out(n) = int32(double(truncated_tri) - double(offset));
            
        else
            % Optional: Clear phase_acc if out of window to mirror a synchronous reset
            out(n) = int32(0);
            phase_acc = uint64(0); 
        end
    end
end