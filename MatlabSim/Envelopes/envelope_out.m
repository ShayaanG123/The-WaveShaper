function final_out = envelope_out(fs, duration, f_target, widths, adsr_params, mix_coeffs, b_coeffs, a_coeffs)
    % PROCESS_SYNTH_PIPELINE: Oscillators -> Mixer -> Filter -> Envelope
    % widths: [ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, ENV_WIDTH]
    % b_coeffs: Feedforward [b0, b1, b2]
    % a_coeffs: Feedback [a1, a2]
    
    total_samples = round(duration * fs);
    
    % 1. Unpack Widths
    % We pass the first three to the filter/mixer stage
    ENV_WIDTH  = widths(4);
    OUT_WIDTH  = widths(2);
    
    % 2. Generate the Normalized Envelope
    env_array = generate_adsr(adsr_params.A, adsr_params.D, ...
                              adsr_params.S, adsr_params.R, ...
                              adsr_params.gate_time, fs);
    
    % Calculate exact step boundaries
    on_step   = round(adsr_params.start_delay * fs) + 1;
    stop_step = on_step + length(env_array) - 1;
    
    % 3. Generate, Mix, and Filter
    % Replacing mixer_out with filter_out. 
    % filter_out internally calls mixer_out and applies the IIR filter.
    disp('Generating, Mixing, and Filtering Oscillators...');
    filtered_output = filter_out(fs, total_samples, f_target, ...
                                 widths(1:3), mix_coeffs, ...
                                 b_coeffs, a_coeffs);
    
    % 4. Apply Hardware-Accurate Envelope
    % Now applying the envelope to the FILTERED signal.
    disp('Applying hardware envelope to filtered signal...');
    final_out = apply_envelope(filtered_output, env_array, on_step, stop_step, ...
                               OUT_WIDTH, ENV_WIDTH, OUT_WIDTH);
end