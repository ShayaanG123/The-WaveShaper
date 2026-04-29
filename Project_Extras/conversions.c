#include <stdio.h>
#include <stdint.h>
#include <math.h>

// --- System & Hardware Constants ---
#define SYS_CLK      50000000.0 // 50 MHz
#define SAMPLE_RATE  48000.0    // 48 kHz (Hardware Enable Pulse)
#define PI           3.14159265358979323846

// --- Bit Widths from SystemVerilog ---
#define AUDIO_WIDTH  24         // Locked 24-bit data path
#define ACC_WIDTH    32         // Oscillator phase accumulator
#define COEF_FRACT   22         // Chamberlin Filter Q2.22 format
#define ENV_FRACT    16         // ADSR Envelope Q16 format

// Max envelope value in Q16 (65536 represents 1.0 amplitude)
#define MAX_ENV (1 << ENV_FRACT)

// ==========================================
// 1. Oscillator Calculation
// ==========================================
uint32_t calc_tuning_word(double target_freq) {
    // Tuning Word = (Target_Freq * 2^ACC_WIDTH) / Sample_Rate
    double two_to_32 = 4294967296.0; 
    double word = (target_freq * two_to_32) / SAMPLE_RATE;
    return (uint32_t)round(word);
}

// ==========================================
// 2. Filter Coefficient Calculation
// ==========================================
void calc_filter_coefs(double cutoff_freq, double resonance_q, int32_t *f_out, int32_t *damp_out) {
    // 1. Calculate ideal floating point values
    double f_float = 2.0 * sin(PI * cutoff_freq / SAMPLE_RATE);
    double damp_float = 1.0 / resonance_q;
    
    // 2. Convert to Q2.22 Fixed Point format
    double q_scale = (double)(1 << COEF_FRACT); 
    
    *f_out = (int32_t)round(f_float * q_scale);
    *damp_out = (int32_t)round(damp_float * q_scale);
}

// ==========================================
// 3. ADSR Step Calculation
// ==========================================
void calc_adsr_steps(double attack_sec, double decay_sec, double sustain_norm, double release_sec,
                     uint32_t *attack_step, uint32_t *decay_step, uint32_t *sustain_level, uint32_t *release_step) {
    
    // Calculate total clock ticks (at 48kHz enable rate) for each time window
    double attack_samples  = attack_sec * SAMPLE_RATE;
    double decay_samples   = decay_sec * SAMPLE_RATE;
    double release_samples = release_sec * SAMPLE_RATE;
    
    // 1. Sustain Level (Target Amplitude)
    if (sustain_norm < 0.0) sustain_norm = 0.0;
    if (sustain_norm > 1.0) sustain_norm = 1.0;
    *sustain_level = (uint32_t)round(sustain_norm * MAX_ENV);
    
    // 2. Attack Step (0 -> MAX_ENV)
    if (attack_samples > 0) {
        *attack_step = (uint32_t)round((double)MAX_ENV / attack_samples);
    } else {
        *attack_step = MAX_ENV; // Instant attack
    }
    
    // 3. Decay Step (MAX_ENV -> sustain_level)
    if (decay_samples > 0) {
        double decay_distance = (double)MAX_ENV - (double)(*sustain_level);
        *decay_step = (uint32_t)round(decay_distance / decay_samples);
    } else {
        *decay_step = MAX_ENV; 
    }
    
    // 4. Release Step (sustain_level -> 0)
    if (release_samples > 0) {
        *release_step = (uint32_t)round((double)(*sustain_level) / release_samples);
    } else {
        *release_step = MAX_ENV;
    }
}

// ==========================================
// Quick Validation Test
// ==========================================
int main() {
    printf("--- Generating Digital Synthesizer Parameters (24-bit Audio Path) ---\n\n");

    // 1. Test Oscillator
    double target_hz = 440.0; // A4
    uint32_t tuning = calc_tuning_word(target_hz);
    printf("Oscillator (%.2f Hz):\n", target_hz);
    printf("  Tuning Word: %u (0x%08X)\n\n", tuning, tuning);

    // 2. Test Filter
    double fc = 1200.0;
    double Q = 1.5;
    int32_t f_coef, damp_coef;
    calc_filter_coefs(fc, Q, &f_coef, &damp_coef);
    printf("Chamberlin SVF (Fc: %.2f Hz, Q: %.2f):\n", fc, Q);
    printf("  F_int:    %d\n", f_coef);
    printf("  Damp_int: %d\n\n", damp_coef);

    // 3. Test ADSR
    double a_time = 0.1;  
    double d_time = 0.2;  
    double s_norm = 0.7;  
    double r_time = 0.5;  
    
    uint32_t a_step, d_step, s_lvl, r_step;
    calc_adsr_steps(a_time, d_time, s_norm, r_time, &a_step, &d_step, &s_lvl, &r_step);
    
    printf("ADSR Envelope (A:%.2fs, D:%.2fs, S:%.2f, R:%.2fs):\n", a_time, d_time, s_norm, r_time);
    printf("  Attack Step:   %u\n", a_step);
    printf("  Decay Step:    %u\n", d_step);
    printf("  Sustain Level: %u\n", s_lvl);
    printf("  Release Step:  %u\n\n", r_step);

    return 0;
}