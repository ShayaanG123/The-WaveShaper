function final_out = effect_out(fs, duration, f_target, widths, adsr_params, mix_coeffs, b_coeffs, a_coeffs, effect_chain)
    % EFFECT_OUT Complete Synth Pipeline: Osc -> Env -> Filter -> Effects
    % effect_chain: A cell array of function handles to apply sequentially
    
    OUT_WIDTH = widths(2);
    
    % 1. Run the base pipeline (Osc -> Mixer -> ADSR -> Filter)
    % Based on your provided filter_out, this returns a SIGNED int32 array
    signal = filter_out(fs, duration, f_target, widths, adsr_params, mix_coeffs, b_coeffs, a_coeffs);
    
    % 2. Process the Effects Chain
    % We loop through the cell array and feed the output of the previous 
    % effect directly into the input of the next.
    if ~isempty(effect_chain)
        disp(['Processing ', num2str(length(effect_chain)), ' effect stages...']);
        for i = 1:length(effect_chain)
            % Extract the function handle from the cell
            current_effect = effect_chain{i};
            
            % Apply it to the signal
            signal = current_effect(signal);
        end
    else
        disp('No effects in chain. Bypassing effects module.');
    end
    
    % 3. Final Hardware Conversion (Signed to Unsigned)
    % Convert the final processed signed signal back to unsigned for 
    % your standard visualization or unsigned DAC output.
    midpoint = 2^(OUT_WIDTH - 1);
    final_out = uint32(double(signal) + midpoint);
    
end