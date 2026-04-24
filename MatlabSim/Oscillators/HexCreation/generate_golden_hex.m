function generate_golden_hex(osc_func, file_path, tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH)

    %% 1. Ensure output directory exists
    [folder, ~, ~] = fileparts(file_path);
    if ~isempty(folder) && ~exist(folder, 'dir')
        mkdir(folder);
        fprintf('Created missing directory: %s\n', folder);
    end

    %% 2. Generate oscillator data (robust dispatch)
    try
        % Try full signature (most oscillators)
        out_data = osc_func(total_samples, 1, total_samples, tuning_word, ACC_WIDTH, OUT_WIDTH);
    catch
        % Fallback for noise-style generators
        out_data = osc_func(total_samples, 1, total_samples, ACC_WIDTH, OUT_WIDTH);
    end

    % Force column + int64 for safety
    out_data = int64(out_data(:));

    %% 3. Open file
    fid = fopen(file_path, 'w');
    if fid == -1
        error('Could not open file. Check permissions for: %s', file_path);
    end

    %% 4. Hex formatting setup
    hex_chars = ceil(OUT_WIDTH / 4);
    format_spec = ['%0' num2str(hex_chars) 'x\n'];

    % Mask for OUT_WIDTH bits (prevents overflow issues)
    mask = bitshift(int64(1), OUT_WIDTH) - 1;

    %% 5. Write data (true 2's complement behavior)
    for i = 1:length(out_data)
        val = out_data(i);

        % Apply hardware-style wrapping
        wrapped_val = bitand(val, mask);

        % Convert to unsigned for printing
        unsigned_val = uint64(wrapped_val);

        fprintf(fid, format_spec, unsigned_val);
    end

    fclose(fid);

    fprintf('Success! Golden file written to: %s\n', file_path);
end