--  ETCS DMI
--  Grouping of numeric and alphanumeric data, DMI 5.1.5.

pragma Ada_2012;

package body DMI_Data_Format is

   Max_Group_Len : constant := 5; -- 5.1.5.1

   function Grouped (Data : Wide_String) return Grouped_T is
      Result : Grouped_T;
      Index  : Natural := Data'First;
   begin
      while Index <= Data'Last and then Result.Count < Max_Lines loop
         declare
            -- 5.1.5.2: a 'line break' every 8 characters
            Last  : constant Natural :=
              Natural'Min (Index + Max_Chars_Per_Line - 1, Data'Last);
            Taken : constant Natural := Last - Index + 1;
            Line  : Line_T;
         begin
            if Taken > Max_Group_Len then
               -- 5.1.5.1: a single 'space' creates 2 groups, neither
               -- longer than 5 characters. The specification fixes only
               -- that maximum, so the split is as even as possible
               -- (implementation choice); 8 characters become "1234
               -- 5678" as Figure 134 shows them.
               declare
                  First_Len : constant Natural := (Taken + 1) / 2;
               begin
                  Line.Length := Taken + 1;
                  Line.Text (1 .. First_Len) :=
                    Data (Index .. Index + First_Len - 1);
                  Line.Text (First_Len + 1) := ' ';
                  Line.Text (First_Len + 2 .. Line.Length) :=
                    Data (Index + First_Len .. Last);
               end;
            else
               Line.Length := Taken;
               Line.Text (1 .. Taken) := Data (Index .. Last);
            end if;
            Result.Count := Result.Count + 1;
            Result.Lines (Result.Count) := Line;
            Index := Last + 1;
         end;
      end loop;
      return Result;
   end Grouped;

end DMI_Data_Format;
