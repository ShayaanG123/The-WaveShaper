function out = apply_redux(waveform, BIT_CRUSH, OUT_WIDTH)
    % APPLY_REDUX Hardware-compliant Bitcrusher with 1-sample Latency
    % waveform:  Input audio array (signed int32)
    % BIT_CRUSH: Number of LSBs to zero out (Matches SV parameter)
    % OUT_WIDTH: Bit-width of the audio path (e.g., 32)
    
    total_samples = length(waveform);
    % Initialize with zeros to match the RTL reset state
    out = zeros(1, total_samples, 'int32');
    
    % --- 1. Define the Mask ---
    full_mask = uint64(2^OUT_WIDTH - 1);
    crush_mask = uint32(bitand(bitshift(full_mask, BIT_CRUSH), full_mask));
    
    % --- 2. Process with Latency ---
    % Stop at total_samples - 1 to avoid indexing out of bounds on the output
    for n = 1:(total_samples - 1)
        % Convert to unsigned for bitwise operations
        u_signal = typecast(int32(waveform(n)), 'uint32');
        
        % Apply the hardware mask
        u_crushed = bitand(u_signal, crush_mask);
        
        % Store in the NEXT sample slot (Latency = 1)
        % Matches: signal_out <= signal_in & bit_crush_mask;
        out(n + 1) = typecast(u_crushed, 'int32');
    end
end