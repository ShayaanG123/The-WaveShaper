# --- Directories ---
ROOT_DIR    = $(shell pwd)
OSC_DIR     = $(ROOT_DIR)/../Oscillators
EFFECTS_DIR = $(ROOT_DIR)
TB_DIR      = $(ROOT_DIR)/Matlab_Verification/Matlab_TB

# --- Tool Settings (VCS) ---
# Removed -vpi to stop the warning; corrected debug access flags
VCS = vcs -q -sverilog -full64 -debug_access+r+w+nomemcbk -debug_region+cell \
      -timescale=1ns/1ps +incdir+$(ROOT_DIR) +incdir+$(OSC_DIR)

# --- Common Dependencies ---
# Behavioral RAM used by both Echo and Chorus
RAM_MODEL = $(EFFECTS_DIR)/Echo_ram.sv
# Oscillators needed for testbench signal generation
OSC_SAW   = $(OSC_DIR)/osc_saw.sv
OSC_TRI   = $(OSC_DIR)/osc_triangle.sv

# --- Test Lists ---
TESTS = distortion redux echo chorus

.PHONY: all clean help $(TESTS)

help:
	@echo "Effects Verification Makefile"
	@echo "Usage: make [target]"
	@echo "Targets: distortion, redux, echo, chorus, all, clean"

all: $(TESTS)
	@echo "-----------------------------------------------"
	@echo "All Effects Bit-True Tests Completed."
	@echo "-----------------------------------------------"

# --- Distortion Verification ---
distortion:
	@echo "Compiling and Running Bit-True Test for: Sawtooth -> Distortion"
	@$(VCS) $(OSC_SAW) \
           $(EFFECTS_DIR)/distortion.sv \
           $(TB_DIR)/matlab_distortion_tb.sv -o simv_distortion
	@./simv_distortion | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee distortion_results.log
	@echo "Done with distortion."

# --- Redux Verification ---
redux:
	@echo "Compiling and Running Bit-True Test for: Sawtooth -> Redux"
	@$(VCS) $(OSC_SAW) \
           $(EFFECTS_DIR)/redux.sv \
           $(TB_DIR)/matlab_redux_tb.sv -o simv_redux
	@./simv_redux | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee redux_results.log
	@echo "Done with redux."

# --- Echo Verification ---
echo:
	@echo "Compiling and Running Bit-True Test for: Echo (Single-Shot)"
	@$(VCS) $(OSC_SAW) \
           $(RAM_MODEL) \
           $(EFFECTS_DIR)/echo.sv \
           $(TB_DIR)/matlab_echo_tb.sv -o simv_echo
	@./simv_echo | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee echo_results.log
	@echo "Done with echo."

# --- Chorus Verification ---
chorus:
	@echo "Compiling and Running Bit-True Test for: Triangle LFO -> Chorus"
	@$(VCS) $(OSC_SAW) \
           $(OSC_TRI) \
           $(RAM_MODEL) \
           $(EFFECTS_DIR)/chorus.sv \
           $(TB_DIR)/matlab_chorus_tb.sv -o simv_chorus
	@./simv_chorus | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee chorus_results.log
	@echo "Done with chorus."

# --- Reverb Verification ---
reverb:
	@echo "Compiling and Running Bit-True Test for: Sawtooth -> Reverb"
	@$(VCS) $(OSC_SAW) \
           $(RAM_MODEL) \
           $(EFFECTS_DIR)/reverb.sv \
           $(TB_DIR)/matlab_reverb_tb.sv -o simv_reverb
	@./simv_reverb | grep -E "MISMATCH|FAILURE|SUCCESS|Sample|ERR" | tee reverb_results.log
	@echo "Done with reverb."

# --- Cleanup ---
clean:
	@echo "Cleaning up VCS artifacts and logs..."
	@rm -rf csrc simv* *.daidir ucli.key inter.vpd DVEfiles *.log waveforms.*
	@rm -rf $(TB_DIR)/csrc $(TB_DIR)/simv* $(TB_DIR)/*.daidir