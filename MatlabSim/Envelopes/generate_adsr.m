function env = generate_adsr(A, D, S, R, gate_time, fs)
    % GENERATE_ADSR creates an ADSR envelope array.
    % A, D, R, gate_time are in seconds. S is an amplitude (0.0 to 1.0).
    % fs is the sample rate in Hz.

    % 1. Convert times to number of samples
    A_samples = round(A * fs);
    D_samples = round(D * fs);
    R_samples = round(R * fs);
    
    % Calculate sustain duration
    sustain_time = gate_time - A - D;
    
    % 2. Handle Edge Case: Gate released early
    if sustain_time < 0
        % If the note is too short, we won't have a sustain phase
        S_samples = 0;
        
        % We also need to figure out where the envelope was interrupted
        total_gate_samples = round(gate_time * fs);
        
        if total_gate_samples <= A_samples
            % Interrupted during the Attack phase
            A_samples = total_gate_samples;
            D_samples = 0;
            release_start_level = A_samples / round(A * fs); % Proportional amplitude
        else
            % Interrupted during the Decay phase
            D_samples = total_gate_samples - A_samples;
            % Calculate where the decay got cut off
            decay_progress = D_samples / round(D * fs);
            release_start_level = 1 - (decay_progress * (1 - S));
        end
    else
        % Normal note hold
        S_samples = round(sustain_time * fs);
        release_start_level = S; % Release starts from the Sustain level
    end

    % 3. Generate the individual phase arrays
    if A_samples > 0
        attack = linspace(0, 1, A_samples);
    else
        attack = [];
    end
    
    if D_samples > 0
        decay = linspace(1, S, D_samples);
    else
        decay = [];
    end
    
    if S_samples > 0
        sustain = S * ones(1, S_samples);
    else
        sustain = [];
    end
    
    if R_samples > 0
        release = linspace(release_start_level, 0, R_samples);
    else
        release = [];
    end
    
    % 4. Stitch it all together
    env = [attack, decay, sustain, release];
end