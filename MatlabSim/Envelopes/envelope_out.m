function final_out = envelope_out(fs, duration, f_target, widths, adsr_params, mix_coeffs)
    % PROCESS_SYNTH_PIPELINE Full Hardware-to-Audio Chain
    % widths: [ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, ENV_WIDTH]
    % adsr_params: struct with fields .A, .D, .S, .R, .gate_time, .start_delay
    
    total_samples = round(duration * fs);
    
    % 1. Unpack Widths
    ACC_WIDTH  = widths(1);
    OUT_WIDTH  = widths(2);
    ADDR_WIDTH = widths(3);
    ENV_WIDTH  = widths(4);
    
    % 2. Generate the Normalized Envelope
    % Logic: (A, D, S, R, gate_time, fs)
    env_array = generate_adsr(adsr_params.A, adsr_params.D, ...
                              adsr_params.S, adsr_params.R, ...
                              adsr_params.gate_time, fs);
    
    % Calculate exact step boundaries
    on_step   = round(adsr_params.start_delay * fs) + 1;
    stop_step = on_step + length(env_array) - 1;
    
    % 3. Generate and Mix Waveforms
    % We call the run_synth_core function we previously defined
    disp('Generating and Mixing Oscillators...');
    mixer_output = mixer_out(fs, total_samples, f_target, ...
                               ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, ...
                               mix_coeffs);
    
    % 4. Apply Hardware-Accurate Envelope
    disp('Applying hardware envelope...');
    % Note: mixer_out is passed as the waveform input
    final_out = apply_envelope(mixer_output, env_array, on_step, stop_step, ...
                               OUT_WIDTH, ENV_WIDTH, OUT_WIDTH);
end