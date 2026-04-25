# --- Directories ---
ROOT_DIR = $(shell pwd)
OSC_DIR  = $(ROOT_DIR)/../Oscillators
TB_DIR   = $(ROOT_DIR)/Matlab_Verification/Matlab_TB

# --- Tool Settings (VCS) ---
VCS = vcs -q -sverilog -full64 +acc +vpi -debug_access+all \
      -timescale=1ns/1ps +incdir+$(ROOT_DIR) +incdir+$(OSC_DIR)

# --- Test Lists ---
# Current focus is the square filter integration
TESTS = square_filter

.PHONY: all clean help $(TESTS)

help:
	@echo "Filter Verification Makefile"
	@echo "Usage: make [target]"
	@echo "Targets: square_filter, all, clean"

all: $(TESTS)
	@echo "-----------------------------------------------"
	@echo "All Filter Bit-True Tests Completed."
	@echo "-----------------------------------------------"

# --- Specific Rule for Integrated Square Filter ---
# This pulls the square oscillator from the neighboring directory
square_filter:
	@echo "Compiling and Running Bit-True Test for: Square -> Chamberlin SVF"
	@$(VCS) $(OSC_DIR)/osc_square.sv \
	       $(ROOT_DIR)/Chamberlin_SVF.sv \
	       $(TB_DIR)/square_filter_tb.sv -o simv_sq_fltr
	@./simv_sq_fltr | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee square_filter_results.log
	@echo "Done with square_filter."

# --- Specific Rule for Integrated Sawtooth Filter ---
saw_filter:
	@echo "Compiling and Running Bit-True Test for: Sawtooth -> Chamberlin SVF"
	@$(VCS) $(OSC_DIR)/osc_saw.sv \
           $(ROOT_DIR)/Chamberlin_SVF.sv \
           $(TB_DIR)/saw_filter_tb.sv -o simv_saw_fltr
	@./simv_saw_fltr | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee saw_filter_results.log
	@echo "Done with saw_filter."

# --- Cleanup ---
clean:
	@echo "Cleaning up VCS artifacts and logs..."
	@rm -rf csrc simv* *.daidir ucli.key inter.vpd DVEfiles *.log waveforms.*
	@rm -rf $(TB_DIR)/csrc $(TB_DIR)/simv* $(TB_DIR)/*.daidir
	@rm -f *.bak