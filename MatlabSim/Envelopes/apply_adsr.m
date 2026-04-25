function out = apply_adsr(audio_in, gate_in, a_step, d_step, s_level, r_step, OUT_WIDTH, ENV_FRACT)
    total_samples = length(audio_in);
    out = zeros(1, total_samples, 'int32'); 
    
    MAX_ENV = int64(2^ENV_FRACT); % 65536 = 1.0
    
    % --- State Machine Enums ---
    IDLE = 0; ATTACK = 1; DECAY = 2; SUSTAIN = 3; RELEASE = 4;
    
    % --- Hardware Pipeline Registers ---
    state     = IDLE;
    env_val   = int64(0);
    audio_reg = int32(0);

    % Use int64 for steps to prevent any overflow during calculation
    a_step = int64(a_step);
    d_step = int64(d_step);
    s_level = int64(s_level);
    r_step = int64(r_step);

    for n = 1:total_samples
        
        % ==========================================
        % STAGE 1: State Machine & Envelope Gen (Next State Logic)
        % ==========================================
        next_state   = state;
        next_env_val = env_val;
        current_gate = gate_in(n);

        if (state ~= IDLE) && (state ~= RELEASE) && (current_gate == 0)
            next_state = RELEASE;
        else
            switch state
                case IDLE
                    next_env_val = 0;
                    if current_gate == 1
                        next_state = ATTACK;
                    end
                case ATTACK
                    if (MAX_ENV - env_val) <= a_step
                        next_env_val = MAX_ENV;
                        next_state   = DECAY;
                    else
                        next_env_val = env_val + a_step;
                    end
                case DECAY
                    if env_val <= (s_level + d_step)
                        next_env_val = s_level;
                        next_state   = SUSTAIN;
                    else
                        next_env_val = env_val - d_step;
                    end
                case SUSTAIN
                    next_env_val = s_level;
                case RELEASE
                    if env_val <= r_step
                        next_env_val = 0;
                        next_state   = IDLE;
                    else
                        next_env_val = env_val - r_step;
                    end
            end
        end

        % ==========================================
        % STAGE 2: Apply Envelope (Combinational logic)
        % ==========================================
        % In the RTL, audio_out is assigned shifted_product on the clock edge.
        % We use the current values of audio_reg and env_val here.
        full_product = int64(audio_reg) * env_val;
        shifted_product = bitshift(full_product, -ENV_FRACT);
        
        % RTL ALIGNMENT: Assign output for this index
        out(n) = int32(shifted_product);

        % ==========================================
        % CLOCK EDGE: Update internal registers for the NEXT sample
        % ==========================================
        audio_reg = int32(audio_in(n));
        env_val   = next_env_val;
        state     = next_state;
    end
end