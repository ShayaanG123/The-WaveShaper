function plot_waveform(t, data, OUT_WIDTH, plot_title)
    % PLOT_WAVEFORM Renders a hardware-accurate signal in Dark Mode
    % t:          Time vector (seconds)
    % data:       The waveform array (uint32/int32)
    % OUT_WIDTH:  Bit width of the signal (for Y-axis scaling)
    % plot_title: String for the subplot title
    % line_color: RGB triplet [R G B] or color character (e.g., [0 1 1])

    % 1. Calculate the hardware limit
    max_val = 2^OUT_WIDTH - 1;
    
    % 2. Create the Plot
    line_color = [0 1 1];
    plot(t, data, 'LineWidth', 1.2, 'Color', line_color);
    
    % 3. Apply Dark Mode Aesthetics
    ax = gca;
    ax.Color = 'k';             % Black plot background
    ax.XColor = 'w';            % White X-axis
    ax.YColor = 'w';            % White Y-axis
    ax.GridColor = [0.4 0.4 0.4]; % Subtle grey grid
    ax.GridAlpha = 0.4;
    grid on;
    
    % 4. Text and Labels
    title(plot_title, 'Color', 'w', 'FontSize', 12);
    ylabel('LSB Value', 'Color', 'w');
    
    % 5. Set Y-Limits with a 5% "Headroom" buffer
    % This makes it obvious if the signal is flatlining at the max value
    ylim([-0.05 * max_val, 1.05 * max_val]);
    
    % Optional: Add a subtle red line at the hardware clipping point
    line([t(1) t(end)], [max_val max_val], 'Color', [0.5 0 0], 'LineStyle', '--');
end