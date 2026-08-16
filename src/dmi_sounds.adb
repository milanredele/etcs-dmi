--  ETCS DMI
--  Sound queue implementation.

package body DMI_Sounds is

   Queue_Size : constant := 8;
   type Queue_Index_T is mod Queue_Size;

   Queue : array (Queue_Index_T) of Sound_T;
   Head, Tail : Queue_Index_T := 0;
   Count : Natural := 0;

   S2_Active : Boolean := False;

   procedure Play (The_Sound : Sound_T) is
   begin
      -- S2 is continuous: suppress duplicate starts and stray stops
      case The_Sound is
         when S2_Warning_Start =>
            if S2_Active then
               return;
            end if;
            S2_Active := True;
         when S2_Warning_Stop =>
            if not S2_Active then
               return;
            end if;
            S2_Active := False;
         when others =>
            null;
      end case;

      if Count = Queue_Size then
         return; -- full; drop
      end if;
      Queue (Tail) := The_Sound;
      Tail := Tail + 1;
      Count := Count + 1;
   end Play;

   function Pop (The_Sound : out Sound_T) return Boolean is
   begin
      if Count = 0 then
         return False;
      end if;
      The_Sound := Queue (Head);
      Head := Head + 1;
      Count := Count - 1;
      return True;
   end Pop;

end DMI_Sounds;
