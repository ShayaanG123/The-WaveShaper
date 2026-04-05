function generate_golden_hex(osc_func, file_path, tuning_word, total_samples, ACC_WIDTH, OUT_WIDTH)
    % 1. Safety check: Create the directory if it does not exist
    [folder, ~, ~] = fileparts(file_path);
    if ~isempty(folder) && ~exist(folder, 'dir')
        mkdir(folder);
        fprintf('Created missing directory: %s\n', folder);
    end

    num_args = nargin(osc_func);
    if num_args == 5
        % Case for osc_noise(total_samples, start, stop, ACC_WIDTH, OUT_WIDTH)
        out_data = osc_func(total_samples, 1, total_samples, ACC_WIDTH, OUT_WIDTH);
    elseif num_args == 6
        % Case for osc_square/saw/sine(total_samples, start, stop, tuning_word, ACC_WIDTH, OUT_WIDTH)
        out_data = osc_func(total_samples, 1, total_samples, tuning_word, ACC_WIDTH, OUT_WIDTH);
    else
        error('Unexpected number of arguments (%d) for function: %s', num_args, func2str(osc_func));
    end

    % 3. Data Export
    fid = fopen(file_path, 'w');
    if fid == -1
        error('Could not open file. Check permissions for: %s', file_path);
    end

    % Calculate hex padding based on bit width (e.g., 24-bit = 6 hex chars)
    hex_chars = ceil(OUT_WIDTH / 4);
    format_spec = ['%0' num2str(hex_chars) 'x\n'];

    for i = 1:length(out_data)
        fprintf(fid, format_spec, out_data(i));
    end

    fclose(fid);
    fprintf('Success! Golden file written to: %s\n', file_path);
end