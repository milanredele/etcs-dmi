--  ETCS DMI test simulator
--  Train dynamics implementation.

package body EVC_Train is

   EB_Level : Float := 0.0;
   SB_Level : Float := 0.0;

   function EB_Effort return Float is (EB_Level);
   function SB_Effort return Float is (SB_Level);

   function Speed_KMH return Natural is
     (Natural (Speed_MS * 3.6));

   --  A brake effort towards 1.0 while commanded, towards 0.0 otherwise,
   --  at the rate of its build-up time
   procedure Build (Level : in out Float; On : Boolean;
                    Build_Up_S, Dt_S : Float) is
   begin
      if On then
         Level := Float'Min (1.0, Level + Dt_S / Build_Up_S);
      else
         Level := Float'Max (0.0, Level - Dt_S / Build_Up_S);
      end if;
   end Build;

   procedure Step (Dt_S : Float) is
      Accel : Float;
   begin
      if Brake_Commanded then
         Accel := -EVC_Brake_MS2;
      elsif Demand >= 0 then
         Accel := Float (Demand) / 100.0 * Max_Traction_MS2;
      else
         Accel := Float (Demand) / 100.0 * Max_Brake_MS2;
      end if;

      -- the train interface of the ETCS on-board; never used by the mock
      if EB_Commanded or else SB_Commanded or else Traction_Cut_Off
        or else EB_Level > 0.0 or else SB_Level > 0.0
      then
         Build (EB_Level, EB_Commanded, EB_Build_Up_S, Dt_S);
         Build (SB_Level, SB_Commanded, SB_Build_Up_S, Dt_S);
         if EB_Commanded or else SB_Commanded or else Traction_Cut_Off then
            Accel := Float'Min (Accel, 0.0);
         end if;
         Accel := Float'Min
           (Accel, -Float'Max (EB_Level * Emergency_Brake_MS2,
                               SB_Level * Service_Brake_MS2));
      end if;

      Speed_MS := Speed_MS + Accel * Dt_S;
      if Speed_MS < 0.0 then
         Speed_MS := 0.0;
      end if;
      Position_M := Position_M + Speed_MS * Dt_S;
   end Step;

   procedure Reset is
   begin
      Demand := 0;
      Brake_Commanded := False;
      Position_M := 0.0;
      Speed_MS := 0.0;
      EB_Commanded := False;
      SB_Commanded := False;
      Traction_Cut_Off := False;
      EB_Level := 0.0;
      SB_Level := 0.0;
   end Reset;

end EVC_Train;
