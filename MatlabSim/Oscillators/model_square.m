function out = model_square(total_samples, start_step, stop_step, tuning_word, ACC_WIDTH, OUT_WIDTH)
    % Pre-allocate as signed int32
    out = zeros(1, total_samples, 'int32');
    
    % Initialize internal phase accumulator (32-bit unsigned)
    phase_acc = uint32(0);
    
    % 1. Hardware Peak Values (Matching your SV localparams)
    % Note: h1FFFFFFF is 536,870,911 | hE0000000 is -536,870,912
    % These should be cast or calculated based on your OUT_WIDTH
    if OUT_WIDTH == 32
        POS_PEAK = int32(hex2dec('1fffffff'));
        NEG_PEAK = typecast(uint32(hex2dec('e0000000')), 'int32');
    else
        % If OUT_WIDTH is not 32, we scale the peaks accordingly
        % (Your SV hardcodes 32'h, so this logic mirrors that specific width)
        POS_PEAK = int32(2^(OUT_WIDTH - 3) - 1); 
        NEG_PEAK = int32(-(2^(OUT_WIDTH - 3)));
    end
    
    tuning_word = uint32(tuning_word);
    
    for n = 1:total_samples
        if (n >= start_step) && (n <= stop_step)
            
            % 2. Combinational Logic (Matches SV ternary)
            % SV: (phase_acc[ACC_WIDTH-1] == 1'b0) ? POS_PEAK : NEG_PEAK;
            % MATLAB bitget is 1-indexed, so ACC_WIDTH is the MSB
            if bitget(phase_acc, ACC_WIDTH) == 0
                out(n) = POS_PEAK;
            else
                out(n) = NEG_PEAK;
            end
            
            % 3. Sequential Register Update
            % Using uint64 intermediate to prevent MATLAB double precision rounding
            % then masking to ACC_WIDTH to simulate hardware overflow.
            ACC_MASK = uint64(2^ACC_WIDTH - 1);
            next_phase = uint64(phase_acc) + uint64(tuning_word);
            phase_acc = uint32(bitand(next_phase, ACC_MASK));
            
        else
            % Enable is low: Output matches '0' from SV rst/enable logic
            out(n) = int32(0); 
        end
    end
end