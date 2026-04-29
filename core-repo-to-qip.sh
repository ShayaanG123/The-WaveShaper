#!/bin/sh

# Thank you, Gemini.

#!/bin/bash

# Define the source directory (defaults to 'src' if no argument provided)
SRC_DIR=${1:-src}

# Print a header for the .qip file (optional but helpful)
echo "# Generated QIP file for Quartus"
echo "# Path: $SRC_DIR"

# 1. find $SRC_DIR: Search in the source folder
# 2. -name "*.sv": Look for SystemVerilog files
# 3. ! -name "*_tb.sv": Exclude testbenches
# 4. while read: Process each file found
find "$SRC_DIR" -type f -name "*.sv" ! -name "*_tb.sv" | while read -r file; do
    # Format for Quartus QIP:
    # Uses [file join $::quartus(qip_path) "path/to/file"] for portability
    echo "set_global_assignment -name SYSTEMVERILOG_FILE [file join \$::quartus(qip_path) \"$file\"]"
done
