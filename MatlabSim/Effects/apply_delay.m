function out = apply_delay(waveform, fs, delay_ms, feedback, mix_wet)
    % APPLY_DELAY Hardware-style Echo / Delay Line
    % waveform: Input audio array (signed int32)
    % fs:       Sample rate (e.g., 48000)
    % delay_ms: Time between echoes in milliseconds
    % feedback: How much of the echo feeds back into the input (0.0 to 0.95)
    % mix_wet:  Dry/Wet balance (0.0 to 1.0)
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32');
    
    % 1. Calculate Buffer Size
    % Convert milliseconds to number of samples
    delay_samps = round((delay_ms / 1000) * fs);
    
    % Hardware BRAM Allocation
    % In an FPGA, this size dictates how many BRAM tiles you consume.
    delay_line = zeros(1, delay_samps, 'int32');
    
    % Pointers
    write_ptr = 1;
    % For a fixed delay, the read pointer is exactly 1 sample ahead of the 
    % write pointer in the circular buffer (representing the oldest data).
    read_ptr = 2; 
    
    for n = 1:total_samples
        % Read current dry sample
        x_n = double(waveform(n));
        
        % --- READ PHASE ---
        % Grab the delayed sample from RAM
        delayed_val = double(delay_line(read_ptr));
        
        % --- WRITE PHASE (with Feedback) ---
        % To create multiple echoes, we mix the incoming dry signal 
        % with a scaled-down version of the delayed signal.
        write_val = x_n + (delayed_val * feedback);
        
        % Store into BRAM
        delay_line(write_ptr) = int32(write_val);
        
        % --- MIX WET AND DRY ---
        mixed_val = ((1.0 - mix_wet) * x_n) + (mix_wet * delayed_val);
        out(n) = int32(mixed_val);
        
        % --- ADVANCE POINTERS ---
        write_ptr = write_ptr + 1;
        if write_ptr > delay_samps
            write_ptr = 1;
        end
        
        read_ptr = read_ptr + 1;
        if read_ptr > delay_samps
            read_ptr = 1;
        end
    end
end