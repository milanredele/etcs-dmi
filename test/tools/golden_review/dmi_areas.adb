--  ETCS DMI
--  Helper for test/tools/golden_review.py: prints the DMI layout areas
--  (Display.ID_T, dmi/display.ads) one per line as
--
--      NAME PARENT X Y W H
--
--  X, Y, W, H are the area's absolute bounding box in screen pixels
--  (Display.Get_Area already resolves sub-areas to absolute coordinates).
--  PARENT is "-" for a main area (A, B, C, ... Y, Z) and the first
--  character of a sub-area's name otherwise (e.g. "B" for "B3"), which
--  is exactly the main area a sub-area nests in (Display's own naming
--  convention: every sub-area is named after its parent letter).
--
--  This program belongs to the review tool, not to the tree under
--  review: it is compiled against whichever revision's dmi/ sources are
--  being reviewed (test/tools/golden_review/dmi_areas.gpr, DMI_DIR),
--  including older revisions that do not carry this file themselves.

pragma Ada_2012;
with Ada.Text_IO; use Ada.Text_IO;
with Display;     use Display;

procedure Dmi_Areas is

   function Img (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      return S (S'First + 1 .. S'Last);
   end Img;

begin
   for ID in Display.ID_T loop
      declare
         A      : constant Area_T := Get_Area (ID);
         Name   : constant String := ID_T'Image (ID);
         Parent : constant String :=
           (if ID in Main_ID_T then "-" else Name (Name'First .. Name'First));
      begin
         Put_Line (Name & " " & Parent & " "
                   & Img (A.Position.X) & " " & Img (A.Position.Y) & " "
                   & Img (A.Width) & " " & Img (A.Height));
      end;
   end loop;
end Dmi_Areas;
