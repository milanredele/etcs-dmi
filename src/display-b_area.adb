pragma Ada_2012;
with Display.B_Area.Speed_Dial;
package body Display.B_Area is

   procedure Fill_Background is
   begin
      B_Buffer.Fill (General_Parameters.Background_Color);
   end Fill_Background;

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin
      Fill_Background;
      Speed_Dial.Draw;
   end Draw;


end Display.B_Area;
