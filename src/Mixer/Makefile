# --- Directories ---
ROOT_DIR    = $(shell pwd)
OSC_DIR     = $(ROOT_DIR)/../Oscillators
TB_DIR      = $(ROOT_DIR)/Matlab_Verification/Matlab_TB

# --- Tool Settings (VCS) ---
VCS = vcs -q -sverilog -full64 -debug_access+r+w+nomemcbk -debug_region+cell \
      -timescale=1ns/1ps +incdir+$(ROOT_DIR) +incdir+$(OSC_DIR)

# --- Dependencies ---
# Included all potential oscillators for future-proofing
OSC_FILES = $(OSC_DIR)/osc_saw.sv \
            $(OSC_DIR)/osc_square.sv \
            $(OSC_DIR)/osc_triangle.sv \
            $(OSC_DIR)/osc_noise.sv

MIXER_RTL = $(ROOT_DIR)/mixer.sv
MIXER_TB  = $(TB_DIR)/matlab_mixer_tb.sv

.PHONY: all mixer clean help

help:
	@echo "Mixer Verification Makefile"
	@echo "Usage: make mixer"
	@echo "Targets: mixer, clean"

all: mixer

# --- Mixer Verification ---
mixer:
	@echo "Compiling and Running Bit-True Test for: Multi-Channel Mixer"
	@$(VCS) $(OSC_FILES) \
           $(MIXER_RTL) \
           $(MIXER_TB) -o simv_mixer
	@./simv_mixer | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee mixer_results.log
	@echo "Done with mixer."

# --- Cleanup ---
clean:
	@echo "Cleaning up VCS artifacts and logs..."
	@rm -rf csrc simv* *.daidir ucli.key inter.vpd DVEfiles *.log waveforms.*
	@rm -rf $(TB_DIR)/csrc $(TB_DIR)/simv* $(TB_DIR)/*.daidir