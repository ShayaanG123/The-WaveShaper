`default_nettype none
timeunit 1ns;
timeprecision 100ps;
///*** --ADSR Envelope--
//A once-per-trigger filter that dictates how volume should attenuate over time
//  -Can modulate any param, but really volume by convention, and to start for
//  us
//Attack: How long should the sound take to come in?
//Decay: The volume falls from an initial peak to a lower level. Decay decides
//how long this takes
//Sustain: The level the volume decays to after the initial peak
//Release: How long to attenuate volume to silence after key-press ***///

//This file contains hardware to generate envelope control wave.
//No modulation of OSC waves yet occurs. 
//We can scale OSC amplitude externally with a multiplier or some other logic
module ADSR_envelope_bank
    #(
        parameter VOICE_NUM = 4,
        parameter BIT_DEPTH = 24,
        parameter OPTION_DEPTH = 8 //num bits on user-facing controls
        )
    (
        input logic [VOICE_NUM-1:0] gate,
        input logic [VOICE_NUM-1:0][OPTION_DEPTH-1:0] attack_time,
        input logic [VOICE_NUM-1:0][OPTION_DEPTH-1:0] decay_time,
        input logic [VOICE_NUM-1:0][OPTION_DEPTH-1:0] sustain_level,
        input logic [VOICE_NUM-1:0][OPTION_DEPTH-1:0] release_time,
        input logic clk, rst_l,

        output logic [VOICE_NUM-1:0][BIT_DEPTH-1:0] control_waves
        );

        genvar i;
        generate
            for (i = 0; i < VOICE_NUM; i = i + 1) begin : ADSRs
              ADSR_envelope_onevoice adsr(.clk(clk), .rst_l(rst_l), 
                    .gate(gate[i]), .attack_time(attack_time[i]),
                    .decay_time(decay_time[i]), 
                    .sustain_level(sustain_level[i]),
                    .release_time(release_time[i]),
                    .control_wave(control_waves[i]) );
            end
        endgenerate
        //*** TODO: Key-press arbitration logic:
        //          Suppose we're traversing a release in one of the EGs
        //          How do we evict oldest note-press
        //          upon the pressing of a fifth note? ***//

endmodule

module ADSR_envelope_onevoice
    #(
        parameter BIT_DEPTH = 24,
        parameter  OPTION_DEPTH = 8
      )
     (
        input logic clk, rst_l,
        input logic [OPTION_DEPTH-1:0] attack_time,
        input logic [OPTION_DEPTH-1:0] decay_time,
        input logic [OPTION_DEPTH-1:0] sustain_level,
        input logic [OPTION_DEPTH-1:0] release_time,
        input logic gate, //key-press for us


        output logic [BIT_DEPTH-1:0] control_wave
        );

        logic triggered, detriggered, last_gate, retrig_window;
        logic [23:0] attack_guard_check;
        logic [23:0] release_guard_check;

        always_ff @(posedge clk or negedge rst_l) begin
            //update trigger/detrigger for moving thru A/D, and switching to R 
            if (gate && !last_gate) begin
                    triggered <= 1;
                    detriggered <= 0;
            end
            else if (gate && last_gate) begin
                    triggered <= 1;
                    detriggered <= 0;
            end
            else if (!gate && last_gate) begin
                    triggered <=0;
                    detriggered <=1;
            end
            else if (!gate && !last_gate) begin
               detriggered <=0;
               triggered <=0;
            end
            
            last_gate <= gate;
        end
       
        logic [OPTION_DEPTH-1:0] envelope_accumulator;//divide clk, to come
        logic [BIT_DEPTH-1:0] envelope_level;
        logic [BIT_DEPTH-1:0] last_level;

        /// *** --- ATTACK, DECAY & RELEASE ---
        //Attack is ~ a slope. X - time, Y - normalized volume from [0,1]
        //Where 1 is full volume. So an attack level of 0 should be a straight
        //line up, where an attack level of MAX should achieve Max volume only 
        //after N seconds. When Attack finishes, decay begins. 
        //Decay is the same but with negative slope from 1 to sust. level
        //Release is a negative slope from sustained level to 0
        //triggered upon a key-release*** ///
        logic [BIT_DEPTH-1:0] attack_incr, decay_incr, release_incr; 
        //attack time is inversely proportional to increment
        logic [BIT_DEPTH-1:0] ones;
        assign ones = '1;//all ones
        assign attack_incr =  {16'b0, attack_time};
        assign decay_incr = {16'b0, decay_time};
        assign release_incr = {16'b0, release_time};

        //track which envelope phase we're in
        logic attack_done, decay_done, release_done; 

        assign attack_guard_check = envelope_level + attack_incr; 
        assign release_guard_check = envelope_level - release_incr; 

        always_ff @(posedge clk or negedge rst_l) begin
            if (!rst_l) begin
                retrig_window <= 0;
                attack_done <= 0;
                last_level <= 0;
                decay_done <= 0;
                envelope_level <= 0; 
                release_done <= 0;
            end
            else if (retrig_window & gate) begin //reset on retrig and 
                retrig_window <= 0;
                envelope_level <= 0;
                release_done <= 0;
                decay_done <= 0;
                attack_done <= 0;
                last_level <= 0;
            end
            else if (gate) begin//key press: A -> D -> latch at sustained level
                //ATTACK
                if (!attack_done) begin
                    //basic increment
                    envelope_level <= envelope_level + attack_incr;
                    //if this causes overflow, move onto decay

                    if (envelope_level > attack_guard_check) begin
                        attack_done <= 1;
                        envelope_level <= '1;
                    end
                end

                //DECAY
                else if (attack_done && !decay_done) begin
                    envelope_level <= envelope_level - decay_incr;
                    //guard to move-to sustain
                    if ({sustain_level, 16'b0} > envelope_level) begin
                        envelope_level <= {sustain_level, 16'b0};
                        decay_done <= 1;
                    end
                end
                //SUSTAIN
                else if (attack_done && decay_done) begin
                    envelope_level <= {sustain_level, 16'b0};
                end
            end 
            //on key-off: start release
            else if (!gate && !release_done) begin 
                retrig_window <= 1;
                //reset others and begin release immediately;
                // attack_done <= 0;
                // decay_done <= 0;
                envelope_level <= envelope_level - release_incr;
                if (envelope_level < release_guard_check) begin
                    envelope_level <= 0;
                    release_done <= 1;
                end
            end
            else begin
                attack_done <= 0;
                release_done <= 0;
                decay_done <=0;
            end

            last_level <= envelope_level;
            control_wave <= envelope_level;
        end
endmodule
