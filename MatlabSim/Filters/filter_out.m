function filtered_out = filter_out(fs, total_len, f_target, widths, mix_coeffs, fc, Q, filter_type)
    % FILTER_OUT: Oscillator Mixer -> Chamberlin SVF (Bit-True Hardware Model)
    
    % 1. Extract Widths
    ACC_WIDTH  = widths(1);
    OUT_WIDTH  = widths(2);
    GAIN_SH    = 2; % Hardware-accurate shift to prevent mixer overflow
    
    % 2. Run the Hardware-Accurate Mixer Stage
    % Calculate Tuning Word for DDS
    tuning_word = uint32(round((f_target * 2^ACC_WIDTH) / fs));
    
    % Generate the 4 primary hardware waveforms
    w_sq  = model_square(total_len, 1, total_len, tuning_word, ACC_WIDTH, OUT_WIDTH);
    w_tri = model_triangle(total_len, 1, total_len, tuning_word, ACC_WIDTH, OUT_WIDTH);
    w_saw = model_saw(total_len, 1, total_len, tuning_word, ACC_WIDTH, OUT_WIDTH);
    w_noi = model_noise(total_len, 1, total_len, ACC_WIDTH, OUT_WIDTH);
    w_zero = zeros(1, total_len, 'int32'); % Dummy 5th input
    
    % Call wave_mixer directly to include RTL startup artifacts and saturation
    raw_mixed = wave_mixer(w_sq, w_tri, w_saw, w_noi, w_zero, ...
                           mix_coeffs, OUT_WIDTH, GAIN_SH);
    
    % 3. Convert to Signed 2's Complement (Hardware Coherency)
    % Since your model_square and wave_mixer already output signed int32, 
    % we ensure the signal is in the correct format for the SVF logic.
    signed_input = int32(raw_mixed);
    
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