function out = apply_envelope(waveform, envelope, start_step, stop_step, WAVE_WIDTH, ENV_WIDTH, OUT_WIDTH)
    % APPLY_ENVELOPE Hardware-accurate envelope application (Signed)
    % waveform:   Input audio array (SIGNED integer values)
    % envelope:   Normalized envelope array (0.0 to 1.0)
    % start_step: Sample index where the envelope begins
    % stop_step:  Sample index where the envelope ends
    % WAVE_WIDTH: Bit width of the incoming waveform
    % ENV_WIDTH:  Bit width to quantize the envelope multiplier
    % OUT_WIDTH:  Bit width of the final truncated output
    
    total_samples = length(waveform);
    % Initialize as signed int32
    out = zeros(1, total_samples, 'int32');
    
    % Convert the floating-point envelope into an integer fractional multiplier.
    % We cast to int64 right away so the multiplication step has matching types.
    env_quantized = int64(envelope * (2^ENV_WIDTH - 1));
    
    % Shift right by the fractional width of the envelope
    shift_val = -int32(ENV_WIDTH); 
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            env_idx = n - start_step + 1;
            
            % 1. Hardware Multiplier (Signed)
            % Cast the signed waveform to int64 to prevent overflow during multiplication.
            % (Signed 24-bit) * (Positive 24-bit) = (Signed 48-bit result)
            mult_result = int64(waveform(n)) * env_quantized(env_idx);
            
            % 2. Arithmetic Shift and Truncate
            % bitshift() on a signed integer performs an arithmetic shift right,
            % carrying the sign bit down through the upper bits.
            shifted_result = bitshift(mult_result, shift_val);
            
            % Because we are multiplying by a fraction (envelope <= 1.0), 
            % the result is guaranteed to fit back into the original bit width, 
            % so we can safely cast directly to int32 without needing an explicit bitmask.
            out(n) = int32(shifted_result);
            
        else
            % Explicit zero (silence) for samples outside the gate window
            out(n) = int32(0);
        end
    end
end