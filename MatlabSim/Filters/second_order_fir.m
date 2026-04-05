function out = second_order_fir(waveform, b_coeffs, COEFF_FRAC_WIDTH, OUT_WIDTH)
    % SECOND_ORDER_FIR Optimized 3-tap FIR filter (Signed Two's Complement)
    % b_coeffs: [b0, b1, b2]
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32'); 
    
    % 1. Fixed-point coefficient quantization
    b_quant = int64(round(b_coeffs .* (2^COEFF_FRAC_WIDTH)));
    
    % 2. Setup bit manipulation constants
    OUT_MASK  = int64(2^OUT_WIDTH - 1); 
    SIGN_BIT  = bitshift(int64(1), OUT_WIDTH - 1);
    PAD_MASK  = bitcmp(OUT_MASK, 'int64');
    shift_val = -int32(COEFF_FRAC_WIDTH);
    
    % 3. Input Delay Line (Registers)
    x_z1 = int64(0);
    x_z2 = int64(0);
    
    for n = 1:total_samples
        x_n = int64(waveform(n));
        
        % Multiply-Accumulate (MAC)
        accum = (x_n  * b_quant(1)) + ...
                (x_z1 * b_quant(2)) + ...
                (x_z2 * b_quant(3));
                
        % Arithmetic Shift Right (ASR) to return to original scale
        val_shifted = bitshift(accum, shift_val);
        
        % Truncation and Sign Extension (Manual 2's complement handling)
        y_n = bitand(val_shifted, OUT_MASK);
        if bitand(y_n, SIGN_BIT)
            y_n = bitor(y_n, PAD_MASK);
        end
        
        out(n) = int32(y_n);
        
        % Update registers
        x_z2 = x_z1;
        x_z1 = x_n;
    end
end