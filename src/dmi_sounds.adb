--  ETCS DMI
--  Sound queue implementation.

package body DMI_Sounds is

   -- The sounds that are played once wait in a small queue
   Queue_Size : constant := 8;
   type Queue_Index_T is mod Queue_Size;
   subtype Once_T is Sound_T range Click .. S1_Overspeed;

   Queue : array (Queue_Index_T) of Once_T := (others => Click);
   Head, Tail : Queue_Index_T := 0;
   Count : Natural := 0;

   -- S2 is a state, not an event (14.3.3.2), and is kept out of the
   -- queue: S2_Wanted follows the Warning status, S2_Reported is what
   -- the display unit was told last. Pop reports the difference.
   S2_Wanted   : Boolean := False;
   S2_Reported : Boolean := False;

   -- Put The_Sound in the place of the oldest queued Victim, if any
   procedure Replace_Oldest (Victim, The_Sound : Once_T;
                             Done : out Boolean) is
      Index : Queue_Index_T := Head;
   begin
      Done := False;
      for I in 1 .. Count loop
         if Queue (Index) = Victim then
            Queue (Index) := The_Sound;
            Done := True;
            return;
         end if;
         Index := Index + 1;
      end loop;
   end Replace_Oldest;

   procedure Play (The_Sound : Sound_T) is
   begin
      case The_Sound is
         when S2_Warning_Start =>
            S2_Wanted := True;
         when S2_Warning_Stop =>
            S2_Wanted := False;
         when Once_T =>
            if Count < Queue_Size then
               Queue (Tail) := The_Sound;
               Tail := Tail + 1;
               Count := Count + 1;
            elsif The_Sound = S1_Overspeed then
               -- full: a click, else a Sinfo, makes room for S1. When
               -- the queue holds nothing but S1, S1 is going to be
               -- played anyway.
               declare
                  Done : Boolean;
               begin
                  Replace_Oldest (Click, The_Sound, Done);
                  if not Done then
                     Replace_Oldest (Sinfo, The_Sound, Done);
                  end if;
               end;
            end if;
            -- full: a click or a Sinfo is dropped
      end case;
   end Play;

   function Pop (The_Sound : out Sound_T) return Boolean is
   begin
      if S2_Wanted /= S2_Reported then
         S2_Reported := S2_Wanted;
         The_Sound := (if S2_Wanted then S2_Warning_Start
                       else S2_Warning_Stop);
         return True;
      end if;
      if Count = 0 then
         The_Sound := Click; -- defined, not meaningful
         return False;
      end if;
      The_Sound := Queue (Head);
      Head := Head + 1;
      Count := Count - 1;
      return True;
   end Pop;

end DMI_Sounds;
