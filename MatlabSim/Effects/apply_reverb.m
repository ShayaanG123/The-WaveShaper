function out = apply_reverb(waveform, AUDIO_WIDTH, ADDR_WIDTH)
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32'); 
    
    % Constants matching RTL
    MAX_VAL = 2^(AUDIO_WIDTH-1) - 1;
    MIN_VAL = -2^(AUDIO_WIDTH-1);
    RAM_SIZE = 2^ADDR_WIDTH;
    DELAY_SAMPLES = 811; % Prime number delay matching RTL
    
    % Initialize memory and pointers
    delay_line = zeros(1, RAM_SIZE, 'int32');
    wr_ptr = 0; 
    
    % Latency registers to perfectly match RTL pipeline
    x_n_reg = int32(0);
    wet_val_reg = int32(0);

    for n = 1:total_samples
        % 1. Attenuate the feedback (Arithmetic Shift Right by 1)
        % This perfectly matches the RTL: {wet_signal[31], wet_signal[31:1]}
        feedback_attenuated = bitshift(wet_val_reg, -1);
        
        % 2. Output previous calculation
        mixed_val = double(x_n_reg) + double(feedback_attenuated);
        
        % Apply Saturation
        if mixed_val > MAX_VAL
            out(n) = int32(MAX_VAL);
        elseif mixed_val < MIN_VAL
            out(n) = int32(MIN_VAL);
        else
            out(n) = int32(mixed_val);
        end
        
        % 3. Update state for next cycle
        x_n = int32(waveform(n));
        
        % Pointer arithmetic
        rd_ptr = mod(wr_ptr - DELAY_SAMPLES, RAM_SIZE);
        
        % Capture RAM read and dry signal for next cycle
        wet_val_reg = delay_line(rd_ptr + 1); 
        x_n_reg = x_n;
        
        % THE REVERB WRITE: Write the SATURATED MIX back into the delay line.
        % This creates the infinite decaying tail characteristic of reverb.
        delay_line(wr_ptr + 1) = out(n);
        
        % Increment write pointer
        wr_ptr = mod(wr_ptr + 1, RAM_SIZE);
    end
end