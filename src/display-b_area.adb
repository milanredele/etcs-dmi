pragma Ada_2012;
package body Display.B_Area is

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin

      raise Program_Error with "Unimplemented procedure Draw";
   end Draw;

   ---------------
   -- Set_Speed --
   ---------------

   procedure Set_Speed (Speed : Speed_Params) is
   begin
      The_Speed := Speed;
   end Set_Speed;

end Display.B_Area;
