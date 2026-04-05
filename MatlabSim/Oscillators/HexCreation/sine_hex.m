% LUT Parameters
ADDR_WIDTH = 8;
OUT_WIDTH = 24;
num_entries = 2^ADDR_WIDTH;

% Calculate max amplitude for signed 24-bit: 2^(23) - 1
max_amp = (2^(OUT_WIDTH - 1)) - 1; 

% Open file for writing
fileID = fopen('sine_lut.hex', 'w');

for i = 0:(num_entries - 1)
    % Calculate sine value
    val = round(max_amp * sin(2 * pi * i / num_entries));
    
    % Handle two's complement for negative numbers
    if val < 0
        val = val + 2^OUT_WIDTH;
    end
    
    % Write to file as 6-character zero-padded hex
    fprintf(fileID, '%06X\n', val);
end

fclose(fileID);
disp('Generated sine_lut.hex successfully.'); 