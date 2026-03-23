function out = apply_reverb(waveform, fs, room_size, mix_wet)
    % APPLY_REVERB Algorithmic Reverb (Schroeder topology)
    % waveform:  Input audio array (signed int32)
    % fs:        Sample rate (e.g., 48000)
    % room_size: Feedback multiplier for the tail (0.0 to 0.95, >0.98 will blow up!)
    % mix_wet:   Dry/Wet mix (0.0 to 1.0)
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32');
    
    % --- 1. Hardware BRAM Allocations ---
    % Delay lengths MUST be mutually prime to avoid metallic ringing frequencies stacking up.
    % These specific sample lengths are tuned for 48kHz.
    comb_sizes = [1557, 1617, 1491, 1422]; 
    apf_sizes  = [225, 341];               
    
    % Pre-allocate Circular Buffers (Represents 6 individual BRAM blocks)
    comb_bufs = {zeros(1, comb_sizes(1)), zeros(1, comb_sizes(2)), ...
                 zeros(1, comb_sizes(3)), zeros(1, comb_sizes(4))};
    apf_bufs  = {zeros(1, apf_sizes(1)),  zeros(1, apf_sizes(2))};
    
    % Pointers for the circular buffers
    comb_ptrs = [1, 1, 1, 1];
    apf_ptrs  = [1, 1];
    
    % All-Pass Feedforward/Feedback coefficient (usually fixed in hardware)
    apf_g = 0.5; 
    
    % Process sample-by-sample (Hardware Clock Cycle Emulation)
    for n = 1:total_samples
        x_n = double(waveform(n));
        
        % --- STAGE 1: Parallel Comb Filters ---
        comb_sum = 0;
        for c = 1:4
            % Read from BRAM
            comb_read = comb_bufs{c}(comb_ptrs(c));
            
            % Accumulate the outputs of all 4 combs
            comb_sum = comb_sum + comb_read;
            
            % Calculate feedback and write back to BRAM
            % Hardware: write_val = x_n + (comb_read * room_size)
            write_val = x_n + (comb_read * room_size);
            comb_bufs{c}(comb_ptrs(c)) = write_val;
            
            % Advance Pointer
            comb_ptrs(c) = comb_ptrs(c) + 1;
            if comb_ptrs(c) > comb_sizes(c)
                comb_ptrs(c) = 1;
            end
        end
        
        % Scale down the sum to prevent bit-overflow before the next stage
        comb_sum = comb_sum * 0.25; 
        
        % --- STAGE 2: Series All-Pass Filters ---
        % APF 1
        apf1_read = apf_bufs{1}(apf_ptrs(1));
        apf1_out  = apf1_read - (comb_sum * apf_g);
        apf_bufs{1}(apf_ptrs(1)) = comb_sum + (apf1_read * apf_g);
        
        apf_ptrs(1) = apf_ptrs(1) + 1;
        if apf_ptrs(1) > apf_sizes(1); apf_ptrs(1) = 1; end
        
        % APF 2 (Takes the output of APF 1 as its input)
        apf2_read = apf_bufs{2}(apf_ptrs(2));
        apf2_out  = apf2_read - (apf1_out * apf_g);
        apf_bufs{2}(apf_ptrs(2)) = apf1_out + (apf2_read * apf_g);
        
        apf_ptrs(2) = apf_ptrs(2) + 1;
        if apf_ptrs(2) > apf_sizes(2); apf_ptrs(2) = 1; end
        
        % --- STAGE 3: Dry/Wet Mix ---
        wet_signal = apf2_out;
        mixed_val = ((1.0 - mix_wet) * x_n) + (mix_wet * wet_signal);
        
        out(n) = int32(mixed_val);
    end
end