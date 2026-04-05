ADDR_WIDTH = 8;               
OUT_WIDTH = 32;               
num_entries = 2^ADDR_WIDTH;

% Using (2^31)-1 to stay within signed 32-bit limits
amplitude = (2^(OUT_WIDTH-1)) - 1; 

% 1. Create a clean sine wave starting at 0
t = (0:num_entries-1)' / num_entries;
sine_wave = sin(2 * pi * t); 

% 2. Scale
scaled_sine = round(amplitude * sine_wave);

% 3. Generate the file (The "Bit-Pattern" Logic)
fid = fopen('sine_lut_32.mif', 'w');
fprintf(fid, 'WIDTH=32;\nDEPTH=256;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n');

for i = 0:(num_entries-1)
    val = scaled_sine(i+1);
    % Standard 2's complement conversion for the hex string
    if val < 0
        hex_val = uint32(val + 2^32);
    else
        hex_val = uint32(val);
    end
    fprintf(fid, '    %02X : %08X;\n', i, hex_val);
end
fprintf(fid, 'END;\n');
fclose(fid);