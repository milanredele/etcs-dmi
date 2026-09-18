--  ETCS DMI
--  Audible information (DMI chapter 14). The DMI has no audio device of
--  its own here: sounds are queued and sent to the UI as MSG_SOUND.

package DMI_Sounds is

   type Sound_T is (Click,            -- 14.2.1, on button press
                    Sinfo,            -- 14.3.1, new visual information
                    S1_Overspeed,     -- 14.3.2, TSM over-speed, once
                    S2_Warning_Start, -- 14.3.3, continuous while WaS
                    S2_Warning_Stop);

   procedure Play (The_Sound : Sound_T);

   -- Take the next queued sound; False when the queue is empty
   function Pop (The_Sound : out Sound_T) return Boolean;

end DMI_Sounds;
