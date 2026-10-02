--  ETCS on-board (EVC)
--  A SUBSET-076 test sequence in memory, body.

pragma Ada_2012;
with Scn_Reader; use Scn_Reader;

package body S076_Sequences is

   function To_Text (S : String) return Text_T is
      T : Text_T;
      N : constant Natural := Natural'Min (S'Length, Max_Line);
   begin
      T.S (1 .. N) := S (S'First .. S'First + N - 1);
      T.N := N;
      return T;
   end To_Text;

   function Cut (S : String; Max : Natural) return Text_T is
     (To_Text (S (S'First .. S'First + Natural'Min (S'Length, Max) - 1)));

   function Column (S : String) return Column_T is
      C : Column_T := (others => ' ');
      N : constant Natural := Natural'Min (S'Length, C'Length);
   begin
      C (1 .. N) := S (S'First .. S'First + N - 1);
      return C;
   end Column;

   --  A decimal natural of at most 9 digits; OK False otherwise
   function To_Nat (S : String; OK : out Boolean) return Natural is
      V : Natural := 0;
   begin
      OK := S'Length in 1 .. 9;
      for C of S loop
         if C not in '0' .. '9' then
            OK := False;
         end if;
         exit when not OK;
         V := V * 10 + (Character'Pos (C) - Character'Pos ('0'));
      end loop;
      return (if OK then V else 0);
   end To_Nat;

   --  "75.00" metres as cm; OK False when it is not a number
   function To_Cm (S : String; OK : out Boolean) return Integer_64 is
      R : Real;
   begin
      Scn_Reader.Valid := True;
      R := Scn_Reader.To_Real (S);
      OK := Scn_Reader.Valid and then abs R < 1.0E7;
      return (if OK then Integer_64 (R * 100.0) else 0);
   end To_Cm;

   procedure Hex_To_Bytes (Hex : String; T : in out Telegram_T;
                           OK : out Boolean) is
      function Nibble (C : Character) return Unsigned_8 is
        (case C is
            when '0' .. '9' =>
               Unsigned_8 (Character'Pos (C) - Character'Pos ('0')),
            when 'a' .. 'f' =>
               Unsigned_8 (Character'Pos (C) - Character'Pos ('a') + 10),
            when 'A' .. 'F' =>
               Unsigned_8 (Character'Pos (C) - Character'Pos ('A') + 10),
            when others => 16#FF#);
      Bytes : constant Natural := (Hex'Length + 1) / 2;
   begin
      OK := Hex'Length > 0 and then Bytes <= Max_Bytes;
      if not OK then
         return;
      end if;
      T.Data := (others => 0);
      for I in 0 .. Bytes - 1 loop
         declare
            Hi : constant Unsigned_8 := Nibble (Hex (Hex'First + 2 * I));
            Lo : constant Unsigned_8 :=
              (if Hex'First + 2 * I + 1 <= Hex'Last
               then Nibble (Hex (Hex'First + 2 * I + 1)) else 0);
         begin
            if Hi > 15 or else Lo > 15 then
               OK := False;
               return;
            end if;
            T.Data (1 + I) := Hi * 16 + Lo;
         end;
      end loop;
   end Hex_To_Bytes;

   --  The value of a "var" row: the digit groups up to the unit (b, d,
   --  h; none: decimal) or the "; comment"
   function Var_Value (L : Line_T; OK : out Boolean) return Unsigned_64 is
      Last : Natural := L.Count;
      Base : Unsigned_64 := 10;
      V    : Unsigned_64 := 0;
      N    : Natural := 0;
   begin
      for I in 4 .. L.Count loop
         if Word (L, I) = ";" then
            Last := I - 1;
            exit;
         end if;
      end loop;
      OK := Last >= 4;
      if not OK then
         return 0;
      end if;
      if Word (L, Last) = "b" then
         Base := 2;
         Last := Last - 1;
      elsif Word (L, Last) = "h" then
         Base := 16;
         Last := Last - 1;
      elsif Word (L, Last) = "d" then
         Last := Last - 1;
      end if;
      OK := Last >= 4;
      for I in 4 .. Last loop
         for C of Word (L, I) loop
            declare
               D : constant Integer :=
                 (case C is
                     when '0' .. '9' => Character'Pos (C) - Character'Pos ('0'),
                     when 'a' .. 'f' =>
                        Character'Pos (C) - Character'Pos ('a') + 10,
                     when 'A' .. 'F' =>
                        Character'Pos (C) - Character'Pos ('A') + 10,
                     when others => -1);
            begin
               if D < 0 or else Unsigned_64 (D) >= Base or else N >= 16 then
                  OK := False;
                  return 0;
               end if;
               V := V * Base + Unsigned_64 (D);
               N := N + 1;
            end;
         end loop;
      end loop;
      OK := OK and then N > 0;
      return V;
   end Var_Value;

   ---------------------------------------------------------------------

   Cur : access Sequence_T := Loaded'Access;
   --  the block the "var" rows belong to: 0 none, 1 a telegram (its
   --  index in Telegrams), 2 a message
   Block      : Natural := 0;
   Block_Step : Natural := 0;

   procedure On_Line (L : Line_T; Line_No : Positive) is
      S : Sequence_T renames Cur.all;
      K : constant String := Word (L, 1);
      OK : Boolean;
   begin
      if K /= "var" then
         Block := 0;
      end if;
      if K = "sequence" and then L.Count >= 2 then
         S.Name := To_Text (Word (L, 2));
      elsif K = "meta" then
         for I in 2 .. L.Count - 1 loop
            if Word (L, I) = "sv" then
               S.SV := To_Nat (Word (L, I + 1), OK);
            elsif Word (L, I) = "feature" then
               S.Feature := To_Text (Word (L, I + 1));
            end if;
         end loop;
      elsif K = "step" then
         if S.Step_Count = Max_Steps then
            S.Truncated := True;
            return;
         end if;
         S.Step_Count := S.Step_Count + 1;
         declare
            St : Step_T renames S.Steps (S.Step_Count);
            OK1, OK2, OK3 : Boolean;
         begin
            St := (others => <>);
            St.Line_No := Line_No;
            St.Number := To_Nat (Word (L, 2), OK1);
            St.Row := To_Nat (Word (L, 3), OK2);
            St.Dist_Cm := To_Cm (Word (L, 4), OK3);
            St.Well_Formed := L.Count = 10 and then OK1 and then OK3;
            if L.Count >= 10 then
               St.Lvl_Before := Column (Word (L, 5));
               St.Mode_Before := Column (Word (L, 6));
               St.IO := (if Word (L, 7) = "I" then Input
                         elsif Word (L, 7) = "O" then Output else Unknown);
               St.Interface_Name := Column (Word (L, 8));
               St.Lvl_After := Column (Word (L, 9));
               St.Mode_After := Column (Word (L, 10));
            end if;
            if St.IO = Unknown then
               St.Well_Formed := False;
            end if;
         end;
      elsif (K = "text:" or else K = "comment:") and then S.Step_Count > 0
      then
         if K = "text:" then
            S.Steps (S.Step_Count).Text := Cut (Rest (L, 2), Max_Text);
         else
            S.Steps (S.Step_Count).Comment := Cut (Rest (L, 2), Max_Text);
         end if;
      elsif (K = "input" or else K = "expect") and then S.Step_Count > 0
      then
         S.Steps (S.Step_Count).Line := To_Text (Rest (L, 1));
      elsif K = "telegram" then
         if S.Telegram_Count = Max_Telegrams then
            S.Truncated := True;
            return;
         end if;
         declare
            T   : Telegram_T;
            I   : Positive := 4;
            OK1 : Boolean;
         begin
            T.Step := To_Nat (Word (L, 2), OK1);
            T.Tag_Len := Natural'Min (Word (L, 3)'Length, T.Tag'Length);
            T.Tag (1 .. T.Tag_Len) :=
              Word (L, 3) (Word (L, 3)'First
                           .. Word (L, 3)'First + T.Tag_Len - 1);
            T.Loop_Tag := Word (L, 3) = "LOOP";
            T.Packet_Tag := Word (L, 3)'Length > 6
              and then Word (L, 3) (Word (L, 3)'First
                                    .. Word (L, 3)'First + 5) = "PACKET";
            --  k/n
            if Field (Word (L, I), 2, "/") /= "" then
               T.Part := To_Nat (Field (Word (L, I), 1, "/"), OK1);
               T.Parts := To_Nat (Field (Word (L, I), 2, "/"), OK1);
               I := I + 1;
            end if;
            T.Dist_Cm := To_Cm (Word (L, I), OK1);
            I := I + 1;
            if Word (L, I) = "rel" then
               T.Rel_Cm := To_Cm (Word (L, I + 1), OK1);
               I := I + 2;
            end if;
            if Word (L, I) = "bits" and then I + 2 <= L.Count then
               T.Bits := To_Nat (Word (L, I + 1), OK1);
               Hex_To_Bytes (Word (L, I + 2), T, OK);
               T.Has_Bits := OK1 and then OK
                 and then T.Bits in 210 | 830
                 and then (T.Bits + 7) / 8 <= (Word (L, I + 2)'Length + 1) / 2;
            end if;
            S.Telegram_Count := S.Telegram_Count + 1;
            S.Telegrams (S.Telegram_Count) := T;
            Block := 1;
            Block_Step := T.Step;
         end;
      elsif K = "message" then
         Block := 2;
         Block_Step := To_Nat (Word (L, 2), OK);
         if S.Message_Count = Max_Messages then
            S.Truncated := True;
            return;
         end if;
         S.Message_Count := S.Message_Count + 1;
         S.Messages (S.Message_Count) := (others => <>);
         S.Messages (S.Message_Count).Step := Block_Step;
         S.Messages (S.Message_Count).Dist_Cm := To_Cm (Word (L, 3), OK);
         for I in 4 .. L.Count - 1 loop
            if Word (L, I) = "nid" then
               S.Messages (S.Message_Count).NID :=
                 To_Nat (Word (L, I + 1), OK);
            end if;
         end loop;
      elsif K = "var" and then Block > 0 and then L.Count >= 4 then
         declare
            Name : constant String := Word (L, 2);
            V    : constant Unsigned_64 := Var_Value (L, OK);
         begin
            if OK and then Block = 1 and then Name = "M_VERSION"
              and then S.Telegram_Count > 0
            then
               S.Telegrams (S.Telegram_Count).M_Version := Integer (V mod 128);
            end if;
            if OK and then Block = 1 and then Name = "M_LEVELTEXTDISPLAY"
              and then V = 5 and then S.Telegram_Count > 0
            then
               S.Telegrams (S.Telegram_Count).Old_Level_Text := True;
            end if;
            if OK and then Block = 1 and then Name = "NID_PACKET"
              and then V < 255 and then S.Telegram_Count > 0
            then
               declare
                  T : Telegram_T renames S.Telegrams (S.Telegram_Count);
               begin
                  if T.Packet_Count < T.Packets'Length then
                     T.Packet_Count := T.Packet_Count + 1;
                     T.Packets (T.Packet_Count) := Unsigned_8 (V);
                  end if;
               end;
            end if;
            if OK and then Name'Length > 2
              and then Name (Name'First .. Name'First + 1) = "T_"
              and then S.Timer_Count < Max_Timers
            then
               S.Timer_Count := S.Timer_Count + 1;
               S.Timers (S.Timer_Count) :=
                 (Name => Column (Name), Name_Text => To_Text (Name),
                  Value => V, Step => Block_Step);
            end if;
         end;
      elsif K = "dmi" and then L.Count >= 3 then
         if S.DMI_Count = Max_DMI then
            return;
         end if;
         declare
            Line : constant String := Rest (L, 1);
            First_Bar, Second_Bar : Natural := 0;
         begin
            for I in Line'Range loop
               if Line (I) = '|' then
                  if First_Bar = 0 then
                     First_Bar := I;
                  elsif Second_Bar = 0 then
                     Second_Bar := I;
                  end if;
               end if;
            end loop;
            S.DMI_Count := S.DMI_Count + 1;
            S.DMI (S.DMI_Count) := (others => <>);
            S.DMI (S.DMI_Count).Step := To_Nat (Word (L, 2), OK);
            S.DMI (S.DMI_Count).Event := To_Nat (Word (L, 3), OK);
            if First_Bar > 0 and then Second_Bar > First_Bar then
               declare
                  D : constant String := Line (First_Bar + 1 .. Second_Bar - 1);
                  F : Natural := D'First;
                  T : Natural := D'Last;
               begin
                  while F <= T and then D (F) = ' ' loop
                     F := F + 1;
                  end loop;
                  while T >= F and then D (T) = ' ' loop
                     T := T - 1;
                  end loop;
                  S.DMI (S.DMI_Count).Data := To_Text (D (F .. T));
               end;
            end if;
         end;
      elsif K = "workbook" then
         S.Workbook := True;
      elsif K = "cell" and then L.Count >= 4 then
         declare
            OK1 : Boolean;
            V   : constant Natural := To_Nat (Word (L, L.Count), OK1);
            Ref : constant String := Word (L, L.Count - 1);
         begin
            if OK1 and then Ref = "(main)!D18" and then Word (L, 2) = "Train"
            then
               S.WB_Length := V;
            elsif OK1 and then Ref = "(lambda)!F2" then
               S.WB_Lambda := V;
            end if;
         end;
      elsif K = "chart" and then L.Count >= 2 and then Word (L, 2) = "speedprofile"
        and then S.Chart_Count = 0
      then
         for I in 3 .. L.Count loop
            exit when S.Chart_Count = Max_Points;
            declare
               W : constant String := Word (L, I);
            begin
               Scn_Reader.Valid := True;
               declare
                  X : constant Real := To_Real (Field (W, 1, ":"));
                  V : constant Real := To_Real (Field (W, 2, ":"));
               begin
                  if Scn_Reader.Valid then
                     S.Chart_Count := S.Chart_Count + 1;
                     S.Chart (S.Chart_Count) := (X, V);
                  end if;
               end;
            end;
         end loop;
      end if;
   exception
      when others =>
         null;
   end On_Line;

   procedure Read (Path : String; Ok : out Boolean) is
   begin
      Loaded.Name := (others => <>);
      Loaded.SV := 0;
      Loaded.Feature := (others => <>);
      Loaded.Step_Count := 0;
      Loaded.Telegram_Count := 0;
      Loaded.Message_Count := 0;
      Loaded.DMI_Count := 0;
      Loaded.Timer_Count := 0;
      Loaded.Chart_Count := 0;
      Loaded.Truncated := False;
      Loaded.Workbook := False;
      Loaded.WB_Length := 0;
      Loaded.WB_Lambda := 0;
      Cur := Loaded'Access;
      Block := 0;
      Scn_Reader.Read_File (Path, On_Line'Access, Ok);
   end Read;

   function DMI_Data (S : Sequence_T; Step : Natural) return String is
   begin
      for I in 1 .. S.DMI_Count loop
         if S.DMI (I).Step = Step then
            return Image (S.DMI (I).Data);
         end if;
      end loop;
      return "";
   end DMI_Data;

   function Chart_Speed (S : Sequence_T; X_M : Long_Float) return Long_Float
   is
   begin
      if S.Chart_Count = 0 then
         return -1.0;
      end if;
      if X_M <= S.Chart (1).X_M then
         return S.Chart (1).V_Kmh;
      end if;
      for I in 2 .. S.Chart_Count loop
         declare
            A : Point_T renames S.Chart (I - 1);
            B : Point_T renames S.Chart (I);
         begin
            if X_M <= B.X_M then
               if B.X_M - A.X_M < 0.001 then
                  return Long_Float'Max (A.V_Kmh, B.V_Kmh);
               end if;
               return A.V_Kmh
                 + (B.V_Kmh - A.V_Kmh) * (X_M - A.X_M) / (B.X_M - A.X_M);
            end if;
         end;
      end loop;
      return S.Chart (S.Chart_Count).V_Kmh;
   end Chart_Speed;

end S076_Sequences;
