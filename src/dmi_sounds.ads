--  ETCS DMI
--  Audible information (DMI chapter 14). The DMI has no audio device of
--  its own here: sounds are queued and sent to the UI as MSG_SOUND.

package DMI_Sounds is

   type Sound_T is (Click,            -- 14.2.1, on button press
                    Sinfo,            -- 14.3.1, new visual information
                    S1_Overspeed,     -- 14.3.2, TSM over-speed, once
                    S2_Warning_Start, -- 14.3.3, continuous while WaS
                    S2_Warning_Stop);

   -- Click, Sinfo and S1 are played once (14.2.1.2, 14.3.1.2, 14.3.2.2)
   -- and wait in a queue of 8. S2 is played as long as the Warning
   -- status is active (14.3.3.2): it is kept as a state beside the
   -- queue, so neither a start nor a stop can be lost, however full the
   -- queue is. Pop reports a change of that state before the queued
   -- sounds; a start and a stop between two calls of Pop cancel out, and
   -- repeated starts or stops are reported once.
   --
   -- Queue full: a click or a Sinfo is dropped. S1 takes the place of
   -- the oldest queued click, else of the oldest Sinfo.
   procedure Play (The_Sound : Sound_T);

   -- DMI 8.5.1.7: S2 is also played while the ERTMS/ATO on-board
   -- requests a warning sound. It is a second reason for the same S2
   -- state, kept apart from the Warning status of the supervision
   -- (S2_Warning_Start / S2_Warning_Stop above): S2 sounds while either
   -- reason holds, and neither can stop the other one's S2.
   procedure Set_ATO_Warning (On : Boolean);

   -- Take the next queued sound; False when the queue is empty
   function Pop (The_Sound : out Sound_T) return Boolean;

end DMI_Sounds;
