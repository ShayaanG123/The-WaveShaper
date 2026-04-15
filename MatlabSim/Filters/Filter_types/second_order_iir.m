function out = second_order_iir(waveform, b_coeffs, a_coeffs, WAVE_WIDTH, COEFF_FRAC_WIDTH, OUT_WIDTH)
    % SECOND_ORDER_IIR Hardware-accurate biquad filter (Signed Two's Complement)
    % waveform:         Input audio array (signed integer values)
    % b_coeffs:         Feedforward coefficients [b0, b1, b2] (floats to be quantized)
    % a_coeffs:         Feedback coefficients [a1, a2] (floats to be quantized)
    % WAVE_WIDTH:       Bit width of the incoming waveform
    % COEFF_FRAC_WIDTH: Number of fractional bits in the coefficients (e.g., 14 for Q2.14)
    % OUT_WIDTH:        Bit width of the final output (and state registers)
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32'); 
    
    % 1. Quantize coefficients to signed integers (Q-format mapping)
    % Unlike the unsigned envelope (which maps 0-1 to max uint), coefficients 
    % are multiplied by 2^FRAC_WIDTH to create a fixed-point integer.
    b_quant = int64(round(b_coeffs .* (2^COEFF_FRAC_WIDTH)));
    a_quant = int64(round(a_coeffs .* (2^COEFF_FRAC_WIDTH)));
    
    % Hardware-style masks and shifts
    % Use int64 for the accumulator to prevent overflow during MAC operations
    OUT_MASK  = int64(2^OUT_WIDTH - 1); 
    shift_val = -int32(COEFF_FRAC_WIDTH); % Shift right to remove fractional growth
    
    % Hardware State Registers (Delay lines z^-1, z^-2)
    x_z1 = int64(0);
    x_z2 = int64(0);
    y_z1 = int64(0);
    y_z2 = int64(0);
    
    for n = 1:total_samples
        % Cast incoming signed sample to int64 for wide accumulator math
        x_n = int64(waveform(n));
        
        % 1. Hardware Multipliers and Accumulator (MAC)
        % Multiply signed inputs/states by signed coefficients
        % Note: We subtract the 'a' coefficients per the difference equation
        accum = (x_n  * b_quant(1)) + ...
                (x_z1 * b_quant(2)) + ...
                (x_z2 * b_quant(3)) - ...
                (y_z1 * a_quant(1)) - ...
                (y_z2 * a_quant(2));
                
        % 2. Shift down to remove the fractional component
        % In MATLAB, bitshift on signed integers performs an Arithmetic Shift Right,
        % which perfectly matches SystemVerilog's '>>>' operator.
        accum_shifted = bitshift(accum, shift_val);
        
        % 3. Slice and Mask (Bit-true Truncation & Sign Extension)
        % Extract the lower OUT_WIDTH bits
        val_masked = bitand(accum_shifted, OUT_MASK);
        
        % Because this is signed hardware, if the MSB of our OUT_WIDTH slice is 1,
        % we must sign-extend it in MATLAB so it behaves properly as a negative number.
        sign_bit = bitshift(int64(1), OUT_WIDTH - 1);
        if bitand(val_masked, sign_bit)
            % Pad the upper bits with 1s to match the container width
            pad_mask = bitcmp(OUT_MASK, 'int64');
            y_n_final = bitor(val_masked, pad_mask);
        else
            y_n_final = val_masked;
        end
        
        % Assign to output
        out(n) = int32(y_n_final);
        
        % 4. Update State Registers
        % It is CRUCIAL that y_z1 stores the truncated/quantized output, 
        % not the high-precision accumulator, to perfectly match hardware feedback.
        x_z2 = x_z1;
        x_z1 = x_n;
        y_z2 = y_z1;
        y_z1 = y_n_final; 
    end
end