function out = model_sine(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate as signed int32 to match 'logic signed [OUT_WIDTH-1:0]'
    out = zeros(1, total_samples, 'int32');
    phase_acc = uint32(0);
    
    % 1. Hardware ROM Parameters (Matching your SV rom_addr [31:24])
    ADDR_WIDTH = 8; % Your SV uses phase_acc[31:24], which is 8 bits
    lut_size = 2^ADDR_WIDTH;
    n_lut = 0:(lut_size-1);
    
    % 2. Generate Signed Sine LUT
    % In hardware, we store 2's complement values.
    % We use a 25% peak (matching your square wave headroom) or full scale.
    % To match your 'osc_square', we'll use the same headroom logic.
    amplitude = double(2^(OUT_WIDTH - 3) - 1); 
    
    % Store as int32. No "mid_point" needed for signed signals.
    sine_lut = int32(round(amplitude * sin(2 * pi * n_lut / lut_size)));
    
    % 3. Latency Simulation
    % Your SV uses an 'always_ff' for sine_out, creating 1 cycle of latency
    % after the ROM. If the ROM IP itself has 1 cycle, total latency is 2.
    ROM_LATENCY = 2; 
    pipe_reg = zeros(1, ROM_LATENCY, 'int32');
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            
            % Extract Address (Truncation)
            % SV: assign rom_addr = phase_acc[31:24];
            % This is a right shift by 24 for a 32-bit accumulator.
            idx = bitshift(phase_acc, -(ACC_WIDTH - ADDR_WIDTH));
            
            % Fetch from ROM
            current_rom_q = sine_lut(idx + 1);
            
            % Update phase
            ACC_MASK = uint64(2^ACC_WIDTH - 1);
            next_phase = uint64(phase_acc) + uint64(tuning_word);
            phase_acc = uint32(bitand(next_phase, ACC_MASK));
        else
            current_rom_q = int32(0);
        end
        
        % 4. Model the Pipeline Latency (Shift Register)
        out(n) = pipe_reg(1);
        for i = 1:(ROM_LATENCY-1)
            pipe_reg(i) = pipe_reg(i+1);
        end
        pipe_reg(ROM_LATENCY) = current_rom_q;
    end
end