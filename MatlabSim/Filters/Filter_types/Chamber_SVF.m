function [lp_out, bp_out, hp_out] = Chamber_SVF(input_signal, fc, Q, fs, OUT_WIDTH)
    % --- 1. Fixed-Point Configuration ---
    SH_AMT             = 22;
    INTERNAL_PRECISION = 8;
    REG_WIDTH          = OUT_WIDTH + INTERNAL_PRECISION;
    
    F_int    = int64(round((2 * sin(pi * fc / fs)) * (2^SH_AMT)));
    damp_int = int64(round((1 / Q)                 * (2^SH_AMT)));
    
    fprintf('SVF Hardware Coeffs for SV Testbench:\n');
    fprintf('F_int:    %d\n', F_int);
    fprintf('Damp_int: %d\n', damp_int);
        
    % Match SV exactly: (1 <<< (COEF_FRACT - 1))
    ROUND_VAL = int64(2^(SH_AMT - 1));
    
    REG_MASK = int64(2^REG_WIDTH - 1);
    REG_SIGN = int64(2^(REG_WIDTH - 1));
    
    % Saturation limits for 32-bit output
    POS_MAX  = int64(2^(OUT_WIDTH - 1) - 1);
    NEG_MAX  = int64(-(2^(OUT_WIDTH - 1)));

    % --- 2. Registers ---
    lp_reg = int64(0);
    bp_reg = int64(0);
    
    N      = length(input_signal);
    lp_out = zeros(1, N, 'int32');
    bp_out = zeros(1, N, 'int32');
    hp_out = zeros(1, N, 'int32');

    for n = 1:N
        x = int64(input_signal(n)); 
    
        % --- HP Stage ---
        damp_product = damp_int * bp_reg;
        % Force 40-bit truncation on the term before subtraction
        damp_term    = wrap_twos_complement(bitshift(damp_product + ROUND_VAL, -SH_AMT), REG_MASK, REG_SIGN);
        hp_full      = x - lp_reg - damp_term;
        hp_wrapped   = wrap_twos_complement(hp_full, REG_MASK, REG_SIGN);
    
        % --- BP Stage ---
        bp_product = F_int * hp_wrapped;
        bp_term    = wrap_twos_complement(bitshift(bp_product + ROUND_VAL, -SH_AMT), REG_MASK, REG_SIGN);
        bp_next    = wrap_twos_complement(bp_reg + bp_term, REG_MASK, REG_SIGN);
    
        % --- LP Stage ---
        lp_product = F_int * bp_next;
        lp_term    = wrap_twos_complement(bitshift(lp_product + ROUND_VAL, -SH_AMT), REG_MASK, REG_SIGN);
        lp_next    = wrap_twos_complement(lp_reg + lp_term, REG_MASK, REG_SIGN);
    
        % --- Update States ---
        lp_reg = lp_next;
        bp_reg = bp_next;
    
        % --- Output Saturation ---
        lp_out(n) = int32(max(min(lp_next, POS_MAX), NEG_MAX));
        bp_out(n) = int32(max(min(bp_next, POS_MAX), NEG_MAX));
        hp_out(n) = int32(max(min(hp_wrapped, POS_MAX), NEG_MAX));
    end
end

% --- Helper: force int64 value into N-bit two's complement window ---
function y = wrap_twos_complement(x, mask, sign_bit)
    y = bitand(int64(x), mask);
    if y >= sign_bit
        y = y - int64(2) * sign_bit;
    end
end