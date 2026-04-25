%% --- Helper Function ---
function generate_mixer_hex(effect_func, file_path, OUT_WIDTH, input_signal, varargin)
    % 1. Ensure directory exists
    [folder, ~, ~] = fileparts(file_path);
    if ~isempty(folder) && ~exist(folder, 'dir'), mkdir(folder); end
    
    % 2. Apply the Effect
    try
        out_data = effect_func(input_signal, varargin{:});
    catch ME
        fprintf('Error in %s: %s\n', func2str(effect_func), ME.message);
        rethrow(ME);
    end
    
    out_data = int64(out_data(:));
    
    % 3. Open and Write File
    fid = fopen(file_path, 'w');
    if fid == -1, error('File error: %s', file_path); end
    
    hex_chars = ceil(OUT_WIDTH / 4);
    format_spec = ['%0' num2str(hex_chars) 'x\n'];
    mask = bitshift(int64(1), OUT_WIDTH) - 1;
    
    for i = 1:length(out_data)
        unsigned_val = uint64(bitand(out_data(i), mask));
        fprintf(fid, format_spec, unsigned_val);
    end
    
    fclose(fid);
    fprintf('Success! Golden file written: %s\n', file_path);
end