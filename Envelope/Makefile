# --- Directories ---
ROOT_DIR = $(shell pwd)
TB_DIR   = $(ROOT_DIR)/Matlab_Verification/Matlab_TB

# --- Tool Settings (VCS) ---
# Matched to your working Oscillator Makefile for stability
VCS = vcs -q -sverilog -full64 +acc +vpi -debug_access+all \
      -timescale=1ns/1ps +incdir+$(ROOT_DIR)

# --- Dependencies ---
# Ensure capitalization matches your filename (ADSR.sv vs adsr.sv)
ADSR_RTL = $(ROOT_DIR)/ADSR.sv
ADSR_TB  = $(TB_DIR)/matlab_adsr_tb.sv

.PHONY: all adsr clean help

help:
	@echo "ADSR Verification Makefile"
	@echo "Usage: make adsr"
	@echo "Targets: adsr, clean"

all: adsr

# --- ADSR Verification ---
adsr:
	@echo "Compiling and Running Bit-True Test for: ADSR Envelope"
	@rm -rf simv_adsr simv_adsr.daidir  # Ensure no stale binary survives
	@$(VCS) $(ADSR_RTL) $(ADSR_TB) -o simv_adsr
	@./simv_adsr | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee adsr_results.log
	@echo "Done with ADSR verification."

# --- Cleanup ---
# Matched to your working clean routine
clean:
	@echo "Cleaning up VCS artifacts and logs..."
	@rm -rf csrc simv* *.daidir ucli.key inter.vpd DVEfiles *.log waveforms.*
	@rm -rf $(TB_DIR)/csrc $(TB_DIR)/simv* $(TB_DIR)/*.daidir
	@rm -f *.bak