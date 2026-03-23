function filtered_out = filter_out(fs, duration, f_target, widths, adsr_params, mix_coeffs, b_coeffs, a_coeffs)
    % FILTER_OUT Integrated Oscillator -> Mixer -> Envelope -> IIR Filter
    % b_coeffs: Feedforward coefficients [b0, b1, b2]
    % a_coeffs: Feedback coefficients [a1, a2]
    
    % 1. Run the previous stage (Oscillators + Envelope)
    % This returns an UNSIGNED signal (0 to 2^OUT_WIDTH - 1)
    envelope_signal = envelope_out(fs, duration, f_target, widths, adsr_params, mix_coeffs);
    
    OUT_WIDTH = widths(2);
    COEFF_FRAC_WIDTH = 14; % Typical for FPGA DSP (Q2.14 format)
    
    % 2. Centering (Unsigned to Signed Conversion)
    % Digital filters blow up if they have a massive DC offset. 
    % We subtract the midpoint (2^(OUT_WIDTH-1)) to center the wave at 0.
    midpoint = 2^(OUT_WIDTH - 1);
    signed_signal = int32(double(envelope_signal) - midpoint);
    
    % 3. Apply the Second Order IIR (Biquad)
    % Using the signed hardware-accurate function we wrote earlier
    disp('Applying Second Order IIR Filter...');
    filtered_out = second_order_iir(signed_signal, b_coeffs, a_coeffs, ...
                                       OUT_WIDTH, COEFF_FRAC_WIDTH, OUT_WIDTH);
                                   
end