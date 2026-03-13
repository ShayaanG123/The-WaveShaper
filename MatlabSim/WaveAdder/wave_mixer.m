function mixed_out = wave_mixer(w1, w2, w3, w4, w5, c1, c2, c3, c4, c5, OUT_WIDTH)
    % 1. Enforce size constraint
    % isequal checks if all dimensions of the provided arrays match perfectly
    if ~isequal(size(w1), size(w2), size(w3), size(w4), size(w5))
        error('Dimension Mismatch: All 5 input oscillator vectors must be the exact same size.');
    end

    if (c1 + c2 + c3 + c4 + c5 > 1)
        error("Coefficient greater than 1");
    end
    
    % 2. Convert to double for precise fractional math
    % If we multiplied fractional coefficients directly against uint32, 
    % MATLAB would aggressively truncate/round at each step, losing quality.
    mix_double = c1 * double(w1) + ...
                 c2 * double(w2) + ...
                 c3 * double(w3) + ...
                 c4 * double(w4) + ...
                 c5 * double(w5);

    mix_int = uint32(round(mix_double));
                 
    % 3. Cast back to uint32 for our bit-true hardware emulation
    OUT_MASK = uint32(2^OUT_WIDTH - 1);
    mixed_out = bitand(mix_int, OUT_MASK);
end