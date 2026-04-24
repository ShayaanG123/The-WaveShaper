function out = apply_delay(waveform, AUDIO_WIDTH, ADDR_WIDTH)
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32'); 
    MAX_VAL = 2^(AUDIO_WIDTH-1) - 1;
    MIN_VAL = -2^(AUDIO_WIDTH-1);
    RAM_SIZE = 2^ADDR_WIDTH;
    FIXED_DELAY = 512;
    
    delay_line = zeros(1, RAM_SIZE, 'int32');
    wr_ptr = 0; 
    
    % Latency registers to hold the "previous" state
    x_n_reg = int32(0);
    wet_val_reg = int32(0);

    for n = 1:total_samples
        % 1. Output the result from the PREVIOUS cycle's calculation
        % This effectively aligns MATLAB with the hardware's 1-cycle lag
        mixed_val = double(x_n_reg) + double(wet_val_reg);
        
        if mixed_val > MAX_VAL
            out(n) = int32(MAX_VAL);
        elseif mixed_val < MIN_VAL
            out(n) = int32(MIN_VAL);
        else
            out(n) = int32(mixed_val);
        end
        
        % 2. Calculate values for the NEXT cycle (Current RTL state)
        x_n = int32(waveform(n));
        rd_ptr = mod(wr_ptr - FIXED_DELAY, RAM_SIZE);
        
        % Capture the current values to be used in the next iteration's output
        wet_val_reg = delay_line(rd_ptr + 1); 
        x_n_reg = x_n;
        
        % Update RAM and pointer
        delay_line(wr_ptr + 1) = x_n;
        wr_ptr = mod(wr_ptr + 1, RAM_SIZE);
    end
end