function filtered_out = filter_out(fs, total_len, f_target, widths, mix_coeffs, fc, Q, filter_type)
    % FILTER_OUT: Oscillator Mixer -> Chamberlin SVF (Bit-True Hardware Model)
    
    % 1. Extract Widths
    ACC_WIDTH  = widths(1);
    OUT_WIDTH  = widths(2);
    
    % 2. Run the Mixer Stage
    raw_mixed = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, mix_coeffs);
    
    % 3. Convert to Signed 2's Complement (Hardware Coherency)
    % FIX: Use isa() and handle the conversion to signed domain safely
    if isa(raw_mixed, 'uint32') || all(raw_mixed >= 0)
        % Center the unsigned signal around zero for the filter
        % Shift range from [0, 2^N-1] to [-2^(N-1), 2^(N-1)-1]
        midpoint = 2^(OUT_WIDTH - 1);
        signed_input = int32(double(raw_mixed) - midpoint);
    else
        signed_input = int32(raw_mixed);
    end
    
    % 4. Call the Hardware-Bit-True Chamberlin SVF
    fprintf('Applying Hardware-Coherent Chamber_SVF (%s)...\n', upper(filter_type));
    
    % This calls your specific [lp, bp, hp] function
    [lp_out, bp_out, hp_out] = Chamber_SVF(signed_input, fc, Q, fs, OUT_WIDTH);
    
    % 5. Select the requested output node
    switch lower(filter_type)
        case 'hp'
            filtered_out = hp_out;
        case 'bp'
            filtered_out = bp_out;
        case 'lp'
            filtered_out = lp_out;
        case 'notch'
            filtered_out = hp_out + lp_out;
        otherwise
            error('Invalid filter_type. Use ''lp'', ''bp'', ''hp'', or ''notch''.');
    end
end