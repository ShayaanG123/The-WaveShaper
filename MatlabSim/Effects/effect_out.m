function signal = effect_out(fs, duration, f_target, widths, adsr_params, mix_coeffs, b_coeffs, a_coeffs, effect_chain)
    % EFFECT_OUT Complete Synth Pipeline: (Osc -> Mixer -> Filter -> Env) -> Effects Chain
    % effect_chain: A cell array of function handles (e.g., {@fx_chorus, @fx_reverb})
    
    % 1. Run the base synthesis pipeline
    % This handles oscillators, the IIR filter, and the ADSR amplitude shaping.
    % It returns a SIGNED signal centered at 0.
    disp('Starting Synthesis Engine (Osc + Filter + ADSR)...');
    signal = envelope_out(fs, duration, f_target, widths, adsr_params, ...
                          mix_coeffs, b_coeffs, a_coeffs);
    
    % 2. Process the Effects Chain
    % Each effect in the cell array is a function handle that takes 
    % the signal and returns a processed version of it.
    if ~isempty(effect_chain)
        fprintf('Processing %d effect stages...\n', length(effect_chain));
        for i = 1:length(effect_chain)
            % Extract the function handle from the cell
            current_effect = effect_chain{i};
            
            % Apply the effect (e.g., Delay, Reverb, Distortion)
            signal = current_effect(signal);
        end
    else
        disp('No effects in chain. Bypassing effects module.');
    end
    
    disp('Pipeline Processing Complete.');
end