--  ETCS on-board (EVC)
--  Generic reader of the line oriented .scn scenario files, body.

pragma Ada_2012;
with Ada.Directories;
with Ada.Text_IO; use Ada.Text_IO;

package body Scn_Reader is

   -----------
   -- Split --
   -----------

   procedure Split (L : in out Line_T) is
      I : Natural := L.Text'First;
   begin
      L.Count := 0;
      while I <= L.Text'Last loop
         while I <= L.Text'Last and then L.Text (I) = ' ' loop
            I := I + 1;
         end loop;
         exit when I > L.Text'Last;
         declare
            J : Natural := I;
         begin
            while J <= L.Text'Last and then L.Text (J) /= ' ' loop
               J := J + 1;
            end loop;
            if L.Count < Max_Words then
               L.Count := L.Count + 1;
               L.W (L.Count) := (I, J - 1);
            end if;
            I := J;
         end;
      end loop;
   end Split;

   ----------
   -- Word --
   ----------

   function Word (L : Line_T; K : Positive) return String is
     (if K <= L.Count then L.Text (L.W (K).First .. L.W (K).Last) else "");

   ----------
   -- Rest --
   ----------

   function Rest (L : Line_T; K : Positive) return String is
     (if K <= L.Count then L.Text (L.W (K).First .. L.Text'Last) else "");

   -----------
   -- Field --
   -----------

   function Field (S : String; K : Positive; Delims : String := ":=@+")
     return String
   is
      N     : Natural := 1;
      First : Natural := S'First;
   begin
      for I in S'Range loop
         declare
            Is_Delim : Boolean := False;
         begin
            for D of Delims loop
               if S (I) = D then
                  Is_Delim := True;
               end if;
            end loop;
            if Is_Delim then
               if N = K then
                  return S (First .. I - 1);
               end if;
               N := N + 1;
               First := I + 1;
            end if;
         end;
      end loop;
      return (if N = K then S (First .. S'Last) else "");
   end Field;

   -------------
   -- To_Real --
   -------------

   function To_Real (S : String) return Real is
   begin
      if S = "inf" then
         return Real'Last;
      elsif S'Length = 0 or else S'Length > 40 then
         Valid := False;
         return 0.0;
      end if;
      for C of S loop
         if not (C in '0' .. '9' | '.' | '-' | '+' | 'e' | 'E') then
            Valid := False;
            return 0.0;
         end if;
      end loop;
      declare
         R : constant Real := Real'Value (S);
      begin
         if R'Valid and then abs R < 1.0E12 then
            return R;
         end if;
         Valid := False;
         return 0.0;
      end;
   exception
      when others =>
         Valid := False;
         return 0.0;
   end To_Real;

   ---------------
   -- Read_File --
   ---------------

   procedure Read_File
     (Path    : String;
      Handler : not null access procedure (L : Line_T; Line_No : Positive);
      Ok      : out Boolean)
   is
      F       : File_Type;
      Line_No : Natural := 0;
   begin
      Ok := True;
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Line_No := Line_No + 1;
         declare
            Text : constant String := Get_Line (F);
            L    : Line_T (Text'Length);
         begin
            L.Text := Text;
            Split (L);
            if L.Count > 0 and then Word (L, 1) /= "#" then
               Handler (L, Line_No);
            end if;
         end;
      end loop;
      Close (F);
   exception
      when others =>
         Ok := False;
         if Is_Open (F) then
            Close (F);
         end if;
   end Read_File;

   ---------------------
   -- List_Scn_Files --
   ---------------------

   procedure List_Scn_Files
     (Dir     : String;
      Recurse : Boolean;
      Paths   : out Paths_T;
      Count   : out Natural)
   is
      use Ada.Directories;

      procedure Walk (D : String) is
         Search : Search_Type;
         Item   : Directory_Entry_Type;
      begin
         Start_Search (Search, D, "*.scn",
                       (Ordinary_File => True, others => False));
         while More_Entries (Search) loop
            Get_Next_Entry (Search, Item);
            declare
               N : constant String := Full_Name (Item);
            begin
               if Count < Max_Files and then N'Length <= Max_Path then
                  Count := Count + 1;
                  Paths (Count).S (1 .. N'Length) := N;
                  Paths (Count).N := N'Length;
               end if;
            end;
         end loop;
         End_Search (Search);

         if Recurse then
            Start_Search (Search, D, "*",
                          (Directory => True, others => False));
            while More_Entries (Search) loop
               Get_Next_Entry (Search, Item);
               declare
                  Name : constant String := Simple_Name (Item);
               begin
                  if Name /= "." and then Name /= ".." then
                     Walk (Full_Name (Item));
                  end if;
               end;
            end loop;
            End_Search (Search);
         end if;
      end Walk;
   begin
      Count := 0;
      if Exists (Dir) and then Kind (Dir) = Directory then
         Walk (Dir);
      end if;
      --  sorted, for a stable order
      for I in 2 .. Count loop
         for J in reverse 2 .. I loop
            exit when Paths (J - 1).S (1 .. Paths (J - 1).N)
                      <= Paths (J).S (1 .. Paths (J).N);
            declare
               T : constant Path_T := Paths (J);
            begin
               Paths (J) := Paths (J - 1);
               Paths (J - 1) := T;
            end;
         end loop;
      end loop;
   exception
      when others =>
         Count := 0;
   end List_Scn_Files;

end Scn_Reader;
