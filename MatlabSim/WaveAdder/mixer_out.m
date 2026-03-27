function synth_out = mixer_out(fs, total_len, freq_hz, ACC_WIDTH, OUT_WIDTH, mix_coeffs)
    % RUN_SYNTH_CORE Generates and mixes waveforms based on hardware params
    % fs:         Sampling frequency (e.g., 48000)
    % total_len:  Number of samples to generate
    % freq_hz:    Target frequency of the oscillators (e.g., 440)
    % ACC_WIDTH:  Phase accumulator bit width
    % OUT_WIDTH:  Output bit width
    % ADDR_WIDTH: Sine LUT address width
    % mix_coeffs: Struct or vector containing [sq, tri, saw, sin, noi] weights
    
    % 1. Calculate Tuning Word (M)
    % M = (f_out * 2^N) / f_s
    M = round((freq_hz * 2^ACC_WIDTH) / fs);
    
    % 2. Generate Waveforms
    % Using your model_ functions (assuming they are in the path)
    w_sq  = model_square(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
    w_tri = model_triangle(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
    w_saw = model_saw(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
    w_sin = model_sine(total_len, 1, total_len, M, ACC_WIDTH, OUT_WIDTH);
    w_noi = model_noise(total_len, 1, total_len, ACC_WIDTH, OUT_WIDTH);
    
    % 3. Extract Mix Coefficients
    c_sq  = mix_coeffs(1);
    c_tri = mix_coeffs(2);
    c_saw = mix_coeffs(3);
    c_sin = mix_coeffs(4);
    c_noi = mix_coeffs(5);
    
    % 4. Hardware-Style Mixing
    % This calls your wave_mixer function
    synth_out = wave_mixer(w_sq, w_tri, w_saw, w_sin, w_noi, ...
                           c_sq, c_tri, c_saw, c_sin, c_noi, OUT_WIDTH);
end