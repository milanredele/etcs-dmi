pragma Ada_2012;
package body Display.B_Area.Speed_Dial is

   function Speed_To_Angle (Speed : Speed_T) return Angle
   is
      subtype Max_Speed_T is Speed_T range 140.0 .. 400.0;

      function Linear_Scale (Max : Max_Speed_T) return Angle is
         ((Upper_Limit - Lower_Limit) * Angle (Speed / Max));
   begin
      case General_Parameters.Speed_Dial_Range is
         when General_Parameters.Range_140 =>
            -- DMI 8.2.1.1.14.2
            return Linear_Scale (140.0);
         when General_Parameters.Range_180 =>
            -- DMI 8.2.1.1.13.2
            return Linear_Scale (180.0);
         when General_Parameters.Range_250 =>
            -- DMI 8.2.1.1.12.2
            return Linear_Scale (250.0);
         when General_Parameters.Range_400 =>
            -- DMI 8.2.1.1.11.2
            if Speed < 200.0 then
               return (Threshold_200 - Lower_Limit) * Angle (Speed / 200.0);
            else
               return (Upper_Limit - Threshold_200) * Angle ((Speed - 200.0) / 200.0);
            end if;
      end case;
   end Speed_To_Angle;

   procedure Draw_Speed_Indicator_Lines is
      Max : Natural := General_Parameters.Max_Speed_Map (General_Parameters.Speed_Dial_Range);
   begin
      null;
   end Draw_Speed_Indicator_Lines;

   ----------
   -- Draw --
   ----------

   procedure Draw (Stream : not null access Ada.Streams.Root_Stream_Type'Class)
   is

      procedure Draw_Dial_140 is
      begin
         null;
      end Draw_Dial_140;
   begin

      case General_Parameters.Speed_Dial_Range is
         when General_Parameters.Range_140 =>
            Draw_Dial_140;
         when others =>
            raise Program_Error with "Not implemented";
      end case;
   end Draw;

end Display.B_Area.Speed_Dial;
