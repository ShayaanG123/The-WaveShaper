function [lp_out, bp_out, hp_out] = Chamber_SVF(input_signal, fc, Q, fs, OUT_WIDTH)
    % --- 1. Fixed-Point Configuration ---
    SH_AMT             = 22;
    INTERNAL_PRECISION = 8;
    REG_WIDTH          = OUT_WIDTH + INTERNAL_PRECISION;
    
    F_int    = int64(round((2 * sin(pi * fc / fs)) * (2^SH_AMT)));
    damp_int = int64(round((1 / Q)                 * (2^SH_AMT)));

    % Print coefficients to console to put into Chamberlin_SVF_tb.sv
    fprintf('SVF Hardware Coeffs for SV Testbench:\n');
    fprintf('F_int:    %d\n', F_int);
    fprintf('Damp_int: %d\n', damp_int);
        
    % FIXED: round bit must sit at the boundary of bits discarded by -SH_AMT,
    % accounting for the INTERNAL_PRECISION offset already in the registers.
    ROUND_VAL = int64(2^(SH_AMT + INTERNAL_PRECISION - 1));
    
    REG_MASK = int64(2^REG_WIDTH - 1);
    REG_SIGN = int64(2^(REG_WIDTH - 1));
    POS_MAX  = int64(2^(OUT_WIDTH - 1) - 1);
    NEG_MAX  = int64(-(2^(OUT_WIDTH - 1)));

    % --- 2. Registers (wide, simulate wrap-around) ---
    lp_reg = int64(0);
    bp_reg = int64(0);

    N      = length(input_signal);
    lp_out = zeros(1, N, 'int32');
    bp_out = zeros(1, N, 'int32');
    hp_out = zeros(1, N, 'int32');

    ROUND_VAL = int64(2^(SH_AMT - 1));

    for n = 1:N
        x = int64(input_signal(n));   % FIXED: no scaling
    
        % --- HP ---
        damp_product = damp_int * bp_reg;
        damp_term    = bitshift(damp_product + ROUND_VAL, -SH_AMT);
        hp           = x - lp_reg - damp_term;
    
        % --- BP ---
        hp_wrapped = wrap_twos_complement(hp, REG_MASK, REG_SIGN);
        bp_product = F_int * hp_wrapped;
        bp_term    = bitshift(bp_product + ROUND_VAL, -SH_AMT);
        bp_next    = wrap_twos_complement(bp_reg + bp_term, REG_MASK, REG_SIGN);
    
        % --- LP ---
        lp_product = F_int * bp_next;
        lp_term    = bitshift(lp_product + ROUND_VAL, -SH_AMT);
        lp_next    = wrap_twos_complement(lp_reg + lp_term, REG_MASK, REG_SIGN);
    
        % --- Update ---
        lp_reg = lp_next;
        bp_reg = bp_next;
    
        % --- Output (NO INTERNAL SHIFT NEEDED ANYMORE) ---
        lp_out(n) = int32(max(min(lp_next, POS_MAX), NEG_MAX));
        bp_out(n) = int32(max(min(bp_next, POS_MAX), NEG_MAX));
        hp_out(n) = int32(max(min(hp,      POS_MAX), NEG_MAX));
    end
end

% --- Helper: force int64 value into N-bit two's complement window ---
function y = wrap_twos_complement(x, mask, sign_bit)
    % Mask to N bits
    y = bitand(x, mask);
    % If sign bit is set, extend the sign (make it negative)
    if y >= sign_bit
        y = y - int64(2) * sign_bit;
    end
end