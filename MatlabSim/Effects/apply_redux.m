function out = apply_redux(waveform, target_bit_depth, downsample_factor, OUT_WIDTH, mix_wet)
    % APPLY_REDUX Hardware-style Bitcrusher and Decimator
    % waveform:          Input audio array (signed int32)
    % target_bit_depth:  The new bit-depth (e.g., 8, 4, 1)
    % downsample_factor: How many samples to hold (e.g., 1 = off, 6 = hold for 6 cycles)
    % OUT_WIDTH:         Original bit width (e.g., 24)
    % mix_wet:           Dry/Wet balance (0.0 to 1.0)
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32');
    
    % 1. Bit Reduction Calculation
    % In hardware, we just shift the bits to the right to delete the LSBs, 
    % and then shift them back to the left to maintain the overall amplitude.
    shift_amount = OUT_WIDTH - target_bit_depth;
    if shift_amount < 0
        shift_amount = 0; % Prevent errors if target > OUT_WIDTH
    end
    
    % Variables for Sample and Hold
    held_val = int32(0);
    hold_counter = 0;
    
    for n = 1:total_samples
        x_n = waveform(n);
        
        % --- DECIMATION (Sample Rate Reduction) ---
        % Only grab a new sample if the counter has reset
        if hold_counter == 0
            held_val = x_n;
        end
        
        % Increment counter and wrap around
        hold_counter = hold_counter + 1;
        if hold_counter >= downsample_factor
            hold_counter = 0;
        end
        
        % --- QUANTIZATION (Bit Depth Reduction) ---
        % Right shift throws away the bottom bits, Left shift restores the scale.
        % MATLAB's bitshift works directly on integers just like SystemVerilog '>>' and '<<'
        crushed_val = bitshift(bitshift(held_val, -shift_amount), shift_amount);
        
        % --- MIX WET AND DRY ---
        mixed_val = ((1.0 - mix_wet) * double(x_n)) + (mix_wet * double(crushed_val));
        
        out(n) = int32(mixed_val);
    end
end