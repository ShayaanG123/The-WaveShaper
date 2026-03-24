function filtered_out = filter_out(fs, total_len, f_target, widths, mix_coeffs, b_coeffs, a_coeffs)
    % FILTER_OUT: Oscillator Mixer -> IIR Filter
    % fs:         Sampling frequency
    % total_len:  Duration in samples
    % f_target:   Frequency in Hz
    % widths:     [ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH]
    % mix_coeffs: [sq, tri, saw, sin, noi]
    % b_coeffs:   Feedforward coefficients [b0, b1, b2]
    % a_coeffs:   Feedback coefficients [a1, a2]
    
    % 1. Run the Mixer Stage
    % Extract widths for clarity
    ACC_WIDTH  = widths(1);
    OUT_WIDTH  = widths(2);
    ADDR_WIDTH = widths(3);
    
    % This returns the raw mixed signal (Unsigned 0 to 2^OUT_WIDTH - 1)
    mixed_signal = mixer_out(fs, total_len, f_target, ACC_WIDTH, OUT_WIDTH, ADDR_WIDTH, mix_coeffs);
    
    % 2. Centering (Unsigned to Signed Conversion)
    % Digital filters require a signal centered at 0 to function correctly.
    COEFF_FRAC_WIDTH = 14; % Fixed-point precision for DSP coefficients
    midpoint = 2^(OUT_WIDTH - 1);
    signed_signal = int32(double(mixed_signal) - midpoint);
    
    % 3. Apply the Second Order IIR (Biquad)
    % Processes the raw oscillators before any ADSR envelope is applied
    disp('Applying Second Order IIR Filter to Mixer Output...');
    filtered_out = second_order_iir(signed_signal, b_coeffs, a_coeffs, ...
                                       OUT_WIDTH, COEFF_FRAC_WIDTH, OUT_WIDTH);
end