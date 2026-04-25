%% SV_vs_MATLAB_plot.m
% Cross-check SystemVerilog Filter Output vs MATLAB Golden Model
clear; clc; close all;

%% 1. Define Paths
sv_file     = 'Filters/SV_Verification/sv_lp_out.txt';
golden_file = 'Filters/SV_Verification/square_filter_golden.hex';

%% 2. Helper Function: Hex to Signed 32-bit
function data_out = load_hex_to_signed32(filepath)
    if ~isfile(filepath)
        error('File not found: %s', filepath);
    end
    
    fid = fopen(filepath, 'r');
    hex_strs = textscan(fid, '%s');
    fclose(fid);
    hex_strs = hex_strs{1};
    
    N = length(hex_strs);
    data_out = zeros(N, 1, 'int32');
    
    for i = 1:N
        % hex2dec converts to double. uint32 casts the bits safely.
        % typecast forces MATLAB to interpret those bits as a signed 2's complement integer.
        data_out(i) = typecast(uint32(hex2dec(hex_strs{i})), 'int32');
    end
end

%% 3. Load Both Files using the exact same logic
rtl_raw     = load_hex_to_signed32(sv_file);
golden_data = load_hex_to_signed32(golden_file);

%% 4. Align Data
min_len = min(length(rtl_raw), length(golden_data));
rtl_plot    = double(rtl_raw(1:min_len));
golden_plot = double(golden_data(1:min_len));

%% 5. Plot (Safe Rendering)
figure(1);
clf;

% ---- Overlay Plot ----
subplot(2,1,1);
plot(golden_plot, 'LineWidth', 3, 'Color', [0.7 0.7 0.7]); hold on;
plot(rtl_plot, '--', 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
title('Time Domain Overlay: MATLAB vs SV (Bit-True Hex Parsing)');
legend('MATLAB Golden', 'SV RTL');
ylabel('Amplitude');
xlabel('Sample Index');
grid on;

% ---- Zoomed Comparison ----
subplot(2,1,2);
zoom_start = 100;
zoom_end   = min(150, min_len);
plot(zoom_start:zoom_end, golden_plot(zoom_start:zoom_end), 'o-', 'Color', [0.7 0.7 0.7], 'MarkerSize', 8); hold on;
plot(zoom_start:zoom_end, rtl_plot(zoom_start:zoom_end), 'x--', 'Color', [0 0.447 0.741], 'LineWidth', 1.2);
title(sprintf('Zoomed Comparison (Samples %d-%d)', zoom_start, zoom_end));
ylabel('Amplitude');
xlabel('Sample Index');
grid on;

%% 6. Error Analysis
diff_vec = rtl_plot - golden_plot;
max_err = max(abs(diff_vec));

fprintf('--- Results ---\n');
if max_err == 0
    fprintf('STATUS: [MATCH] Bit-true agreement visually confirmed.\n');
else
    fprintf('STATUS: [MISMATCH] Max error = %d LSBs\n', max_err);
    first_idx = find(abs(diff_vec) > 0, 1);
    fprintf('First mismatch at index: %d\n', first_idx);
end