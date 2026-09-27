--  ETCS DMI
--  The operated system version implementation.

package body DMI_System_Version is

   procedure Set (New_X, New_Y : Natural) is
   begin
      if New_X in X_T and then New_Y in Y_T then
         Known := True;
         X := New_X;
         Y := New_Y;
      else
         Reset;
      end if;
   end Set;

   function Image return Wide_String is
      X_Img : constant Wide_String := Natural'Wide_Image (X);
      Y_Img : constant Wide_String := Natural'Wide_Image (Y);
   begin
      if not Known then
         return "";
      end if;
      return X_Img (2 .. X_Img'Last) & "." & Y_Img (2 .. Y_Img'Last);
   end Image;

   procedure Reset is
   begin
      Known := False;
      X := 0;
      Y := 0;
   end Reset;

end DMI_System_Version;
