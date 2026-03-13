function out = model_noise(total_samples, start_step, stop_step, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate output array
    out = zeros(1, total_samples, 'uint32');
    
    % 1. Initial Seed
    % This MUST be non-zero. Let's match your SV seed.
    lfsr_reg = uint32(hex2dec('ACE1')); 
    
    % XOR Mask for a 32-bit maximal period Galois LFSR
    % Polynomial Taps: 32, 22, 2, 1 
    poly_mask = uint32(hex2dec('80000007'));
    
    % Mask for the 24-bit output
    OUT_MASK = uint32(2^OUT_WIDTH - 1);

    for n = 1:total_samples
        % The 'enable' logic
        if (n >= start_step) && (n <= stop_step)
            
            % 2. Extract Output (Truncation)
            % Slice the top OUT_WIDTH bits (e.g., bits 31 down to 8)
            out(n) = bitand(bitshift(lfsr_reg, -(ACC_WIDTH - OUT_WIDTH)), OUT_MASK);
            
            % 3. Galois LFSR Logic
            % If the LSB is 1, shift right and XOR with the polynomial
            if bitget(lfsr_reg, 1) == 1
                lfsr_reg = bitxor(bitshift(lfsr_reg, -1), poly_mask);
            else
                % If LSB is 0, just shift right
                lfsr_reg = bitshift(lfsr_reg, -1);
            end
            
        else
            % Output is 0 when disabled
            out(n) = uint32(0);
            % Note: In hardware, the LFSR usually keeps its state when disabled
            % so it doesn't repeat the same sequence every time you "press a key."
        end
    end
end

