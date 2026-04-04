function out = apply_chorus(waveform, fs, base_delay_ms, depth_ms, lfo_rate_hz, mix_wet)
    % APPLY_CHORUS Hardware-style Chorus with Circular Buffer and Interpolation
    % waveform:      Input audio array (signed int32)
    % fs:            Sample rate (e.g., 48000)
    % base_delay_ms: The central delay time (typically 15-30ms)
    % depth_ms:      How much the LFO sweeps the delay (+/- ms)
    % lfo_rate_hz:   Speed of the sweep (typically 0.5 - 3 Hz)
    % mix_wet:       Fraction of the delayed signal to mix in (0.0 to 1.0)
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32'); 
    
    % 1. Convert Time to Samples
    base_delay_samps = (base_delay_ms / 1000) * fs;
    depth_samps      = (depth_ms / 1000) * fs;
    
    % 2. Allocate Circular Buffer (RAM)
    % Must be large enough to hold the maximum possible delay + padding
    max_delay_samps = ceil(base_delay_samps + depth_samps) + 5;
    delay_line = zeros(1, max_delay_samps, 'int32');
    write_ptr = 1;
    
    % LFO Setup (In hardware, this would be your phase accumulator + LUT)
    lfo_phase_inc = 2 * pi * lfo_rate_hz / fs;
    lfo_phase = 0;
    
    for n = 1:total_samples
        % Read the current dry sample
        x_n = double(waveform(n));
        
        % --- WRITE PHASE ---
        % Store current sample into the circular buffer
        delay_line(write_ptr) = int32(x_n);
        
        % --- LFO CALCULATION ---
        % Get LFO value between -1.0 and 1.0
        lfo_val = sin(lfo_phase);
        lfo_phase = lfo_phase + lfo_phase_inc;
        if lfo_phase >= 2*pi
            lfo_phase = lfo_phase - 2*pi;
        end
        
        % Calculate modulated delay in samples
        current_delay = base_delay_samps + (depth_samps * lfo_val);
        
        % --- READ PHASE (Calculate fractional pointer) ---
        read_ptr_float = write_ptr - current_delay;
        
        % Wrap the read pointer if it goes below 1 (RAM address wrapping)
        if read_ptr_float < 1
            read_ptr_float = read_ptr_float + max_delay_samps;
        end
        
        % --- LINEAR INTERPOLATION (DSP Slice Math) ---
        % Separate integer address and fractional remainder
        idx1 = floor(read_ptr_float);
        frac = read_ptr_float - idx1;
        
        % Get the next address for interpolation, wrap if necessary
        idx2 = idx1 + 1;
        if idx2 > max_delay_samps
            idx2 = 1;
        end
        
        % Read the two adjacent samples from RAM
        y1 = double(delay_line(idx1));
        y2 = double(delay_line(idx2));
        
        % Blend them based on the fraction: y = y1*(1-frac) + y2*frac
        % This smooths out the quantization of discrete memory addresses
        wet_val = ((1.0 - frac) * y1) + (frac * y2);
        
        % --- MIX WET AND DRY ---
        mixed_val = ((1.0 - mix_wet) * x_n) + (mix_wet * wet_val);
        out(n) = int32(mixed_val);
        
        % --- ADVANCE WRITE POINTER ---
        write_ptr = write_ptr + 1;
        if write_ptr > max_delay_samps
            write_ptr = 1;
        end
    end
end