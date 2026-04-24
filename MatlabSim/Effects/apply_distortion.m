function out = apply_distortion(waveform, gain, OUT_WIDTH)
    % APPLY_DISTORTION Hardware-compliant Hard Clipping with 1-sample Latency
    % waveform:  Input audio array (signed int32)
    % gain:      Integer gain multiplier (signed int32)
    % OUT_WIDTH: Bit-width of the audio path (e.g., 32)
    
    total_samples = length(waveform);
    % Initialize with zeros to match the RTL reset state
    out = zeros(1, total_samples, 'int32');
    
    % Define Boundaries using power operator for accuracy
    POS_MAX = int64(2^(OUT_WIDTH - 1)) - int64(1);
    NEG_MAX = -int64(2^(OUT_WIDTH - 1));
    
    % Note: We loop from 1 to total_samples-1 because the output 
    % at index (n+1) depends on the input at index (n).
    for n = 1:(total_samples - 1)
        % --- 2. Apply Input Gain (PROD_WIDTH) ---
        gain_prod = int64(waveform(n)) * int64(gain);
        
        % --- 3. Saturation (Hard Clipping) ---
        if gain_prod > POS_MAX
            x_clipped = POS_MAX;
        elseif gain_prod < NEG_MAX
            x_clipped = NEG_MAX;
        else
            x_clipped = gain_prod;
        end
        
        % --- 4. Store in the NEXT sample slot (Latency = 1) ---
        % In SV: signal_out <= signal_out_next (takes one clock cycle)
        out(n + 1) = int32(x_clipped);
    end
end