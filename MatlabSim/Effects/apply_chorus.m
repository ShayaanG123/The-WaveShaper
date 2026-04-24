function out = apply_chorus(waveform, lfo_tri, AUDIO_WIDTH, ADDR_WIDTH)
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32'); 
    MAX_VAL = 2^(AUDIO_WIDTH-1) - 1;
    MIN_VAL = -2^(AUDIO_WIDTH-1);
    RAM_SIZE = 2^ADDR_WIDTH;
    
    delay_line = zeros(1, RAM_SIZE, 'int32');
    wr_ptr = 0; 
    
    % Latency registers to perfectly match RTL pipeline
    x_n_reg = int32(0);
    wet_val_reg = int32(0);

    for n = 1:total_samples
        % 1. Output previous calculation
        mixed_val = double(x_n_reg) + double(wet_val_reg);
        
        if mixed_val > MAX_VAL
            out(n) = int32(MAX_VAL);
        elseif mixed_val < MIN_VAL
            out(n) = int32(MIN_VAL);
        else
            out(n) = int32(mixed_val);
        end
        
        % 2. Update state for next cycle
        x_n = int32(waveform(n));
        
        % BULLETPROOF VERILOG BIT-SLICE: lfo_tri[30:26]
        % Cast to uint32 to force a Logical Shift Right (LSR)
        lfo_val_uint = typecast(int32(lfo_tri(n)), 'uint32');
        lfo_offset = bitshift(lfo_val_uint, -26);
        lfo_offset_u = double(bitand(lfo_offset, 31)); 
        
        % Pointer arithmetic
        rd_ptr = mod(wr_ptr - (256 + lfo_offset_u), RAM_SIZE);
        
        % Register updates
        wet_val_reg = delay_line(rd_ptr + 1); 
        x_n_reg = x_n;
        
        delay_line(wr_ptr + 1) = x_n;
        wr_ptr = mod(wr_ptr + 1, RAM_SIZE);
    end
end