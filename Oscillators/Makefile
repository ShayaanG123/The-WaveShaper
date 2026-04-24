# --- Directories ---
ROOT_DIR = $(shell pwd)
TB_DIR   = $(ROOT_DIR)/Matlab_Verification/Matlab_TB
DATA_DIR = $(ROOT_DIR)/Matlab_Verification/Data

# --- Tool Settings (VCS) ---
# Added -full64 and -timescale for consistent ECE environment simulation
VCS = vcs -q -sverilog -full64 +acc +vpi -debug_access+all \
      -timescale=1ns/1ps +incdir+$(ROOT_DIR)

# --- Test Lists ---
TESTS = square saw sine noise triangle

.PHONY: all clean help $(TESTS)

help:
	@echo "Usage: make [target]"
	@echo "Targets: square, saw, sine, noise, triangle, all, clean"

all: $(TESTS)
	@echo "-----------------------------------------------"
	@echo "All Oscillator Bit-True Tests Completed."
	@echo "-----------------------------------------------"

# --- Generic Pattern Rule for Oscillators ---
# This replaces the repetitive square, saw, sine, etc. blocks
$(TESTS): %:
	@echo "Compiling and Running Bit-True Test for: $*"
	@$(VCS) $(ROOT_DIR)/osc_$*.sv $(TB_DIR)/matlab_$*_tb.sv -o simv_$*
	@./simv_$* | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee $*_results.log
	@echo "Done with $*."

# --- Cleanup ---
clean:
	@echo "Cleaning up VCS artifacts and logs..."
	@rm -rf csrc simv* *.daidir ucli.key inter.vpd DVEfiles *.log waveforms.*
	@rm -rf $(TB_DIR)/csrc $(TB_DIR)/simv* $(TB_DIR)/*.daidir
	@rm -f *.bak