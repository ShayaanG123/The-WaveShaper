`timescale 1ns / 1ps

package waveshaper_types;
    // Take after MIDI option depth.
    parameter int OPT_DEPTH = 8;

    // Width of sample in bits.
    parameter int SMPL_WIDTH = 24;

    // Number of voices.
    parameter int NUM_VOICES = 4;

    // Oscillator parameters.
    typedef struct { logic [OPT_DEPTH-1:0] sq;
                     logic [OPT_DEPTH-1:0] sw;
                     logic [OPT_DEPTH-1:0] sn;
                     logic [OPT_DEPTH-1:0] tr;
                     logic [OPT_DEPTH-1:0] ns; } coefs_t;

    typedef struct { coefs_t      coefs;
                     logic [7:0]  velocity;
                     logic [7:0]  note_idx; } osc_params_t;

    // ADSR parameters.
    typedef struct { logic [OPT_DEPTH-1:0] attack_time;
                     logic [OPT_DEPTH-1:0] decay_time;
                     logic [OPT_DEPTH-1:0] sustain_ampl;
                     logic [OPT_DEPTH-1:0] release_time; } adsr_params_t;

    // Filter parameters.
    typedef enum { HIGH_P, LOW_P, BAND_P, NOTCH } filter_kind_e;

    typedef struct { filter_kind_e kind;
                     logic [OPT_DEPTH-1:0] res_freq;
                     logic [OPT_DEPTH-1:0] damp;  } filter_params_t;

    // FX select.
    typedef enum   { BYPASS,
                     ECHO,
                     CHORUS,
                     REDUX  } fx_e;
endpackage
