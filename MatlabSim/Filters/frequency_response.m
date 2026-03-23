function [h_mag, f_axis] =frequency_response(b, a_coeffs, fs)
    % PLOT_FREQUENCY_RESPONSE Manually computes H(z) without Signal Toolbox
    % b: Feedforward coeffs [b0, b1, b2]
    % a_coeffs: Feedback coeffs [a1, a2]
    % fs: Sample rate
    
    % 1. Create a full 'a' vector (MATLAB convention includes a0 = 1)
    a = [1, a_coeffs(1), a_coeffs(2)];
    
    % 2. Setup frequency axis (0 to Nyquist)
    num_points = 1024;
    f_axis = linspace(0, fs/2, num_points);
    w = 2 * pi * f_axis / fs; % Normalized frequency in radians
    
    % 3. Evaluate the Transfer Function H(e^jw)
    % z = e^(jw)
    z = exp(1j * w);
    
    % Numerator: b0 + b1*z^-1 + b2*z^-2
    num = b(1) + b(2)*z.^-1 + b(3)*z.^-2;
    
    % Denominator: 1 + a1*z^-1 + a2*z^-2
    den = a(1) + a(2)*z.^-1 + a(3)*z.^-2;
    
    h_complex = num ./ den;
    h_mag = abs(h_complex);
    h_db = 20 * log10(h_mag);
    
    % 4. Visualization (Dark Mode)
    figure('Color', 'k', 'Name', 'Filter Frequency Response');
    semilogx(f_axis, h_db, 'LineWidth', 2, 'Color', [1 0.8 0]); % Gold color
    
    ax = gca;
    ax.Color = 'k'; ax.XColor = 'w'; ax.YColor = 'w';
    ax.GridColor = [0.4 0.4 0.4]; ax.GridAlpha = 0.5;
    grid on;
    
    title('Filter Magnitude Response (Digital Biquad)', 'Color', 'w');
    xlabel('Frequency (Hz)', 'Color', 'w');
    ylabel('Magnitude (dB)', 'Color', 'w');
    
    % Set limits
    xlim([20, fs/2]);
    ylim([-60, 10]); % Show 60dB of rejection
    
    % Mark the -3dB point (approximate cutoff)
    hold on;
    line([20 fs/2], [-3 -3], 'Color', [1 0 0], 'LineStyle', '--');
    text(25, -6, '-3dB Cutoff Line', 'Color', [1 0 0]);
end