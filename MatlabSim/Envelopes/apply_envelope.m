function out = apply_envelope(waveform, envelope, start_step, stop_step, WAVE_WIDTH, ENV_WIDTH, OUT_WIDTH)
    % APPLY_ENVELOPE Hardware-accurate envelope application (Unsigned)
    % waveform:   Input audio array (unsigned integer values)
    % envelope:   Normalized envelope array (0.0 to 1.0)
    % start_step: Sample index where the envelope begins
    % stop_step:  Sample index where the envelope ends
    % WAVE_WIDTH: Bit width of the incoming waveform
    % ENV_WIDTH:  Bit width to quantize the envelope multiplier
    % OUT_WIDTH:  Bit width of the final truncated output
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'uint32');
    
    % Convert the floating-point envelope into an unsigned integer fractional multiplier
    env_quantized = uint32(envelope * (2^ENV_WIDTH - 1));
    
    % Hardware-style masks and shifts using your technique
    OUT_MASK = uint64(2^OUT_WIDTH - 1); 
    shift_val = -int32(ENV_WIDTH); % Shift right by the fractional width of the envelope
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            env_idx = n - start_step + 1;
            
            % 1. Hardware Multiplier
            % Multiply unsigned waveform by unsigned envelope
            % We cast to uint64 to hold the (WAVE_WIDTH + ENV_WIDTH) product
            mult_result = uint64(waveform(n)) * uint64(env_quantized(env_idx));
            
            % 2. Slice and Mask using your exact technique
            % Shift down to remove the fractional component and mask to OUT_WIDTH
            out(n) = uint32(bitand(bitshift(mult_result, shift_val), OUT_MASK));
            
        else
            % Explicit zero for samples outside the gate window
            out(n) = uint32(0);
        end
    end
end