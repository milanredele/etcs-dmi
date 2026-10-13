--  ETCS on-board (EVC)
--  A SUBSET-076 test sequence in memory, body.

pragma Ada_2012;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;
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

   procedure Hex_To_Bytes (Hex : String; Data : out Byte_Array;
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
      Data := (others => 0);
      OK := Hex'Length > 0 and then Bytes <= Data'Length;
      if not OK then
         return;
      end if;
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
            Data (Data'First + I) := Hi * 16 + Lo;
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

   --  A "limit" name or a "curve-columns" header without its '-'
   --  ("EBI-(m)" of the Gamma sheet and "EBI(m)" of the Lambda sheet)
   function Squeeze (S : String) return String is
      R : String (1 .. S'Length);
      N : Natural := 0;
   begin
      for C of S loop
         if C /= '-' then
            N := N + 1;
            R (N) := C;
         end if;
      end loop;
      return R (1 .. N);
   end Squeeze;

   function Limit_Key (N : Limit_Name_T) return String is
     (case N is
         when Initial_Speed => "Initialspeed",
         when Perturbation  => "Perturbation",
         when Indication    => "Indication",
         when Permitted     => "Permitted",
         when Warning       => "Warning",
         when SBI           => "SBI",
         when EBI           => "EBI",
         when Start_RSM     => "StartRSM",
         when Release_Speed => "Releasespeed");

   function Column_Key (C : Curve_Column_T) return String is
     (case C is
         when EBD         => "EBD(m)",
         when SBD         => "SBD(m)",
         when EBI         => "EBI(m)",
         when SBI1        => "SBI1(m)",
         when SBI2        => "SBI2(m)",
         when SBI         => "SBI(m)",
         when Warning     => "Warning(m)",
         when Permitted   => "Permitted(m)",
         when Indication  => "Indication(m)",
         when GUI_EOA     => "GUIEOA(m)",
         when EBI_Release => "EBIforreleasespeed(m)");

   --  The column of a "curve-columns" header, -1 when not taken
   function Column_Of (Header : String) return Integer is
      H : constant String := Squeeze (Header);
   begin
      for C in Curve_Column_T loop
         if H = Column_Key (C) then
            return Curve_Column_T'Pos (C);
         end if;
      end loop;
      return -1;
   end Column_Of;

   --  A value of a "limit" or "curve" line; "-" (none) is No_Value
   function Curve_Value (W : String) return Long_Float is
   begin
      if W = "-" then
         return No_Value;
      end if;
      Scn_Reader.Valid := True;
      declare
         V : constant Real := To_Real (W);
      begin
         return (if Scn_Reader.Valid then Long_Float (V) else No_Value);
      end;
   end Curve_Value;

   ---------------------------------------------------------------------

   Cur : access Sequence_T := Loaded'Access;
   --  the block the "var" rows belong to: 0 none, 1 a telegram (its
   --  index in Telegrams), 2 a message
   Block      : Natural := 0;
   Block_Step : Natural := 0;
   --  the bit of the next "var" row of a message block
   Var_Bit    : Natural := 0;
   --  the rows of the labels of the workbook's train
   Length_Row, Brake_Row : Text_T;
   --  the workbook of the lines read, its open "curves" block (0 none)
   --  and the column of each word of its "curve" lines (-1 not taken)
   Workbook_Name : Text_T;
   Curve_Set     : Natural := 0;
   Max_Curve_Words : constant := 32;
   Curve_Map : array (1 .. Max_Curve_Words) of Integer := (others => -1);
   --  B200: the target speed and the flatness of the open workbook
   --  (its cells come before its "curves" blocks)
   WB_Target : Long_Float := No_Value;
   WB_Flat   : Boolean := True;
   WB_Grades : Grades_T;
   --  B290, B291: the factor sheet and option buttons of the open
   --  workbook
   WB_Cells  : Sheet_T;
   --  B200: in a packet 3 (its rows), and the speed (km/h) or length (m)
   --  step of the factor row that follows; Natural'Last skips the rows
   --  of the passenger set
   In_P3  : Boolean := False;
   K_From : Natural := 0;
   --  B280: the NID_C of the header of the telegram read last
   Group_Country : Natural := 0;

   --  B200: a "var" row of a telegram or message: the integrated
   --  correction factors of its packets 3 (7.5.1 resolutions: M_NVKVINT
   --  0.02, M_NVKRINT and M_NVKTINT 0.05, V_NVKVINT 5 km/h, L_NVKRINT
   --  25 m)
   procedure On_Packet_3 (S : in out Sequence_T; Name : String;
                          V : Unsigned_64)
   is
      N : constant Natural := Natural (V mod 2 ** 16);
   begin
      if Name = "V_RELEASEDP" and then N < 126
        and then S.Release_DP_Count < Max_K_Steps
      then
         S.Release_DP_Count := S.Release_DP_Count + 1;
         S.Release_DP (S.Release_DP_Count) := (N * 5, 0.0);
         return;
      end if;
      if Name = "V_RELEASEDP" and then N = 126 then
         S.Release_OB := True;
         return;
      end if;
      if Name = "NID_PACKET" then
         In_P3 := V = 3 and then S.P3_Count < Max_P3;
         if In_P3 then
            S.P3_Count := S.P3_Count + 1;
            S.P3 (S.P3_Count) := (others => <>);
            S.P3 (S.P3_Count).Group_Country :=
              (if Block = 1 then Group_Country else 0);
            K_From := 0;
         end if;
         return;
      elsif Name = "NID_C" and then Block = 1 and then S.Telegram_Count > 0
        and then S.Telegrams (S.Telegram_Count).Packet_Count = 0
      then
         --  the telegram header's NID_C, before its first packet
         Group_Country := N;
         return;
      elsif not In_P3 then
         return;
      end if;
      if Name = "NID_C" and then S.P3 (S.P3_Count).Country = 0 then
         S.P3 (S.P3_Count).Country := N;
      end if;
      declare
         F : Factors_T renames S.P3 (S.P3_Count);
      begin
         if Name = "Q_NVKINT" then
            F.Given := V = 1;
         elsif Name = "Q_NVKVINTSET" then
            K_From := (if V = 0 then 0 else Natural'Last);
         elsif Name = "V_NVKVINT" and then K_From /= Natural'Last then
            K_From := N * 5;
         elsif Name = "M_NVKVINT" and then K_From /= Natural'Last
           and then F.Kv_Count < Max_K_Steps
         then
            F.Kv_Count := F.Kv_Count + 1;
            F.Kv (F.Kv_Count) := (K_From, Long_Float (N) * 0.02);
         elsif Name = "L_NVKRINT" then
            K_From := N * 25;
         elsif Name = "M_NVKRINT" and then F.Kr_Count < Max_K_Steps then
            --  the first factor counts from 0 m
            F.Kr_Count := F.Kr_Count + 1;
            F.Kr (F.Kr_Count) :=
              ((if F.Kr_Count = 1 then 0 else K_From), Long_Float (N) * 0.05);
         elsif Name = "M_NVKTINT" then
            F.Kt := Long_Float (N) * 0.05;
         end if;
      end;
   end On_Packet_3;

   --  A "curves", "limit", "curve-columns" or "curve" line of a workbook
   procedure On_Curve_Line (S : in out Sequence_T; L : Line_T) is
      K : constant String := Word (L, 1);
   begin
      if K = "curves" then
         Curve_Set := 0;
         if S.Curve_Count < Max_Curve_Sets then
            S.Curve_Count := S.Curve_Count + 1;
            Curve_Set := S.Curve_Count;
            S.Curves (Curve_Set).Workbook := Workbook_Name;
            S.Curves (Curve_Set).Sheet := To_Text (Rest (L, 2));
            S.Curves (Curve_Set).Limits := (others => No_Value);
            S.Curves (Curve_Set).Row_Count := 0;
            S.Curves (Curve_Set).From_Twin := False;
            S.Curves (Curve_Set).Twin := (others => <>);
            S.Curves (Curve_Set).Target_Kmh := WB_Target;
            S.Curves (Curve_Set).Flat := WB_Flat;
            S.Curves (Curve_Set).Grades := WB_Grades;
            S.Curves (Curve_Set).Cells := WB_Cells;
            Curve_Map := (others => -1);
         end if;
      elsif Curve_Set = 0 or else L.Count < 2 then
         null;
      elsif K = "curves-from" then
         S.Curves (Curve_Set).From_Twin := True;
         S.Curves (Curve_Set).Twin := To_Text (Rest (L, 2));
      elsif K = "limit" and then L.Count >= 3 then
         for N in Limit_Name_T loop
            if Squeeze (Word (L, 2)) = Limit_Key (N) then
               S.Curves (Curve_Set).Limits (N) := Curve_Value (Word (L, 3));
            end if;
         end loop;
      elsif K = "curve-columns" then
         --  word 2 names the speed, the distances from word 3 on
         for I in 3 .. Integer'Min (L.Count, Max_Curve_Words) loop
            Curve_Map (I) := Column_Of (Word (L, I));
         end loop;
      elsif K = "curve" then
         declare
            C : Curve_Set_T renames S.Curves (Curve_Set);
            V : constant Long_Float := Curve_Value (Word (L, 2));
         begin
            if V /= No_Value and then C.Row_Count < Max_Curve_Rows then
               C.Row_Count := C.Row_Count + 1;
               C.Rows (C.Row_Count) :=
                 (Speed_Kmh => V, D => (others => No_Value));
               for I in 3 .. Integer'Min (L.Count, Max_Curve_Words) loop
                  if Curve_Map (I) >= 0 then
                     C.Rows (C.Row_Count).D
                       (Curve_Column_T'Val (Curve_Map (I))) :=
                       Curve_Value (Word (L, I));
                  end if;
               end loop;
            end if;
         end;
      end if;
   end On_Curve_Line;

   --  B290: a cell of the sheet "Integrated correction factors" (Ref
   --  "factors!B5"): the step tables (freight A5:B14, passenger sets a /
   --  interpolated / b D5:E14, D18:E27, D31:E40, Kr_int A32:B41) and
   --  A_NVP12 D44, A_NVP23 F44, Kt_int D47; labels are skipped
   procedure On_Factor_Cell (Ref, Value : String) is
      P   : constant Natural := Ada.Strings.Fixed.Index (Ref, "!");
      OK1 : Boolean := False;
      Row : Natural := 0;
      Col : Character := ' ';
      V   : constant Long_Float := Curve_Value (Value);
   begin
      if P = 0 or else P + 2 > Ref'Last
        or else Ref (Ref'First .. P) /= "factors!"
      then
         return;
      end if;
      WB_Cells.Present := True;
      Col := Ref (P + 1);
      Row := To_Nat (Ref (P + 2 .. Ref'Last), OK1);
      if not OK1 or else V = No_Value then
         return;
      end if;
      declare
         procedure Put (T : Sheet_Tables_T; First : Natural; Is_X : Boolean)
         is
         begin
            if Row in First .. First + 9 then
               if Is_X then
                  WB_Cells.Tables (T) (Row - First + 1).X := V;
               else
                  WB_Cells.Tables (T) (Row - First + 1).K := V;
               end if;
            end if;
         end Put;
      begin
         case Col is
            when 'A' | 'B' =>
               Put (Kv_Freight, 5, Col = 'A');
               Put (Kr, 32, Col = 'A');
            when 'D' | 'E' =>
               Put (Kv_A, 5, Col = 'D');
               Put (Kv_Interpolated, 18, Col = 'D');
               Put (Kv_B, 31, Col = 'D');
               if Col = 'D' and then Row = 44 then
                  WB_Cells.A_NVP12 := V;
               elsif Col = 'D' and then Row = 47 then
                  WB_Cells.Kt_Int := V;
               end if;
            when 'F' =>
               if Row = 44 then
                  WB_Cells.A_NVP23 := V;
               end if;
            when others =>
               null;
         end case;
      end;
   end On_Factor_Cell;

   --  B290, B291: an option button of the tool, "<sheet>!<name>" (the
   --  Train (main) sheet's with "Train " before); True when taken
   function On_Control (Name : String; Set : Boolean) return Boolean is
      C : Sheet_T renames WB_Cells;
   begin
      if Name = "Train (main)!Freight_G" then
         C.Train_Type := (if Set then Freight_G else C.Train_Type);
      elsif Name = "Train (main)!Freight_P" then
         C.Train_Type := (if Set then Freight_P else C.Train_Type);
      elsif Name = "Train (main)!Passenger_P" then
         C.Train_Type := (if Set then Passenger_P else C.Train_Type);
      elsif Name = "Train (main)!Gamma" then
         C.Gamma := (if Set then First else C.Gamma);
      elsif Name = "Train (main)!Lambda" then
         C.Gamma := (if Set then Second else C.Gamma);
      elsif Name = "Track!EoA_SvL" then
         C.Target := (if Set then First else C.Target);
      elsif Name = "Track!LoA_MRSP" then
         C.Target := (if Set then Second else C.Target);
      elsif Name = "Track!Release_speed_fixed" then
         C.Release := (if Set then First else C.Release);
      elsif Name = "Track!Release_speed_OB" then
         C.Release := (if Set then Second else C.Release);
      else
         return False;
      end if;
      return True;
   end On_Control;

   --  B160: the families of the drawings (see Calibrated): the zero
   --  drawn and the middle of the scales that fit every chart of the
   --  family in the SV30 corpus
   type Family_T is record
      Zero, Scale : Long_Float;
   end record;
   Families : constant array (1 .. 8) of Family_T :=
     ((-1.9, 0.9585), (-1.8, 0.9675), (0.3, 1.078), (-0.6, 0.986),
      (0.9, 1.0065), (0.5, 1.0815), (0.4, 1.0805), (-1.2, 0.9755));

   function Family_Scale (Zero : Long_Float) return Long_Float is
   begin
      for F of Families loop
         if abs (F.Zero - Zero) < 0.05 then
            return F.Scale;
         end if;
      end loop;
      return 0.0;
   end Family_Scale;

   --  the distance of D km/h scaled by K to the nearest multiple of 5
   function Off_Grid (D, K : Long_Float) return Long_Float is
     (abs (D * K - 5.0 * Long_Float'Rounding (D * K / 5.0)));

   --  B160: the "mrsp" chart line: the zero and the plateaus, then the
   --  scale of Calibrated
   procedure On_Mrsp_Chart (S : in out Sequence_T; L : Line_T) is
      Max_Plateaus : constant := 16;
      P : array (1 .. Max_Plateaus) of Long_Float := (others => 0.0);
      N, Count : Natural := 0;
      Zero, Prev_X, Prev_V : Long_Float := 0.0;
      Lo, Hi : array (1 .. 8) of Long_Float := (others => 0.0);
      NI, Chosen : Natural := 0;
      K : Long_Float;
   begin
      for I in 3 .. L.Count loop
         Scn_Reader.Valid := True;
         declare
            W : constant String := Word (L, I);
            X : constant Real := To_Real (Field (W, 1, ":"));
            V : constant Real := To_Real (Field (W, 2, ":"));
         begin
            if Scn_Reader.Valid then
               Count := Count + 1;
               if Count = 1 then
                  Zero := V;
               elsif X > Prev_X and then abs (V - Prev_V) < 0.001
                 and then V - Zero > 3.0 and then N < Max_Plateaus
                 and then (for all J in 1 .. N =>
                             abs (P (J) - (V - Zero)) > 0.001)
               then
                  N := N + 1;
                  P (N) := V - Zero;
               end if;
               Prev_X := X;
               Prev_V := V;
            end if;
         end;
      end loop;
      --  S076_RAW_CHART=1: the charts as drawn (for comparison)
      if Count = 0 or else Ada.Environment_Variables.Exists ("S076_RAW_CHART")
      then
         return;
      end if;
      for I in 0 .. 400 loop
         K := 0.90 + Long_Float (I) * 0.0005;
         if N > 0 and then (for all J in 1 .. N => Off_Grid (P (J), K) <= 0.5)
         then
            if NI > 0 and then Hi (NI) >= K - 0.0006 then
               Hi (NI) := K;
            elsif NI < Lo'Last then
               NI := NI + 1;
               Lo (NI) := K;
               Hi (NI) := K;
            end if;
         end if;
      end loop;
      for I in 1 .. NI loop
         if Family_Scale (Zero) in Lo (I) - 0.0005 .. Hi (I) + 0.0005
           or else NI = 1
         then
            Chosen := I;
         end if;
      end loop;
      if Chosen = 0 and then NI > 0 then
         Chosen := 1;
         for I in 2 .. NI loop
            if abs (1.0 - (Lo (I) + Hi (I)) / 2.0)
              < abs (1.0 - (Lo (Chosen) + Hi (Chosen)) / 2.0)
            then
               Chosen := I;
            end if;
         end loop;
      end if;
      if Chosen > 0 then
         declare
            K0 : constant Long_Float := (Lo (Chosen) + Hi (Chosen)) / 2.0;
            Num, Den : Long_Float := 0.0;
         begin
            for J in 1 .. N loop
               Num := Num + 5.0 * Long_Float'Rounding (P (J) * K0 / 5.0) * P (J);
               Den := Den + P (J) * P (J);
            end loop;
            K := Long_Float'Min (Hi (Chosen),
                                 Long_Float'Max (Lo (Chosen), Num / Den));
         end;
      elsif Family_Scale (Zero) > 0.0 then
         K := Family_Scale (Zero);
      else
         return;
      end if;
      S.Chart_Zero := Zero;
      S.Chart_Scale := K;
   end On_Mrsp_Chart;

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
               Hex_To_Bytes (Word (L, I + 2), T.Data, OK);
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
         declare
            M : Message_T renames S.Messages (S.Message_Count);
            OK1 : Boolean;
         begin
            for I in 4 .. L.Count - 1 loop
               if Word (L, I) = "nid" then
                  M.NID := To_Nat (Word (L, I + 1), OK);
               elsif Word (L, I) = "bits" and then I + 2 <= L.Count then
                  M.Bits := To_Nat (Word (L, I + 1), OK1);
                  Hex_To_Bytes (Word (L, I + 2), M.Data, OK);
                  M.Has_Bits := OK1 and then OK and then M.Bits > 0
                    and then (M.Bits + 7) / 8
                             <= (Word (L, I + 2)'Length + 1) / 2;
               end if;
            end loop;
         end;
         Var_Bit := 0;
      elsif K = "var" and then Block > 0 and then L.Count >= 4 then
         declare
            Name : constant String := Word (L, 2);
            V    : constant Unsigned_64 := Var_Value (L, OK);
         begin
            if Block = 2 and then S.Message_Count > 0 then
               declare
                  M : Message_T renames S.Messages (S.Message_Count);
                  OK_W  : Boolean;
                  Width : constant Natural := To_Nat (Word (L, 3), OK_W);
               begin
                  if Name = "T_TRAIN" and then M.T_Train_Count < 4 then
                     M.T_Train_Count := M.T_Train_Count + 1;
                     M.T_Train_At (M.T_Train_Count) := Var_Bit;
                  end if;
                  if Name = "NID_PACKET" and then V < 255
                    and then M.Packet_Count < M.Packets'Length
                  then
                     M.Packet_Count := M.Packet_Count + 1;
                     M.Packets (M.Packet_Count) := Unsigned_8 (V mod 256);
                  end if;
                  Var_Bit := Var_Bit + Width;
               end;
            end if;
            if OK then
               On_Packet_3 (S, Name, V);
            end if;
            if OK and then Block = 1 and then Name = "M_VERSION"
              and then S.Telegram_Count > 0
            then
               S.Telegrams (S.Telegram_Count).M_Version := Integer (V mod 128);
            end if;
            if OK and then Block = 1 and then Name = "M_LEVELTR"
              and then V = 4 and then S.Telegram_Count > 0
            then
               S.Telegrams (S.Telegram_Count).Level_3 := True;
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
              and then (Name (Name'First .. Name'First + 1) = "T_"
                        or else (Name'Length > 4
                                 and then Name (Name'First .. Name'First + 3)
                                          = "V_NV"))
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
         Workbook_Name := To_Text (Rest (L, 2));
         Curve_Set := 0;
         WB_Target := No_Value;
         WB_Flat := True;
         WB_Grades := (others => <>);
         WB_Cells := (others => <>);
      elsif K = "cell" and then L.Count = 5 and then Word (L, 2) = "Integrated"
        and then Word (L, 3) = "correction"
      then
         On_Factor_Cell (Word (L, 4), Word (L, 5));
      elsif K = "cell" and then L.Count = 3 and then Word (L, 3) in "0" | "1"
        and then On_Control (Word (L, 2), Word (L, 3) = "1")
      then
         null;
      elsif K = "cell" and then L.Count = 4 and then Word (L, 2) = "Train"
        and then Word (L, 4) in "0" | "1"
        and then On_Control ("Train " & Word (L, 3), Word (L, 4) = "1")
      then
         null;
      elsif K = "curves" or else K = "curves-from" or else K = "limit"
        or else K = "curve-columns" or else K = "curve"
      then
         On_Curve_Line (S, L);
      elsif K = "cell" and then L.Count >= 4 and then Word (L, 2) = "Train"
        and then Word (L, 3)'Length > 8
        and then Word (L, 3) (Word (L, 3)'First .. Word (L, 3)'First + 6)
                 = "(main)!"
      then
         --  the Train (main) sheet: a label in column C, its value in
         --  column D of the same row (the rows come in order)
         declare
            Ref  : constant String := Word (L, 3);
            Col  : constant Character := Ref (Ref'First + 7);
            Row  : constant String := Ref (Ref'First + 8 .. Ref'Last);
            Text : constant String := Rest (L, 4);
            OK1  : Boolean;
         begin
            if Col = 'C' and then Text = "Train length (m)" then
               Length_Row := To_Text (Row);
            elsif Col = 'C' and then Text = "Current brake position:" then
               Brake_Row := To_Text (Row);
            elsif Col = 'D' and then Row = Image (Length_Row) then
               S.WB_Length := To_Nat (Word (L, 4), OK1);
            elsif Col = 'D' and then Row = Image (Brake_Row) then
               S.WB_Brake_Position :=
                 (if Text = "Passenger in P" then 1
                  elsif Text = "Freight in P" then 2
                  elsif Text = "Freight in G" then 3 else 0);
            end if;
         end;
      elsif K = "cell" and then L.Count >= 3 then
         declare
            OK1 : Boolean;
            V   : constant Natural := To_Nat (Word (L, L.Count), OK1);
         begin
            if OK1 and then Word (L, L.Count - 1) = "(lambda)!F2" then
               S.WB_Lambda := V;
            elsif OK1 and then Word (L, L.Count - 1) = "(lambda)!F3" then
               S.WB_Lambda_EB := V;
            elsif L.Count = 3 and then Word (L, 2) = "Track!B2" then
               WB_Target := Curve_Value (Word (L, 3));
            elsif L.Count = 3 and then Word (L, 2) = "Track!E2" then
               WB_Cells.Release_Kmh := Curve_Value (Word (L, 3));
            elsif L.Count = 3 and then Word (L, 2) = "Track!B3"
              and then Curve_Value (Word (L, 3)) /= No_Value
            then
               WB_Grades.Target_M := Curve_Value (Word (L, 3));
            elsif L.Count = 3 and then Word (L, 2)'Length > 7
              and then Word (L, 2) (Word (L, 2)'First .. Word (L, 2)'First + 6)
                       in "Track!I" | "Track!J"
              and then Word (L, 2) (Word (L, 2)'First + 7 .. Word (L, 2)'Last)
                       not in "1" | "2"
              and then Curve_Value (Word (L, 3)) /= No_Value
            then
               --  B370: the gradient profile's boundaries and gradients,
               --  in the order of the rows
               declare
                  G : Grades_T renames WB_Grades;
                  X : constant Long_Float := Curve_Value (Word (L, 3));
               begin
                  if Word (L, 2) (Word (L, 2)'First + 6) = 'I' then
                     if G.Bound_Count < Max_Grades then
                        G.Bound_Count := G.Bound_Count + 1;
                        G.Bounds (G.Bound_Count) := X;
                     end if;
                  elsif G.Grade_Count < Max_Grades then
                     G.Grade_Count := G.Grade_Count + 1;
                     G.Permil (G.Grade_Count) := X;
                  end if;
               end;
               if Word (L, 2) (Word (L, 2)'First + 6) = 'J'
                 and then Curve_Value (Word (L, 3)) /= 0.0
               then
                  --  a gradient value of the profile other than 0
                  WB_Flat := False;
               end if;
            elsif L.Count = 3 and then Word (L, 2)'Length > 7
              and then Word (L, 2) (Word (L, 2)'First .. Word (L, 2)'First + 6)
                       = "Track!J"
              and then Curve_Value (Word (L, 3)) not in No_Value | 0.0
            then
               --  a gradient value of the profile other than 0
               WB_Flat := False;
            end if;
         end;
      elsif K = "chart" and then L.Count >= 2
        and then Word (L, 2) = "speedprofile-reverse"
        and then S.Rev_Count = 0
      then
         for I in reverse 3 .. L.Count loop
            exit when S.Rev_Count = Max_Points;
            Scn_Reader.Valid := True;
            declare
               W : constant String := Word (L, I);
               X : constant Real := To_Real (Field (W, 1, ":"));
               V : constant Real := To_Real (Field (W, 2, ":"));
            begin
               if Scn_Reader.Valid then
                  S.Rev_Count := S.Rev_Count + 1;
                  S.Rev (S.Rev_Count) := (X, abs V);
               end if;
            end;
         end loop;
      elsif K = "chart" and then L.Count >= 2 and then Word (L, 2) = "mrsp"
      then
         On_Mrsp_Chart (S, L);
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
      Loaded.Rev_Count := 0;
      Loaded.Chart_Zero := 0.0;
      Loaded.Chart_Scale := 1.0;
      Loaded.Truncated := False;
      Loaded.Workbook := False;
      Loaded.WB_Length := 0;
      Loaded.WB_Lambda := 0;
      Loaded.WB_Brake_Position := 0;
      Loaded.Curve_Count := 0;
      Loaded.WB_Lambda_EB := 0;
      Loaded.P3_Count := 0;
      Loaded.Release_DP_Count := 0;
      Loaded.Release_OB := False;
      In_P3 := False;
      WB_Target := No_Value;
      WB_Flat := True;
      WB_Grades := (others => <>);
      WB_Cells := (others => <>);
      Workbook_Name := (others => <>);
      Curve_Set := 0;
      Length_Row := (others => <>);
      Brake_Row := (others => <>);
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

   --  The speed of a chart (N points, increasing locations) at X_M
   function Interpolate (C : Points_T; N : Natural; X_M : Long_Float)
     return Long_Float
   is
   begin
      if N = 0 then
         return -1.0;
      end if;
      if X_M <= C (1).X_M then
         return C (1).V_Kmh;
      end if;
      for I in 2 .. N loop
         declare
            A : Point_T renames C (I - 1);
            B : Point_T renames C (I);
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
      return C (N).V_Kmh;
   end Interpolate;

   function Chart_Speed (S : Sequence_T; X_M : Long_Float) return Long_Float
   is (Interpolate (S.Chart, S.Chart_Count, X_M));

   function Chart_Speed_Reverse (S : Sequence_T; X_M : Long_Float)
     return Long_Float
   is (Interpolate (S.Rev, S.Rev_Count, X_M));

   function Curve_Distance
     (C : Curve_Set_T; Column : Curve_Column_T; V_Kmh : Long_Float)
      return Long_Float
   is
   begin
      for I in 1 .. C.Row_Count loop
         declare
            A : Curve_Row_T renames C.Rows (I);
         begin
            if V_Kmh = A.Speed_Kmh then
               return A.D (Column);
            elsif I < C.Row_Count
              and then V_Kmh > A.Speed_Kmh
              and then V_Kmh < C.Rows (I + 1).Speed_Kmh
            then
               declare
                  B : Curve_Row_T renames C.Rows (I + 1);
               begin
                  if A.D (Column) = No_Value or else B.D (Column) = No_Value
                  then
                     return No_Value;
                  end if;
                  return A.D (Column)
                    + (B.D (Column) - A.D (Column))
                      * (V_Kmh - A.Speed_Kmh) / (B.Speed_Kmh - A.Speed_Kmh);
               end;
            end if;
         end;
      end loop;
      return No_Value;
   end Curve_Distance;

   function Sheet_Factor (T : Sheet_Table_T; X : Long_Float)
                          return Long_Float
   is
      Last : Long_Float := No_Value;
   begin
      for I in T'Range loop
         if T (I).X /= No_Value and then T (I).K /= No_Value then
            if T (I).X >= X then
               return T (I).K;
            end if;
            Last := T (I).K;
         end if;
      end loop;
      return Last;
   end Sheet_Factor;

   procedure Put_Curves (S : Sequence_T) is
      function Img (X : Long_Float) return String is
         Cm : constant Long_Long_Integer :=
           Long_Long_Integer (Long_Float'Rounding (abs X * 100.0));
         Frac : constant String :=
           Long_Long_Integer'Image (100 + Cm mod 100);
         Whole : constant String := Long_Long_Integer'Image (Cm / 100);
      begin
         if X = No_Value then
            return "-";
         end if;
         return (if X < 0.0 and then Cm > 0 then "-" else "")
           & Whole (Whole'First + 1 .. Whole'Last) & "."
           & Frac (Frac'Last - 1 .. Frac'Last);
      end Img;
   begin
      for I in 1 .. S.Curve_Count loop
         declare
            C : Curve_Set_T renames S.Curves (I);
            V : constant Long_Float := C.Limits (Initial_Speed);
         begin
            Ada.Text_IO.Put_Line
              ("curves" & Natural'Image (I) & ": " & Image (C.Workbook)
               & ", " & Image (C.Sheet) & "," & Natural'Image (C.Row_Count)
               & " rows"
               & (if C.From_Twin then ", from " & Image (C.Twin) else ""));
            Ada.Text_IO.Put ("  limits:");
            for N in Limit_Name_T loop
               Ada.Text_IO.Put (" " & Limit_Name_T'Image (N) & "="
                                & Img (C.Limits (N)));
            end loop;
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Put ("  at " & Img (V) & " km/h:");
            for Col in Curve_Column_T loop
               Ada.Text_IO.Put (" " & Curve_Column_T'Image (Col) & "="
                                & Img (Curve_Distance (C, Col, V)));
            end loop;
            Ada.Text_IO.New_Line;
         end;
      end loop;
   end Put_Curves;

end S076_Sequences;
