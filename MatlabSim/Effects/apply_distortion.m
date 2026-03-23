function out = apply_distortion(waveform, drive_amount, type, OUT_WIDTH)
    % APPLY_DISTORTION Hardware-style Waveshaping
    % waveform:     Input audio array (signed int32)
    % drive_amount: Gain multiplier (e.g., 1.0 = no gain, 10.0 = heavy drive)
    % type:         'hard', 'soft', or 'foldback'
    % OUT_WIDTH:    Bit-width of the audio path (e.g., 24)
    
    total_samples = length(waveform);
    out = zeros(1, total_samples, 'int32');
    
    % Define the maximum and minimum bounds for your signed hardware register
    max_val = (2^(OUT_WIDTH - 1)) - 1;
    min_val = -(2^(OUT_WIDTH - 1));
    
    for n = 1:total_samples
        % 1. Apply Input Gain (Drive)
        % In hardware, this is a DSP multiplier slice
        x = double(waveform(n)) * drive_amount;
        
        % 2. Apply the Waveshaper
        switch lower(type)
            case 'hard'
                % Hard Clipping: Saturation logic in SystemVerilog
                if x > max_val
                    x = max_val;
                elseif x < min_val
                    x = min_val;
                end
                
            case 'soft'
                % Soft Clipping: Smoothly rounds the top using a polynomial approximation
                % Normalizing x to a -1.0 to 1.0 range for the math
                x_norm = x / max_val; 
                if x_norm > 1.0
                    x_norm = 1.0;
                elseif x_norm < -1.0
                    x_norm = -1.0;
                else
                    % A common hardware-friendly soft-clip approximation: x - (x^3)/3
                    x_norm = x_norm - ((x_norm^3) / 3);
                    % Scale it up slightly so peak hits 1.0
                    x_norm = x_norm * 1.5; 
                end
                x = x_norm * max_val;
                
            case 'foldback'
                % Foldback (Overflow): This mimics an integer overflow in Verilog.
                % If the signal goes over the max, it wraps around to the negative side!
                % It sounds like a harsh, robotic ring-modulator.
                range = 2^OUT_WIDTH;
                % Modulo arithmetic simulates bit-wrapping
                x_wrapped = mod(x - min_val, range) + min_val;
                x = x_wrapped;
        end
        
        out(n) = int32(x);
    end
end