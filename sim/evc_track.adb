--  ETCS DMI test simulator
--  Track lookups.

package body EVC_Track is

   function MRSP_At (Position_M : Natural) return Natural is
      Result : Natural := MRSP (MRSP'First).Speed;
   begin
      for Seg of MRSP loop
         if Position_M >= Seg.Start_M then
            Result := Seg.Speed;
         end if;
      end loop;
      return Result;
   end MRSP_At;

   function Gradient_At (Position_M : Natural) return Integer is
      Result : Integer := Gradients (Gradients'First).Value;
   begin
      for Seg of Gradients loop
         if Position_M >= Seg.Start_M then
            Result := Seg.Value;
         end if;
      end loop;
      return Result;
   end Gradient_At;

end EVC_Track;
