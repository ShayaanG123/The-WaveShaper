note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

for semitone in range(12):
    # Formula: 440 * 2^32 * 2^((semitone - 9) / 12)
    base_val = 440.0 * (2**32) * (2.0 ** ((semitone - 9) / 12.0))
    
    # Round to the nearest integer for hardware
    base_val_int = round(base_val)
    
    # Print the SystemVerilog syntax
    print(f"            4'd{semitone}:  selected_base = 64'd{base_val_int}; // {note_names[semitone]}")