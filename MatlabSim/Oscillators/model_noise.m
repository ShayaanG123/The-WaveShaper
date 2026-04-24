function out = model_noise(total_samples, start_step, stop_step, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate as signed int32 to match your system's signed 2's complement audio
    out = zeros(1, total_samples, 'int32');
    
    % 1. Initial Seed (Must match SV)
    lfsr_reg = uint32(hex2dec('ACE1')); 
    
    % XOR Mask for a 32-bit maximal period Galois LFSR
    % Polynomial Taps: 32, 22, 2, 1 
    poly_mask = uint32(hex2dec('80000007'));
    
    % Output register for latency simulation (SV's always_ff behavior)
    noise_out_reg = int32(0);
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            
            % --- 2. Extract and Map to Signed (Matches SV Slicing) ---
            % SV: noise_out <= lfsr_reg[ACC_WIDTH-1 -: OUT_WIDTH];
            shift_val = -(ACC_WIDTH - OUT_WIDTH);
            raw_noise = bitshift(lfsr_reg, shift_val);
            
            % To keep this consistent with your other oscillators (Saw/Tri),
            % we convert this unipolar noise (0 to Max) into bipolar noise (-Max to +Max)
            % by flipping the MSB of the sliced output.
            msb = bitget(raw_noise, OUT_WIDTH);
            flipped_msb = ~msb & 1;
            
            lower_bits_mask = uint32(2^(OUT_WIDTH - 1) - 1);
            lower_bits = bitand(raw_noise, lower_bits_mask);
            
            % Reconstruct as 2's complement
            msb_weight = -int32(flipped_msb) * int32(2^(OUT_WIDTH - 1));
            noise_out_reg = msb_weight + int32(lower_bits);
            
            % --- 3. Galois LFSR Logic (State Update) ---
            if bitget(lfsr_reg, 1) == 1
                lfsr_reg = bitxor(bitshift(lfsr_reg, -1), poly_mask);
            else
                lfsr_reg = bitshift(lfsr_reg, -1);
            end
            
        else
            % Enable is low: SV logic keeps lfsr_reg state but we mute the output
            noise_out_reg = int32(0);
        end
        
        % Assign to output array (simulating the registered hardware output)
        out(n) = noise_out_reg;
    end
end