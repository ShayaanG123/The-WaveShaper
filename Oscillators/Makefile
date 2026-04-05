# --- Directories ---
ROOT_DIR = $(shell pwd)
TB_DIR   = $(ROOT_DIR)/Matlab_Verification/Matlab_TB

# --- Tool Settings (VCS) ---
# Added -q for quiet compilation
VCS = vcs -q -sverilog -full64 +acc +vpi -debug_access+all +incdir+$(ROOT_DIR)

# --- Test Lists ---
TESTS = square saw sine noise triangle

all: $(TESTS)
	@echo "-----------------------------------------------"
	@echo "All Oscillator Tests Completed."
	@echo "-----------------------------------------------"

# --- Specific Oscillator Rules ---
# @ hides the command itself from the terminal
# -ucli -do <<EOF ... EOF runs the simulation and exits immediately without the VCS header
square:
	@$(VCS) $(ROOT_DIR)/osc_square.sv $(TB_DIR)/matlab_sq_tb.sv -o simv_sq
	@./simv_sq | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee sq_results.log

saw:
	@$(VCS) $(ROOT_DIR)/osc_saw.sv $(TB_DIR)/matlab_saw_tb.sv -o simv_saw
	@./simv_saw | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee saw_results.log

sine:
	@$(VCS) $(ROOT_DIR)/osc_sine.sv $(TB_DIR)/matlab_sine_tb.sv -o simv_sine
	@./simv_sine | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee sine_results.log

noise:
	@$(VCS) $(ROOT_DIR)/osc_noise.sv $(TB_DIR)/matlab_noise_tb.sv -o simv_noise
	@./simv_noise | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee noise_results.log

triangle:
	@$(VCS) $(ROOT_DIR)/osc_triangle.sv $(TB_DIR)/matlab_triangle_tb.sv -o simv_triangle
	@./simv_triangle | grep -E "MISMATCH|FAILURE|SUCCESS|Sample" | tee tri_results.log

clean:
	@rm -rf csrc simv* *.daidir ucli.key inter.vpd DVEfiles *.log waveforms.*
	@rm -rf $(TB_DIR)/csrc $(TB_DIR)/simv* $(TB_DIR)/*.daidir