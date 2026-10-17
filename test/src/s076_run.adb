--  ETCS on-board (EVC)
--  One SUBSET-076 test sequence replayed against the on-board, body.

pragma Ada_2012;
with Ada.Characters.Handling;
with Ada.Environment_Variables;
with Ada.Streams;             use Ada.Streams;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Text_IO;             use Ada.Text_IO;
with Interfaces;              use Interfaces;
with Display;
with Display.C_Area;
with DMI_Ack;
with DMI_Buttons;
with DMI_Conditions;
with DMI_Core;
with DMI_Data_Entry;
with DMI_Protocol;
with DMI_System_Status;
with DMI_Observe;
with DMI_Windows;             use DMI_Windows;
with EVC_Core;
with EVC_Distances;
with EVC_Odometry;
with EVC_Position;
with EVC_Ports;
with EVC_Radio;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Modes;               use EVC_Modes;
with EVC_National_Values;
with EVC_Supervision_Input;
with EVC_JRU_Messages;
with S076_Bench;
with EVC_Config;
with S076_Tables;             use S076_Tables;
with Scn_Reader;              use Scn_Reader;
with Supplementary_Driving_Info;
with User_Settings;

package body S076_Run is

   package B renames S076_Bench;
   package SDI renames Supplementary_Driving_Info;

   Seq : Sequence_T renames S076_Sequences.Loaded;

   function Reason_Image (R : Reason_T) return String is
     (case R is
         when R_None             => "none",
         when R_Radio            =>
            "radio: not yet modelled by the runner (E5)",
         when R_Handover         => "RBC handover, a second RBC (E5)",
         when R_Radio_Infill     => "radio infill (3.9, E7)",
         when R_Level_3          => "level 3 (absent from 4.0.0)",
         when R_Version          =>
            "system version other than 4.0 layout (chapter 6, E7)",
         when R_Euroloop         => "Euroloop (E7)",
         when R_E6               => "a function of phase E6",
         when R_NTC              => "NTC/STM (out of scope)",
         when R_ATO              => "ATO (no ATO port payload yet)",
         when R_DMI_Internal     => "DMI internal, not judged",
         when R_JRU_Not_Modelled => "JRU not modelled",
         when R_Not_Modelled     => "on-board input/output not modelled",
         when R_Unclassified     => "vocabulary unclassified in the sibling",
         when R_Extractor        => "unreadable in the sibling (extractor)",
         when R_S076_Defect      => "a defect of SUBSET-076 (known list)",
         when R_Optional         =>
            "optional or implementation dependent step not taken",
         when R_Gamma            => "Gamma train braking model (E6)",
         when R_Old_Tool         =>
            "workbook from the ERA tool without A.3.12 (SV21/SV22, no SV30"
            & " twin)",
         when R_Placement        =>
            "the sequence's location is off its own workbook",
         when R_Tool_Target      =>
            "workbook with the tool's LoA/MRSP target for an EOA"
            & " (SUBSET-076)",
         when R_Factors          =>
            "workbook computed with other correction factors than the"
            & " sequence's (SUBSET-076)",
         when R_Runner           => "runner not implemented for this kind");

   ---------------------------------------------------------------------
   --  Judgements
   ---------------------------------------------------------------------

   type Judgement_T is record
      Verdict : Verdict_T := Not_Judged;
      Reason  : Reason_T := R_None;
      Sig     : Text_T;
   end record;

   function Pass (What : String) return Judgement_T is
     ((Verdict => Passed, Reason => R_None, Sig => To_Text (What)));
   function Fail (Sig : String) return Judgement_T is
     ((Verdict => Failed, Reason => R_None, Sig => To_Text (Sig)));
   function NJ (R : Reason_T; What : String) return Judgement_T is
     ((Verdict => Not_Judged, Reason => R, Sig => To_Text (What)));
   function Check (Ok : Boolean; What, Got : String) return Judgement_T is
     (if Ok then Pass (What) else Fail (What & ", got " & Got));

   function Img (N : Integer) return String is
      S : constant String := Integer'Image (N);
   begin
      return (if N < 0 then S else S (S'First + 1 .. S'Last));
   end Img;

   function Up (S : String) return String
     renames Ada.Characters.Handling.To_Upper;

   function Has (S, Part : String) return Boolean is
     (Ada.Strings.Fixed.Index (Up (S), Up (Part)) > 0);

   function Same (A, Bb : String) return Boolean is (Up (A) = Up (Bb));

   function Starts (S, Prefix : String) return Boolean is
     (S'Length >= Prefix'Length
      and then Up (S (S'First .. S'First + Prefix'Length - 1)) = Up (Prefix));

   function Trim (C : Column_T) return String is
     (Ada.Strings.Fixed.Trim (C, Ada.Strings.Both));

   ---------------------------------------------------------------------
   --  The words of the current input / expect line
   ---------------------------------------------------------------------

   Line : Line_T (Max_Line);

   procedure Load_Line (T : Text_T) is
   begin
      Line.Text := (others => ' ');
      Line.Text (1 .. T.N) := T.S (1 .. T.N);
      Split (Line);
   end Load_Line;

   function W (K : Positive) return String is (Word (Line, K));

   --  The cycles an expectation may wait for. SUBSET-026 3.5.7.2, Table 2
   --  [2], A.3.1: "Connection Lost/Set-Up failed" shows when the 45 s
   --  "connection status" timer expires; the sequences let that time pass
   --  in a step "repeated until t=t0+45" (3150100_07 step 79), so the
   --  symbol's expectation waits for the timer (46 s)
   function Wait_Limit return Natural is
     (if Same (W (3), "status-symbol") and then Same (W (4), "displayed")
        and then Has (W (5), "Connection-Lost")
      then 46_000 / B.Cycle_Ms
      else Wait_Cycles);

   ---------------------------------------------------------------------
   --  The state of the replay
   ---------------------------------------------------------------------

   Debug : constant Boolean := Ada.Environment_Variables.Exists ("DEBUG");
   --  S076_EXACT_SPEED=1: the bench's odometer states the exact speed
   --  for every sequence (the runner before B191; the probe's --vura 0)
   Exact_Speed : constant Boolean :=
     Ada.Environment_Variables.Exists ("S076_EXACT_SPEED");

   --  the SUBSET-027 fields of a JRU expectation this JRU port does not
   --  carry: the step is judged on the others, these are listed
   Field_Gap : Text_T;

   procedure Note_Gap (S : String) is
   begin
      if Field_Gap.N = 0 then
         Field_Gap := To_Text (S);
      end if;
   end Note_Gap;
   --  the time stamp of the last message the RBC of the sequence gave
   --  (S076_Run-Radio_Input), since the last connection set up
   RBC_Stamp       : Unsigned_64 := 0;
   RBC_Stamp_Given : Boolean := False;
   --  The two RBC sessions of the sequence (a handover shows the second):
   --  which have a connection, and the one set up last
   type Alive_T is array (1 .. 2) of Boolean;
   RBC_Alive   : Alive_T := (others => False);
   RBC_Current : Positive range 1 .. 2 := 1;
   Cur            : Natural := 0;       -- the index of the step
   Step_Start_Ms  : Unsigned_64 := 0;   -- the time the last step ended
   Explicit_Speed : Integer := -1;      -- cm/s set by an ODO input
   Wait_Used      : Natural := 0;       -- cycles waited in the window
   Default_Kmh    : constant := 30;

   function Kmh_To_Cms (Kmh : Long_Float) return Natural is
     (Natural (Long_Float'Max (0.0, Kmh) * 100_000.0 / 3600.0));

   --  the chart's speed at the train, km/h, -1 without a chart; while
   --  the train moves backwards the reverse movement's chart where the
   --  sequence has one (B303: 3130232_17 and _18 ran their Reversing
   --  backwards at the forward chart's 40 to 60 km/h, the reverse one
   --  says 13 km/h); B160: the speed of the language for the chart's
   --  drawing (S076_Sequences.Calibrated; the reverse chart is drawn
   --  below the same zero, its speed without its sign)
   function Chart_Kmh return Long_Float is
     (if B.Direction < 0 and then Seq.Rev_Count > 0
      then Calibrated
        (Seq, Chart_Speed_Reverse (Seq, Long_Float (B.Position) / 100.0)
              + 2.0 * Seq.Chart_Zero)
      elsif Seq.Chart_Count = 0 then -1.0
      else Calibrated
        (Seq, Chart_Speed (Seq, Long_Float (B.Position) / 100.0)));

   --  The speed charts are the reference of the speed (the driver of
   --  a sequence runs above a limit on purpose where the chart does); a
   --  limit to keep under the on-board's permitted speed was tried and
   --  broke more sequences than it repaired (the charts are drawings, not
   --  exact, both ways)
   function Capped (Cms : Natural) return Natural is (Cms);

   --  the speed to travel at
   function Transit_Cms return Positive is
   begin
      if Explicit_Speed >= Kmh_To_Cms (10.0) then
         return Explicit_Speed;
      end if;
      declare
         C : constant Long_Float := Chart_Kmh;
      begin
         if C < 0.0 then
            return Positive'Max
              (1, Capped (Kmh_To_Cms (Long_Float (Default_Kmh))));
         end if;
         return Positive'Max
           (1, Capped (Natural'Max (Kmh_To_Cms (C), Kmh_To_Cms (10.0))));
      end;
   end Transit_Cms;

   --  the speed once arrived: the explicit one, else the chart's (a
   --  speed under 1 km/h is standstill)
   procedure Arrive is
   begin
      if Explicit_Speed >= 0 then
         B.Set_Speed (Explicit_Speed);
      else
         declare
            C : constant Long_Float := Chart_Kmh;
         begin
            B.Set_Speed (if C >= 1.0 then Capped (Kmh_To_Cms (C)) else 0);
         end;
      end if;
   end Arrive;

   --  The train follows the speed chart from cycle to cycle (the speed
   --  of the chart where it is), at least 10 km/h until it reaches To_Cm,
   --  cycle by
   --  cycle; the last cycle ends at To_Cm. At most an hour.
   --  B262: an explicit speed (an ODO speed step) is the train's at once
   --  when the sequence sets it, whatever the brake (the steps that
   --  provoke a brake on purpose); then the braking model acts on it
   Forced_Speed : Integer := -1;
   --  B490: the chart's speed where the explicit speed came (-1 none)
   Explicit_Chart : Long_Float := -1.0;

   procedure Force_Explicit is
   begin
      if Explicit_Speed >= 0 and then Explicit_Speed /= Forced_Speed then
         B.Force_Speed (Explicit_Speed);
         Explicit_Chart := Chart_Kmh;
      end if;
      Forced_Speed := Explicit_Speed;
   end Force_Explicit;

   --  B490: an explicit speed ends where the chart leaves the speed it
   --  had where the speed came by more than Chart_Band km/h, either way
   --  (3130234_08: 25 km/h held from 1035 m past the chart's rise to 75
   --  km/h at 1100 m; 4100103_16 and _24: a speed under the permitted
   --  held past the chart's stop); the train follows the chart again.
   --  Decision: a fall ends it too, although 3131020_04 reached its step
   --  70 by holding the 78 km/h of step 55 over the chart's fall to 60.7
   --  km/h (its step 68 now judges the chart's speed against our curves,
   --  [workbook train])
   Chart_Band : constant Long_Float := 5.0;

   function Chart_Left return Boolean is
     (Explicit_Speed >= 0 and then Explicit_Chart >= 0.0
      and then Chart_Kmh >= 0.0
      and then abs (Chart_Kmh - Explicit_Chart) > Chart_Band);

   --  B262: the speed asked for is the chart's; the train's is that of
   --  the bench's braking model (lower under a brake command, regaining
   --  the chart's once released); held at standstill by a brake for 10 s
   --  the train stops trying (a trip: the sequence's location is not
   --  reached)
   procedure Drive_To (To_Cm : Integer_64) is
      Dir  : constant Integer := (if To_Cm >= B.Position then 1 else -1);
      Held : Natural := 0;
   begin
      B.Set_Direction (Dir);
      B.Set_Brake_Floor (Kmh_To_Cms (10.0));
      for I in 1 .. 36_000 loop
         Force_Explicit;
         --  an explicit speed a brake has lowered and released is spent:
         --  the chart's speed again (4120100_01: the EB revoked on the
         --  desk's closure, the chart's stop at 655 m)
         if (B.Forced_Spent and then Explicit_Speed >= 0) or else Chart_Left
         then
            Explicit_Speed := -1;
            Forced_Speed := -1;
         end if;
         B.Set_Speed (Transit_Cms);
         declare
            Left : constant Integer_64 :=
              (To_Cm - B.Position) * Integer_64 (Dir);
            Full : constant Integer_64 :=
              Integer_64 (B.Speed) * B.Cycle_Ms / 1000;
         begin
            exit when Left <= 0 or else Held >= 10_000;
            if Left < Full then
               --  B224: the last cycle at the speed, moving the train by
               --  the distance left
               B.Cycle (Left);
            else
               B.Cycle;
            end if;
            Held := (if B.Speed = 0 then Held + B.Cycle_Ms else 0);
         end;
      end loop;
      B.Set_Brake_Floor (0);
   end Drive_To;

   procedure Move_To (To_Cm : Integer_64) is
   begin
      if (B.Direction > 0 and then To_Cm > B.Position + 50)
        or else (B.Direction < 0 and then To_Cm < B.Position - 50)
      then
         Drive_To (To_Cm);
         Arrive;
      end if;
   end Move_To;

   --  One cycle while the runner waits or settles: a train that runs
   --  without an explicit speed keeps following the chart
   --  After a "reach-point" input the speed of the train at that point
   --  stays until the next input: the sequences state where a limit is
   --  passed at a speed, and the on-board's curve may place it some
   --  metres beyond the workbook's
   Hold_Speed : Boolean := False;

   procedure Wait_Cycle is
   begin
      Force_Explicit;
      if Explicit_Speed < 0 and then B.Speed > 0 and then not Hold_Speed then
         Arrive;
      end if;
      B.Cycle;
   end Wait_Cycle;

   ---------------------------------------------------------------------
   --  The step's level and mode columns
   ---------------------------------------------------------------------

   function Our_Mode return Mode_T is
     (if B.Powered then EVC_Core.Mode else M_NP);

   function Our_Level return Level_Kind_T is
   begin
      --  a level kept over No Power is "invalid" (4.10 column NP) until
      --  revalidated: the sequences write it in the level column
      if not B.Powered
        or else EVC_Core.Level_Status = EVC_Modes.Unknown
      then
         return K_None;
      end if;
      return (case EVC_Core.Level is
                 when L0 => K_L0, when NTC => K_NTC,
                 when L1 => K_L1, when L2 => K_L2);
   end Our_Level;

   --  A step whose comment restricts it to level 2 ("Only if in L2",
   --  "only in L2", 44 sequences of sv30, e.g. 4080442_01 step 51: a 136
   --  in level 1 On Sight; "Only if L2", 6060302_04 step 42, a JRU 9 in
   --  level 1) is the sequence's other alternative when the
   --  step's level columns or the on-board's level are not 2
   function Only_In_L2_Elsewhere (St : Step_T) return Boolean is
     ((Has (Image (St.Comment), "only if in L2")
       or else Has (Image (St.Comment), "only if L2")
       or else Has (Image (St.Comment), "only in L2"))
      and then (Trim (St.Lvl_After) /= "L2"
                or else Trim (St.Lvl_Before) /= "L2"
                or else Our_Level /= K_L2));

   function Mode_Abbrev (M : Mode_T) return String is
     (case M is
         when M_FS => "FS", when M_AD => "AD", when M_LS => "LS",
         when M_OS => "OS", when M_SR => "SR", when M_SM => "SM",
         when M_SH => "SH", when M_UN => "UN", when M_PS => "PS",
         when M_SL => "SL", when M_SB => "SB", when M_TR => "TR",
         when M_PT => "PT", when M_SF => "SF", when M_IS => "IS",
         when M_NP => "NP", when M_NL => "NL", when M_SN => "SN",
         when M_RV => "RV");

   function Level_Abbrev (K : Level_Kind_T) return String is
     (case K is
         when K_None => "unknown", when K_L0 => "L0", when K_NTC => "LNTC",
         when K_L1 => "L1", when K_L2 => "L2", when K_L3 => "L3");

   --  The columns against the on-board now. The sequences write the
   --  state of a step either as it is when the step happens or as it is
   --  once the step's reaction is complete, and an input's reaction is
   --  listed over the output steps that follow it in an order of their
   --  own. So the mode and the level are judged against every state
   --  the reaction block of the step names: the before and after
   --  columns of the steps of its block (from the input that opens it
   --  to the step before the next input), of the block before and of
   --  the block after it: the corpus writes a state change in the block
   --  of its cause, or one block early or late. A level column "N/A"
   --  accepts an unknown or an invalid level, a mode column "N/A" (a state the
   --  sequence does not name: 5120400_01 writes the passive shunting
   --  after the cab is closed so) any mode; in No Power the level is
   --  not judged.
   type Level_Set_T is array (Level_Kind_T) of Boolean;

   function Columns (I : Positive) return Judgement_T is
      First, Last : Positive := I;
      Modes  : Mode_Set_T := No_Modes;
      Levels : Level_Set_T := (others => False);
      M  : constant Mode_T := Our_Mode;
      Lv : constant Level_Kind_T := Our_Level;
      Any_Level : Boolean := False;
      Any_Mode  : Boolean := False;

      procedure Add (St : Step_T) is
         Mb : constant Mode_Set_T := Mode_Of (Trim (St.Mode_Before));
         Ma : constant Mode_Set_T := Mode_Of (Trim (St.Mode_After));
      begin
         for X in Mode_T loop
            Modes (X) := Modes (X) or else Mb (X) or else Ma (X);
         end loop;
         Any_Mode := Any_Mode or else Trim (St.Mode_Before) = "N/A"
                     or else Trim (St.Mode_After) = "N/A";
         Levels (Level_Of (Trim (St.Lvl_Before))) := True;
         Levels (Level_Of (Trim (St.Lvl_After))) := True;
      end Add;
   begin
      --  the input that opens the block, and the block before it
      for Round in 1 .. 2 loop
         if First > 1 then
            First := First - 1;
         end if;
         while First > 1 and then Seq.Steps (First).IO /= Input loop
            First := First - 1;
         end loop;
      end loop;
      --  the end of the block, and of the block after it
      for Round in 1 .. 2 loop
         if Last < Seq.Step_Count then
            Last := Last + 1;
         end if;
         while Last < Seq.Step_Count and then Seq.Steps (Last + 1).IO /= Input
         loop
            Last := Last + 1;
         end loop;
      end loop;
      for K in First .. Last loop
         if Seq.Steps (K).Well_Formed then
            Add (Seq.Steps (K));
         end if;
      end loop;
      for K in Level_Kind_T range K_L0 .. K_L3 loop
         Any_Level := Any_Level or else Levels (K);
      end loop;
      if Modes /= No_Modes and then not Any_Mode and then not Modes (M)
      then
         return Fail ("mode " & Trim (Seq.Steps (I).Mode_After) & ", got "
                      & Mode_Abbrev (M));
      end if;
      --  an invalid level is not shown to the driver: "N/A" accepts it
      if Any_Level and then M /= M_NP and then not Levels (Lv)
        and then not (Levels (K_None)
                      and then EVC_Core.Level_Status = EVC_Modes.Invalid)
      then
         return Fail ("level " & Trim (Seq.Steps (I).Lvl_After) & ", got "
                      & Level_Abbrev (Lv));
      end if;
      return Pass ("mode " & Mode_Abbrev (M));
   end Columns;

   ---------------------------------------------------------------------
   --  Driving the DMI
   ---------------------------------------------------------------------

   procedure Press (X, Y : Natural; Hold : Natural := 0) is
   begin
      B.Touch (X, Y, Hold);
   end Press;

   procedure Press_Area (A : Display.Area_T; Hold : Natural := 0) is
   begin
      Press (Natural (A.Position.X) + Natural (A.Width) / 2,
             Natural (A.Position.Y) + Natural (A.Height) / 2, Hold);
   end Press_Area;

   function Top_Is (Wid : Window_ID_T) return Boolean is
     (DMI_Windows.Is_Open and then DMI_Windows.Top = Wid);

   function Top_Image return String is
     (if DMI_Windows.Is_Open then Window_ID_T'Image (DMI_Windows.Top)
      else "the default window");

   --  Table 25: key K of the numeric keyboard, three per row from y 200
   procedure Key (K : Positive) is
   begin
      Press (334 + ((K - 1) mod 3) * 102 + 51,
             15 + 200 + ((K - 1) / 3) * 50 + 25);
   end Key;

   --  Table 22: the data part of a window with a single input field,
   --  its [Enter]
   procedure Enter_Single is
   begin
      Press (487, 90);
   end Enter_Single;

   --  Table 23: the data part of input field I
   procedure Enter_Field (I : Positive) is
   begin
      Press (589, 15 + (I - 1) * 50 + 25);
   end Enter_Field;

   procedure Type_Digits (S : String) is
   begin
      for C of S loop
         if C = '0' then
            Key (11);
         elsif C in '1' .. '9' then
            Key (Character'Pos (C) - Character'Pos ('0'));
         end if;
      end loop;
   end Type_Digits;

   --  Bring window Wid (a menu window of the default window) to the top:
   --  close what is open where [Close] allows it, then its F button
   function Open_Window (Wid : Window_ID_T) return Boolean is
   begin
      if Top_Is (Wid) then
         return True;
      end if;
      for I in 1 .. 4 loop
         exit when not DMI_Windows.Is_Open or else Top_Is (Wid);
         exit when not DMI_Windows.Close_Enabled;
         Press_Area (DMI_Windows.Close_Button_Area);
      end loop;
      if Top_Is (Wid) then
         return True;
      elsif DMI_Windows.Is_Open then
         return False;
      end if;
      case Wid is
         when W_Main      => Press_Area (Display.Get_Area (Display.F1));
         when W_Override  => Press_Area (Display.Get_Area (Display.F2));
         when W_Data_View => Press_Area (Display.Get_Area (Display.F3));
         when W_Special   => Press_Area (Display.Get_Area (Display.F4));
         when W_Settings  => Press_Area (Display.Get_Area (Display.F5));
         when others      => null;
      end case;
      return Top_Is (Wid);
   end Open_Window;

   --  Press button Index of the menu window Wid
   function Press_Menu (Wid : Window_ID_T; Index : Positive; Name : String)
     return Judgement_T
   is
   begin
      if not Open_Window (Wid) then
         return Fail ("DMI " & Name & ": " & Window_ID_T'Image (Wid)
                      & " cannot be opened over " & Top_Image);
      end if;
      --  A button that needs standstill: the train may have stopped in
      --  this very cycle and the DMI not yet received it; the driver
      --  looks again for a few cycles while the train is at standstill
      for I in 1 .. 5 loop
         exit when DMI_Windows.Button_Enabled (Index) or else B.Speed /= 0;
         B.Cycle;
      end loop;
      if not DMI_Windows.Button_Enabled (Index) then
         return Fail ("DMI " & Name & ": the button is disabled");
      end if;
      declare
         Hold : constant Natural :=
           (if DMI_Buttons."=" (DMI_Windows.Button_Kind (Index),
                                DMI_Buttons.Delay_Type)
            then 2_100 else 0);
      begin
         Press_Area (DMI_Windows.Button_Area (Index), Hold);
      end;
      return Pass ("DMI " & Name);
   end Press_Menu;

   --  Wait up to Cycles for Cond
   function Wait_For (Cond : access function return Boolean;
                      Cycles : Natural) return Boolean is
   begin
      for I in 1 .. Cycles loop
         exit when Cond.all;
         B.Cycle;
      end loop;
      return Cond.all;
   end Wait_For;

   function Ack_Valid return Boolean is (DMI_Ack.Current_Valid);

   function Acknowledge (Name : String) return Judgement_T is
      use type DMI_Ack.Ack_Kind_T;
   begin
      if not Wait_For (Ack_Valid'Access, 30) then
         return Fail ("DMI acknowledge " & Name
                      & ": no acknowledgement requested");
      end if;
      case DMI_Ack.Current_Kind is
         when DMI_Ack.Level_Transition | DMI_Ack.Mode_Change =>
            Press_Area (Display.C_Area.C1_Absolute_Area,
                        (if DMI_Ack.Current_Kind = DMI_Ack.Mode_Change
                           and then SDI."=" (DMI_Ack.Current_Mode, SDI.M_SR)
                         then 2_100 else 0));
         when DMI_Ack.Brake_Release =>
            Press_Area (Display.C_Area.Brake_Ack_Area);
         when others =>
            declare
               E : constant Display.Area_T := Display.Get_Area (Display.E);
            begin
               Press (Natural (E.Position.X) + 54 + 117,
                      Natural (E.Position.Y) + 50);
            end;
      end case;
      return Pass ("DMI acknowledge " & Name);
   end Acknowledge;

   --  11.3.9: the seven items of Table 40 over the two windows, then the
   --  entry ends (167, 440) and the validation window follows
   --  The Train Data the driver enters: those of the sequence's braking
   --  curve workbook where it has one (its train length and brake
   --  percentage), else a 40 m train (the L_TRAIN of the corpus' radio
   --  messages) with the workbook's 109 %. The maximum speed stays in
   --  the conversion model (3.13.3.2.1: at most 200 km/h), the only
   --  braking model of a Train Data entry (no pre-programmed one in the
   --  configuration yet, E6).
   function Train_Length_M return Natural is
     (if Seq.WB_Length in 1 .. 4095 then Seq.WB_Length else 40);
   function Brake_Percentage return Natural is
     (if Seq.WB_Lambda in 10 .. 250 then Seq.WB_Lambda else 109);

   --  11.3.9: the seven items of Table 40 over the two windows, then the
   --  entry ends (167, 440) and the validation window follows
   procedure Enter_Train_Data (At_Cm : Integer_64) is
      T : constant S076_Sequences.Train_T :=
        S076_Sequences.Train_At (Seq, At_Cm);
      function Digits_Of (N : Natural) return String is
         S : constant String := Natural'Image (N);
      begin
         return S (S'First + 1 .. S'Last);
      end Digits_Of;
   begin
      --  the train category (Table 41, DMI_Train_Data): PASS 1 (key 1),
      --  FP 1 (key 11) or FG 1 (key 4 after [More]) for the brake
      --  position of the workbook's train
      case Seq.WB_Brake_Position is
         when 2 => Key (11);
         when 3 => Key (12); Key (4);
         when others => Key (1);
      end case;
      Enter_Field (1);
      Type_Digits (Digits_Of (Train_Length_M)); Enter_Field (2);
      Type_Digits (Digits_Of (Brake_Percentage)); Enter_Field (3);
      Type_Digits ("200"); Enter_Field (4);   -- maximum speed, km/h
      Press (539, 440);                       -- [Next]
      --  B471: the axle load category and the loading gauge of the
      --  sequence's packet 11 (DMI_Train_Data: the categories A .. D4XL on
      --  the keys 1 to 11, E4 and E5 after [More]; the gauges G1 .. GC
      --  on the keys 1 to 4, "Out of GC" on 5), else A and "Out of GC"
      case T.Axle_Load is
         when 0 .. 10 => Key (T.Axle_Load + 1);
         when 11 | 12 => Key (12); Key (T.Axle_Load - 10);
         when others => Key (1);
      end case;
      Enter_Field (1);
      Key (7); Enter_Field (2);               -- airtight
      Key (if T.Gauge in 1 .. 4 then T.Gauge else 5);
      Enter_Field (3);
      Press (457, 440);                       -- [Previous]
      Press (167, 440);                       -- entry complete
   end Enter_Train_Data;

   procedure Desk_Isolation is
      Down : constant Stream_Element_Array := (2, 1);
      Up_K : constant Stream_Element_Array := (2, 0);
   begin
      DMI_Core.Handle_Message (DMI_Protocol.MSG_DESK_INPUT, Down);
      B.Run (2_100);
      DMI_Core.Handle_Message (DMI_Protocol.MSG_DESK_INPUT, Up_K);
      B.Cycle;
   end Desk_Isolation;

   --  The level the driver selects. The sequences disagree with
   --  themselves here: 5040300_17 step 10 has the column after L1, the
   --  DMI event LEVEL=1 and the comment "The Driver selects L2", and the
   --  steps that follow settle on L2; 4070201_03 step 10 has the comment
   --  "selects L0" with the column L1 and the steps that follow L1;
   --  5040300_21 step 71 has no LEVEL, the column L1 and the comment
   --  "selects "Level 2"", the steps that follow L2. What holds in every
   --  shape is the level the following steps settle on: the last known
   --  column of the four steps after this one first, then the step's own
   --  column after, the comment's "L2" / "Level 2", the LEVEL of the
   --  PDF's DMI event, the words of the line
   function Selected_Level (St : Step_T; Item : String) return Level_Kind_T
   is
      K : constant Level_Kind_T := Level_Of (Trim (St.Lvl_After));
      D : constant String := DMI_Data (Seq, St.Number);
      U : constant String := Up (Item);
      P : constant Natural := Ada.Strings.Fixed.Index (U, "LEVEL-");

      --  the levels the step's item allows: "Level-0/1/NTC" excludes 2,
      --  "Level-2" names the one level; no list allows every level
      function Allowed (L : Level_Kind_T) return Boolean is
         Tag : constant String :=
           (case L is
               when K_L0 => "0", when K_L1 => "1", when K_L2 => "2",
               when K_NTC => "NTC", when others => "");
      begin
         if P = 0 or else Tag = "" then
            return True;
         end if;
         declare
            List : constant String := U (P + 6 .. U'Last);
            Last : Natural;
         begin
            for I in List'Range loop
               Last := I + Tag'Length - 1;
               if Last <= List'Last and then List (I .. Last) = Tag
                 and then (I = List'First or else List (I - 1) = '/')
                 and then (Last = List'Last or else List (Last + 1) = '/')
               then
                  return True;
               end if;
            end loop;
            return False;
         end;
      end Allowed;

      --  the one level the item names, when it names only one
      function Named_Alone return Level_Kind_T is
      begin
         if P = 0 or else Ada.Strings.Fixed.Index (U (P .. U'Last), "/") > 0
         then
            return K_None;
         end if;
         for L in K_L0 .. K_L2 loop
            if Allowed (L) then
               return L;
            end if;
         end loop;
         return K_None;
      end Named_Alone;

      --  the level the next four steps settle on (their last known column)
      function Settled_Level return Level_Kind_T is
         Found : Level_Kind_T := K_None;
      begin
         for I in Cur + 1 .. Natural'Min (Cur + 4, Seq.Step_Count) loop
            declare
               L : constant Level_Kind_T :=
                 Level_Of (Trim (Seq.Steps (I).Lvl_After));
            begin
               if L /= K_None then
                  Found := L;
               end if;
            end;
         end loop;
         return Found;
      end Settled_Level;

      --  the last "L<d>" or "Level <d>" of the comment, a word on its own
      function From_Comment return Level_Kind_T is
         C     : constant String := Up (Image (St.Comment));
         Found : Level_Kind_T := K_None;
      begin
         for I in C'Range loop
            if C (I) = 'L'
              and then (I = C'First or else C (I - 1) not in 'A' .. 'Z')
            then
               declare
                  J : Natural := I + 1;
               begin
                  if J + 3 <= C'Last and then C (J .. J + 3) = "EVEL" then
                     J := J + 4;
                  end if;
                  while J <= C'Last and then C (J) = ' ' loop
                     J := J + 1;
                  end loop;
                  if J <= C'Last
                    and then (J = C'Last or else C (J + 1) not in '0' .. '9')
                  then
                     case C (J) is
                        when '0' => Found := K_L0;
                        when '1' => Found := K_L1;
                        when '2' => Found := K_L2;
                        when others => null;
                     end case;
                  end if;
               end;
            end if;
         end loop;
         return Found;
      end From_Comment;
   begin
      if Named_Alone /= K_None then
         return Named_Alone;
      end if;
      if Settled_Level /= K_None and then Allowed (Settled_Level) then
         return Settled_Level;
      end if;
      if K /= K_None and then Allowed (K) then
         return K;
      end if;
      if From_Comment /= K_None and then Allowed (From_Comment) then
         return From_Comment;
      end if;
      if Has (D, "LEVEL=0") and then Allowed (K_L0) then
         return K_L0;
      elsif Has (D, "LEVEL=1") and then Allowed (K_L1) then
         return K_L1;
      elsif Has (D, "LEVEL=2") and then Allowed (K_L2) then
         return K_L2;
      end if;
      for I in 4 .. Line.Count loop
         if Level_Of (W (I)) /= K_None then
            return Level_Of (W (I));
         end if;
      end loop;
      --  the level the steps that follow have
      for I in Cur + 1 .. Natural'Min (Cur + 12, Seq.Step_Count) loop
         declare
            L : constant Level_Kind_T :=
              Level_Of (Trim (Seq.Steps (I).Lvl_Before));
         begin
            if L /= K_None then
               return L;
            end if;
         end;
      end loop;
      return K_None;
   end Selected_Level;

   --  The digits that follow Key (and the separators " :=") in Text, or ""
   function Digits_After (Text, Key : String) return String is
      Up_Text : constant String := Up (Text);
      At_Key  : constant Natural :=
        Ada.Strings.Fixed.Index (Up_Text, Up (Key));
      P : Natural;
   begin
      if At_Key = 0 then
         return "";
      end if;
      P := At_Key + Key'Length;
      while P <= Text'Last and then Text (P) in ' ' | ':' | '=' loop
         P := P + 1;
      end loop;
      declare
         First : constant Natural := P;
      begin
         while P <= Text'Last and then Text (P) in '0' .. '9' loop
            P := P + 1;
         end loop;
         return Text (First .. P - 1);
      end;
   end Digits_After;

   --  The RBC contact information the driver enters, from the comment of
   --  the step or of the nearest step before it (within ten) that names
   --  it: "RBC ID = N" / "ETCS ID : N" / "RBCid: N" and "RBC phone number
   --  = N" / "Phone : N". Nothing is assumed: a value not named stays "".
   procedure Radio_Values (RBC_Id, Phone : out Unbounded_String) is
      function Pick (Key1, Key2, Key3 : String; K : Natural) return String is
         C : constant String := Image (Seq.Steps (K).Comment);
      begin
         if Digits_After (C, Key1)'Length > 0 then
            return Digits_After (C, Key1);
         elsif Digits_After (C, Key2)'Length > 0 then
            return Digits_After (C, Key2);
         elsif Key3'Length > 0 and then Digits_After (C, Key3)'Length > 0 then
            return Digits_After (C, Key3);
         end if;
         return "";
      end Pick;
   begin
      RBC_Id := Null_Unbounded_String;
      Phone  := Null_Unbounded_String;
      for K in reverse Natural'Max (1, Cur - 10) .. Cur loop
         if Length (RBC_Id) = 0 then
            RBC_Id := To_Unbounded_String
              (Pick ("RBC ID", "ETCS ID", "RBCID", K));
         end if;
         if Length (Phone) = 0 then
            Phone := To_Unbounded_String
              (Pick ("phone number", "phone", "", K));
         end if;
      end loop;
   end Radio_Values;

   --  11.3.5 (Table 50 S5-3): the RBC data window; the driver types the
   --  values the sequence names and ends the entry
   function RBC_Data_Entry (Verb : String) return Judgement_T is
      Id, Phone : Unbounded_String;
      Typed     : Boolean := False;

      --  the K-th value the window shows (digits)
      function Proposed (K : DMI_Data_Entry.Field_Index_T) return String is
         S : String (1 .. DMI_Data_Entry.Value (K).Length);
      begin
         for N in S'Range loop
            S (N) := Character'Val
              (Wide_Character'Pos (DMI_Data_Entry.Value (K).Text (N)) mod 256);
         end loop;
         return S;
      end Proposed;

      --  11.7.1.4: the window proposes the stored contact (MSG_RBC_CONTACT)
      --  and the step names those values, or none: the driver confirms
      --  them without typing (decision: a step that names no value takes
      --  the proposal, any valid contact being what it asks for)
      function Proposed_Named return Boolean is
         I, P : Unbounded_String;
      begin
         Radio_Values (I, P);
         return (Length (I) > 0 and then To_String (I) = Proposed (1)
                 and then To_String (P) = Proposed (2))
           or else Length (I) = 0;
      end Proposed_Named;
   begin
      --  Table 49 S3-1 -> S3-3 / Table 50 S5-1 -> S5-3: the driver who
      --  is to confirm the RBC data presses 'Enter RBC data' on the
      --  Radio data window. From the Main window (Table 50 S1 -> S5-1)
      --  too: 4040800_05 selects level 2 from the Main window after Exit
      --  Shunting with a contact stored in SH (4.8.4 [3]); the on-board
      --  reports it valid and the radio registered, so the DMI follows
      --  Table 50 D5 to S8, while the sequence shows the RBC data window
      --  (steps 58 / 59, as Table 49 S2 -> S3 would); its rows 5 to 9
      --  are not in the extract
      if not Top_Is (W_RBC_Data) and then not Top_Is (W_Radio_Data)
        and then (Top_Is (W_Main) or else not DMI_Windows.Is_Open)
      then
         declare
            J : constant Judgement_T :=
              Press_Menu (W_Main, 10, "Radio data");
         begin
            if J.Verdict = Failed then
               return J;
            end if;
         end;
      end if;
      if Top_Is (W_Radio_Data) then
         declare
            J : constant Judgement_T :=
              Press_Menu (W_Radio_Data, 3, "Enter RBC data");
         begin
            if J.Verdict = Failed then
               return J;
            end if;
         end;
      end if;
      if not Top_Is (W_RBC_Data) then
         return Fail ("DMI RBC data: the window is not open, top is "
                      & Top_Image);
      end if;
      if DMI_Data_Entry.Value (1).Length = 0
        or else (Same (Verb, "enter") and then not Proposed_Named)
      then
         Typed := True;
         Radio_Values (Id, Phone);
         if Length (Id) = 0 and then Same (Verb, "confirm")
           and then EVC_Radio.Contact.Known
         then
            --  11.7.1.4: the window proposes the stored contact (the
            --  driver confirms it; 4040800_05 step 58: "equal to the
            --  variable of packet 42"). The window shows nothing, so
            --  the driver types the stored contact the on-board has: the
            --  RBC ID as NID_C * 2**14 + NID_RBC, the phone number the
            --  BCD digits of NID_RADIO before the F padding (the form
            --  the on-board reads, EVC_Sessions.Mission.Driver_Contact)
            declare
               C : constant EVC_Radio.RBC_Contact_T := EVC_Radio.Contact;
               R : Unsigned_64 := Unsigned_64 (C.Radio);
               P : String (1 .. 16);
               N : Natural := 0;
            begin
               Id := To_Unbounded_String
                 (Img (Natural (C.RBC.NID_C) * 2**14
                       + Natural (C.RBC.NID_RBC)));
               for K in reverse 1 .. 16 loop
                  P (K) := Character'Val (48 + Natural (R mod 16));
                  R := R / 16;
               end loop;
               while N < 16 and then P (N + 1) in '0' .. '9' loop
                  N := N + 1;
               end loop;
               Phone := To_Unbounded_String (P (1 .. N));
            end;
         end if;
         if Length (Id) = 0 or else Length (Id) > 8
           or else Length (Phone) > 16
         then
            return NJ (R_Radio, "RBC data: the sequence names no value");
         end if;
         Type_Digits (To_String (Id));
         Enter_Field (1);
         if Length (Phone) > 0 then
            Type_Digits (To_String (Phone));
            Enter_Field (2);
         end if;
      end if;
      Press (167, 440);                       -- entry complete
      if Top_Is (W_RBC_Data) then
         return Fail ("DMI RBC data: the entry was not accepted");
      end if;
      return Pass ("DMI RBC data "
                   & (if Typed then "entered" else "confirmed as shown"));
   end RBC_Data_Entry;

   function DMI_Input (St : Step_T) return Judgement_T is
      Verb : constant String := W (3);
      Item : constant String := W (4);
   begin
      if Same (Verb, "enter") and then Same (Item, "Driver-ID") then
         if not Top_Is (W_Driver_ID) then
            declare
               J : constant Judgement_T :=
                 Press_Menu (W_Main, 2, "Driver ID");
            begin
               if J.Verdict = Failed then
                  return J;
               end if;
            end;
         end if;
         Type_Digits ("1234");
         Enter_Single;
         return Pass ("DMI driver ID entered");
      elsif (Same (Verb, "confirm") or else Same (Verb, "validate"))
        and then (Same (Item, "Driver-ID")
                  or else Same (Item, "Train-Running-Number")
                  or else Same (Item, "Level"))
      then
         if not Top_Is (W_Driver_ID) and then not Top_Is (W_TRN)
           and then not Top_Is (W_Level)
         then
            --  the window of the item, from the Main window
            declare
               J : constant Judgement_T :=
                 Press_Menu (W_Main,
                             (if Same (Item, "Driver-ID") then 2
                              elsif Same (Item, "Level") then 5 else 6),
                             Item);
            begin
               if J.Verdict = Failed then
                  return J;
               end if;
            end;
         end if;
         --  the Level window proposes no level when the level is not
         --  valid (after a power-up): the driver selects the level the
         --  steps settle on before confirming, as a select step does
         if Same (Item, "Level") then
            declare
               K : constant Level_Kind_T := Selected_Level (St, Item);
            begin
               if K /= K_None then
                  Key (case K is
                          when K_L1 => 1, when K_L2 => 2, when K_L0 => 4,
                          when others => 5);
               end if;
            end;
         end if;
         Enter_Single;
         return Pass ("DMI " & Item & " confirmed");
      elsif Same (Verb, "select") and then Has (Item, "Level")
      then
         declare
            K : constant Level_Kind_T := Selected_Level (St, Item);
         begin
            if K = K_None then
               return NJ (R_Runner, "DMI select level: which level");
            end if;
            if not Top_Is (W_Level) then
               declare
                  J : constant Judgement_T := Press_Menu (W_Main, 5, "Level");
               begin
                  if J.Verdict = Failed then
                     return J;
                  end if;
               end;
            end if;
            Key (case K is
                    when K_L1 => 1, when K_L2 => 2, when K_L0 => 4,
                    when others => 5);
            Enter_Single;
            return Pass ("DMI level " & Level_Abbrev (K) & " selected");
         end;
      elsif Same (Verb, "press") and then Same (Item, "Train-Data") then
         return Press_Menu (W_Main, 3, "Train data");
      elsif Same (Verb, "enter") and then Same (Item, "Train-Data") then
         if not Top_Is (W_Train_Data) then
            declare
               J : constant Judgement_T :=
                 Press_Menu (W_Main, 3, "Train data");
            begin
               if J.Verdict = Failed then
                  return J;
               end if;
            end;
         end if;
         Enter_Train_Data (St.Dist_Cm);
         declare
            T : constant S076_Sequences.Train_T :=
              S076_Sequences.Train_At (Seq, St.Dist_Cm);
         begin
            return Pass ("DMI Train Data entered (axle load"
                         & Integer'Image (T.Axle_Load) & ", gauge"
                         & Integer'Image (T.Gauge) & ")");
         end;
      elsif Same (Verb, "validate")
        and then (Same (Item, "Train-Data")
                  or else Same (Item, "Flexible-Train-Data"))
      then
         --  the data the window proposes, accepted as they are (the
         --  driver revalidates the Train Data the on-board has)
         if Top_Is (W_Train_Data) then
            Press (167, 440);
         end if;
         if not Top_Is (W_Train_Data_Validation) then
            return Fail ("DMI validate Train Data: the validation window is "
                         & "not open, top is " & Top_Image);
         end if;
         Press (487, 40);
         return Pass ("DMI Train Data validated");
      elsif Same (Verb, "enter") and then Same (Item, "Train-Running-Number")
      then
         if not Top_Is (W_TRN) then
            declare
               J : constant Judgement_T :=
                 Press_Menu (W_Main, 6, "Train running number");
            begin
               if J.Verdict = Failed then
                  return J;
               end if;
            end;
         end if;
         Type_Digits ("1234");
         Enter_Single;
         return Pass ("DMI train running number entered");
      elsif Same (Verb, "press") and then Same (Item, "Start") then
         return Press_Menu (W_Main, 1, "Start");
      elsif Same (Verb, "acknowledge") then
         if Same (Item, "Trip") or else Same (Item, "Staff-Responsible")
           or else Same (Item, "On-Sight") or else Same (Item, "Shunting")
           or else Same (Item, "Unfitted")
           or else Same (Item, "Limited-Supervision")
           or else Same (Item, "Reversing")
           or else Has (Item, "announcement")
           or else Same (Item, "brake-intervention")
           or else Has (Item, "text-message")
           or else Has (Item, "Mode-")
         then
            return Acknowledge (Item);
         elsif Same (Item, "National-System") then
            return NJ (R_NTC, "acknowledge SN");
         end if;
         return NJ (R_Runner, "DMI acknowledge " & Item);
      elsif Same (Verb, "press") and then Same (Item, "Main") then
         return (if Open_Window (W_Main) then Pass ("DMI Main window")
                 else Fail ("DMI Main: cannot be opened over " & Top_Image));
      elsif Same (Verb, "press") and then Same (Item, "Override") then
         return (if Open_Window (W_Override) then Pass ("DMI Override")
                 else Fail ("DMI Override: cannot be opened over "
                            & Top_Image));
      elsif Same (Verb, "press") and then Same (Item, "Special") then
         return (if Open_Window (W_Special) then Pass ("DMI Special")
                 else Fail ("DMI Special: cannot be opened over "
                            & Top_Image));
      elsif Same (Verb, "press") and then Same (Item, "Data-view") then
         return (if Open_Window (W_Data_View) then Pass ("DMI Data view")
                 else Fail ("DMI Data view: cannot be opened over "
                            & Top_Image));
      elsif Same (Verb, "press") and then Top_Is (W_Driver_ID)
        and then (Has (Item, "Settings") or else Has (Item, "Train-Running"))
        and then DMI_Windows.Button_Count >= 2
      then
         --  11.3.3.6, 11.3.3.7: in the step S1 of Start Up the Driver ID
         --  window has 'TRN' and 'settings' buttons, its last two
         Press_Area (DMI_Windows.Button_Area
                       (DMI_Windows.Button_Count
                        - (if Has (Item, "Settings") then 0 else 1)));
         return Pass ("DMI " & Item & " from the Driver ID window");
      elsif Same (Verb, "press") and then Has (Item, "Settings") then
         return (if Open_Window (W_Settings) then Pass ("DMI Settings")
                 else Fail ("DMI Settings: cannot be opened over "
                            & Top_Image));
      elsif Same (Verb, "press") and then Same (Item, "Override-EoA") then
         return Press_Menu (W_Override, 1, "Override EoA");
      elsif Same (Verb, "press") and then Same (Item, "SHUNTING") then
         return Press_Menu (W_Main, 7, "Shunting");
      elsif Same (Verb, "press") and then Same (Item, "EXIT-SHUNTING") then
         return Press_Menu (W_Main, 7, "Exit Shunting");
      elsif Same (Verb, "press") and then Same (Item, "NON-LEADING") then
         return Press_Menu (W_Main, 8, "Non-leading");
      elsif Same (Verb, "press") and then Same (Item, "MAINTAIN-SHUNTING")
      then
         return Press_Menu (W_Main, 9, "Maintain Shunting");
      elsif Same (Verb, "press") and then Same (Item, "Driver-ID") then
         return Press_Menu (W_Main, 2, "Driver ID");
      elsif Same (Verb, "press") and then Same (Item, "Level") then
         return Press_Menu (W_Main, 5, "Level");
      elsif Same (Verb, "press")
        and then (Same (Item, "Train-Running-Number")
                  or else Same (Item, """Train-Running-Number""-[MAIN]"))
      then
         return Press_Menu (W_Main, 6, "Train running number");
      elsif Same (Verb, "press") and then Same (Item, "Adhesion") then
         return Press_Menu (W_Special, 1, "Adhesion");
      elsif Same (Verb, "press") and then Same (Item, "SR-speed/distance")
      then
         return Press_Menu (W_Special, 2, "SR speed/distance");
      elsif Same (Verb, "press") and then Same (Item, "Train-Integrity") then
         return Press_Menu (W_Special, 3, "Train integrity");
      elsif Same (Verb, "press") and then Same (Item, "System-version") then
         return Press_Menu (W_Settings, 4, "System version");
      elsif Same (Verb, "request") and then Has (Item, "speed-and-distance")
      then
         --  8.2.2.4: the A/B toggle, where the default window shows it:
         --  the driver closes the windows that are open first
         for I in 1 .. 4 loop
            exit when not DMI_Windows.Is_Open
              or else not DMI_Windows.Close_Enabled;
            Press_Area (DMI_Windows.Close_Button_Area);
         end loop;
         if DMI_Windows.Is_Open then
            return Fail ("DMI speed information toggle: a window is open: "
                         & Top_Image);
         end if;
         Press (150, 150);
         return Pass ("DMI speed information toggled");
      elsif Same (Verb, "close") then
         if not DMI_Windows.Is_Open then
            return Fail ("DMI close " & Item & ": no window open");
         elsif not DMI_Windows.Close_Enabled then
            return Fail ("DMI close " & Item & ": [Close] disabled");
         end if;
         Press_Area (DMI_Windows.Close_Button_Area);
         return Pass ("DMI " & Item & " closed");
      elsif (Same (Verb, "modify") or else Same (Verb, "confirm"))
        and then Same (Item, "Adhesion-Factor")
      then
         if not Top_Is (W_Adhesion) and then Same (Verb, "modify") then
            return Press_Menu (W_Special, 1, "Adhesion");
         elsif not Top_Is (W_Adhesion) then
            return Fail ("DMI confirm adhesion: the window is not open, top "
                         & "is " & Top_Image);
         end if;
         --  11.3.11: the dedicated keyboard, key 1 non slippery, key 2
         --  slippery rail
         if Has (Image (St.Comment), "Non Slippery")
           or else Has (Image (St.Comment), "non-slippery")
         then
            Key (1);
         elsif Has (Image (St.Comment), "Slippery") then
            Key (2);
         end if;
         Enter_Single;
         return Pass ("DMI adhesion entered");
      elsif Same (Verb, "press") and then Same (Item, "Geographical-Position")
      then
         if DMI_Windows.Is_Open then
            return Fail ("DMI geographical position: a window is open: "
                         & Top_Image);
         end if;
         Press_Area (Display.Get_Area (Display.G12));
         return Pass ("DMI geographical position toggled");
      elsif Same (Verb, "request") and then Has (Item, "tunnel-stopping-area")
      then
         if DMI_Windows.Is_Open then
            return Fail ("DMI tunnel toggle: a window is open: " & Top_Image);
         end if;
         Press_Area (Display.C_Area.Tunnel_Toggle_Area);
         return Pass ("DMI tunnel stopping area toggled");
      elsif Same (Verb, "press") and then Same (Item, "BMM-reaction-inhibition")
      then
         return Press_Menu (W_Special, 4, "BMM reaction inhibition");
      elsif Has (Item, "VBC") then
         return NJ (R_E6, "DMI " & Verb & " " & Item & " (VBC, 3.15.9)");
      elsif Same (Verb, "isolate") then
         Desk_Isolation;
         return Pass ("DMI isolation");
      elsif Same (Item, "Enter-RBC-data") and then Same (Verb, "press") then
         return Press_Menu (W_Radio_Data, 3, "Enter RBC data");
      elsif Same (Item, "Contact-last-RBC") and then Same (Verb, "press") then
         return Press_Menu (W_Radio_Data, 1, "Contact last RBC");
      elsif Same (Item, "Use-short-number") and then Same (Verb, "press") then
         return Press_Menu (W_Radio_Data, 2, "Use short number");
      elsif Same (Item, "RBC-data")
        and then (Same (Verb, "enter") or else Same (Verb, "confirm")
                  or else Same (Verb, "validate"))
      then
         return RBC_Data_Entry (Verb);
      elsif Same (Item, "Radio-Data") and then Same (Verb, "press") then
         --  the driver presses 'Radio data' in the Main window (DMI
         --  11.2.5, Table 50 S1 -> S5-1), from the default window too;
         --  the Radio data window already open, there is nothing to press
         if Top_Is (W_Radio_Data) then
            return Pass ("DMI Radio data window open");
         end if;
         return Press_Menu (W_Main, 10, "Radio data");
      elsif Has (Item, "RBC") or else Has (Item, "Radio")
        or else Has (Item, "GSM-R")
      then
         --  the radio data dialogues of the start of mission in level 2
         --  (5.4.3.2; DMI 11.2.5, 11.3.4, 11.3.5, 11.3.15, 11.3.16): the
         --  on-board opens them; the runner does not fill them yet, so
         --  the step is judged only on the window being there
         if not (Top_Is (W_Radio_Data) or else Top_Is (W_RBC_Data)
                 or else Top_Is (W_GSMR_Network)
                 or else Top_Is (W_Radio_Network_Type)
                 or else Top_Is (W_One_Radio))
         then
            return Fail ("DMI radio data dialogue: no radio data window "
                         & "open, top is " & Top_Image);
         end if;
         return NJ (R_Radio, "DMI " & Verb & " " & Item);
      elsif Has (Item, "SM") or else Has (Item, "Track-ahead") then
         return NJ (R_Radio, "DMI " & Verb & " " & Item);
      elsif Has (Item, "ATO") then
         return NJ (R_ATO, "DMI " & Verb & " " & Item);
      end if;
      return NJ (R_Runner, "DMI " & Verb & " " & Item);
   end DMI_Input;

   ---------------------------------------------------------------------
   --  Inputs
   ---------------------------------------------------------------------

   --  An input is applied (Passed: then the columns are judged), cannot
   --  be applied by the driver (Failed), or blocks the sequence (Not
   --  judged, with the reason)

   function Timer_Seconds (Name : String; Found : out Boolean)
     return Natural
   is
      Best : Natural := 0;
   begin
      Found := False;
      for I in 1 .. Seq.Timer_Count loop
         if Same (Image (Seq.Timers (I).Name_Text), Name)
           and then Seq.Timers (I).Step <= Seq.Steps (Cur).Number
         then
            Best := Natural (Unsigned_64'Min (Seq.Timers (I).Value, 100_000));
            Found := True;
         end if;
      end loop;
      return Best;
   end Timer_Seconds;

   --  The timer is taken to have started when the step before ended: the
   --  time the train took to reach the step's distance counts
   procedure Run_Timer (Seconds : Natural) is
      Elapsed : constant Unsigned_64 := B.Time_Ms - Step_Start_Ms;
      Due     : constant Unsigned_64 := Unsigned_64 (Seconds) * 1000 + 200;
   begin
      if Elapsed < Due then
         for K in 1 .. (Natural (Due - Elapsed) + B.Cycle_Ms - 1) / B.Cycle_Ms
         loop
            Wait_Cycle;
         end loop;
      end if;
   end Run_Timer;

   --  "N seconds", "N second", "N sec", "N s" or "Ns" in a text (the
   --  first one), -1 without
   function Text_Seconds (T : String) return Integer is
      I : Natural := T'First;
   begin
      while I <= T'Last loop
         if T (I) in '0' .. '9'
           and then (I = T'First or else T (I - 1) not in '0' .. '9')
         then
            declare
               J : Natural := I;
               N : Natural := 0;
            begin
               while J <= T'Last and then T (J) in '0' .. '9' loop
                  if N < 100_000 then
                     N := N * 10
                       + (Character'Pos (T (J)) - Character'Pos ('0'));
                  end if;
                  J := J + 1;
               end loop;
               if J <= T'Last and then T (J) = ' ' then
                  J := J + 1;
               end if;
               if J <= T'Last and then (T (J) = 's' or else T (J) = 'S')
                 and then (J = T'Last
                           or else T (J + 1) not in 'a' .. 'z' | 'A' .. 'Z'
                           or else Starts (T (J .. T'Last), "sec"))
               then
                  return N;
               end if;
               I := J;
            end;
         else
            I := I + 1;
         end if;
      end loop;
      return -1;
   end Text_Seconds;

   function Timer_Input (St : Step_T) return Judgement_T is
      Name : constant String := W (4);
      subtype Name_T is String (1 .. 14);
      Known : constant array (1 .. 9) of Name_T :=
        ("T_SECTIONTIMER", "T_ENDTIMER    ", "T_TEXTDISPLAY ",
         "T_ACK         ", "T_LSSMA       ", "T_NVCONTACT   ",
         "T_CYCRQST     ", "T_CYCLOC      ", "T_EMA         ");
      function K (I : Positive) return String is
        (Ada.Strings.Fixed.Trim (Known (I), Ada.Strings.Right));
      Found : Boolean;
      Chosen : Natural := 0;
   begin
      --  "T_SECTIONTIMER - T_TIMEOUTRQST", "T_EMA ' T_TIMEOUTREQUEST" (the
      --  minus garbled in some comments, 3080200_01 step 69): the timer
      --  less the time before it at which the on-board asks for a new MA
      --  (3.8.2.2.1 b), both from the sequence's messages
      if Name = "" or else Name (Name'First) = '<' then
         declare
            C : constant String := Image (St.Comment);
            P : constant Natural := Ada.Strings.Fixed.Index (C, "T_TIMEOUTR");
            Before : constant String :=
              (if P > C'First then C (C'First .. P - 1) else "");
            First : constant String :=
              (if Has (Before, "T_EMA") then "T_EMA"
               elsif Has (Before, "T_SECTION") then "T_SECTIONTIMER"
               else "");
            I : Integer := P - 1;
            F1, F2 : Boolean;
         begin
            while I > C'First and then C (I) = ' ' loop
               I := I - 1;
            end loop;
            if First /= "" and then P > C'First and then I >= C'First
              and then C (I) in '-' | ''' | Character'Val (16#B4#)
            then
               declare
                  S1 : constant Natural := Timer_Seconds (First, F1);
                  S2 : constant Natural :=
                    Timer_Seconds ("T_TIMEOUTRQST", F2);
               begin
                  if F1 and then F2 and then S1 < 1023 and then S2 < S1 then
                     Run_Timer (S1 - S2);
                     return Pass (First & " - T_TIMEOUTRQST"
                                  & Natural'Image (S1 - S2) & " s elapsed");
                  end if;
               end;
            end if;
         end;
      end if;
      --  the named timer, or one the comment names
      for I in Known'Range loop
         if Same (Name, K (I))
           or else (Name = "" and then Has (Image (St.Comment), K (I)))
         then
            Chosen := I;
            exit;
         end if;
      end loop;
      --  A timer without a name whose comment gives its duration runs
      --  that long (3080200_04 step 72: "The train stops before the EOA
      --  and 255 seconds have passed since the MA request was sent")
      if Name = "" and then Chosen = 0
        and then Text_Seconds (Image (St.Comment)) >= 0
      then
         Run_Timer (Text_Seconds (Image (St.Comment)));
         return Pass ("timer of"
                      & Integer'Image (Text_Seconds (Image (St.Comment)))
                      & " s elapsed (the comment's)");
      end if;
      --  the radio timers whose value a message gave (T_NVCONTACT of
      --  packet 3, T_CYCRQST of packet 57, T_CYCLOC of packet 58, in s)
      --  are run as the others; 255 is "infinite" (7.5.1)
      if (Chosen = 0 or else Chosen >= 6)
        and then (Name = "T_CYCRQSTD"
                  or else Name = "T_TIMEOUTRQST"
                  or else (Name = "" and then (Has (Image (St.Comment), "radio")
                                     or else Has (Image (St.Comment),
                                                  "registration")
                                     or else Has (Image (St.Comment), "RBC"))))
      then
         return NJ (R_Radio, "timer " & Name);
      end if;
      if Chosen = 0 then
         return NJ (R_Runner, "timer " & (if Name = "" then "without a name"
                                          else Name));
      end if;
      if K (Chosen) = "T_ACK" then
         --  A.3.1: T_ACK 5 s
         Run_Timer (5);
         return Pass ("T_ACK elapsed");
      end if;
      declare
         S : constant Natural := Timer_Seconds (K (Chosen), Found);
      begin
         if Chosen >= 6 and then (not Found or else S = 255) then
            return NJ (R_Radio, "timer " & K (Chosen)
                       & (if Found then " infinite" else " without a value"));
         elsif not Found or else S >= 1023 then
            return NJ (R_Runner, "timer " & K (Chosen)
                       & " without a value");
         end if;
         Run_Timer (S);
         return Pass (K (Chosen) & Natural'Image (S) & " s elapsed");
      end;
   end Timer_Input;

   --  The front end of the antenna and the point named by a reach-point
   --  input, relative to the antenna, cm
   function Point_Offset (Kind : String; Ok : out Boolean) return Integer_64
   is
      F : constant Integer_64 := B.Front_Offset;
   begin
      Ok := True;
      if Same (Kind, "estimated-front-end") then
         return F;
      elsif Same (Kind, "max-safe-front-end")
        or else Same (Kind, "virtual-max-safe-front-end")
      then
         return F + B.Doubt_Over;
      elsif Same (Kind, "min-safe-front-end") then
         return F - B.Doubt_Under;
      elsif Same (Kind, "min-safe-rear-end") then
         return F - B.Doubt_Under - Integer_64 (Train_Length_M) * 100;
      elsif Same (Kind, "min-safe-antenna") then
         return -B.Doubt_Under;
      elsif Same (Kind, "max-safe-antenna") then
         return B.Doubt_Over;
      end if;
      Ok := False;
      return 0;
   end Point_Offset;

   --  The national speed value an expression names (V_NVALLOWOVTRP,
   --  V_NVSUPOVTRP, V_NVONSIGHT, V_NVSHUNT, V_NVSTFF), km/h: the last one
   --  the sequence's telegrams gave before the step, else the default of
   --  A.3.2; -1 when the expression names none
   function National_Limit (E : String) return Integer is
      type Name_Default is record
         Name : String (1 .. 14);
         Kmh  : Natural;
      end record;
      Names : constant array (1 .. 5) of Name_Default :=
        (("V_NVALLOWOVTRP", 0), ("V_NVSUPOVTRP  ", 30),
         ("V_NVONSIGHT   ", 30), ("V_NVSHUNT     ", 30),
         ("V_NVSTFF      ", 40));
   begin
      for N of Names loop
         declare
            Nm : constant String :=
              Ada.Strings.Fixed.Trim (N.Name, Ada.Strings.Right);
            V  : Integer := N.Kmh;
         begin
            if Has (E, Nm) then
               for I in 1 .. Seq.Timer_Count loop
                  if Same (Image (Seq.Timers (I).Name_Text), Nm)
                    and then Seq.Timers (I).Step < Seq.Steps (Cur).Number
                    and then Seq.Timers (I).Value < 127
                  then
                     V := Natural (Seq.Timers (I).Value) * 5;
                  end if;
               end loop;
               return V;
            end if;
         end;
      end loop;
      return -1;
   end National_Limit;

   --  The output steps of the input's block (up to the next input)
   --  expect the emergency brake (EB) or the service brake commanded
   function Brake_Expected (EB : Boolean) return Boolean is
   begin
      for I in Cur + 1 .. Seq.Step_Count loop
         exit when Seq.Steps (I).IO = Input;
         declare
            L : constant String := Image (Seq.Steps (I).Line);
         begin
            if Has (L, (if EB then "TIU emergency-brake commanded"
                        else "TIU service-brake commanded"))
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Brake_Expected;

   --  A reach-point of the max safe front end or the min safe rear end
   --  whose comment names the location of packet 58 (Q_LGTLOC, D_LOC)
   --  or the RBC/RBC border of packet 131 (D_RBCTR, "RBC transition"),
   --  on a train moving forward with such a location stored on-board:
   --  the step's distance is nominal (3150100_01: the location is at
   --  1400 m, the step says 800 m), the location is the on-board's
   function Stored_Location (St : Step_T) return Boolean is
      C : constant String := Image (St.Comment);
      Front : constant Boolean := Same (W (4), "max-safe-front-end");
   begin
      return (Front or else Same (W (4), "min-safe-rear-end"))
        and then (Has (C, "Q_LGTLOC") or else Has (C, "D_LOC")
                  or else Has (C, "D_RBCTR")
                  or else Has (C, "RBC transition"))
        and then B.Direction >= 0
        and then Integer_64 (EVC_Position.Report_Location_To_Go (Front))
                   < EVC_Distances.Max_Cm;
   end Stored_Location;

   --  The train runs until the on-board's nearest location of that kind
   --  is passed (EVC_Position.Report_Location_To_Go: none left, or 0);
   --  the doubts grow with the move: a few rounds
   function Reach_Stored_Location (Front : Boolean) return Judgement_T is
      Go : Integer_64 :=
        Integer_64 (EVC_Position.Report_Location_To_Go (Front));
      --  the antenna where the first location is reached; a location
      --  found well beyond it after a round is the next one (packet 58
      --  repeats its locations), not this one
      Target : Integer_64 := B.Position + Go;
   begin
      for Round in 1 .. 4 loop
         exit when Go = 0 or else Go >= EVC_Distances.Max_Cm
           or else B.Position + Go > Target + 100;
         Target := B.Position + Go;
         Move_To (Target + 1);
         Go := Integer_64 (EVC_Position.Report_Location_To_Go (Front));
      end loop;
      return Pass ("ODO " & W (4) & " at the stored location, antenna at"
                   & Img (Integer (B.Position)));
   end Reach_Stored_Location;

   function ODO_Input (St : Step_T) return Judgement_T is
      Kind : constant String := W (3);
   begin
      if Same (Kind, "reach-point") then
         declare
            Ok : Boolean;
            Off : Integer_64 := Point_Offset (W (4), Ok);
         begin
            if not Ok then
               return NJ (R_Runner, "ODO reach-point " & W (4));
            end if;
            if Stored_Location (St) then
               return Reach_Stored_Location (Same (W (4),
                                                   "max-safe-front-end"));
            end if;
            --  B226: a location the train reaches above the warning speed
            --  (the comment says so; the charts are drawings and may run
            --  above the SBI there): between the warning speed and the SBI
            --  shown, held
            declare
               S : constant B.State_T := B.State;
            begin
               if Has (Image (St.Comment), "overpasses the warning speed")
                 and then S.Has_Speed and then S.V_SBI > S.V_Wsl
               then
                  Explicit_Speed :=
                    Kmh_To_Cms (Long_Float (S.V_Wsl + S.V_SBI) / 2.0);
               end if;
            end;
            --  the doubts grow with the move: a few rounds
            for Round in 1 .. 4 loop
               Move_To (St.Dist_Cm - Off);
               Off := Point_Offset (W (4), Ok);
               exit when B.Position + Off >= St.Dist_Cm - 50;
            end loop;
            return Pass ("ODO " & W (4) & " at" & Img (Integer (St.Dist_Cm)));
         end;
      elsif Same (Kind, "reach") then
         Explicit_Speed := -1;
         B.Set_Speed (0);
         return Pass ("ODO standstill");
      elsif Same (Kind, "start-moving") then
         Explicit_Speed := -1;
         --  the comment, or the next distance, says which way
         if Has (Image (St.Comment), "backward")
           or else Has (Image (St.Comment), "reverse")
         then
            B.Set_Direction (-1);
         elsif Has (Image (St.Comment), "forward") then
            B.Set_Direction (1);
         elsif Cur < Seq.Step_Count
           and then Seq.Steps (Cur + 1).Dist_Cm < St.Dist_Cm - 100
         then
            B.Set_Direction (-1);
         end if;
         --  backwards from where the speed chart stops the train, when
         --  that is just ahead (the step's distance is where the reverse
         --  movement is seen, not where it starts)
         if B.Direction < 0 and then Seq.Chart_Count > 1 then
            for K in 2 .. Seq.Chart_Count loop
               declare
                  X : constant Integer_64 :=
                    Integer_64 (Seq.Chart (K).X_M * 100.0);
               begin
                  if Seq.Chart (K).V_Kmh < 1.0
                    and then X > B.Position
                    and then X - St.Dist_Cm <= 2_000
                  then
                     B.Set_Direction (1);
                     B.Move_To (X, Kmh_To_Cms (10.0));
                     B.Set_Direction (-1);
                     exit;
                  end if;
               end;
            end loop;
         end if;
         B.Set_Speed (Transit_Cms);
         return Pass ("ODO moving"
                      & (if B.Direction < 0 then " backwards" else ""));
      elsif Same (Kind, "direction-reversed") then
         B.Set_Direction (-B.Direction);
         if B.Speed = 0 then
            B.Set_Speed (Kmh_To_Cms (5.0));
         end if;
         return Pass ("ODO direction reversed");
      elsif Same (Kind, "speed") then
         declare
            E   : constant String := W (5);
            S   : constant B.State_T := B.State;
            Kmh : Integer := -1;
            --  A.3.1 default dV_ebi / dV_sbi below V_ebi_min / V_sbi_min
            --  the operator after V_TRAIN; "<x>" brackets an expression
            Op : constant Character :=
              (if E'Length > 7 then E (E'First + 7) else '>');
            Below : constant Boolean := Op = '<';
            Much  : constant Boolean :=
              Below and then E'Length > 8 and then E (E'First + 8) = '<';
         begin
            if not S.Has_Speed then
               return NJ (R_Runner, "ODO speed without supervision shown");
            end if;
            if Has (E, "EBI") then
               Kmh := (S.V_Perm) + 8;
            elsif Has (E, "SBI") then
               Kmh := (if Below then S.V_SBI - 1 else S.V_SBI + 1);
            elsif Has (E, "warning") and then not Below then
               --  B226: above the warning speed and below the SBI, the
               --  middle of the two values shown (each rounded to the
               --  km/h): one above the warning limit expects the Warning
               --  status, not the Intervention
               Explicit_Speed :=
                 Kmh_To_Cms (Long_Float (S.V_Wsl + S.V_SBI) / 2.0);
               B.Set_Speed (Explicit_Speed);
               return Pass ("ODO speed between warning" & S.V_Wsl'Image
                            & " and SBI" & S.V_SBI'Image & " km/h");
            elsif Has (E, "warning") then
               Kmh := S.V_Wsl - 1;
            elsif National_Limit (E) >= 0 then
               --  a national speed value (A.3.2, or the sequence's packet
               --  3): above or below it by 5 km/h
               declare
                  V : constant Natural := National_Limit (E);
               begin
                  Kmh := (if Much then V / 2
                          elsif Below then Integer'Max (1, V - 5)
                          elsif E'Length > 8 and then E (E'First + 8) = '>'
                          then V + 15
                          elsif Brake_Expected (EB => True) then S.V_SBI + 8
                          elsif Brake_Expected (EB => False) then S.V_SBI + 1
                          else V + 5);
               end;
            elsif Has (E, "V_STEP") or else Has (E, "V_1>")
              or else Has (E, "V1>")
            then
               --  a value of the step's own table: not in the text
               Kmh := -1;
            else
               --  V_PERM, V_MRSP, a mode limit (V_NVONSIGHT, V_NVSHUNT,
               --  ...) or a TSR the train runs under: the permitted speed
               --  the on-board shows stands for it
               if Much then
                  Kmh := S.V_Perm / 2;
               elsif Below then
                  Kmh := S.V_Perm - 2;
               elsif Has (E, "+6") then
                  Kmh := S.V_Perm + 7;
               elsif E'Length > 8 and then E (E'First + 8) = '>' then
                  Kmh := S.V_Perm + 15;
               elsif Brake_Expected (EB => True) then
                  --  "above the limit" where the steps that follow expect
                  --  a brake: above the supervision limit that commands it
                  Kmh := S.V_SBI + 8;
               elsif Brake_Expected (EB => False) then
                  Kmh := S.V_SBI + 1;
               else
                  Kmh := S.V_Perm + 1;
               end if;
            end if;
            if Kmh < 0 then
               return NJ (R_Runner, "ODO speed " & E);
            end if;
            Kmh := Integer'Max (Kmh, 1);
            Explicit_Speed := Kmh_To_Cms (Long_Float (Kmh));
            B.Set_Speed (Explicit_Speed);
            return Pass ("ODO speed" & Integer'Image (Kmh) & " km/h");
         end;
      end if;
      return NJ (R_Runner, "ODO " & Kind);
   end ODO_Input;

   --  the train configuration the TIU reports (bits 0 to 5 of input 13)
   Train_Configuration : Natural := 1;

   function TIU_Input (St : Step_T) return Judgement_T is
      Kind : constant String := W (3);
      Arg  : constant String := W (4);
   begin
      if Same (Kind, "cab") then
         --  the driver who opens a desk puts its direction controller
         --  forward (the sequences set it themselves only to change it)
         --  and the train configuration of the train interface is known
         --  (EVC_Ports TIU input 13: the first value is not a change)
         if Same (Arg, "A") then
            B.TIU_Input (2, 0);
            B.TIU_Input (1, 1);
            B.TIU_Input (6, 1);
            B.TIU_Input (13, Train_Configuration);
         elsif Same (Arg, "B") then
            B.TIU_Input (1, 0);
            B.TIU_Input (2, 1);
            B.TIU_Input (6, 1);
            B.TIU_Input (13, Train_Configuration);
         else
            B.TIU_Input (1, 0);
            B.TIU_Input (2, 0);
         end if;
         return Pass ("TIU cab " & Arg);
      elsif Same (Kind, "direction") then
         B.TIU_Input (6, (if Same (Arg, "forward") then 1
                          elsif Same (Arg, "backward") then 2 else 0));
         --  the train will move the way the controller says
         if Same (Arg, "forward") then
            B.Set_Direction (1);
         elsif Same (Arg, "backward") then
            B.Set_Direction (-1);
         end if;
         return Pass ("TIU direction " & Arg);
      elsif Same (Kind, "sleeping") then
         B.TIU_Input (3, (if Same (Arg, "requested") then 1 else 0));
         return Pass ("TIU sleeping " & Arg);
      elsif Same (Kind, "passive-shunting") then
         B.TIU_Input (4, 1);
         return Pass ("TIU passive shunting");
      elsif Same (Kind, "non-leading") then
         B.TIU_Input (5, (if Same (Arg, "permitted") then 1 else 0));
         return Pass ("TIU non-leading " & Arg);
      elsif Same (Kind, "eddy-current-brake") then
         B.TIU_Input (8, (if Same (Arg, "active") then 1 else 0));
         return Pass ("TIU eddy current brake " & Arg);
      elsif Same (Kind, "magnetic-shoe-brake") then
         B.TIU_Input (9, (if Same (Arg, "active") then 1 else 0));
         return Pass ("TIU magnetic shoe brake " & Arg);
      end if;
      if Same (Kind, "other-train-data") then
         if Has (Image (St.Comment), "set speed")
           or else Has (Image (St.Comment), "SETSPEED")
         then
            return NJ (R_Not_Modelled, "TIU set speed (cruise control)");
         end if;
         --  5.17: new Train Data from the train interface (EVC_Ports TIU
         --  input 13): to be validated by the driver (D0) when the comment
         --  says so, of a category, axle load, gauge or traction (D1) when
         --  it names one
         Train_Configuration := (Train_Configuration mod 63) + 1;
         B.TIU_Input
           (13, Train_Configuration
                + (if Has (Image (St.Comment), "validat") then 64 else 0)
                + (if Has (Image (St.Comment), "category")
                     or else Has (Image (St.Comment), "axle load")
                     or else Has (Image (St.Comment), "loading gauge")
                     or else Has (Image (St.Comment), "traction system")
                   then 128 else 0));
         return Pass ("TIU train configuration changed");
      end if;
      return NJ ((if Same (Kind, "train-integrity")
                    or else Same (Kind, "safe-consist-length")
                  then R_Not_Modelled else R_Runner),
                 "TIU " & Kind);
   end TIU_Input;

   --  Bits From .. From + Len - 1 (0 = the first, msb first) of a
   --  telegram's data
   function Field (T : Telegram_T; From, Len : Natural) return Natural is
      V : Natural := 0;
   begin
      for I in From .. From + Len - 1 loop
         V := V * 2
           + Natural (T.Data (1 + I / 8) / 2**(7 - I mod 8)) mod 2;
      end loop;
      return V;
   end Field;

   --  The header of a telegram (7.4.1.1): N_PIG, N_TOTAL, NID_BG
   function N_PIG (T : Telegram_T) return Natural is (Field (T, 9, 3));
   function N_TOTAL (T : Telegram_T) return Natural is (Field (T, 12, 3));
   function NID_BG (T : Telegram_T) return Natural is (Field (T, 35, 14));

   --  The telegrams of a balise group input: placed on the track and
   --  passed by the antenna
   function BTM_Input (St : Step_T) return Judgement_T is
      Far   : Integer_64 := St.Dist_Cm;
      Found : Natural := 0;
   begin
      if Line.Count < 4 then
         --  a packet of a telegram an earlier step delivered
         return Pass ("BTM (delivered at an earlier step)");
      end if;
      for K in 4 .. Line.Count loop
         declare
            Tag : constant String := W (K);
            Step_Of : Natural := 0;
         begin
            if Tag'Length > 6
              and then Tag (Tag'First .. Tag'First + 5) = "PACKET"
            then
               return NJ (R_ATO, "BTM " & Tag);
            elsif Tag = "LOOP" then
               return NJ (R_Euroloop, "BTM LOOP");
            end if;
            --  the telegrams of the tag at this step, else at the last
            --  step before it that has the tag
            for I in 1 .. Seq.Telegram_Count loop
               declare
                  T : Telegram_T renames Seq.Telegrams (I);
               begin
                  if T.Tag (1 .. T.Tag_Len) = Tag
                    and then T.Step <= St.Number and then T.Step >= Step_Of
                  then
                     Step_Of := T.Step;
                  end if;
               end;
            end loop;
            for I in 1 .. Seq.Telegram_Count loop
               declare
                  T : Telegram_T renames Seq.Telegrams (I);
               begin
                  if T.Tag (1 .. T.Tag_Len) = Tag
                    and then T.Step = Step_Of
                  then
                     if not T.Has_Bits then
                        return NJ (R_Extractor, "telegram " & Tag
                                   & " refused by the extractor");
                     end if;
                     --  Known defects of SUBSET-076 v4.0.0 against
                     --  SUBSET-026 v4.0.0: M_LEVELTEXTDISPLAY 5 ("no
                     --  level" before 4.0.0, spare in 4.0.0 7.5.1.66,
                     --  which has it as 4) in sequences of system
                     --  version 3.0; in those of 2.1 and 2.2 the coding
                     --  of their version (chapter 6, E7)
                     if T.M_Version < 0 then
                        --  the PDF loses rows where a table goes over a
                        --  page break (checked against the pages)
                        return NJ (R_S076_Defect, "telegram " & Tag
                                   & ": header rows lost at a page break");
                     end if;
                     if T.Level_3 then
                        return NJ (R_Level_3, "telegram " & Tag
                                   & ": an order to level 3 (M_LEVELTR 4)");
                     end if;
                     if T.Old_Level_Text then
                        return NJ ((if Seq.SV = 30 then R_S076_Defect
                                    else R_Version),
                                   "telegram " & Tag & ": M_LEVELTEXTDISPLAY"
                                   & " 5, the coding before 4.0.0 (7.5.1.66)");
                     end if;
                     if T.M_Version in 16 .. 31 then
                        return NJ (R_Version, "telegram " & Tag
                                   & " of system version"
                                   & Integer'Image (T.M_Version / 16) & "."
                                   & Img (T.M_Version mod 16));
                     end if;
                     declare
                        At_Cm : constant Integer_64 :=
                          T.Dist_Cm + T.Rel_Cm * Integer_64 (B.Direction);
                        Data : B.Byte_Array (1 .. Max_Bytes);
                     begin
                        for J in Data'Range loop
                           Data (J) := T.Data (J);
                        end loop;
                        B.Place_Balise (At_Cm, T.Bits, Data);
                        if (At_Cm - Far) * Integer_64 (B.Direction) > 0 then
                           Far := At_Cm;
                        end if;
                        Found := Found + 1;
                     end;
                  end if;
               end;
            end loop;
         end;
      end loop;
      if Found = 0 then
         return NJ (R_Extractor, "BTM: no telegram for " & W (4));
      end if;
      --  a balise of the step's group marked down-link (Q_UPDOWN 0, which
      --  no balise sends to a train: 7.4.1.1): outside the tests of the
      --  balise group consistency (feature 3.16), where a telegram may be
      --  wrong on purpose, a defect of SUBSET-076
      if Image (Seq.Feature)'Length < 3
        or else Image (Seq.Feature) (1 .. 3) /= "316"
      then
         for I in 1 .. Seq.Telegram_Count loop
            if Seq.Telegrams (I).Step = St.Number
              and then Seq.Telegrams (I).Has_Bits
              and then not Seq.Telegrams (I).Loop_Tag
              and then Field (Seq.Telegrams (I), 0, 1) = 0
            then
               return NJ (R_S076_Defect,
                          "BTM: a balise of the group marked down-link "
                          & "(Q_UPDOWN 0)");
            end if;
         end loop;
         --  two balises of the step's group with the same N_PIG
         for I in 1 .. Seq.Telegram_Count loop
            for J in I + 1 .. Seq.Telegram_Count loop
               declare
                  A : Telegram_T renames Seq.Telegrams (I);
                  C : Telegram_T renames Seq.Telegrams (J);
               begin
                  if A.Step = St.Number and then C.Step = St.Number
                    and then A.Has_Bits and then C.Has_Bits
                    and then not A.Loop_Tag and then not C.Loop_Tag
                    and then NID_BG (A) = NID_BG (C)
                    and then N_PIG (A) = N_PIG (C)
                  then
                     return NJ (R_S076_Defect,
                                "BTM: two balises of the group with N_PIG"
                                & Natural'Image (N_PIG (A)));
                  end if;
               end;
            end loop;
         end loop;
      end if;
      --  the balises of one group (N_TOTAL alike, N_PIG different) that
      --  carry different identities: a defect of SUBSET-076 (the tables
      --  of the second balise of a group copied with another NID_BG)
      for I in 1 .. Seq.Telegram_Count loop
         for J in 1 .. Seq.Telegram_Count loop
            declare
               A : Telegram_T renames Seq.Telegrams (I);
               C : Telegram_T renames Seq.Telegrams (J);
            begin
               if A.Step = St.Number and then C.Step = St.Number
                 and then A.Has_Bits and then C.Has_Bits
                 and then not A.Loop_Tag and then not C.Loop_Tag
                 and then N_TOTAL (A) = N_TOTAL (C) and then N_TOTAL (A) > 0
                 and then N_PIG (A) /= N_PIG (C)
                 and then NID_BG (A) /= NID_BG (C)
               then
                  return NJ (R_S076_Defect,
                             "BTM: the balises of one group with NID_BG"
                             & Natural'Image (NID_BG (A)) & " and"
                             & Natural'Image (NID_BG (C)));
               end if;
            end;
         end loop;
      end loop;
      --  the packets the step's text names must be in the telegrams. A
      --  text gives alternatives as "packet 72/73": the plain text packet
      --  is 72 in telegrams of system version 2.1 and earlier, 73 from
      --  2.2 (6.5.2.3.1.1.2). A packet in no telegram is a defect of
      --  SUBSET-076: the PDFs were read a second, independent way and
      --  their telegram tables do not hold it
      declare
         Txt : constant String := Image (St.Text);
         P   : Natural := Ada.Strings.Fixed.Index (Txt, "packet ");
      begin
         while P > 0 loop
            declare
               N : Natural := 0;
               K : Natural := P + 7;
               Alt  : Natural := 0;
               Have : Boolean := False;
            begin
               while K <= Txt'Last and then Txt (K) in '0' .. '9' loop
                  N := N * 10 + Character'Pos (Txt (K)) - 48;
                  K := K + 1;
               end loop;
               Alt := N;
               if K > P + 7 and then N < 255 then
                  loop
                     for I in 1 .. Seq.Telegram_Count loop
                        for J in 1 .. Seq.Telegrams (I).Packet_Count loop
                           if Seq.Telegrams (I).Step <= St.Number
                             and then
                               Natural (Seq.Telegrams (I).Packets (J)) = Alt
                           then
                              Have := True;
                           end if;
                        end loop;
                     end loop;
                     --  the next alternative, "/nn"
                     exit when K >= Txt'Last or else Txt (K) /= '/'
                       or else Txt (K + 1) not in '0' .. '9';
                     K := K + 1;
                     Alt := 0;
                     while K <= Txt'Last and then Txt (K) in '0' .. '9' loop
                        Alt := Alt * 10 + Character'Pos (Txt (K)) - 48;
                        K := K + 1;
                     end loop;
                  end loop;
                  if not Have then
                     return NJ (R_S076_Defect,
                                "BTM: packet" & Natural'Image (N)
                                & " of the text in no telegram");
                  end if;
               end if;
               P := Ada.Strings.Fixed.Index (Txt, "packet ", K);
            end;
         end loop;
      end;
      --  move past the last balise
      if B.Speed = 0 and then Explicit_Speed < 0 then
         null;
      end if;
      declare
         Target : constant Integer_64 := Far + 100 * Integer_64 (B.Direction);
         Was    : constant Natural := B.Speed;
      begin
         if (Target - B.Position) * Integer_64 (B.Direction) > 0 then
            Drive_To (Target);
            B.Set_Speed (Was);
            Arrive;
         else
            B.Cycle;
         end if;
      end;
      return Pass ("BTM" & Natural'Image (Found) & " telegrams");
   end BTM_Input;

   ---------------------------------------------------------------------
   --  The radio (RTM port, phase E5): S076_Run-Radio_Input and
   --  S076_Run-Radio_Expect
   ---------------------------------------------------------------------

   --  The session of the RBC of the sequence: 1. A sequence shows a
   --  second RBC by an RBC transition order (packet 131, 3.15.1.2) in a
   --  message or a telegram; Radio_Input routes its inputs to the second
   --  session by the order of events (RBC_Alive, RBC_Current).
   Radio_Session : constant := 1;

   function Radio_Input (St : Step_T) return Judgement_T is separate;
   --  The time a balise group input was given, after the move to its
   --  group (Apply_Input moves the train): the window of a negative radio expectation after it starts
   --  there, not at the start of the move (4090100_01 step 115: a 132
   --  sent in level 2 on the way to the transition's group)
   Group_Input_Ms : Unsigned_64 := 0;

   function Radio_Expect (St : Step_T) return Judgement_T is separate;

   function Apply_Input (St : Step_T) return Judgement_T is
      Iface : constant String := W (2);
      Kind  : constant String := W (3);
   begin
      if Iface = "SIM" then
         if Same (Kind, "power") then
            if Same (W (4), "on") then
               if not B.Powered then
                  B.Power_On;
               end if;
            else
               B.Power_Off;
               B.New_Window;
            end if;
            return Pass ("SIM power " & W (4));
         elsif Same (Kind, "fault") then
            B.Fault;
            return Pass ("SIM fault");
         elsif Same (Kind, "odometer-performance") then
            --  3.6.8, A.3.1: the sums of the over- and under-reading
            --  growth over the last 5000 m against 250 m (impaired) and
            --  1500 m (safety threshold); the odometer states the growth
            --  at once, the on-board checks it at the end of its next
            --  100 m interval
            if Same (W (4), "impaired") then
               B.Odometer_Error (30_000);
               B.Set_Accuracy (60);
            elsif Same (W (4), "critical") then
               B.Odometer_Error (160_000);
               B.Set_Accuracy (400);
            else
               B.Set_Accuracy (S076_Bench.Accuracy_Per_Mille);
            end if;
            return Pass ("SIM odometer " & W (4));
         elsif Same (Kind, "door-command") then
            return NJ (R_Not_Modelled, "SIM door command");
         end if;
         return NJ (R_Runner, "SIM " & Kind);
      elsif Iface = "TIU" then
         return TIU_Input (St);
      elsif Iface = "ODO" then
         return ODO_Input (St);
      elsif Iface = "INT" then
         if Same (Kind, "timer-expires") then
            return Timer_Input (St);
         end if;
         return NJ (R_Not_Modelled, "INT " & Kind);
      elsif Iface = "BTM" then
         return BTM_Input (St);
      elsif Iface = "DMI" then
         if not B.Powered then
            return Fail ("DMI " & Kind & ": the on-board is not powered");
         end if;
         return DMI_Input (St);
      elsif Iface = "RTM" then
         return Radio_Input (St);
      elsif Iface = "LTM" then
         return NJ (R_Euroloop, "LTM");
      elsif Iface = "ATO" then
         return NJ (R_ATO, "ATO " & Kind);
      end if;
      return NJ (R_Unclassified, "input " & Iface);
   end Apply_Input;

   ---------------------------------------------------------------------
   --  Expectations
   ---------------------------------------------------------------------

   type State_Word_T is (Displayed, Not_Displayed, Removed, Not_Removed,
                         Enabled, Disabled, Unknown_State);

   function State_Of (S : String) return State_Word_T is
     (if Same (S, "displayed") then Displayed
      elsif Same (S, "not-displayed") then Not_Displayed
      elsif Same (S, "removed") then Removed
      elsif Same (S, "not-removed") then Not_Removed
      elsif Same (S, "enabled") or else Same (S, "not-disabled") then Enabled
      elsif Same (S, "disabled") or else Same (S, "not-enabled") then Disabled
      else Unknown_State);

   --  Judge "shown" for a state word: In_Window (seen in at least one
   --  cycle since the input) and Now (at the end)
   function Shown (St_W : State_Word_T; In_Window, Now : Boolean;
                   What : String) return Judgement_T is
   begin
      case St_W is
         when Displayed | Enabled =>
            return Check (In_Window or else Now, What & " shown", "not shown");
         when Not_Displayed | Removed | Disabled =>
            return Check (not Now, What & " not shown", "shown");
         when Not_Removed =>
            return Check (Now, What & " still shown", "not shown");
         when Unknown_State =>
            return NJ (R_Unclassified, What & ": state");
      end case;
   end Shown;

   function Level_Code (K : Level_Kind_T) return Natural is
     (case K is
         when K_L0 => 2, when K_NTC => 3, when K_L1 => 4, when K_L2 => 5,
         when others => 16#FF#);

   function Mode_Symbol (St_W : State_Word_T; Name : String)
     return Judgement_T
   is
      S    : constant B.State_T := B.State;
      Seen : constant B.Seen_T := B.Seen;
      Ack  : constant Boolean :=
        Name'Length > 12
        and then Same (Name (Name'First .. Name'First + 11), "Acknowledge-");
      Base : constant String :=
        (if Ack then Name (Name'First + 12 .. Name'Last) else Name);
      Set  : constant Mode_Set_T := Mode_Of_Symbol (Base);
      In_W, Now : Boolean := False;
   begin
      if Same (Name, "Override-EOA-is-active") then
         return Shown (St_W, Seen.Override, S.Override, "override symbol");
      end if;
      if Set = No_Modes then
         return NJ (R_Runner, "mode symbol " & Name);
      end if;
      if Set (M_SN) then
         return NJ (R_NTC, "mode symbol " & Name);
      end if;
      for M in Mode_T loop
         if Set (M) and then DMI_Code (M) <= 63 then
            if Ack then
               In_W := In_W or else Seen.Mode_Ack (DMI_Code (M));
               Now := Now or else S.Mode_Ack = DMI_Code (M);
            else
               In_W := In_W or else Seen.Mode (DMI_Code (M));
               Now := Now or else S.Mode = DMI_Code (M);
            end if;
         end if;
      end loop;
      declare
         J : constant Judgement_T := Shown (St_W, In_W, Now,
                                            (if Ack then "mode to acknowledge "
                                             else "mode ") & Name);
      begin
         if J.Verdict = Failed then
            return Fail (Image (J.Sig) & " (mode code" & Img (S.Mode)
                         & ", to acknowledge" & Img (S.Mode_Ack) & ")");
         end if;
         return J;
      end;
   end Mode_Symbol;

   function Level_Symbol (St : Step_T; St_W : State_Word_T; Name : String)
     return Judgement_T
   is
      S    : constant B.State_T := B.State;
      Seen : constant B.Seen_T := B.Seen;
      Ann  : constant Boolean := Has (Name, "announcement");
      Ack  : constant Boolean := Has (Name, "Acknowledge");
      K    : Level_Kind_T;
   begin
      if Ann then
         --  the level announced: any
         declare
            In_W : Boolean := False;
            --  DMI 8.2.3.2: the announcement (LE06, LE08, LE10, LE12)
            --  gives way to its acknowledgement (LE07, LE09) when asked
            Now  : constant Boolean :=
              S.Level_Ann /= B.No_Value
              and then S.Level_Ann_Ack = Ack;
         begin
            for C in 2 .. 5 loop
               In_W := In_W or else (if Ack then Seen.Level_Ann_Ack (C)
                                     else Seen.Level_Ann (C));
            end loop;
            return Shown (St_W, In_W, Now, "level announcement " & Name);
         end;
      end if;
      K := Level_Of (Name);
      if K = K_None then
         --  "Level-0/1/2/NTC": the variant of the step's column
         K := Level_Of (Trim (St.Lvl_After));
      end if;
      if K = K_None or else K = K_L3 then
         return NJ (R_Runner, "level symbol " & Name);
      elsif K = K_NTC then
         return NJ (R_NTC, "level symbol " & Name);
      end if;
      return Shown (St_W, Seen.Level (Level_Code (K)),
                    S.Level = Level_Code (K),
                    "level " & Level_Abbrev (K) & " (code" & Img (S.Level)
                    & ")");
   end Level_Symbol;

   function SS_Message (St_W : State_Word_T; Name : String)
     return Judgement_T
   is
      N : constant Numbers_T := SS_Entries (Name);
      In_W, Now : Boolean := False;
   begin
      if N.Count = 0 then
         return NJ (R_Runner, "system status message " & Name);
      end if;
      for I in 1 .. N.Count loop
         for E in 1 .. B.SS_Count loop
            if B.SS (E).Entry_Number = N.List (I) and then B.SS (E).Event = 0
            then
               In_W := True;
            end if;
         end loop;
         if N.List (I) in 1 .. 38 then
            Now := Now or else DMI_System_Status.Active
                                 (DMI_System_Status.Entry_T (N.List (I)));
         end if;
      end loop;
      return Shown (St_W, In_W, Now, "system status message " & Name);
   end SS_Message;

   function Text_Message (St_W : State_Word_T; Class : Natural;
                          What : String) return Judgement_T is
      Put, Removed_W : Boolean := False;
   begin
      for I in 1 .. B.Text_Count loop
         if B.Text (I).Remove then
            Removed_W := True;
         elsif B.Text (I).Class = Class then
            Put := True;
         end if;
      end loop;
      case St_W is
         when Displayed =>
            return Check (Put, What & " sent", "none");
         when Not_Displayed =>
            return Check (not Put, What & " not sent", "sent");
         when Removed =>
            return Check (Removed_W, What & " removed", "not removed");
         when Not_Removed =>
            return Check (not Removed_W, What & " not removed", "removed");
         when others =>
            return NJ (R_Unclassified, What);
      end case;
   end Text_Message;

   function Window_Of (Name : String; Wid : out Window_ID_T) return Boolean
   is
   begin
      Wid := W_Main;
      if Same (Name, "Driver-ID") then Wid := W_Driver_ID;
      elsif Same (Name, "Main") then Wid := W_Main;
      elsif Same (Name, "Train-Data") then Wid := W_Train_Data;
      elsif Same (Name, "Train-Data-Validation") then
         Wid := W_Train_Data_Validation;
      elsif Same (Name, "Level") then Wid := W_Level;
      elsif Same (Name, "Radio-Data") then Wid := W_Radio_Data;
      elsif Same (Name, "RBC-Data") then Wid := W_RBC_Data;
      elsif Same (Name, "Data-View") then Wid := W_Data_View;
      elsif Same (Name, "Adhesion") then Wid := W_Adhesion;
      elsif Same (Name, "Override") then Wid := W_Override;
      elsif Same (Name, "Special") then Wid := W_Special;
      elsif Same (Name, "Settings") then Wid := W_Settings;
      elsif Same (Name, "Train-Running-Number") then Wid := W_TRN;
      elsif Same (Name, "SR-speed/distance") then Wid := W_SR_Data;
      elsif Same (Name, "System-version") then Wid := W_System_Version;
      else
         return False;
      end if;
      return True;
   end Window_Of;

   function DMI_Window (St : Step_T; St_W : State_Word_T; Name : String)
     return Judgement_T
   is
      Wid : Window_ID_T;
   begin
      --  B005: the Main window expected as the first step of a joined
      --  test case (row 1 after earlier steps), the train at standstill
      --  (3110300_03 step 69, "case 5210200 1": "The Main window is
      --  displayed", "the On-Board equipment waits for the driver
      --  action", then a button of the Main window). Nothing opens the
      --  Main window by itself there (DMI 10.x: the driver presses
      --  "Main" in area F): the joint of the two cases leaves out the
      --  driver's action, which the runner performs
      if Same (Name, "Main") and then St_W = Displayed
        and then St.Row = 1 and then St.Number > 1 and then B.Speed = 0
        and then not Top_Is (W_Main)
      then
         if Open_Window (W_Main) then
            B.Cycle;
         end if;
      end if;
      --  B302: the Adhesion window expected at standstill after rows of
      --  its test case the extract lacks (3130235_01 step 73, row 4
      --  after row 1: the driver's request through the Special window,
      --  DMI 11.3.11, is not in the sequence): the runner performs it
      if Same (Name, "Adhesion") and then St_W = Displayed
        and then Cur > 1 and then St.Row > 2
        and then Seq.Steps (Cur - 1).Row < St.Row - 1
        and then B.Speed = 0 and then not Top_Is (W_Adhesion)
      then
         declare
            J : constant Judgement_T :=
              Press_Menu (W_Special, 1, "Adhesion");
         begin
            if J.Verdict = Passed then
               B.Cycle;
            end if;
         end;
      end if;
      if Same (Name, "Default") then
         return Shown (St_W, not DMI_Windows.Is_Open,
                       not DMI_Windows.Is_Open, "default window (top "
                       & Top_Image & ")");
      end if;
      if not Window_Of (Name, Wid) then
         return NJ (R_DMI_Internal, "window " & Name);
      end if;
      declare
         J : constant Judgement_T :=
           Shown (St_W, Top_Is (Wid), Top_Is (Wid), "window " & Name);
      begin
         if J.Verdict = Failed then
            return Fail (Image (J.Sig) & " (top " & Top_Image & ")");
         end if;
         return J;
      end;
   end DMI_Window;

   function DMI_Button (St_W : State_Word_T; Name : String)
     return Judgement_T
   is
      Enabled_Now : Boolean;
   begin
      if Same (Name, "Close/Driver-ID") then
         if not Top_Is (W_Driver_ID) then
            return Fail ("button " & Name & ": the window is not open (top "
                         & Top_Image & ")");
         end if;
         Enabled_Now := DMI_Windows.Close_Enabled;
      elsif Same (Name, "Start/Main") then
         Enabled_Now := (if Top_Is (W_Main) then DMI_Windows.Button_Enabled (1)
                         else DMI_Conditions.Main_Start);
      elsif Same (Name, "Level/Main") then
         Enabled_Now := (if Top_Is (W_Main) then DMI_Windows.Button_Enabled (5)
                         else DMI_Conditions.Main_Level);
      elsif Same (Name, "EOA/Override") then
         Enabled_Now := (if Top_Is (W_Override)
                         then DMI_Windows.Button_Enabled (1)
                         else DMI_Conditions.Override_EOA);
      else
         return NJ (R_DMI_Internal, "button " & Name);
      end if;
      case St_W is
         when Enabled =>
            return Check (Enabled_Now, "button " & Name & " enabled",
                          "disabled");
         when Disabled =>
            return Check (not Enabled_Now, "button " & Name & " disabled",
                          "enabled");
         when others =>
            return NJ (R_Unclassified, "button " & Name);
      end case;
   end DMI_Button;

   --  DMI 8.2.1.5.7, Table 10: the speed and distance monitoring
   --  information the DMI shows in the mode it shows
   function Speed_Info_Shown return Boolean is
     (case SDI.Mode is
         when SDI.M_FS | SDI.M_AD | SDI.M_SM | SDI.M_LS | SDI.M_RV
            | SDI.M_UN => True,
         when SDI.M_OS | SDI.M_SR | SDI.M_SH =>
            User_Settings.Speed_Info_Visible,
         when others => False);

   function DMI_Expect (St : Step_T) return Judgement_T is
      Kind : constant String := W (3);
      St_W : constant State_Word_T := State_Of (W (4));
      Name : constant String := W (5);
      S    : constant B.State_T := B.State;
      Seen : constant B.Seen_T := B.Seen;
   begin
      if Same (Kind, "mode-symbol") then
         return Mode_Symbol (St_W, Name);
      elsif Same (Kind, "level-symbol") then
         return Level_Symbol (St, St_W, Name);
      elsif Same (Kind, "level-symbol-required") then
         return Shown (St_W, (for some C in 2 .. 5 => Seen.Level_Ann_Ack (C)),
                       S.Level_Ann_Ack, "level acknowledgement");
      elsif Same (Kind, "status-symbol") then
         if Same (Name, "Service-Brake-or-Emergency-Brake-intervention") then
            return Shown (St_W, Seen.Brake_Shown, S.Brake /= 0,
                          "brake intervention (MSG_STATUS brake"
                          & Img (S.Brake) & ")");
         elsif Same (Name, "Hour-glass") then
            return Shown (St_W, False, S.Has_Onboard and then S.Onboard (7) /= 0,
                          "hour glass (MSG_ONBOARD waiting)");
         elsif Has (Name, "Safe-radio-connection---Connection-Up") then
            --  MSG_STATUS radio: 1 up, 2 lost / set-up failed
            return Shown (St_W, Seen.Radio_Up, S.Radio = 1,
                          "safe radio connection up (MSG_STATUS radio"
                          & Img (S.Radio) & ")");
         elsif Has (Name, "Safe-radio-connection---Connection-Lost") then
            return Shown (St_W, Seen.Radio_Lost, S.Radio = 2,
                          "safe radio connection lost (MSG_STATUS radio"
                          & Img (S.Radio) & ")");
         elsif Same (Name, "Reversing-permitted") then
            return Shown (St_W, Seen.Reversing, S.Reversing, "reversing");
         elsif Same (Name, "Adhesion-factor---slippery-rail") then
            return Shown (St_W, Seen.Adhesion, S.Adhesion, "slippery rail");
         elsif Same (Name, "BMM-reaction-inhibition") then
            return Shown (St_W, S.BMM, S.BMM, "BMM inhibition");
         end if;
         return NJ (R_Runner, "status symbol " & Name);
      elsif Same (Kind, "system-status-message") then
         return SS_Message (St_W, Name);
      elsif Same (Kind, "plain-text-message") then
         return Text_Message (St_W, 1, "plain text message");
      elsif Same (Kind, "fixed-text-message") then
         return Text_Message (St_W, 0, "fixed text message");
      elsif Same (Kind, "acknowledgement-request") then
         if Same (Name, "Acknowledge-brake-command") then
            return Shown (St_W, Seen.Brake_Ack, S.Brake = 2,
                          "brake release to acknowledge");
         end if;
         return NJ (R_Runner, "acknowledgement request " & Name);
      elsif Same (Kind, "planning-information") then
         if Same (Name, "gradient-profile") then
            return Shown (St_W, Seen.Gradients, S.Gradients > 0,
                          "planning gradients");
         elsif Same (Name, "indication-marker") then
            return Shown (St_W, Seen.Indication, S.Indication,
                          "indication marker");
         elsif Has (Name, "PASP") or else Has (Name, "speed-profile") then
            --  DMI 8.3.4, 8.3.6: drawn from the speed profile of the
            --  planning information
            return Shown (St_W, S.Speeds > 0, S.Speeds > 0,
                          "planning speed profile");
         elsif Has (Name, "orders") then
            return Shown (St_W, S.Orders > 0, S.Orders > 0, "planning orders");
         end if;
         return NJ (R_Runner, "planning " & Name);
      elsif Same (Kind, "track-condition-symbol")
        or else Same (Kind, "level-crossing-symbol")
      then
         declare
            N : constant Numbers_T := TC_Kinds (Name);
            In_W, Now : Boolean := False;
         begin
            if N.Count = 0 then
               return NJ (R_Runner, "track condition " & Name);
            end if;
            for I in 1 .. N.Count loop
               In_W := In_W or else Seen.TC (N.List (I));
               Now := Now or else S.TC (N.List (I));
            end loop;
            return Shown (St_W, In_W, Now, "track condition " & Name);
         end;
      elsif Same (Kind, "driver-request-symbol") then
         if Same (Name, "Geographical-Position") then
            return Shown (St_W, Seen.Geo, S.Geo_Known, "geographical position");
         elsif Same (Name, "Track-Ahead-Free") then
            return Shown (St_W, Seen.TAF, S.TAF, "track ahead free request");
         end if;
         return NJ (R_Runner, "driver request " & Name);
      elsif Same (Kind, "Geographical-Position") then
         return Shown (State_Of (W (4)), Seen.Geo, S.Geo_Known,
                       "geographical position");
      elsif Same (Kind, "limited-supervision-symbol")
        or else Same (Kind, "lssma-number")
      then
         return Shown (St_W, S.LSSMA /= 16#FFFF#, S.LSSMA /= 16#FFFF#,
                       "LSSMA");
      elsif Same (Kind, "operated-system-version") then
         if Name'Length = 3 and then Name (Name'First) = '3' then
            return Shown (St_W, S.SV_X = 3, S.SV_X = 3,
                          "system version " & Name);
         end if;
         return NJ (R_Version, "operated system version " & Name);
      elsif Same (Kind, "speed-distance-monitoring") then
         --  "displayed" is the speed dial with the aspect of the
         --  supervision status (the comments: "the DMI aspect is coherent
         --  with ... Status"), shown in OS, SR and SH too where the hooks
         --  and the distance wait for the toggle (DMI 8.2.2.4, Table 15);
         --  "removed" and "not displayed" are the toggled objects (5120400:
         --  "the permitted speed is not displayed", then "the train speed
         --  is displayed"), or a mode without them
         declare
            Dial : constant Boolean :=
              Speed_Info_Shown
              or else (St_W = Displayed
                       and then SDI.Mode in SDI.M_OS | SDI.M_SR | SDI.M_SH);
         begin
            return Shown (St_W, Dial, Dial,
                          "speed and distance information on the DMI");
         end;
      elsif Same (Kind, "window") then
         return DMI_Window (St, St_W, Name);
      elsif Same (Kind, "button") then
         return DMI_Button (St_W, Name);
      elsif Same (Kind, "isolation-indicated") then
         return Check (Our_Mode = M_IS, "isolation", Mode_Abbrev (Our_Mode));
      elsif Same (Kind, "ato-symbol") then
         return NJ (R_ATO, "ATO symbol");
      elsif Same (Kind, "supervised-manoeuvre-symbol") then
         return NJ (R_Radio, "SM symbol");
      elsif Same (Kind, "data-value")
        and then (Same (Name, "Train-Running-Number")
                  or else Same (Name, "Driver-ID")
                  or else Same (Name, "Driver_ID"))
      then
         --  DMI 11.3.1.4, 11.3.3.4: the window of the topic shows the
         --  current value in its input field (empty when unknown), read
         --  from the window model (DMI_Observe)
         declare
            Wid : constant Window_ID_T :=
              (if Has (Name, "Running") then DMI_Windows.W_TRN
               else DMI_Windows.W_Driver_ID);
            Shown_Now : constant Boolean :=
              DMI_Observe.Entry_Shown (Wid)
              and then DMI_Observe.Field_Value (Wid)
                       = DMI_Observe.Stored_Value (Wid);
         begin
            if St_W /= Displayed then
               return NJ (R_DMI_Internal, Kind & " " & W (4));
            end if;
            return Check (Shown_Now, "data value " & Name & " shown",
                          (if DMI_Observe.Entry_Shown (Wid)
                           then "field '" & DMI_Observe.Field_Value (Wid)
                                & "', stored '"
                                & DMI_Observe.Stored_Value (Wid) & "'"
                           else "window " & Top_Image));
         end;
      elsif Same (Kind, "data-value") or else Same (Kind, "echo-text")
        or else Same (Kind, "local-time")
      then
         return NJ (R_DMI_Internal, Kind);
      end if;
      return NJ (R_Runner, "DMI " & Kind);
   end DMI_Expect;

   function TIU_Expect return Judgement_T is
      Kind : constant String := W (3);
      Arg  : constant String := W (4);
      S    : constant B.State_T := B.State;
      Seen : constant B.Seen_T := B.Seen;
      Want : constant Boolean := Same (Arg, "commanded");
   begin
      if Same (Kind, "service-brake") then
         return (if Want then Check (Seen.SBC or else S.SBC,
                                     "service brake commanded", "not")
                 else Check (not S.SBC, "service brake not commanded",
                             "commanded"));
      elsif Same (Kind, "emergency-brake") then
         return (if Want then Check (Seen.EBC or else S.EBC,
                                     "emergency brake commanded", "not")
                 else Check (not S.EBC, "emergency brake not commanded",
                             "commanded"));
      elsif Same (Kind, "traction-cutoff") then
         return (if Want then Check (Seen.TCO or else S.TCO,
                                     "traction cut off", "not")
                 else Check (not S.TCO, "traction not cut off", "cut off"));
      elsif Same (Kind, "track-condition")
        or else Same (Kind, "no-track-condition")
      then
         declare
            N : constant Numbers_T := TIU_TC_Kinds (Arg);
            In_W, Now : Boolean := False;
         begin
            if N.Count = 0 then
               return NJ (R_Runner, "TIU track condition " & Arg
                          & " (M_TEST_TRACKCOND codes undefined)");
            end if;
            for I in 1 .. N.Count loop
               In_W := In_W or else Seen.TIU_TC (N.List (I));
               Now := Now or else S.TIU_TC (N.List (I));
            end loop;
            return (if Same (Kind, "track-condition")
                    then Check (In_W or else Now, "TIU " & Arg, "none")
                    else Check (not Now, "no TIU " & Arg, "generated"));
         end;
      end if;
      return NJ (R_Not_Modelled, "TIU " & Kind);
   end TIU_Expect;

   ---------------------------------------------------------------------
   --  JRU
   ---------------------------------------------------------------------

   --  The JRU records since the train left the location before: the
   --  windows of the steps at this location, copied at the end of each
   --  step and when judged (Sync_Location_Records). A status or brake
   --  command a step of a braking curve sequence names without a limit
   --  is judged over them when its own window missed it (B140,
   --  Location_Judgement): the on-board's change came at this location
   --  in the window of an earlier step
   Max_Loc_Records : constant := 2048;
   type Loc_Records_T is array (1 .. Max_Loc_Records) of B.JRU_Record_T;
   Loc_Records    : Loc_Records_T;
   Loc_Count      : Natural := 0;
   Loc_Window     : Unsigned_64 := Unsigned_64'Last;
   Loc_Copied     : Natural := 0;
   Location_Scope : Boolean := False;

   procedure Sync_Location_Records is
   begin
      if B.Window_Ms /= Loc_Window then
         Loc_Window := B.Window_Ms;
         Loc_Copied := 0;
      end if;
      for I in Loc_Copied + 1 .. B.JRU_Count loop
         if Loc_Count < Max_Loc_Records then
            Loc_Count := Loc_Count + 1;
            Loc_Records (Loc_Count) := B.JRU (I);
         end if;
      end loop;
      Loc_Copied := Natural'Max (Loc_Copied, B.JRU_Count);
   end Sync_Location_Records;

   --  The records judged: the step's window, or the location's
   function Rec_Count return Natural is
     (if Location_Scope then Loc_Count else B.JRU_Count);
   function Rec (I : Positive) return B.JRU_Record_T is
     (if Location_Scope then Loc_Records (I) else B.JRU (I));

   function Rec_Matches (R : B.JRU_Record_T; Event : Natural;
                         Sub, B3 : Integer) return Boolean is
     (R.Event = Event and then (Sub < 0 or else R.B2 = Sub)
      and then (B3 < 0 or else R.B3 = B3));

   function Any_Rec (Event : Natural; Sub, B3 : Integer) return Boolean is
   begin
      for I in 1 .. Rec_Count loop
         if Rec_Matches (Rec (I), Event, Sub, B3) then
            return True;
         end if;
      end loop;
      return False;
   end Any_Rec;

   --  The fact holds (Positive) or is absent from the window (not)
   function Holds (F : Fact_T; Positive : Boolean) return Boolean is
      M : constant Natural := Mode_T'Pos (F.Mode);
   begin
      case F.Kind is
         when No_Fact =>
            return False;
         when Mode_Is =>
            return (if Positive then B.JRU_Mode = M
                    else not Any_Rec (1, M, -1));
         when Mode_Is_Not =>
            return (if Positive then B.JRU_Mode /= M
                                     and then B.JRU_Mode /= B.No_Value
                    else Any_Rec (1, M, -1) or else B.JRU_Mode = M);
         when Level_Is =>
            declare
               Lv : constant Natural := Level_T'Pos (F.Level);
               Is_L : constant Boolean :=
                 B.JRU_Level_Status = 2 and then B.JRU_Level = Lv;
            begin
               return (if Positive then Is_L
                       else not (Any_Rec (40, 1, Lv) or else Is_L));
            end;
         when Event_Seen =>
            return Any_Rec (F.Event, F.Sub, F.B3) = Positive;
         when Mode_Proposed =>
            --  recorded in the window, or still asked (the record of its
            --  symbol was made when it was asked, and stands)
            return (Any_Rec (41, 6, M) or else Any_Rec (23, 4, M)
                    or else (Positive
                             and then B.State.Mode_Ack = DMI_Code (F.Mode)))
                   = Positive;
         when Mode_Acked =>
            return (Any_Rec (41, 7, M) or else Any_Rec (23, 5, M)) = Positive;
         when Brake_Change =>
            for I in 1 .. Rec_Count loop
               declare
                  R : constant B.JRU_Record_T := Rec (I);
               begin
                  if R.Event = 20
                    and then (R.B2 / 2**F.Bit) mod 2 = F.Value
                    and then (R.Prev / 2**F.Bit) mod 2 /= F.Value
                  then
                     return Positive;
                  end if;
               end;
            end loop;
            return not Positive;
         when Brakes_Shown =>
            --  the symbol still shown (MSG_STATUS brake, ST01) passes a
            --  step that expects it, as a standing request does for
            --  Mode_Proposed: its record was made when it came (B380)
            if Positive and then F.Value = 1
              and then (B.State.Brake /= 0 or else B.Seen.Brake_Shown)
            then
               return True;
            end if;
            for I in 1 .. Rec_Count loop
               declare
                  R : constant B.JRU_Record_T := Rec (I);
               begin
                  if R.Event = 20
                    and then ((R.B2 mod 4) /= 0) = (F.Value = 1)
                  then
                     return Positive;
                  end if;
               end;
            end loop;
            return not Positive;
         when Ack_Not_Asked =>
            declare
               Lv : constant Natural := Level_T'Pos (F.Level);
            begin
               return (Any_Rec (40, 5, Lv) or else not Any_Rec (40, 4, Lv))
                      = Positive;
            end;
         when Announced =>
            declare
               Lv : constant Natural := Level_T'Pos (F.Level);
            begin
               return (Any_Rec (40, 2, Lv) or else Any_Rec (40, 5, Lv))
                      = Positive;
            end;
         when Trip_Reason =>
            for I in 1 .. F.B3_List.Count loop
               if Any_Rec (23, 1, F.B3_List.List (I)) then
                  return Positive;
               end if;
            end loop;
            return not Positive;
         when Symbol_Shown =>
            --  judged as the DMI step of the symbol (DMI_Expect): shown
            --  in the window or at its end; a record with the bit cleared
            --  is the symbol removed by the end
            declare
               S    : constant B.State_T := B.State;
               Seen : constant B.Seen_T := B.Seen;
               In_W, Now : Boolean;
            begin
               case F.Bit is
                  when 39 => In_W := Seen.Adhesion; Now := S.Adhesion;
                  when 40 => In_W := Seen.Radio_Up; Now := S.Radio = 1;
                  when 41 => In_W := Seen.Radio_Lost; Now := S.Radio = 2;
                  when 42 => Now := S.Has_Onboard and then S.Onboard (7) /= 0;
                     In_W := Now;
                  when 43 => In_W := Seen.Reversing; Now := S.Reversing;
                  --  TCnn, LX01 as the track condition kind 38
                  when 44 .. 80 | 86 =>
                     declare
                        K : constant Natural :=
                          (if F.Bit = 86 then 38 else F.Bit - 43);
                     begin
                        In_W := Seen.TC (K); Now := S.TC (K);
                     end;
                  when 82 => In_W := Seen.TAF; Now := S.TAF;
                  --  LS01 stands with the LSSMA shown (DMI 8.2.1.7.4)
                  when others => Now := S.LSSMA /= 16#FFFF#; In_W := Now;
               end case;
               if F.Value = 1 then
                  return (In_W or else Now) = Positive;
               end if;
               return (if Positive then not Now else Now or else not In_W);
            end;
         when SS_Shown =>
            --  judged as the DMI step of the message (SS_Message): put in
            --  the window or active at its end; Value 0 removed by then
            declare
               In_W, Now : Boolean := False;
            begin
               for I in 1 .. F.B3_List.Count loop
                  for E in 1 .. B.SS_Count loop
                     if B.SS (E).Entry_Number = F.B3_List.List (I)
                       and then B.SS (E).Event = 0
                     then
                        In_W := True;
                     end if;
                  end loop;
                  if F.B3_List.List (I) in 1 .. 38 then
                     Now := Now or else DMI_System_Status.Active
                       (DMI_System_Status.Entry_T (F.B3_List.List (I)));
                  end if;
               end loop;
               if F.Value = 1 then
                  return (In_W or else Now) = Positive;
               end if;
               return (if Positive then not Now else Now or else not In_W);
            end;
      end case;
   end Holds;

   --  "a/b/c" alternatives of a field value, each read in Base
   type Values_T is array (1 .. 16) of Integer;

   procedure Alternatives (S : String; Base : Positive;
                           V : out Values_T; N : out Natural;
                           Ok : out Boolean) is
      F : Natural := S'First;
   begin
      N := 0;
      Ok := S'Length > 0;
      V := (others => -1);
      for I in S'First .. S'Last + 1 loop
         if I > S'Last or else S (I) = '/' then
            declare
               P : constant String := S (F .. I - 1);
               X : Integer := 0;
            begin
               if P'Length = 0 or else N = V'Last then
                  Ok := False;
                  return;
               end if;
               for C of P loop
                  if C not in '0' .. '9'
                    or else Character'Pos (C) - 48 >= Base
                  then
                     Ok := False;
                     return;
                  end if;
                  X := X * Base + (Character'Pos (C) - 48);
                  exit when X > 1_000_000;
               end loop;
               N := N + 1;
               V (N) := X;
            end;
            F := I + 1;
         end if;
      end loop;
   end Alternatives;

   --  "<Bit24=1>", "<Bit06=1/Bit07=1>", "<Bit22=1&Bit23=1>": the facts,
   --  Any for "/", all for "&"
   type Bits_Fn is access function (Bit : Natural; On : Boolean)
     return Fact_T;

   --  The track condition kinds of A (TC numbers, 38 LX01) as text
   function Kinds_Image (A : B.Bit_Array_T) return String is
      R : String (1 .. 4 * 38) := (others => ' ');
      N : Natural := 0;
   begin
      for K in 1 .. 38 loop
         if A (K) then
            declare
               I : constant String := Natural'Image (K);
            begin
               R (N + 1 .. N + I'Length) := I;
               N := N + I'Length;
            end;
         end if;
      end loop;
      return (if N = 0 then " none" else R (1 .. N));
   end Kinds_Image;

   --  The grey and yellow symbols of one track condition (DMI 8.2.3.5:
   --  grey for an automatic execution by the train, yellow when the
   --  driver acts): the other one of TC number K, 0 when none
   function TC_Twin (K : Natural) return Natural is
     (case K is
         when 2 | 4 | 6 | 8 | 13 | 15 | 17 => K + 1,
         when 3 | 5 | 7 | 9 | 14 | 16 | 18 => K - 1,
         when 19 | 20 => K + 2,
         when 21 | 22 => K - 2,
         when others => 0);

   --  A record 21 field "<BitNN=1...>" naming a track condition symbol
   --  whose twin (TC_Twin) the DMI shows in the window or now: the
   --  sequence's train executes it in the other way than the bench's
   --  A record 21 field naming a track condition symbol (bits 44 to 80,
   --  86): its failure says which kinds the DMI shows
   function Names_TC (S : String) return Boolean is
     (for some I in S'First .. S'Last - 5 =>
        S (I .. I + 2) = "Bit" and then S (I + 3) in '0' .. '9'
        and then S (I + 4) in '0' .. '9' and then S (I + 5) = '='
        and then ((Character'Pos (S (I + 3)) - 48) * 10
                  + Character'Pos (S (I + 4)) - 48) in 44 .. 80 | 86);

   function Twin_Shown (S : String) return Boolean is
   begin
      for I in S'First .. S'Last - 5 loop
         if S (I .. I + 2) = "Bit" and then S (I + 3) in '0' .. '9'
           and then S (I + 4) in '0' .. '9' and then S (I + 5) = '='
         then
            declare
               Bit : constant Natural :=
                 (Character'Pos (S (I + 3)) - 48) * 10
                 + Character'Pos (S (I + 4)) - 48;
               T   : constant Natural :=
                 (if Bit in 44 .. 80 then TC_Twin (Bit - 43) else 0);
            begin
               if T > 0 and then (B.State.TC (T) or else B.Seen.TC (T))
               then
                  return True;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Twin_Shown;

   function Bit_Set (S : String; Fn : Bits_Fn; Positive : Boolean;
                     Message : String) return Judgement_T is
      Inner : constant String :=
        (if S'Length >= 2 and then S (S'First) = '<' and then S (S'Last) = '>'
         then S (S'First + 1 .. S'Last - 1) else S);
      Conj : constant Boolean := Ada.Strings.Fixed.Index (Inner, "&") > 0;
      F    : Natural := Inner'First;
      Any_True : Boolean := False;
      All_True : Boolean := True;
   begin
      for I in Inner'First .. Inner'Last + 1 loop
         if I > Inner'Last or else Inner (I) = '/' or else Inner (I) = '&' then
            declare
               P  : constant String := Inner (F .. I - 1);
               Eq : constant Natural := Ada.Strings.Fixed.Index (P, "=");
            begin
               if P'Length < 6 or else Eq = 0
                 or else not Same (P (P'First .. P'First + 2), "Bit")
               then
                  return NJ (R_Unclassified, "JRU " & Message & " " & S);
               end if;
               declare
                  Bit_S : constant String := P (P'First + 3 .. Eq - 1);
                  V_S   : constant String := P (Eq + 1 .. P'Last);
                  Bit   : Natural := 0;
               begin
                  for C of Bit_S loop
                     if C not in '0' .. '9' then
                        return NJ (R_Unclassified, "JRU " & Message & " " & S);
                     end if;
                     Bit := Bit * 10 + Character'Pos (C) - 48;
                  end loop;
                  declare
                     Fact : constant Fact_T := Fn (Bit, V_S = "1");
                  begin
                     --  the spare bits of DMI_SYMB_STATUS (4.2.4.21: 05,
                     --  11, 13) set: a defect of the sequence
                     if Message = "21" and then Bit in 5 | 11 | 13
                       and then V_S = "1"
                     then
                        return NJ (R_S076_Defect, "JRU 21 spare bit"
                                   & Bit_S & " set");
                     end if;
                     if Fact.Kind = No_Fact then
                        return NJ (R_JRU_Not_Modelled,
                                   Message & "/Bit" & Bit_S & "=" & V_S);
                     end if;
                     if Holds (Fact, Positive) then
                        Any_True := True;
                     else
                        All_True := False;
                     end if;
                  end;
               end;
            end;
            F := I + 1;
         end if;
      end loop;
      return Check ((if Conj then All_True else Any_True),
                    "JRU " & Message & " " & S
                    & (if Positive then "" else " not") & " recorded",
                    "JRU mode" & Img (B.JRU_Mode) & " level"
                    & Img (B.JRU_Level)
                    & (if Message = "21" and then Names_TC (S)
                       then "; TC now" & Kinds_Image (B.State.TC)
                            & ", window" & Kinds_Image (B.Seen.TC)
                       else ""));
   end Bit_Set;

   --  A field of the header of a JRU message (SUBSET-027 4.2.3.5 to
   --  4.2.3.11) by its name, -1 for a field this does not read. The LRBG
   --  fields with Q_LRBG 1 are the SOLR's (the LRBG is the SOLR)
   function Header_Value (Name : String; H : EVC_JRU_Messages.Header_T)
                          return Integer
   is
      L : constant EVC_JRU_Messages.Reference_T :=
        (if H.Q_LRBG = 2 then H.LRBG else H.SOLR);
      Has_L : constant Boolean := H.Q_LRBG in 1 .. 2;
   begin
      if Same (Name, "Q_LRBG") then
         return H.Q_LRBG;
      elsif Same (Name, "NID_SOLR") then
         return H.SOLR.NID;
      elsif Same (Name, "D_SOLR") then
         return H.SOLR.D;
      elsif Same (Name, "Q_DIRSOLR") then
         return H.SOLR.Q_Dir;
      elsif Same (Name, "Q_DSOLR") then
         return H.SOLR.Q_D;
      elsif Same (Name, "L_DOUBTOVER_SOLR") then
         return H.SOLR.Over;
      elsif Same (Name, "L_DOUBTUNDER_SOLR") then
         return H.SOLR.Under;
      elsif Same (Name, "NID_LRBG") then
         return (if Has_L then L.NID else 16777215);
      elsif Same (Name, "D_LRBG") then
         return (if Has_L then L.D else 32767);
      elsif Same (Name, "Q_DIRLRBG") then
         return (if Has_L then L.Q_Dir else 2);
      elsif Same (Name, "Q_DLRBG") then
         return (if Has_L then L.Q_D else 2);
      elsif Same (Name, "L_DOUBTOVER_LRBG") then
         return (if Has_L then L.Over else 32767);
      elsif Same (Name, "L_DOUBTUNDER_LRBG") then
         return (if Has_L then L.Under else 32767);
      elsif Same (Name, "V_TRAIN") then
         return H.V_Train;
      elsif Same (Name, "NID_ENGINE") then
         return H.NID_Engine;
      elsif Same (Name, "M_VERSION") then
         return H.M_Version;
      end if;
      return -1;
   end Header_Value;

   --  The value "unknown" of a header field (7.5.1.90, 7.5.1.13, 7.5.1.104,
   --  7.5.1.106, 7.5.1.43, 7.5.1.44 by analogy); NID_C 0 with NID_BG
   --  16383 (unknown, 7.5.1.86) counts as unknown too
   function Header_Unknown (Name : String; F : Integer) return Boolean is
     (if Has (Name, "NID_") then F in 16777215 | 16383
      elsif Starts (Name, "D_") or else Starts (Name, "L_DOUBT")
      then F = 32767
      elsif Starts (Name, "Q_DIR") or else Starts (Name, "Q_D") then F = 2
      elsif Same (Name, "M_VERSION") then F = 0
      else False);

   --  A header field against a value of a step: a number ("16777215",
   --  the unknown NID whichever way coded; "0" for V_TRAIN also its
   --  standstill 1023, 4.2.3.6), alternatives ("1/2"), "<>N" not that
   --  number, M_VERSION's seven bits (X judged, see Header_Field),
   --  the passed group for NID_LRBG / NID_SOLR as in Header_Field; no
   --  value or a name of the sequence ("<BG2>", "<updated>", "<D0>"):
   --  the field known (decision: the names are not resolved)
   function Header_Holds (Name, Value : String; F : Integer)
                          return Boolean
   is
      Not_Equal : constant Boolean :=
        Value'Length > 2 and then Value (Value'First .. Value'First + 1) = "<>";
      Num : constant String :=
        (if Not_Equal then Value (Value'First + 2 .. Value'Last) else Value);
      Numeric : constant Boolean :=
        Num'Length in 1 .. 40
        and then (for all C of Num => C in '0' .. '9' | '/');
      Result : Boolean := False;
      First : Natural := Num'First;
   begin
      if Same (Name, "M_VERSION") and then Num'Length = 7
        and then (for all C of Num => C in '0' .. '1')
      then
         Result := F / 16 = Natural'Value ("2#" & Num (Num'First .. Num'First + 2) & "#");
      elsif (Same (Name, "NID_LRBG") or else Same (Name, "NID_SOLR"))
        and then (Same (Value, "<IDofthepassedBG>")
                  or else Same (Value, "<equaltotheidentityofthepreviousBG>")
                  or else Same (Value, "<changed>")
                  or else Same (Value, "<differentfrombalisemessage>")
                  or else Same (Value, "<unchanged>"))
      then
         Result := (not Header_Unknown (Name, F)
                    and then F = B.JRU_Last_BG_Id)
           = not (Same (Value, "<differentfrombalisemessage>")
                  or else Same (Value, "<unchanged>"));
      elsif not Numeric then
         Result := not Header_Unknown (Name, F);
      else
         for I in Num'First .. Num'Last + 1 loop
            if I > Num'Last or else Num (I) = '/' then
               if I - First in 1 .. 9 then
                  declare
                     V : constant Natural := Natural'Value (Num (First .. I - 1));
                  begin
                     Result := Result or else F = V
                       or else (Header_Unknown (Name, V)
                                and then Header_Unknown (Name, F))
                       or else (Same (Name, "V_TRAIN") and then V = 0
                                and then F = 1023);
                  end;
               end if;
               First := I + 1;
            end if;
         end loop;
      end if;
      return Result /= Not_Equal;
   end Header_Holds;

   --  The items of a word of a JRU step: "D_SOLR=<D2>;L_DOUBTOVER_SOLR" is
   --  two, each a name and its value
   procedure Item (Wd : String; K : Positive; Name, Value : out Unbounded_String;
                   Found : out Boolean)
   is
      N : Natural := 0;
      F : Natural := Wd'First;
   begin
      Name := Null_Unbounded_String;
      Value := Null_Unbounded_String;
      Found := False;
      for I in Wd'First .. Wd'Last + 1 loop
         if I > Wd'Last or else Wd (I) = ';' then
            N := N + 1;
            if N = K then
               declare
                  It : constant String := Wd (F .. I - 1);
                  Eq : constant Natural := Ada.Strings.Fixed.Index (It, "=");
                  Ne : constant Natural := Ada.Strings.Fixed.Index (It, "<>");
                  --  "NID_SOLR<>16777215": the value keeps its "<>"
                  Cut : constant Natural :=
                    (if Eq > 0 then Eq elsif Ne > It'First then Ne else 0);
               begin
                  Found := It'Length > 0;
                  Name := To_Unbounded_String
                    (if Cut > 0 then It (It'First .. Cut - 1) else It);
                  Value := To_Unbounded_String
                    (if Eq > 0 then It (Eq + 1 .. It'Last)
                     elsif Cut > 0 then It (Cut .. It'Last) else "");
               end;
               return;
            end if;
            F := I + 1;
         end if;
      end loop;
   end Item;

   --  The header fields of a JRU step judged on the messages of the
   --  window (SUBSET-027 4.2.3, S076_Bench.Message_Header): a message
   --  (NID_MESSAGE Id, any for ALL) whose header holds them all, none for
   --  a negative step. Judged is False when the step names none of them
   function Header_Judge (Id : Natural; Positive : Boolean;
                          Judged : out Boolean) return Judgement_T
   is
      Probe : constant EVC_JRU_Messages.Header_T := (others => <>);
      Names : Unbounded_String;
      Found : Boolean := False;
      Last  : Natural := 0;

      --  every header item of the step holds in H (Judged: one exists)
      function All_Hold (H : EVC_JRU_Messages.Header_T) return Boolean is
         N, V : Unbounded_String;
         Ok   : Boolean;
      begin
         for K in 5 .. Line.Count loop
            for J in 1 .. 20 loop
               Item (W (K), J, N, V, Ok);
               exit when not Ok;
               if Header_Value (To_String (N), H) >= 0
                 and then not Header_Holds
                   (To_String (N), To_String (V),
                    Header_Value (To_String (N), H))
               then
                  return False;
               end if;
            end loop;
         end loop;
         return True;
      end All_Hold;

      --  the values of the step's header items in H
      function Image (H : EVC_JRU_Messages.Header_T) return String is
         R : Unbounded_String;
         N, V : Unbounded_String;
         Ok : Boolean;
      begin
         for K in 5 .. Line.Count loop
            for J in 1 .. 20 loop
               Item (W (K), J, N, V, Ok);
               exit when not Ok;
               if Header_Value (To_String (N), H) >= 0 then
                  Append (R, " " & To_String (N) & Img
                            (Header_Value (To_String (N), H)));
               end if;
            end loop;
         end loop;
         return To_String (R);
      end Image;
   begin
      Judged := False;
      for K in 5 .. Line.Count loop
         for J in 1 .. 20 loop
            declare
               N, V : Unbounded_String;
               Ok   : Boolean;
            begin
               Item (W (K), J, N, V, Ok);
               exit when not Ok;
               if Header_Value (To_String (N), Probe) >= 0 then
                  Judged := True;
                  Append (Names, " " & W (K));
                  exit;
               end if;
            end;
         end loop;
      end loop;
      if not Judged then
         return Pass ("JRU header");
      end if;
      for I in 1 .. B.Message_Count loop
         if Id = 0 or else B.Message_NID (I) = Id then
            Last := I;
            if All_Hold (B.Message_Header (I)) then
               Found := True;
               exit;
            end if;
         end if;
      end loop;
      if Positive and then Last = 0 then
         --  nothing recorded in the window: what the sequence expects
         --  recorded here is an event this on-board does not record
         return NJ (R_JRU_Not_Modelled,
                    "no message for the header:" & To_String (Names));
      end if;
      return Check (Found = Positive,
                    "JRU header" & To_String (Names)
                    & (if Positive then "" else " not"),
                    (if Last = 0 then "no message"
                     else "last message" & Image (B.Message_Header (Last))));
   end Header_Judge;

   --  The header fields every record carries (4.2.2.2) judged from the
   --  on-board's state in the window: the mode, the level, the driver
   --  (decision: the message's own are those at the end of its event's
   --  cycle, and the sequences name the mode they enter; the location,
   --  speed, version and identity fields are Header_Judge's)
   function Header_Field (Name, Value : String; Positive : Boolean;
                          Handled : out Boolean) return Judgement_T is
      V  : Values_T;
      N  : Natural;
      Ok : Boolean;
   begin
      Handled := True;
      if Same (Name, "M_MODE") then
         Alternatives (Value, 10, V, N, Ok);
         if not Ok then
            return NJ (R_Unclassified, "JRU M_MODE=" & Value);
         end if;
         for I in 1 .. N loop
            declare
               M : Mode_T;
            begin
               if Mode_Of_M_MODE (V (I), M)
                 and then Holds ((Kind => Mode_Is, Mode => M, others => <>),
                                 Positive)
               then
                  return Pass ("JRU mode " & Mode_Abbrev (M));
               end if;
            end;
         end loop;
         return Fail ("JRU M_MODE=" & Value
                      & (if Positive then "" else " not") & ", got mode "
                      & (if B.JRU_Mode <= Mode_T'Pos (Mode_T'Last)
                         then Mode_Abbrev (Mode_T'Val (B.JRU_Mode))
                         else "none"));
      elsif Same (Name, "M_LEVEL") then
         Alternatives (Value, 10, V, N, Ok);
         if not Ok then
            return NJ (R_Unclassified, "JRU M_LEVEL=" & Value);
         end if;
         for I in 1 .. N loop
            if V (I) in 0 .. 3
              and then Holds ((Kind => Level_Is, Level => Level_T'Val (V (I)),
                               others => <>), Positive)
            then
               return Pass ("JRU level");
            end if;
         end loop;
         return Fail ("JRU M_LEVEL=" & Value & ", got"
                      & Img (B.JRU_Level) & " status"
                      & Img (B.JRU_Level_Status));
      elsif Same (Name, "DRIVER_ID") then
         return Check (Any_Rec (41, 1, -1) = Positive, "JRU driver ID",
                       "no event 41 kind 1");
      end if;
      Handled := False;
      return NJ (R_JRU_Not_Modelled, "ALL." & Name);
   end Header_Field;

   --  The fields of an expectation of message 38 (cab status) or 45
   --  (track conditions), EVC_JRU_Records: words and their parts joined
   --  by ';' or '&'. 38: M_CAB_A_STATUS is byte 2 of event 38,
   --  M_CAB_B_STATUS byte 4. 45: M_TRACKCOND_TI is byte 2 of event 45, the
   --  distances say the phase of byte 3 (D_MAXSFE_TO_START "not relevant"
   --  -32768 or below 0: the start passed, any other value: ahead;
   --  D_MIN*_TO_END below 0: the end passed, above 0: not). A record of the
   --  window matches, or, for 45, the phase of the last one of its kind
   --  (the message goes to the train interface every cycle while the item
   --  is generated, the event only when it changes).
   function Cab_Or_Condition (Id : Natural; Positive : Boolean)
     return Judgement_T
   is
      B2, B4   : Integer := -1;
      Phase_Ok : array (0 .. 2) of Boolean := (others => True);

      procedure Field (F : String) is
         Op : Natural := 0;
      begin
         for I in F'Range loop
            if F (I) in '=' | '<' | '>' then
               Op := I;
               exit;
            end if;
         end loop;
         if Op <= F'First or else Op = F'Last then
            return;
         end if;
         declare
            Name : constant String := F (F'First .. Op - 1);
            Rel  : constant Character := F (Op);
            Val  : constant String := F (Op + 1 .. F'Last);
            Num  : Integer := -1;
         begin
            if (for all C of Val => C in '0' .. '9') and then Val'Length <= 3
            then
               Num := Integer'Value (Val);
            end if;
            if Same (Name, "M_CAB_A_STATUS") and then Rel = '=' and then Num >= 0
            then
               B2 := Num;
            elsif Same (Name, "M_CAB_B_STATUS") and then Rel = '='
              and then Num >= 0
            then
               B4 := Num;
            elsif Same (Name, "M_TRACKCOND_TI") and then Rel = '='
              and then Num >= 0
            then
               B2 := Num;
            elsif Same (Name, "D_MAXSFE_TO_START") then
               if Val = "-32768" or else (Rel = '<' and then Val = "0") then
                  Phase_Ok (0) := False;
               else
                  Phase_Ok (1) := False;
                  Phase_Ok (2) := False;
               end if;
            elsif Starts (Name, "D_MIN") and then Has (Name, "_TO_END")
              and then Val = "0"
            then
               --  "<0" the end passed, ">0" not ("<D2": still ahead, the
               --  start says the rest)
               if Rel = '<' then
                  Phase_Ok (0) := False;
                  Phase_Ok (1) := False;
               elsif Rel = '>' then
                  Phase_Ok (2) := False;
               end if;
            elsif not Same (Name, "M_MODE") and then not Same (Name, "M_LEVEL")
              and then not Same (Name, "NID_SOLR")
              and then not Same (Name, "D_SOLR")
              and then not Same (Name, "Q_DSOLR")
            then
               Note_Gap (Img (Id) & "." & Name);
            end if;
         end;
      end Field;

      function Matches (R : B.JRU_Record_T) return Boolean is
        (R.Event = Id
         and then (B2 < 0 or else R.B2 = B2)
         and then (B4 < 0 or else R.B4 = B4)
         and then (Id /= 45 or else (R.B3 <= 2 and then Phase_Ok (R.B3))));

      Found : Boolean := False;
   begin
      for K in 5 .. Line.Count loop
         declare
            Wd : constant String := W (K);
            F  : Natural := Wd'First;
         begin
            for I in Wd'First .. Wd'Last + 1 loop
               if I > Wd'Last or else Wd (I) in ';' | '&' then
                  if I > F then
                     Field (Wd (F .. I - 1));
                  end if;
                  F := I + 1;
               end if;
            end loop;
         end;
      end loop;
      for I in 1 .. B.JRU_Count loop
         Found := Found or else Matches (B.JRU (I));
      end loop;
      if not Found and then Positive and then Id = 45 and then B2 >= 0
        and then B.JRU_TC_Phase (B2) in 0 .. 2
        and then Phase_Ok (B.JRU_TC_Phase (B2))
      then
         Found := True;
      end if;
      return Check (Found = Positive,
                    "JRU" & Img (Id)
                    & (if B2 >= 0 then (if Id = 38 then " cab A" else " TI")
                                       & Img (B2) else "")
                    & (if B4 >= 0 then " cab B" & Img (B4) else "")
                    & (if Id = 45 and then not (for all P of Phase_Ok => P)
                       then " phase" & (if Phase_Ok (0) then " 0" else "")
                            & (if Phase_Ok (1) then " 1" else "")
                            & (if Phase_Ok (2) then " 2" else "")
                       else "")
                    & (if Positive then "" else " not"),
                    (if Found then "recorded" else "none"));
   end Cab_Or_Condition;

   --  JRU record 10, a message to the RBC (SUBSET-027 4.2.4.10): the
   --  on-board's JRU port has no event for it, the bench's RTM capture of
   --  the step's window is the same evidence. The message is the one the
   --  line names (NID_MESSAGE), else the one of the "expect RTM message"
   --  step directly before, which the record follows in the sequences
   --  (3300 of 3310 in sv30): judged as that expectation without its
   --  packets, with the record's own fields (M_VERSION, NID_ENGINE), so
   --  the same message satisfies both. A record of no named message
   --  passes on any message sent in the window.
   function JRU_Sent (St : Step_T; Positive : Boolean) return Judgement_T is
      Nid    : Unbounded_String;
      Fields, Packets : Unbounded_String;
      Index  : Natural := 0;
      J      : Judgement_T;
   begin
      for K in 5 .. Line.Count loop
         if Starts (W (K), "NID_MESSAGE=") then
            Nid := To_Unbounded_String (W (K) (W (K)'First + 12 .. W (K)'Last));
         elsif Starts (W (K), "NID_PACKET=") then
            Packets := To_Unbounded_String
              (" packets " & W (K) (W (K)'First + 11 .. W (K)'Last));
         else
            Append (Fields, " " & W (K));
         end if;
      end loop;
      for K in 1 .. Seq.Step_Count loop
         if Seq.Steps (K).Line_No = St.Line_No then
            Index := K;
         end if;
      end loop;
      if Length (Nid) = 0 and then Index > 1
        and then Seq.Steps (Index - 1).IO = Output
      then
         Load_Line (Seq.Steps (Index - 1).Line);
         if Line.Count >= 4 and then W (2) = "RTM"
           and then (W (3) = "message" or else W (3) = "no-message")
         then
            Nid := To_Unbounded_String (W (4));
         end if;
      end if;
      --  a message from the RBC (track to train, NID_MESSAGE below 128)
      --  named in a record of a message to it: 4100103_28 step 94 lists
      --  the record of the 3 just received as 10; the record of a
      --  received message is 9 (4.2.4.9)
      if Length (Nid) in 1 .. 3
        and then (for all C of To_String (Nid) => C in '0' .. '9')
        and then Natural'Value (To_String (Nid)) < 128
      then
         Load_Line (St.Line);
         return NJ (R_S076_Defect, "JRU 10 of a message from the RBC");
      end if;
      if Length (Nid) = 0 then
         Load_Line (St.Line);
         if Length (Fields) > 0 then
            return NJ (R_JRU_Not_Modelled, "10 without NID_MESSAGE");
         end if;
         return Check ((for some I in 1 .. B.Radio_Count =>
                          not B.Radio (I).Is_Request) = Positive,
                       "JRU10 any message to the RBC"
                       & (if Positive then "" else " not"), "the window");
      end if;
      Load_Line (To_Text ("expect RTM " & (if Positive then "" else "no-")
                          & "message " & To_String (Nid)
                          & To_String (Packets) & To_String (Fields)));
      J := Radio_Expect (St);
      Load_Line (St.Line);
      J.Sig := To_Text ("JRU10 " & Image (J.Sig));
      return J;
   end JRU_Sent;

   --  Record 20 (speed and distance monitoring information, SUBSET-027
   --  4.2.4.20) expected without M_SDMTYPE / M_SDMSUPSTAT: judged when an
   --  event 21 of the window records it, a field with a number (V_PERM,
   --  V_SBI, V_TARGET, V_RELEASE at 1 km/h, D_TARGET at 1 m) against the
   --  value the DMI shows at the end of the window (the record carries
   --  the speeds the DMI is given), a symbolic one (<V1>, V_TSR) by the
   --  record alone; no event 21 in the window: not judged, naming the
   --  first field
   function JRU_20_Fields (Positive : Boolean) return Judgement_T is
      S       : constant B.State_T := B.State;
      First   : Natural := 0;
      Numbers : Natural := 0;
   begin
      for K in 5 .. Line.Count loop
         if First = 0
           and then (Ada.Strings.Fixed.Index (W (K), "V_") = 1
                     or else Ada.Strings.Fixed.Index (W (K), "D_") = 1)
         then
            First := K;
         end if;
      end loop;
      if not Positive or else not Any_Rec (21, -1, -1) then
         return NJ (R_JRU_Not_Modelled,
                    "20 " & (if First = 0 then "" else W (First) & " ")
                    & (if Positive then "without a record 20 in the window"
                       else "absent, without M_SDMTYPE / M_SDMSUPSTAT"));
      end if;
      for K in 5 .. Line.Count loop
         declare
            Wd   : constant String := W (K);
            Eq   : constant Natural := Ada.Strings.Fixed.Index (Wd, "=");
            Name : constant String :=
              (if Eq > 0 then Wd (Wd'First .. Eq - 1) else Wd);
            Txt  : constant String :=
              (if Eq > 0 then Wd (Eq + 1 .. Wd'Last) else "");
            Want : Integer := -1;
            Got  : Integer := -1;
         begin
            if Txt'Length in 1 .. 5
              and then (for all C of Txt => C in '0' .. '9')
            then
               Want := Integer'Value (Txt);
               Got := (if not S.Has_Speed then -1
                       elsif Name = "V_PERM" then S.V_Perm
                       elsif Name = "V_SBI" then S.V_SBI
                       elsif Name = "V_TARGET" then S.V_Target
                       elsif Name = "V_RELEASE" then S.V_Release
                       elsif Name = "D_TARGET" then S.D_Target
                       else -2);
            end if;
            if Want >= 0 and then Got = -1 then
               return NJ (R_JRU_Not_Modelled,
                          "20 " & Wd & ": no speeds shown");
            elsif Want >= 0 and then Got >= 0 then
               if abs (Got - Want) > 1 then
                  return Check (False, "JRU 20 " & Wd,
                                Name & "=" & Img (Got) & " shown");
               end if;
               Numbers := Numbers + 1;
            end if;
         end;
      end loop;
      return Pass ("JRU 20 as event 21"
                   & (if Numbers > 0
                      then "," & Img (Numbers) & " fields as shown"
                      else ""));
   end JRU_20_Fields;

   function JRU_Window_Expect (St : Step_T) return Judgement_T is
      Positive : constant Boolean := Same (W (3), "record");
      Id_S     : constant String := W (4);
      Id       : Natural := 0;
      Result   : Judgement_T := Pass ("JRU");
      Any_Field : Boolean := False;
   begin
      if Same (Id_S, "ALL") then
         if Line.Count = 4 then
            return Check ((B.JRU_Count > 0) = Positive,
                          "JRU any record" & (if Positive then "" else " not"),
                          Img (B.JRU_Count) & " records");
         end if;
      else
         for C of Id_S loop
            if C not in '0' .. '9' then
               return NJ (R_Unclassified, "JRU " & Id_S);
            end if;
            Id := Id * 10 + Character'Pos (C) - 48;
            exit when Id > 999;
         end loop;
      end if;
      --  the message itself, when it is not ALL
      if Id > 0 then
         case Id is
            when 10 =>
               return JRU_Sent (St, Positive);
            when 3 | 4 | 43 =>
               declare
                  Bit : constant Natural :=
                    (case Id is when 3 => 0, when 4 => 1, when others => 2);
                  Val : Integer := -1;
               begin
                  for K in 5 .. Line.Count loop
                     declare
                        Eq : constant Natural :=
                          Ada.Strings.Fixed.Index (W (K), "=");
                     begin
                        if Eq > 0 and then Has (W (K), "COMMAND_STATE") then
                           Val := (if W (K) (Eq + 1 .. W (K)'Last) = "1"
                                   then 1 else 0);
                        end if;
                     end;
                  end loop;
                  if Val < 0 then
                     return Check
                       ((for some I in 1 .. Rec_Count => Rec (I).Event = 20
                          and then (Rec (I).B2 / 2**Bit) mod 2
                                   /= (Rec (I).Prev / 2**Bit) mod 2)
                        = Positive, "JRU" & Id_S, "brake commands");
                  end if;
                  return Check (Holds ((Kind => Brake_Change, Bit => Bit,
                                        Value => Val, others => <>),
                                       Positive),
                                "JRU" & Id_S & " state" & Img (Val)
                                & (if Positive then "" else " not"),
                                "no such brake command change");
               end;
            when 11 =>
               for K in 5 .. Line.Count loop
                  declare
                     Wd : constant String := W (K);
                     Eq : constant Natural := Ada.Strings.Fixed.Index (Wd, "=");
                     V  : Values_T;
                     N  : Natural;
                     Ok : Boolean;
                     Any : Boolean := False;
                  begin
                     --  M_DRIVERACTION and M_DRIVER: misspelt in a few
                     --  sequences
                     if Eq > 0 and then Starts (Wd (Wd'First .. Eq - 1),
                                                "M_DRIVER")
                     then
                        Alternatives (Wd (Eq + 1 .. Wd'Last), 2, V, N, Ok);
                        if not Ok then
                           return NJ (R_Unclassified, "JRU 11 " & Wd);
                        end if;
                        for I in 1 .. N loop
                           declare
                              F : constant Fact_T := Driver_Action_Fact (V (I));
                           begin
                              --  no event of ours: 37 is spare in SUBSET-027
                              --  4.0.0 (4.2.4.11), 43 to 48 the ATO's, the
                              --  others (scrolling, FRMCS) not recorded
                              if F.Kind = No_Fact then
                                 return NJ ((case V (I) is
                                               when 37 => R_S076_Defect,
                                               when 43 .. 48 => R_ATO,
                                               when others => R_JRU_Not_Modelled),
                                            "11/M_DRIVERACTIONS=" & Img (V (I)));
                              end if;
                              Any := Any or else Holds (F, Positive);
                           end;
                        end loop;
                        --  a level selected that is the level in force
                        --  already switches nothing: EVC_Levels records no
                        --  event for it
                        if not Any and then Positive
                          and then not Any_Rec (40, 1, -1)
                        then
                           for I in 1 .. N loop
                              if V (I) in 34 .. 36 | 38
                                and then B.JRU_Level_Status = 2
                                and then B.JRU_Level
                                           = (case V (I) is
                                                 when 34 => 0, when 35 => 2,
                                                 when 36 => 3, when others => 1)
                              then
                                 return NJ (R_JRU_Not_Modelled,
                                            "11/M_DRIVERACTIONS=level in "
                                            & "force selected again");
                              end if;
                           end loop;
                        end if;
                        return Check (Any, "JRU driver action "
                                      & Wd (Eq + 1 .. Wd'Last),
                                      "no event of ours for it in the window");
                     end if;
                  end;
               end loop;
               --  without M_DRIVERACTIONS: any action of the window that
               --  an event of ours records
               if Positive
                 and then (for some C in 0 .. 63 =>
                             Driver_Action_Fact (C).Kind /= No_Fact
                             and then Holds (Driver_Action_Fact (C), True))
               then
                  return Pass ("JRU driver action (any)");
               end if;
               return NJ (R_JRU_Not_Modelled, "11 without M_DRIVERACTIONS");
            when 21 | 23 =>
               for K in 5 .. Line.Count loop
                  declare
                     Wd : constant String := W (K);
                     Eq : constant Natural := Ada.Strings.Fixed.Index (Wd, "=");
                  begin
                     if Eq > 0 then
                        declare
                           C : constant String := Image (St.Comment);
                           R : constant Judgement_T := Bit_Set
                             (Wd (Eq + 1 .. Wd'Last),
                              (if Id = 21 then Symbol_Fact'Access
                               else System_Status_Fact'Access),
                              Positive, Img (Id));
                        begin
                           --  one of two alternatives (a track condition
                           --  symbol grey for an automatic execution,
                           --  yellow when the driver acts, DMI 8.2.3.5;
                           --  "only if the displayed symbol changes"):
                           --  the other one is ours
                           if R.Verdict = Failed and then Id = 21
                             and then Positive
                             and then Twin_Shown (Wd (Eq + 1 .. Wd'Last))
                           then
                              return NJ (R_Optional, Image (R.Sig)
                                         & " (the other execution of "
                                         & "DMI 8.2.3.5 shown)");
                           end if;
                           if R.Verdict = Failed
                             and then (Starts (Up (C), "ONLY IF")
                                       or else Has (Up (C), "ONLY IF THE "
                                                    & "DISPLAYED SYMBOL")
                                       or else Has (Up (C), "(AUTOMATIC "
                                                    & "EXECUTION)"))
                           then
                              return NJ (R_Optional, Image (R.Sig));
                           end if;
                           return R;
                        end;
                     end if;
                  end;
               end loop;
               return NJ (R_JRU_Not_Modelled, Img (Id) & " without bits");
            when 13 =>
               --  radio error (4.2.4.13): event 13, byte 2 M_ERROR
               declare
                  Wd : constant String := (if Line.Count > 4 then W (5) else "");
                  E  : Integer := -1;
               begin
                  if Starts (Wd, "M_ERROR=") then
                     E := Natural'Value (Wd (Wd'First + 8 .. Wd'Last));
                  end if;
                  --  the on-board records the errors it reports, radio
                  --  message consistency (3) and sequence (4), and the
                  --  safe radio connection error (5) of the T_NVCONTACT
                  --  reaction (3.16.3.4.1, EVC_Sessions.Contact_Error)
                  if E >= 0 and then E not in 3 .. 5 then
                     return NJ (R_JRU_Not_Modelled, "13.M_ERROR=" & Img (E));
                  end if;
                  return Check (Any_Rec (13, E, -1) = Positive,
                                "JRU13 radio error"
                                & (if E >= 0 then " M_ERROR" & Img (E) else "")
                                & (if Positive then "" else " not"),
                                "event 13");
               end;
            when 44 =>
               --  the LSSMA displayed (4.2.4.44): the on-board's JRU port
               --  has no event for it, the bench's DMI state is the
               --  evidence, judged as the DMI step of the LSSMA; V_LSSMA
               --  is symbolic in the sequences
               declare
                  Shown_Now : constant Boolean := B.State.LSSMA /= 16#FFFF#;
               begin
                  --  no record: no change of the LSSMA displayed, which the
                  --  bench does not follow (4080100_04 step 113)
                  if not Positive then
                     return Check (not B.Seen.LSSMA_Changed,
                                   "JRU44 not: the LSSMA shown unchanged",
                                   "changed in the window");
                  end if;
                  return Check (Shown_Now = Positive,
                                "JRU44 LSSMA shown"
                                & (if Positive then "" else " not"),
                                (if Shown_Now then "shown" else "not shown"));
               end;
            when 12 =>
               if Line.Count > 4 then
                  --  M_ERROR 0, the linking consistency error of 3.16.2.3,
                  --  is the position's events 4 to 6 (EVC_Ports: linking
                  --  reaction, unexpected and missed group); the others
                  --  (1, 2 message consistency, 7, 8 double linking and
                  --  repositioning) have no event of ours
                  for K in 5 .. Line.Count loop
                     if Starts (W (K), "M_ERROR=")
                       and then not Starts (W (K), "M_ERROR=0")
                     then
                        return NJ (R_JRU_Not_Modelled, "12." & W (K));
                     end if;
                  end loop;
               end if;
               return Check ((Any_Rec (4, -1, -1) or else Any_Rec (5, -1, -1)
                              or else Any_Rec (6, -1, -1)) = Positive,
                             "JRU balise group error"
                             & (if Positive then "" else " not"),
                             "events 4 to 6");
            when 20 =>
               declare
                  --  the alternatives of each field ("0/2"), none: any
                  Mons, Sups : Values_T := (others => -1);
                  Mon_N, Sup_N : Natural := 0;
                  Hit : Boolean := False;
               begin
                  for K in 5 .. Line.Count loop
                     declare
                        Wd : constant String := W (K);
                        Eq : constant Natural :=
                          Ada.Strings.Fixed.Index (Wd, "=");
                        Name : constant String :=
                          (if Eq > 0 then Wd (Wd'First .. Eq - 1) else Wd);
                        V  : Values_T;
                        N  : Natural;
                        Ok : Boolean;
                     begin
                        if Same (Name, "M_SDMTYPE")
                          or else Same (Name, "M_SDMSUPSTAT")
                        then
                           if Eq = 0 then
                              return NJ (R_Unclassified, "JRU 20 " & Wd);
                           end if;
                           Alternatives (Wd (Eq + 1 .. Wd'Last), 10, V, N, Ok);
                           if not Ok then
                              return NJ (R_Unclassified, "JRU 20 " & Wd);
                           end if;
                           if Same (Name, "M_SDMTYPE") then
                              Mons := V;
                              Mon_N := N;
                           else
                              Sups := V;
                              Sup_N := N;
                           end if;
                        elsif not Same (Name, "M_MODE")
                          and then not Same (Name, "M_LEVEL")
                        then
                           Note_Gap ("20." & Name);
                        end if;
                     end;
                  end loop;
                  if Mon_N = 0 and then Sup_N = 0 then
                     return JRU_20_Fields (Positive);
                  end if;
                  --  event 21 is recorded when the monitoring or the
                  --  status changes: a record of message 20 for another
                  --  change carries the values of the last one
                  for I in 1 .. Natural'Max (1, Mon_N) loop
                     for J in 1 .. Natural'Max (1, Sup_N) loop
                        declare
                           Mon : constant Integer :=
                             (if Mon_N = 0 then -1 else Mons (I));
                           Sup : constant Integer :=
                             (if Sup_N = 0 then -1 else Sups (J));
                        begin
                           if Any_Rec (21, Mon, Sup)
                             or else (Positive
                                      and then (Mon < 0
                                                or else B.JRU_Monitoring = Mon)
                                      and then (Sup < 0
                                                or else B.JRU_Sup_Status = Sup))
                           then
                              Hit := True;
                           end if;
                        end;
                     end loop;
                  end loop;
                  Result := Check (Hit = Positive,
                                   "JRU supervision monitoring"
                                   & (if Mon_N = 0 then "-1"
                                      else Img (Mons (1)))
                                   & " status"
                                   & (if Sup_N = 0 then "-1"
                                      else Img (Sups (1)))
                                   & (if Positive then "" else " not"),
                                   "monitoring" & Img (B.JRU_Monitoring)
                                   & " status" & Img (B.JRU_Sup_Status));
                  if Result.Verdict /= Passed then
                     return Result;
                  end if;
               end;
            when 38 | 45 =>
               Result := Cab_Or_Condition (Id, Positive);
               if Result.Verdict /= Passed then
                  return Result;
               end if;
            when others =>
               declare
                  Map : constant JRU_Map_T := Message_Event (Id);
                  Found, Found_Event : Boolean := False;

                  --  the record's own fields its event carries
                  --  (Record_Field): every number given is the record's
                  function Fields_Match (R : B.JRU_Record_T) return Boolean is
                  begin
                     for K in 5 .. Line.Count loop
                        declare
                           Wd : constant String := W (K);
                           Eq : constant Natural :=
                             Ada.Strings.Fixed.Index (Wd, "=");
                           F : constant Field_Map_T :=
                             (if Eq > Wd'First and then Eq < Wd'Last
                              then Record_Field (Id, Wd (Wd'First .. Eq - 1))
                              else (others => <>));
                           V : constant Integer :=
                             (if F.Byte = 0 then -1
                              else Field_Value (Wd (Eq + 1 .. Wd'Last),
                                                F.Binary));
                           Got : constant Natural :=
                             (case F.Byte is
                                when 2 => R.B2,
                                when 3 => (if F.Wide then R.B3 * 256 + R.B4
                                           else R.B3),
                                when others => R.B4);
                        begin
                           if V >= 0 and then V /= Got then
                              return False;
                           end if;
                        end;
                     end loop;
                     return True;
                  end Fields_Match;
               begin
                  --  the records of a later phase (SUBSET-027 4.2.4.5, .7,
                  --  .8, .26): radio infill and Euroloop (E7), NTC
                  if Id in 5 | 8 then
                     return NJ (R_Radio_Infill, "JRU " & Img (Id));
                  elsif Id = 7 then
                     return NJ (R_Euroloop, "JRU 7");
                  elsif Id = 26 then
                     return NJ (R_NTC, "JRU 26");
                  end if;
                  if not Map.Known then
                     return NJ (R_JRU_Not_Modelled, Img (Id));
                  end if;
                  for I in 1 .. Rec_Count loop
                     if Rec_Matches (Rec (I), Map.Event, Map.Sub, -1)
                       and then (Map.B4 < 0 or else Rec (I).B4 = Map.B4)
                     then
                        Found_Event := True;
                        Found := Found or else Fields_Match (Rec (I));
                     end if;
                  end loop;
                  --  the Train Data are also recorded when they changed
                  --  by another source (5.17.2.2 A7, event 23 kind 11
                  --  byte 3 6)
                  if Id = 2 and then Any_Rec (23, 11, 6) then
                     Found := True;
                  end if;
                  --  Q_RBCENTRY 2 for RBC data entered on an on-board with
                  --  GSM-R only: 3 in SUBSET-027 4.0.0 (4.2.4.24), 2 the
                  --  coding of the versions before FRMCS
                  if not Found and then Positive and then Id = 24
                    and then (for some K in 5 .. Line.Count =>
                                W (K) = "Q_RBCENTRY=2")
                    and then Any_Rec (124, 3, -1)
                  then
                     return NJ (R_S076_Defect, "JRU 24 Q_RBCENTRY 2, the "
                                & "coding before 4.0.0 (ours 3, GSM-R)");
                  end if;
                  Result := Check (Found = Positive,
                                   "JRU" & Id_S & " as event" & Img (Map.Event)
                                   & (if Positive then "" else " not"),
                                   (if Found then "recorded"
                                    elsif Found_Event
                                    then "recorded with other values"
                                    else "none"));
                  if Result.Verdict /= Passed then
                     return Result;
                  end if;
                  --  its own fields: a symbolic value stands for what was
                  --  entered (NID_OPERATIONAL_1); a number is not carried
                  for K in 5 .. Line.Count loop
                     declare
                        Wd : constant String := W (K);
                        Eq : constant Natural :=
                          Ada.Strings.Fixed.Index (Wd, "=");
                        Name : constant String :=
                          (if Eq > 0 then Wd (Wd'First .. Eq - 1) else Wd);
                     begin
                        if not Same (Name, "M_MODE")
                          and then not Same (Name, "M_LEVEL")
                          and then not Same (Name, "DRIVER_ID")
                          and then Record_Field (Id, Name).Byte = 0
                          and then not (Eq > 0 and then Eq < Wd'Last
                                        and then Wd (Eq + 1) not in '0' .. '9')
                        then
                           Note_Gap (Img (Id) & "." & Name);
                        end if;
                     end;
                  end loop;
               end;
         end case;
      end if;
      --  the header fields: the location, speed, identity and version
      --  from the messages' headers, the others from the on-board's state
      if Id = 0 then
         declare
            Judged : Boolean;
            J : constant Judgement_T := Header_Judge (Id, Positive, Judged);
         begin
            if Judged then
               Any_Field := True;
               if J.Verdict /= Passed then
                  return J;
               end if;
            end if;
         end;
      end if;
      for K in 5 .. Line.Count loop
         declare
            Wd : constant String := W (K);
            Eq : constant Natural := Ada.Strings.Fixed.Index (Wd, "=");
            Name : constant String :=
              (if Eq > 0 then Wd (Wd'First .. Eq - 1) else Wd);
            Value : constant String :=
              (if Eq > 0 then Wd (Eq + 1 .. Wd'Last) else "");
            Handled : Boolean;
            J : Judgement_T;
            First_Name, First_Value : Unbounded_String;
            Ok : Boolean;
         begin
            Item (Wd, 1, First_Name, First_Value, Ok);
            if Id = 0 and then Ok
              and then Header_Value (To_String (First_Name),
                                     (others => <>)) >= 0
            then
               null;
            elsif Same (Name, "M_MODE") or else Same (Name, "M_LEVEL")
              or else Same (Name, "DRIVER_ID") or else Id = 0
            then
               J := Header_Field (Name, Value, Positive, Handled);
               if not Handled then
                  Note_Gap ("ALL." & Name);
               else
                  Any_Field := True;
                  if J.Verdict /= Passed then
                     return J;
                  end if;
               end if;
            end if;
         end;
      end loop;
      if Id = 0 and then not Any_Field then
         return NJ (R_JRU_Not_Modelled, Image (Field_Gap));
      end if;
      return Result;
   end JRU_Window_Expect;

   --  A JRU record step judged over its window, else over its location
   --  (the records since the train left the location before,
   --  Sync_Location_Records): the steps of one location describe one
   --  instant, and the record of a step whose window an earlier step at
   --  the same location used up (waiting for its own record or symbol)
   --  came in that step's window
   function JRU_Expect (St : Step_T) return Judgement_T is
      J : constant Judgement_T := JRU_Window_Expect (St);
      L : Judgement_T;
   begin
      if J.Verdict /= Failed or else Location_Scope then
         return J;
      end if;
      Sync_Location_Records;
      Location_Scope := True;
      L := JRU_Window_Expect (St);
      Location_Scope := False;
      return (if L.Verdict = Passed then L else J);
   end JRU_Expect;

   function Expect (St : Step_T) return Judgement_T is
      Iface : constant String := W (2);
   begin
      if Iface = "JRU" then
         return JRU_Expect (St);
      elsif Iface = "DMI" then
         return DMI_Expect (St);
      elsif Iface = "TIU" then
         return TIU_Expect;
      elsif Iface = "RTM" then
         return Radio_Expect (St);
      elsif Iface = "ATO" then
         return NJ (R_ATO, "ATO " & W (3));
      end if;
      return NJ (R_Unclassified, "expect " & Iface);
   end Expect;

   ---------------------------------------------------------------------
   --  The sequence
   ---------------------------------------------------------------------

   --  Step I delivers again, at the same place, a balise group an
   --  earlier step delivered (the joined case of 3060500_01, BG1d at
   --  50 m in steps 39 and 43): the radio messages and requests made at
   --  the first delivery stay listed (step 49 expects the connect
   --  request of step 39)
   function Redelivered (I : Positive) return Boolean is
      St : Step_T renames Seq.Steps (I);
      L  : constant String := Image (St.Line);
   begin
      if St.IO /= Input or else not Starts (L, "input BTM balise-group ")
      then
         return False;
      end if;
      for K in reverse 1 .. I - 1 loop
         if Seq.Steps (K).IO = Input
           and then Seq.Steps (K).Dist_Cm = St.Dist_Cm
           and then Image (Seq.Steps (K).Line) = L
         then
            return True;
         end if;
      end loop;
      return False;
   end Redelivered;

   --  e5/jru-radio: an "expect JRU record 9" (message from the RBC)
   --  directly followed by an "input RTM message" and not itself after an
   --  input is the record of that message, listed before it (3150100_09
   --  and _11 step 71, 9990200_13 step 71): the pair is one event, the
   --  record judged after the input
   function JRU_Before_Message (I : Positive) return Boolean is
     (I < Seq.Step_Count
      and then I > 1
      and then Seq.Steps (I).IO = Output
      and then Seq.Steps (I - 1).IO = Output
      and then Seq.Steps (I + 1).IO = Input
      and then Starts (Image (Seq.Steps (I).Line) & " ",
                       "expect JRU record 9 ")
      and then Starts (Image (Seq.Steps (I + 1).Line),
                       "input RTM message "));

   --  The order the steps are run in: as listed, but for the pairs above
   function Step_Order (K : Positive) return Positive is
     (if JRU_Before_Message (K) then K + 1
      elsif K > 1 and then JRU_Before_Message (K - 1) then K - 1
      else K);

   --  Step I is the driver's acknowledgement of what a balise group
   --  input brought (the steps between are expectations only): the
   --  radio messages sent at the group stay listed. 5100400_06: BG4d at
   --  1200 m gives level 2 and On Sight (step 93), the on-board reports
   --  its position there (3.6.5.1.4 b and g), the sequence lists that
   --  136 after the acknowledgement at 1215 m (steps 101, 103): it
   --  lists the outputs of one event in an order the on-board does not
   --  keep
   function Ack_After_Group (I : Positive) return Boolean is
   begin
      if not Starts (Image (Seq.Steps (I).Line), "input DMI acknowledge ")
      then
         return False;
      end if;
      for K in reverse 1 .. I - 1 loop
         if Seq.Steps (K).IO = Input then
            return Starts (Image (Seq.Steps (K).Line),
                           "input BTM balise-group ");
         end if;
      end loop;
      return False;
   end Ack_After_Group;

   --  Step I is a reach-point at the nominal place of the balise group
   --  input right before it (the steps between are expectations only):
   --  the radio messages sent at the group stay listed. 5100300_09: BG2d
   --  at 850 m orders level 0 (step 56), the on-board reports it there
   --  (136, 3.6.5.1.4 g); the sequence lists that 136 at step 61, after
   --  the min safe rear end reach-point of step 60 at the same 850 m
   --  (B003). Only when the step after it expects a radio message: an
   --  absence after the reach-point judges the reach-point's own window
   --  (4050200_04 step 88: no 136 after the reach-point at 650 m, the
   --  place of BG3d, step 82)
   function Reach_Point_At_Group (I : Positive) return Boolean is
   begin
      if not Starts (Image (Seq.Steps (I).Line), "input ODO reach-point ")
        or else I = Seq.Step_Count
        or else not Starts (Image (Seq.Steps (I + 1).Line),
                            "expect RTM message ")
      then
         return False;
      end if;
      for K in reverse 1 .. I - 1 loop
         if Seq.Steps (K).IO = Input then
            return Starts (Image (Seq.Steps (K).Line),
                           "input BTM balise-group ")
              and then Seq.Steps (K).Dist_Cm = Seq.Steps (I).Dist_Cm;
         end if;
      end loop;
      return False;
   end Reach_Point_At_Group;

   --  A step out of the scope of this phase: level 2 / 3, NTC
   function Scope (St : Step_T) return Reason_T is
      Lb : constant Level_Kind_T := Level_Of (Trim (St.Lvl_Before));
      La : constant Level_Kind_T := Level_Of (Trim (St.Lvl_After));
   begin
      if Lb = K_L3 or else La = K_L3 then
         return R_Level_3;
      elsif Lb = K_NTC or else La = K_NTC
        or else Trim (St.Mode_Before) = "SN" or else Trim (St.Mode_After) = "SN"
      then
         return R_NTC;
      end if;
      return R_None;
   end Scope;

   --  e5/handover-4: the test cases of 3.15.1.3.2, the exception for an
   --  on-board that handles one GSM-R session at a time (no connect at
   --  the order, the Accepting RBC's after the Handing Over session is
   --  over). This one handles two (EVC_Config Radio_Sessions, decision 2
   --  of E5): 3.15.1.3.1 a) applies, the cases are not applicable. The
   --  sequence, the case of feature 3150100 (its scn "case" line) and
   --  its first step, the same in the three system versions.
   type Single_Case_T is record
      Sequence : String (1 .. 10);
      Case_No  : Positive;
      First    : Positive;
   end record;
   Single_Session_Cases : constant array (1 .. 5) of Single_Case_T :=
     (("3150100_02", 3, 76), ("3150100_02", 4, 112),
      ("3150100_02", 7, 148), ("3150100_07", 10, 70),
      ("3150100_07", 11, 125));

   function Single_Session_Case (St : Step_T) return Boolean is
     (for some C of Single_Session_Cases =>
        Has (Image (Seq.Name), C.Sequence) and then St.Number = C.First);

   --  A step conditional on the initial mode of its test case ("only if
   --  initial mode is SB mode", "Only if initial mode isn't SM"), the
   --  initial mode the mode before of the case's first row (the nearest
   --  step at or before it with row 1: 3110500_02 step 70, case 3110500
   --  10 begins in FS at step 67): the step is not taken when the
   --  case's initial mode is another
   function Initial_Mode_Excludes (I : Positive) return Boolean is
      C     : constant String := Up (Image (Seq.Steps (I).Comment));
      Tag   : constant String := "ONLY IF INITIAL MODE ";
      P     : constant Natural := Ada.Strings.Fixed.Index (C, Tag);
      First : Positive := I;
   begin
      if P = 0 then
         return False;
      end if;
      while First > 1 and then Seq.Steps (First).Row /= 1 loop
         First := First - 1;
      end loop;
      declare
         Mode : constant String := Up (Trim (Seq.Steps (First).Mode_Before));
         Rest : constant String := C (P + Tag'Length .. C'Last);
         Neg  : constant Boolean :=
           Starts (Rest, "ISN'T ") or else Starts (Rest, "IS NOT ");
         From : constant Natural :=
           (if Starts (Rest, "ISN'T ") then Rest'First + 6
            elsif Starts (Rest, "IS NOT ") then Rest'First + 7
            elsif Starts (Rest, "IS ") then Rest'First + 3 else 0);
         Last : Natural := From;
      begin
         if From = 0 then
            return False;
         end if;
         while Last + 1 <= Rest'Last and then Rest (Last + 1) in 'A' .. 'Z'
         loop
            Last := Last + 1;
         end loop;
         if Last > Rest'Last or else Rest (From) not in 'A' .. 'Z' then
            return False;
         end if;
         return (Rest (From .. Last) = Mode) = Neg;
      end;
   end Initial_Mode_Excludes;

   --  The steps of a sequence that are a defect of SUBSET-076, by
   --  sequence and step (the same in the three system versions), the
   --  sequence blocked there: 3130700_02 step 51, the train at the
   --  chart's 12 km/h "below V5" for D_PBD 105 m, the ERA tool's
   --  unrounded V_PBD, which 3.11.11.6 rounds down to the next lower
   --  multiple of 5 km/h (10, EVC_PBD)
   type Defect_Step_T is record
      Sequence : String (1 .. 10);
      Step     : Positive;
   end record;
   Defect_Steps : constant array (1 .. 1) of Defect_Step_T :=
     (1 => ("3130700_02", 51));

   function Defect_Step (St : Step_T) return Boolean is
     (for some C of Defect_Steps =>
        Has (Image (Seq.Name), C.Sequence) and then St.Number = C.Step);

   --  Known defects of SUBSET-076 found at a step, each with the clause
   --  it contradicts; the step, the same in the three system versions,
   --  blocks the sequence. The linking data: the step that expects the
   --  passed group taken as the LRBG (or the input of the group where no
   --  step judges it) where the sequence's own linking (packet 5 of the
   --  LRBG, 3.4.4.2) places that group elsewhere than its track does, or
   --  names another group there. The on-board rejects the group (found
   --  outside its expectation window, 3.4.4.4.3.2; linked and not in the
   --  linking information, 3.4.4.4.2) and keeps its LRBG, so the steps
   --  after run on another position reference than the sequence's.
   type Linking_Case_T is record
      Sequence : String (1 .. 10);
      Step     : Positive;
   end record;
   Linking_Data_Cases : constant array (1 .. 10) of Linking_Case_T :=
     (("3131040_13", 56),
      ("3131040_27", 55),
      ("3131040_31", 55),
      ("3131040_37", 52),
      ("3080500_03", 49),
      ("3131040_20", 56),
      ("3131040_38", 56),
      ("3131040_50", 56),
      ("3130234_10", 50),
      ("3131040_78", 56));

   --  what the data of case I say against the track or the clause
   function Linking_Why (I : Positive) return String is
     (case I is
         when 1 =>
           "linking: BG1d links BG2 at 350 m, BG3 at 550; BG2d at 50,"
           & " BG3d at 250 (3.4.4.4.3.2)",
         when 2 =>
           "linking: BG1d links BG2 at 800 m, BG3 at 1600; BG2d 750, BG3d"
           & " 950 (3.4.4.4.3.2)",
         when 3 =>
           "linking: BG1d links BG2 at 500 m, BG3 at 800; BG2d 100, BG3d"
           & " 400 (3.4.4.4.3.2)",
         when 4 =>
           "linking: BG1d links NID_BG 2 at 700 m; the track has BG3d"
           & " there (3.4.4.4.2)",
         when 5 =>
           "linking: BG3d's linking (BG5 at 1170 m) leaves out BG4d at"
           & " 1200 (3.4.4.4.2)",
         when 6 =>
           "linking: BG2d links NID_BG 2 at 1150 m; the track has BG3d"
           & " there (3.4.4.4.2)",
         when 7 | 8 =>
           "linking: BG1d links NID_BG 2 at 705 m; the track has BG3d"
           & " there (3.4.4.4.2)",
         when 9 =>
           "linking: BG1d links BG2 at 250 m; BG2d at 300, its MA"
           & " rejected (3.4.4.4.3.2)",
         when others =>
           "the text: V_TRAIN > V_EMA, the comment and the Indication"
           & " expected: below V_EMA (3.13.10.4.15)");

   function Linking_Data_Case (St : Step_T) return Natural is
   begin
      for I in Linking_Data_Cases'Range loop
         if Has (Image (Seq.Name), Linking_Data_Cases (I).Sequence)
           and then St.Number = Linking_Data_Cases (I).Step
         then
            return I;
         end if;
      end loop;
      return 0;
   end Linking_Data_Case;

   ---------------------------------------------------------------------
   --  The braking curve steps judged with the ERA workbook's results
   --  (B101, e5/curves-judge). A step whose comment says the train has
   --  passed (or reached) a supervision limit with one of its ends sets
   --  the reference of its location: the workbook (the set named in
   --  that comment or an earlier one, else the only set), the limit,
   --  and our state there (the named end's distance to our target, the
   --  speed, the permitted and SBI speeds shown). The first step of a
   --  location sets it, a step at another location clears it. A failed
   --  supervision status, brake command or traction cut-off expectation
   --  at a location with a reference is judged by it (Curve_Judgement);
   --  one that passed stays passed (decision: the curves explain a
   --  failure, they do not overrule a status that matched).
   ---------------------------------------------------------------------

   type Curve_Ref_T is record
      Valid     : Boolean := False;
      Set       : Natural := 0;
      Column    : Curve_Column_T := Permitted;
      Dist_Cm   : Integer_64 := 0;
      --  the named end at the step's location, track coordinate, cm, and
      --  whether it is the max safe front end (else the estimated one)
      End_Cm    : Integer_64 := 0;
      End_Max   : Boolean := False;
   end record;
   Ref        : Curve_Ref_T;
   Last_Named : Natural := 0;
   --  the location of the last step and the time the train left the
   --  one before (the end of the last step there): the changes of the
   --  on-board's supervision since are the ones of this location
   Loc_Cm     : Integer_64 := Integer_64'First;
   Loc_Since  : Unsigned_64 := 0;

   --  Tolerances (decided here, PLAN section 13 "Runner judges at its
   --  own status changes"): our location of a limit agrees with the
   --  workbook's when it is at most 10 m further from the target
   --  (conservative: the conversion model's steps) or at most 2 m nearer
   --  (the sampling of the workbook's rows) plus the margin of the
   --  tool's emergency brake (Tool_Margin)
   Curve_Out   : constant Long_Float := 10.0;
   Curve_In    : constant Long_Float := 2.0;

   --  The set whose workbook Text names ("According to Subset-076-6-
   --  3_3130234_06b_v400": white space dropped, matched on "3130234_06b"
   --  followed by "_v"), 0 when none
   function Named_Set (Text : String) return Natural is
      T : String (1 .. Text'Length);
      N : Natural := 0;
   begin
      for C of Text loop
         if C /= ' ' then
            N := N + 1;
            T (N) := C;
         end if;
      end loop;
      for S in 1 .. Seq.Curve_Count loop
         declare
            Wb : constant String := Image (Seq.Curves (S).Workbook);
            P  : constant Natural := Ada.Strings.Fixed.Index (Wb, "6-3_");
            Q  : constant Natural := Ada.Strings.Fixed.Index (Wb, "_v4");
         begin
            if P > 0 and then Q > P + 4
              and then Ada.Strings.Fixed.Index
                (T (1 .. N), Wb (P + 4 .. Q - 1) & "_v") > 0
            then
               return S;
            end if;
         end;
      end loop;
      return 0;
   end Named_Set;

   --  The limit a comment says the train passed or reached: the first
   --  limit word after the first of "PASSED", "REACH", "LEFT", "LEAVES",
   --  "OVERPASS", "PASSES"; the release speed, the
   --  start of release speed monitoring, the perturbation location, an
   --  EOA or SvL first: none (no curve column judged)
   procedure Limit_Of (Text : String; Col : out Curve_Column_T;
                       Found : out Boolean)
   is
      U    : constant String := Up (Text);
      P    : Natural := Ada.Strings.Fixed.Index (U, "PASSED");
      Best : Natural := Natural'Last;
      Kind : Curve_Column_T := EBI_Release;

      procedure Try (Word : String; C : Curve_Column_T) is
         K : constant Natural := Ada.Strings.Fixed.Index (U, Word, P);
      begin
         if K > 0 and then K < Best then
            Best := K;
            Kind := C;
         end if;
      end Try;

      --  the first of "PASSED" and the other verbs
      procedure Verb (Word : String) is
         K : constant Natural := Ada.Strings.Fixed.Index (U, Word);
      begin
         if K > 0 and then (P = 0 or else K < P) then
            P := K;
         end if;
      end Verb;
   begin
      Col := Permitted;
      Found := False;
      Verb ("REACH");
      Verb (" LEFT ");
      Verb (" LEAVES ");
      Verb ("OVERPASS");
      Verb (" PASSES ");
      if P = 0 then
         return;
      end if;
      Try ("INDICATION", Indication);
      Try ("PERMITTED", Permitted);
      Try ("WARNING", Warning);
      Try ("SBI", SBI);
      Try ("EBI", EBI);
      Try ("RSM", EBI_Release);
      Try ("RELEASE SPEED", EBI_Release);
      Try ("PERTURBATION", EBI_Release);
      Try ("EOA", EBI_Release);
      Try ("SVL", EBI_Release);
      Found := Best /= Natural'Last and then Kind /= EBI_Release;
      Col := Kind;
   end Limit_Of;

   --  The end of the train a step places at its location, relative to
   --  the antenna, cm: the point of a reach-point input, else the first
   --  end its comment names (estimated front end when none)
   function End_Offset (Text : String) return Integer_64 is
      U  : constant String := Up (Text);
      Ok : Boolean;
      P  : Integer_64;
      Best : Natural := Natural'Last;
      Kind : String (1 .. 3) := "EST";

      procedure Try (Word, K : String) is
         I : constant Natural := Ada.Strings.Fixed.Index (U, Word);
      begin
         if I > 0 and then I < Best then
            Best := I;
            Kind := K;
         end if;
      end Try;
   begin
      if W (2) = "ODO" and then Same (W (3), "reach-point") then
         P := Point_Offset (W (4), Ok);
         if Ok then
            return P;
         end if;
      end if;
      Try ("ESTIMATED", "EST");
      Try ("MAX SAFE", "MAX");
      Try ("MAXIMUM SAFE", "MAX");
      Try ("MIN SAFE", "MIN");
      Try ("MINIMUM SAFE", "MIN");
      return (if Kind = "MAX" then B.Front_Offset + B.Doubt_Over
              elsif Kind = "MIN" then B.Front_Offset - B.Doubt_Under
              else B.Front_Offset);
   end End_Offset;

   --  The first end Text names is the max safe front end
   function Max_End_Named (Text : String) return Boolean is
      U : constant String := Up (Text);
      function At_Of (Word : String) return Natural is
        (if Ada.Strings.Fixed.Index (U, Word) = 0 then Natural'Last
         else Ada.Strings.Fixed.Index (U, Word));
      M : constant Natural :=
        Natural'Min (At_Of ("MAX SAFE"), At_Of ("MAXIMUM SAFE"));
   begin
      return M < Natural'Last
        and then M < At_Of ("ESTIMATED")
        and then M < Natural'Min (At_Of ("MIN SAFE"), At_Of ("MINIMUM SAFE"));
   end Max_End_Named;

   --  The set of a curve step whose comment names no limit: the set
   --  named last, or the only one; 0 when not known
   function Unnamed_Set return Natural is
     (if Last_Named in 1 .. Seq.Curve_Count then Last_Named
      elsif Seq.Curve_Count = 1 then 1 else 0);

   --  Set or clear the reference at step I (above)
   procedure Note_Curve_Ref (I : Positive) is
      St    : Step_T renames Seq.Steps (I);
      C     : constant String := Image (St.Comment);
      N     : constant Natural := Named_Set (C);
      Col   : Curve_Column_T;
      Found : Boolean;
   begin
      if N > 0 then
         Last_Named := N;
      end if;
      if St.Dist_Cm /= Loc_Cm then
         Loc_Cm := St.Dist_Cm;
         Loc_Since := Step_Start_Ms;
         --  the records of before the end of the last step belong to
         --  the location before; this step's own follow
         Loc_Count := 0;
         Sync_Location_Records;
      end if;
      if Ref.Valid and then Ref.Dist_Cm = St.Dist_Cm then
         return;
      end if;
      Ref.Valid := False;
      if Seq.Curve_Count = 0 then
         return;
      end if;
      Limit_Of (C, Col, Found);
      if not Found then
         return;
      end if;
      Ref :=
        (Valid   => True,
         Set     => (if Last_Named > 0 then Last_Named
                     elsif Seq.Curve_Count = 1 then 1 else 0),
         Column  => Col,
         Dist_Cm => St.Dist_Cm,
         End_Cm  => St.Dist_Cm + End_Offset (C),
         End_Max => Max_End_Named (C));
      Ref.Valid := Ref.Set > 0;
   end Note_Curve_Ref;

   --  A failed expectation the braking curves decide: the supervision
   --  status (JRU message 20), the brake and traction cut-off commands
   --  (JRU 3 / 4 / 43, TIU)
   function Curve_Kind (Sig : String) return Boolean is
     (Has (Sig, "JRU supervision") or else Has (Sig, "JRU3 state")
      or else Has (Sig, "JRU4 state") or else Has (Sig, "JRU43 state")
      or else (W (2) = "TIU"
               and then (Same (W (3), "service-brake")
                         or else Same (W (3), "emergency-brake")
                         or else Same (W (3), "traction-cutoff"))));

   --  A difference in metres as a band of the signature (the metres
   --  themselves are in the trace)
   function Band (M : Long_Float) return String is
     (if M < 10.0 then "under 10 m" elsif M < 30.0 then "10 to 30 m"
      elsif M < 100.0 then "30 to 100 m"
      elsif M < 300.0 then "100 to 300 m" else "over 300 m");

   function Metres (M : Long_Float) return String is
     ((if M < 0.0 then "-" else "+") & Img (Integer (abs M)) & " m");

   --  The first change of the on-board's supervision (S076_Bench) of
   --  the kind a limit is passed with: Indication, Permitted (to
   --  Overspeed), Warning, SBI (the service brake command), EBI (the
   --  emergency brake command) since the train left the location before;
   --  0 when none was seen
   function Change_Of (Column : Curve_Column_T) return Natural is
      function Here (I : Positive) return Boolean is
        (B.Change (I).Shown
         and then Unsigned_64 (B.Change (I).Time_Ms) >= Loc_Since);
      use type B.Change_Kind_T;
      K : constant B.Change_Kind_T :=
        (case Column is
            when Indication => B.To_Indication,
            when Permitted  => B.To_Overspeed,
            when Warning    => B.To_Warning,
            when EBI        => B.EB_On,
            when others     => B.SB_On);
   begin
      --  the earliest at this location: a later one follows a speed the
      --  bench imposed again after the on-board's brake (decision)
      for I in reverse 1 .. B.Change_Count loop
         if Here (I) and then B.Change (I).Kind = K then
            return I;
         end if;
      end loop;
      --  a status passed over (the on-board entered target speed
      --  monitoring above the limit's speed, or a cycle passed two
      --  limits): the latest change to a higher status, the limit was
      --  passed at the latest there
      for I in reverse 1 .. B.Change_Count loop
         if Here (I) and then K in B.To_Indication .. B.To_Warning
           and then B.Change (I).Kind in B.To_Indication .. B.To_Intervention
           and then B.Change (I).Kind > K
         then
            return I;
         end if;
      end loop;
      return 0;
   end Change_Of;

   --  A JRU message 20 step that expects release speed monitoring
   --  (M_SDMTYPE 2)
   function Release_Step return Boolean is
     (for some K in 5 .. Line.Count =>
        Starts (Up (W (K)), "M_SDMTYPE=") and then Has (W (K), "2"));
   --  A release speed step its location's records do not show (B140,
   --  B360): the step names the start of release speed monitoring or
   --  its status without a limit of the workbook's columns, so the
   --  curves do not judge it. It is judged at our own start of release
   --  speed monitoring (EVC_SDM.Shown_At_T.RSM_Start, 3.13.9.4.6, .7: the
   --  location where the estimated front end, or with RSM_Max_Safe the
   --  max safe front end, enters release speed monitoring), as a curve
   --  step is judged at our status change (Drive_On): when that start is
   --  ahead and at most Release_Past past the step's location, the train
   --  runs on at its speed until the on-board monitors the release speed
   --  and the step is judged again over its location. The sequence's
   --  location is its start (the step before has the train reach it).
   --  Still failed: the signature names the release speed's origin of
   --  the workbook (fixed by Track!E2, or calculated on board) and why
   --  (no release speed supervised, our start past the location, or the
   --  record itself); the trace gives ours
   Release_Past : constant Integer_64 := 1_000;  -- cm, as Drive_On_Limit

   --  declared here for Release_Judgement; the body is with the curves
   function Tool_Margin (C : Curve_Set_T; V_Kmh, V_Target_Kmh : Long_Float)
                         return Long_Float;

   --  The workbook whose start of release speed monitoring is for the
   --  release speed V_Kmh (within 1 km/h): the set named last when it
   --  is, else the first such set; 0 when none
   function Release_Set (V_Kmh : Long_Float) return Natural is
      function For_V (S : Positive) return Boolean is
        (Seq.Curves (S).Limits (S076_Sequences.Start_RSM) /= No_Value
         and then abs (Seq.Curves (S).Limits (S076_Sequences.Release_Speed)
                       - V_Kmh) <= 1.0);
   begin
      if Unnamed_Set > 0 and then For_V (Unnamed_Set) then
         return Unnamed_Set;
      end if;
      for S in 1 .. Seq.Curve_Count loop
         if For_V (S) then
            return S;
         end if;
      end loop;
      return 0;
   end Release_Set;

   function Release_Judgement (St : Step_T; J : Judgement_T;
                               Verbose : Boolean) return Judgement_T
   is
      use type EVC_SDM.Monitoring_T;
      R      : constant EVC_SDM.Result_T := EVC_Core.Supervision;
      --  the set named last or the only one, else the sets' common
      --  choice (Unknown when they differ or none is read); the
      --  sequence's own V_RELEASEDP 126 says calculated on board
      Choice : S076_Sequences.Choice_T :=
        (if Unnamed_Set > 0 then Seq.Curves (Unnamed_Set).Cells.Release
         elsif Seq.Curve_Count > 0 then Seq.Curves (1).Cells.Release
         else S076_Sequences.Unknown);
      Dir    : constant Integer_64 := Integer_64 (B.Direction);
      From   : constant Integer_64 := B.Position;
      --  our start in track coordinates, and how far past the step's
      --  location it is (cm, along the train's movement)
      Ahead  : constant Integer_64 :=
        Integer_64 (R.Shown_At.RSM_Start) - Integer_64 (R.Shown_At.X_Est);
      --  the reference: the workbook's start for our release speed (m
      --  from the EOA, less the tool margin), else the step's location
      V_Ours : constant Long_Float := Long_Float (R.V_Release) * 0.036;
      Set    : constant Natural := Release_Set (V_Ours);
      Wb     : constant Long_Float :=
        (if Set = 0 then No_Value
         else Seq.Curves (Set).Limits (S076_Sequences.Start_RSM)
              - Tool_Margin (Seq.Curves (Set), V_Ours, 0.0));
      Past   : constant Integer_64 :=
        (if Wb /= No_Value
         then Integer_64 (Wb * 100.0)
              - (Integer_64 (B.State.Plan_MA) * 100 - Ahead)
         else Dir * (From + Dir * Ahead - St.Dist_Cm));
      Ours   : constant Boolean :=
        R.Monitoring /= EVC_SDM.RSM and then Integer_64 (R.Shown_At.RSM_Start) /= 0
        and then Ahead > 0;
      Driven : Integer_64 := 0;
      Again  : Judgement_T;
   begin
      if Unnamed_Set = 0 then
         for S in 1 .. Seq.Curve_Count loop
            if Seq.Curves (S).Cells.Release /= Choice then
               Choice := S076_Sequences.Unknown;
            end if;
         end loop;
      end if;
      if Ours and then Past <= Release_Past and then B.Speed > 0 then
         for I in 1 .. 200_000 loop
            exit when EVC_Core.Supervision.Monitoring = EVC_SDM.RSM
              or else B.Speed = 0
              or else abs (B.Position - From) > Ahead + B.Current.Over
                                                + Release_Past;
            B.Cycle;
         end loop;
         Driven := abs (B.Position - From);
      end if;
      declare
         Origin : constant String :=
           (if Choice = S076_Sequences.First and then not Seq.Release_OB
            then "fixed"
            elsif Choice = S076_Sequences.Second or else Seq.Release_OB
            then "calculated on board"
            else "of no single workbook choice");
         Now    : constant EVC_SDM.Result_T := EVC_Core.Supervision;
         Why    : constant String :=
           (if R.Monitoring /= EVC_SDM.RSM and then not Ours
            then ", no release speed supervised"
            elsif Ours and then Past > Release_Past
            then ", our start of release speed monitoring past the location"
            elsif Now.Monitoring /= EVC_SDM.RSM
            then ", no release speed monitoring at our start"
            else "");
      begin
         if Verbose then
            Put_Line ("      release speed: the workbook's " & Origin
                      & "; ours " & Img (Integer (Long_Float (R.V_Release)
                                                  * 0.036))
                      & " km/h, monitoring "
                      & EVC_SDM.Monitoring_T'Image (R.Monitoring) & " at "
                      & Img (Integer (From / 100)) & " m; our start"
                      & Integer_64'Image (Ahead / 100) & " m ahead ("
                      & (if R.Shown_At.RSM_Max_Safe then "max safe"
                         else "estimated") & " front end),"
                      & Integer_64'Image (Past / 100)
                      & " m past the "
                      & (if Wb /= No_Value
                         then "workbook's (set" & Natural'Image (Set)
                              & ", with its margin)"
                         else "location")
                      & "; driven"
                      & Integer_64'Image (Driven / 100) & " m to "
                      & EVC_SDM.Monitoring_T'Image (Now.Monitoring));
         end if;
         if Driven > 0 and then Why'Length = 0 then
            Sync_Location_Records;
            Location_Scope := True;
            Again := Expect (St);
            Location_Scope := False;
            if Again.Verdict = Passed then
               return Pass (Image (Again.Sig) & " at our start of release "
                            & "speed monitoring,"
                            & Integer_64'Image (Past / 100) & " m past the "
                            & (if Wb /= No_Value then "workbook's"
                               else "location"));
            end if;
            return Fail (Image (Again.Sig) & " [release speed " & Origin
                         & ", at our start]");
         end if;
         return Fail (Image (J.Sig) & " [release speed " & Origin & Why
                      & "]");
      end;
   end Release_Judgement;

   --  A failed status, brake or traction cut-off step of a braking curve
   --  sequence whose location names no limit (B140): judged over the
   --  location (the records and the supervision changes since the train
   --  left the location before), the on-board's own change of that
   --  status or command having come in the window of an earlier step at
   --  the same location; still failed: the tag of its triage line. The
   --  same for any JRU record such a sequence expects (the DMI symbols
   --  of the status, Tag empty): the steps of one location describe one
   --  instant
   function Location_Judgement (St : Step_T; J : Judgement_T;
                                Verbose : Boolean;
                                Tag : String := " [workbook train]")
                                return Judgement_T
   is
      use type B.Change_Kind_T;
      K : B.Change_Kind_T := B.EB_On;
      R : Judgement_T;
   begin
      Sync_Location_Records;
      if W (2) = "TIU" then
         if not Same (W (4), "commanded") then
            return Fail (Image (J.Sig) & Tag);
         end if;
         K := (if Same (W (3), "service-brake") then B.SB_On
               elsif Same (W (3), "traction-cutoff") then B.TCO_On
               else B.EB_On);
         for I in 1 .. B.Change_Count loop
            if B.Change (I).Kind = K
              and then Unsigned_64 (B.Change (I).Time_Ms) >= Loc_Since
            then
               return Pass (Image (J.Sig) & " in its window; at this "
                            & "location at "
                            & Img (Integer (B.Change (I).Track_Cm / 100))
                            & " m");
            end if;
         end loop;
         return Fail (Image (J.Sig) & Tag);
      end if;
      Location_Scope := True;
      R := Expect (St);
      Location_Scope := False;
      if R.Verdict = Passed then
         return Pass (Image (J.Sig) & " in its window; at this location");
      end if;
      if Tag'Length > 0 and then Release_Step then
         return Release_Judgement (St, J, Verbose);
      end if;
      return Fail (Image (J.Sig) & Tag);
   end Location_Judgement;

   --  The named end's distance to the target of a change, m: to the EOA
   --  of an EOA target, else to the target location (Curve_Judgement)
   function Our_Distance (Ch : B.Change_T) return Long_Float is
     (Long_Float (if Ch.EOA_Kind then Ch.D_EOA else Ch.D_Loc) / 100.0
      - (if Ref.End_Max then Long_Float (Ch.Over) / 100.0 else 0.0));

   --  B200 (a): the workbook was computed with the ERA tool's target
   --  type LoA/MRSP at 0 km/h, not EoA/SvL, as test/tools/curve_probe.py
   --  recognises it from the block: target speed 0 (Track!B2), no SBD
   --  nor SBI1 value in any row (the tool computes them for an EoA/SvL
   --  only), the EBD reaching 0 m at a speed above 0 (dV_ebi above an
   --  LoA of 0 km/h). B291: the workbook's own option button decides
   --  where it is given (Track!LoA_MRSP selected, the target speed 0 of
   --  Track!B2: an EOA computed as an LoA; LoA_MRSP with a target speed
   --  above 0 is a real LoA or MRSP target and judged); the block's
   --  shape only without the buttons
   function Tool_Target (C : Curve_Set_T) return Boolean is
      Service, Ebd_0 : Boolean := False;
   begin
      if C.Cells.Target /= S076_Sequences.Unknown then
         return C.Cells.Target = S076_Sequences.Second
           and then C.Target_Kmh = 0.0;
      end if;
      for I in 1 .. C.Row_Count loop
         Service := Service or else C.Rows (I).D (SBD) /= No_Value
           or else C.Rows (I).D (SBI1) /= No_Value;
         Ebd_0 := Ebd_0 or else (C.Rows (I).Speed_Kmh >= 1.0
                                 and then C.Rows (I).D (EBD) /= No_Value
                                 and then abs C.Rows (I).D (EBD) <= 0.5);
      end loop;
      return C.Target_Kmh = 0.0 and then not Service and then Ebd_0;
   end Tool_Target;

   --  B200 (b): the product Kv_int x Kr_int the on-board uses at V_Kmh
   --  for the workbook train's length: the integrated correction factors
   --  in force (EVC_National_Values.Current), i.e. the sequence's packet
   --  3 as delivered so far, or the defaults of A.3.2 (0.7, 0.9) without
   --  one (decision: not the packet 3 of the file, since a sequence may
   --  carry several, 3130237_06 the defaults in BG3d after its own in
   --  BG1d). Kv_int of the set for freight trains, or for all trains
   function Seq_Kv_Kr (V_Kmh : Long_Float) return Long_Float is
      NV : constant EVC_Supervision_Input.National_Values_T :=
        EVC_National_Values.Current.Values;
      Kv : Natural := 1_000;
      Kr : Natural := 1_000;
   begin
      for I in 1 .. NV.Kv_Int_Fresh.Count loop
         if Long_Float (NV.Kv_Int_Fresh.Steps (I).Speed) * 0.036 <= V_Kmh
         then
            Kv := Natural (NV.Kv_Int_Fresh.Steps (I).Factor);
         end if;
      end loop;
      for I in 1 .. NV.Kr_Int.Count loop
         if Natural (NV.Kr_Int.Steps (I).Length) <= Seq.WB_Length * 100 then
            Kr := Natural (NV.Kr_Int.Steps (I).Factor);
         end if;
      end loop;
      return Long_Float (Kv) * Long_Float (Kr) / 1.0E6;
   end Seq_Kv_Kr;

   --  A.3.7.1: the emergency brake percentage is the train's (lambda_o =
   --  lambda, 109 for every workbook's train), while the ERA tool that
   --  filled the workbooks computes its EBD with 100 (Brake parameters
   --  (lambda)!F3; B175): its EBD distances are longer, so our limits
   --  from the EBD may sit nearer the target by the difference of the
   --  two EBD distances from V_bec down to the target speed. B261: both
   --  from the conversion model of the bench (S076_Bench.Ebd_Distance:
   --  A_basic of each percentage, Kv_int by A_ebmax of each, Kr_int, the
   --  factors in force), not a ratio of AD_0 (16 against the probe's 26
   --  m at 60 km/h for 3131040_04). B231: the EBD is entered at V_bec,
   --  not at the speed (3.13.9.3.2.10 with A_est 0: V_est + V_delta0,
   --  V_delta0 = V_ura of SUBSET-041 5.3.1.2). B300: per limit. Where
   --  the SBD of an EOA decides (the workbook's SBI1 at the speed at or
   --  beyond its SBI2: 3131040_04's P at 60 km/h, 618 m against 352), the
   --  tool's service brake ran at 100 too (A.3.7.1: min (lambda, 135)),
   --  and the limits of the column, SBI1 = d_SBD + V * T_bs1 and W and P
   --  at fixed times from it (3.13.9.3.3.1, .4.1, .5.1), move by the SBD
   --  distance and by T_bs_reduced, whose ramp of A.3.12 depends on A_SB
   --  (S076_Bench.Sbd_Terms), the Indication by T_indication = max (0.8
   --  T_bs_reduced, 5 s) + T_driver as well (3.13.9.3.6.2): 13 m of the
   --  SBD and 14 m of T_bs at 60 km/h there, the probe's 26 to 27 m.
   --  The EBD-based limits also move by V_bec times the difference of
   --  T_be_reduced, whose ramp depends on A_EB (A.3.12, 3.13.9.3.2.6)
   function Tool_Margin (C : Curve_Set_T; V_Kmh, V_Target_Kmh : Long_Float)
                         return Long_Float
   is
      V_Bec : constant Long_Float :=
        V_Kmh + Long_Float'Max (2.0, (640.0 + 0.36 * V_Kmh) / 470.0);
      Vt    : constant Long_Float := Long_Float'Max (V_Target_Kmh, 0.0);
      Tool  : constant Natural :=
        (if Seq.WB_Lambda_EB in 10 .. 250 then Seq.WB_Lambda_EB else 100);
      S1    : constant Long_Float := Curve_Distance (C, SBI1, V_Kmh);
      S2    : constant Long_Float := Curve_Distance (C, SBI2, V_Kmh);
      On_Sbd : constant Boolean :=
        Ref.Column in SBD | SBI1 | SBI | Warning | Permitted | Indication
        and then S1 /= No_Value
        and then (S2 = No_Value or else S1 >= S2);
      Service : Long_Float := 0.0;
   begin
      if On_Sbd or else Ref.Column in SBI2 | SBI | Warning | Permitted
                                      | Indication
      then
         declare
            To : constant Long_Float := (if On_Sbd then 0.0 else Vt);
            Vm : constant Long_Float := V_Kmh / 3.6;
            Ts : constant B.Sbd_Terms_T :=
              B.Sbd_Terms (Tool, Seq.WB_Brake_Position, Train_Length_M,
                           V_Kmh, To, C.Grades);
            Tr : constant B.Sbd_Terms_T :=
              B.Sbd_Terms (Brake_Percentage, Seq.WB_Brake_Position,
                           Train_Length_M, V_Kmh, To, C.Grades);
            T  : constant Long_Float :=
              (if Ref.Column = SBD then 0.0 else Ts.T_Bs - Tr.T_Bs)
              + (if Ref.Column = Indication
                 then Long_Float'Max (0.8 * Ts.T_Bs, 5.0)
                      - Long_Float'Max (0.8 * Tr.T_Bs, 5.0)
                 else 0.0);
         begin
            Service := Vm * T + (if On_Sbd then Ts.D_Sbd - Tr.D_Sbd else 0.0);
         end;
         if On_Sbd then
            return Long_Float'Max (0.0, Service);
         end if;
      end if;
      if V_Bec <= Vt then
         return Long_Float'Max (0.0, Service);
      end if;
      return Long_Float'Max
        (0.0,
         Service
         + B.Ebd_Distance (Tool, Seq.WB_Brake_Position, Train_Length_M,
                           V_Bec, Vt, C.Grades, With_Bec => True)
         - B.Ebd_Distance (Brake_Percentage, Seq.WB_Brake_Position,
                           Train_Length_M, V_Bec, Vt, C.Grades,
                           With_Bec => True));
   end Tool_Margin;

   --  B200 (b): the workbook's integrated correction factors are not in
   --  the sequence file (their sheet, "Integrated correction factors",
   --  is not extracted: B230), so the workbook's Kv_int x Kr_int is read
   --  from its EBD instead: on a flat profile, between V1 and V1 + 30
   --  km/h (both below V_lim of the conversion model, A.3.3: AD_0
   --  constant) the EBD's deceleration is Kv_int x Kr_int x AD_0, with
   --  AD_0 = 0.0075 lambda + 0.076 at the tool's emergency brake
   --  percentage (Brake parameters (lambda)!F3). 0.0 when not readable
   --  (a gradient, no two rows, Kv_int changing in the range)
   procedure Workbook_Kv_Kr (C : Curve_Set_T; K, V1 : out Long_Float) is
      L_EB : constant Long_Float :=
        Long_Float (if Seq.WB_Lambda_EB in 10 .. 250 then Seq.WB_Lambda_EB
                    else 100);
      AD_0 : constant Long_Float := 0.0075 * L_EB + 0.076;
   begin
      K := 0.0;
      V1 := 0.0;
      if not C.Flat then
         return;
      end if;
      for N in 1 .. 3 loop
         declare
            Lo : constant Long_Float := 20.0 * Long_Float (N);
            D1 : constant Long_Float := Curve_Distance (C, EBD, Lo);
            D2 : constant Long_Float := Curve_Distance (C, EBD, Lo + 30.0);
         begin
            if D1 /= No_Value and then D2 /= No_Value and then D2 > D1 + 1.0
              and then Seq_Kv_Kr (Lo) = Seq_Kv_Kr (Lo + 30.0)
            then
               K := (((Lo + 30.0) / 3.6) ** 2 - (Lo / 3.6) ** 2)
                 / (2.0 * (D2 - D1)) / AD_0;
               V1 := Lo;
               return;
            end if;
         end;
      end loop;
   end Workbook_Kv_Kr;

   --  B200: Kv_int x Kr_int of the packet 3 F at V_Kmh for the workbook
   --  train's length; the defaults of A.3.2 when F gives none
   function Packet_Kv_Kr (F : S076_Sequences.Factors_T; V_Kmh : Long_Float)
                          return Long_Float
   is
      Kv : Long_Float := 0.7;
      Kr : Long_Float := 0.9;
   begin
      if F.Given then
         Kv := 1.0;
         Kr := 1.0;
         for I in 1 .. F.Kv_Count loop
            if Long_Float (F.Kv (I).From) <= V_Kmh then
               Kv := F.Kv (I).K;
            end if;
         end loop;
         for I in 1 .. F.Kr_Count loop
            if F.Kr (I).From <= Seq.WB_Length then
               Kr := F.Kr (I).K;
            end if;
         end loop;
      end if;
      return Kv * Kr;
   end Packet_Kv_Kr;

   --  B200: the workbook's product K is one the sequence gives (within
   --  0.03; the products in use are 0.63, 0.81, 0.864, 0.96): the one in
   --  force on the on-board, the one of any of its packets 3, or the
   --  defaults when it has none (decision: a workbook made with the
   --  factors of a packet the on-board no longer holds at the step is
   --  judged, the difference is the sequence's location or ours)
   function Known_Kv_Kr (K, V_Kmh : Long_Float) return Boolean is
      function Near (X : Long_Float) return Boolean is (abs (K - X) <= 0.03);
   begin
      if Near (Seq_Kv_Kr (V_Kmh))
        or else (Seq.P3_Count = 0 and then Near (0.63))
      then
         return True;
      end if;
      for I in 1 .. Seq.P3_Count loop
         if Near (Packet_Kv_Kr (Seq.P3 (I), V_Kmh)) then
            return True;
         end if;
      end loop;
      return False;
   end Known_Kv_Kr;

   --  B290: the first difference between the workbook's integrated
   --  correction factors in use (its sheet "Integrated correction
   --  factors", the set its train type selects) and those in force on
   --  the on-board at the step (EVC_National_Values.Current: the
   --  sequence's packet 3 as delivered so far, or the A.3.2 defaults),
   --  "" when none. Exact (to the 0.001 of the on-board's milli
   --  factors). Decisions: Kv_int is compared at every km/h + 0.5 from
   --  0 to the set's highest speed (off the 5 km/h steps of V_NVKVINT),
   --  Kr_int at the workbook train's length less 0.25 m (off the 25 m
   --  steps), Kt_int as is. For a conventional passenger train in P
   --  (3.13.6.2.1.8.1) both sides take their subset at the workbook
   --  train's A_ebmax, read as AD_0 of the conversion model at the
   --  tool's emergency brake percentage (Brake parameters (lambda)!F3;
   --  the deceleration below V_lim is the maximum): a when at most
   --  A_NVP12, b when at least A_NVP23, else interpolated (the sheet's
   --  own interpolated set when it has one); the on-board without a
   --  passenger set uses its one set for every train (A.3.2)
   function Sheet_Difference (C : Curve_Set_T) return String is
      NV : constant EVC_Supervision_Input.National_Values_T :=
        EVC_National_Values.Current.Values;
      W  : Sheet_T renames C.Cells;
      L_EB : constant Long_Float :=
        Long_Float (if Seq.WB_Lambda_EB in 10 .. 250 then Seq.WB_Lambda_EB
                    else 100);
      A_Eb : constant Long_Float := 0.0075 * L_EB + 0.076;
      Passenger : constant Boolean := W.Train_Type = Passenger_P;
      P12 : constant Long_Float := Long_Float (NV.A_NVP12) / 1000.0;
      P23 : constant Long_Float := Long_Float (NV.A_NVP23) / 1000.0;
      V_Max : Long_Float := 0.0;
      function Step (S : EVC_Supervision_Input.Kv_Set_T; V : Long_Float)
                     return Long_Float
      is
         K : Long_Float := 1.0;
      begin
         for I in 1 .. S.Count loop
            if Long_Float (S.Steps (I).Speed) * 0.036 <= V then
               K := Long_Float (S.Steps (I).Factor) / 1000.0;
            end if;
         end loop;
         return K;
      end Step;
      function Ours (V : Long_Float) return Long_Float is
        (if not Passenger or else NV.Kv_Int_Passenger.Count = 0
         then Step (NV.Kv_Int_Fresh, V)
         elsif A_Eb <= P12 then Step (NV.Kv_Int_Passenger, V)
         elsif A_Eb >= P23 then Step (NV.Kv_Int_Passenger_B, V)
         else Step (NV.Kv_Int_Passenger, V)
              + (A_Eb - P12) / (P23 - P12)
                * (Step (NV.Kv_Int_Passenger_B, V)
                   - Step (NV.Kv_Int_Passenger, V)));
      function Theirs (V : Long_Float) return Long_Float is
        (if not Passenger then Sheet_Factor (W.Tables (Kv_Freight), V)
         elsif W.Tables (Kv_Interpolated) (1).K /= No_Value
         then Sheet_Factor (W.Tables (Kv_Interpolated), V)
         elsif W.A_NVP12 = No_Value or else A_Eb <= W.A_NVP12
         then Sheet_Factor (W.Tables (Kv_A), V)
         else Sheet_Factor (W.Tables (Kv_B), V));
      function Fix (X : Long_Float) return String is
        (Img (Integer (X * 1000.0)) & "/1000");
      Kr_Ours : Natural := 1_000;
      L : constant Long_Float := Long_Float (Seq.WB_Length) - 0.25;
   begin
      if W.Kt_Int /= No_Value
        and then abs (W.Kt_Int * 1000.0 - Long_Float (NV.Kt_Int)) > 0.5
      then
         return "Kt_int " & Fix (W.Kt_Int) & " against "
           & Img (Natural (NV.Kt_Int)) & "/1000";
      end if;
      for I in 1 .. NV.Kr_Int.Count loop
         if Long_Float (NV.Kr_Int.Steps (I).Length) <= L * 100.0 then
            Kr_Ours := Natural (NV.Kr_Int.Steps (I).Factor);
         end if;
      end loop;
      if Sheet_Factor (W.Tables (Kr), L) /= No_Value
        and then abs (Sheet_Factor (W.Tables (Kr), L) * 1000.0
                      - Long_Float (Kr_Ours)) > 0.5
      then
         return "Kr_int " & Fix (Sheet_Factor (W.Tables (Kr), L))
           & " against " & Img (Kr_Ours) & "/1000 at " & Img (Seq.WB_Length)
           & " m";
      end if;
      for I in 1 .. C.Row_Count loop
         V_Max := Long_Float'Max (V_Max, C.Rows (I).Speed_Kmh);
      end loop;
      for N in 0 .. Integer (V_Max) loop
         declare
            V : constant Long_Float := Long_Float (N) + 0.5;
            T : constant Long_Float := Theirs (V);
         begin
            if T /= No_Value and then abs (T - Ours (V)) > 0.0005 then
               return "Kv_int " & Fix (T) & " against " & Fix (Ours (V))
                 & " at " & Img (N) & " km/h"
                 & (if Passenger then " (passenger)" else "");
            end if;
         end;
      end loop;
      return "";
   end Sheet_Difference;

   --  B225: the workbook computed with a fixed release speed (Track!
   --  Release_speed_fixed, Track!E2) that no V_RELEASEDP of the
   --  sequence gives: 3131040_37, _38, _50 send V_RELEASEDP 30 (150
   --  km/h) where their workbooks have 30 km/h (V_RELEASEDP 6, as
   --  3131040_04): the on-board limits the 150 km/h to the MRSP
   --  (3.13.9.4.9) and supervises the release speed from far before the
   --  EOA where the workbook's train is in target speed monitoring.
   --  Decision: a defect of SUBSET-076 (R_S076_Defect), recognised from
   --  the cells rather than listed by name, so a twin is caught alike
   function Release_Defect (C : Curve_Set_T) return Boolean is
   begin
      if C.Cells.Release /= S076_Sequences.First
        or else C.Cells.Release_Kmh = No_Value
        or else Seq.Release_DP_Count = 0
      then
         return False;
      end if;
      for I in 1 .. Seq.Release_DP_Count loop
         if abs (Long_Float (Seq.Release_DP (I).From) - C.Cells.Release_Kmh)
           < 0.5
         then
            return False;
         end if;
      end loop;
      return True;
   end Release_Defect;

   --  B280: the packet 3 of the sequence whose factors are the
   --  workbook's sheet and whose country is not that of the telegram
   --  carrying it (0 none): 3131040_32 and _56 send in BG1d (country
   --  352) a packet 3 for country 64, which the on-board takes at once
   --  and drops at the next group of 352 (3.18.2.8.1, 3.18.2.5,
   --  3.18.2.10; B232); their workbooks were computed with it
   function Other_Country (C : Curve_Set_T) return Natural is
      L : constant Long_Float := Long_Float (Seq.WB_Length) - 0.25;
      function Same (A, B : Long_Float) return Boolean is
        (A /= No_Value and then abs (A - B) < 0.0005);
   begin
      for I in 1 .. Seq.P3_Count loop
         declare
            F : S076_Sequences.Factors_T renames Seq.P3 (I);
            Kv_P : Long_Float := 1.0;
            Kr_P : Long_Float := 1.0;
            OK : Boolean := F.Given and then F.Country /= F.Group_Country
              and then F.Group_Country /= 0
              and then Same (C.Cells.Kt_Int, F.Kt);
         begin
            for J in 1 .. F.Kr_Count loop
               if Long_Float (F.Kr (J).From) <= L then
                  Kr_P := F.Kr (J).K;
               end if;
            end loop;
            OK := OK and then Same (Sheet_Factor (C.Cells.Tables (Kr), L), Kr_P);
            for V in 0 .. 200 loop
               for J in 1 .. F.Kv_Count loop
                  if Long_Float (F.Kv (J).From) <= Long_Float (V) + 0.5 then
                     Kv_P := F.Kv (J).K;
                  end if;
               end loop;
               OK := OK and then Same
                 (Sheet_Factor (C.Cells.Tables (Kv_Freight),
                                Long_Float (V) + 0.5), Kv_P);
            end loop;
            if OK then
               return F.Country;
            end if;
         end;
      end loop;
      return 0;
   end Other_Country;

   function No_Reference (C : Curve_Set_T) return Reason_T;

   --  The detail of why set C is no reference, before the step's own
   --  text: the release speeds (B225), the country (B280); "" else
   function Reference_Note (C : Curve_Set_T) return String is
      R : constant Reason_T := No_Reference (C);
   begin
      if R = R_S076_Defect then
         return "the MA's V_RELEASEDP "
           & Img (Seq.Release_DP (1).From) & " km/h, the workbook's fixed"
           & " release speed " & Img (Integer (C.Cells.Release_Kmh))
           & " km/h: ";
      elsif R = R_Factors and then Other_Country (C) /= 0 then
         return "the workbook's national values are the packet 3 for"
           & " country " & Img (Other_Country (C)) & ", dropped at the next"
           & " group of another country (3.18.2.5): ";
      end if;
      return "";
   end Reference_Note;

   --  B200: why the curve steps of set C are not judged: a Gamma train
   --  (B100), an SV21 / SV22 workbook of the old tool (B170), the tool's
   --  LoA/MRSP target, other correction factors (Known_Kv_Kr; Kt_int is
   --  not readable from the EBD and not compared); R_None. B290, B291:
   --  the workbook's own option buttons (Train (main)!Gamma) and factor
   --  sheet (Sheet_Difference, Kt_int included) where it has them, the
   --  sheet's name and the EBD's deceleration only without
   function No_Reference (C : Curve_Set_T) return Reason_T is
      K, V1 : Long_Float;
   begin
      if (if C.Cells.Gamma = S076_Sequences.Unknown
          then Has (Image (C.Sheet), "Gamma")
          else C.Cells.Gamma = First)
      then
         return R_Gamma;
      elsif Seq.SV in 21 | 22 and then not C.From_Twin then
         return R_Old_Tool;
      elsif Tool_Target (C) then
         return R_Tool_Target;
      elsif Release_Defect (C) then
         return R_S076_Defect;
      elsif C.Cells.Present then
         return (if Sheet_Difference (C) = "" then R_None else R_Factors);
      end if;
      Workbook_Kv_Kr (C, K, V1);
      if K > 0.0 and then not Known_Kv_Kr (K, V1)
        and then not (Seq.WB_Brake_Position = 1
                      and then EVC_National_Values.Current.Values
                                 .Kv_Int_Passenger.Count > 0)
      then
         return R_Factors;
      end if;
      return R_None;
   end No_Reference;

   --  B200: the trace of the two sets of correction factors
   procedure Put_Factors (C : Curve_Set_T) is
      function Fix (X : Long_Float) return String is
        ("0." & Ada.Strings.Fixed.Tail
                  (Img (Integer (X * 1000.0) mod 1000), 3, '0'));
      K, V1 : Long_Float;
   begin
      if C.Cells.Present then
         Put_Line ("      curves: the workbook's factor sheet against the"
                   & " national values in force: "
                   & Sheet_Difference (C)
                   & (if EVC_National_Values.Current.From_Trackside
                      then " (from the track)" else " (the defaults)"));
         return;
      end if;
      Workbook_Kv_Kr (C, K, V1);
      Put_Line ("      curves: Kv_int x Kr_int of the workbook " & Fix (K)
                & " (its EBD from " & Img (Integer (V1)) & " to "
                & Img (Integer (V1 + 30.0)) & " km/h), of the sequence "
                & Fix (Seq_Kv_Kr (V1)) & " (in force, train of"
                & Natural'Image (Seq.WB_Length) & " m, Kt_int"
                & Natural'Image (Natural (EVC_National_Values.Current.Values
                                           .Kt_Int)) & "/1000"
                & (if EVC_National_Values.Pending then ", a set pending"
                   else "")
                & (if EVC_National_Values.Current.From_Trackside
                   then ", from the track)" else ", the defaults)"));
   end Put_Factors;

   --  B176: how far the train was driven on past the sequence's
   --  location to our change of the limit's kind (cm, 0 when not)
   Driven_Cm : Integer_64 := 0;
   Drive_On_Limit : constant Long_Float := 10.0;  -- m past the workbook's

   --  B176: a curve step whose limit our supervision has not reached
   --  at the sequence's location (no change of the limit's kind since
   --  the location before, Change_Of): the train runs on at its speed,
   --  cycle by cycle, until our change of that kind comes or the named
   --  end is Drive_On_Limit past the workbook's location of the limit
   --  at that speed (a target shown; without one, the on-board in
   --  ceiling speed monitoring, it runs on until one is), or the
   --  workbook's distance of the limit plus Drive_On_Limit (the
   --  sequence's target passed), or the train stands. The sequence has
   --  failed at this step anyway (its later steps count after the
   --  first failure), so the drive is real, on the runner's only state,
   --  not on a copy (decision). Not for a Gamma sheet or an SV21 / SV22
   --  workbook of the old tool, nor the workbooks of B200: those are not
   --  judged (No_Reference)
   procedure Drive_On (Verbose : Boolean) is
      C     : Curve_Set_T renames Seq.Curves (Ref.Set);
      From  : constant Integer_64 := B.Position;
      V     : constant Long_Float := Long_Float (B.Speed) * 0.036;
      Wb    : constant Long_Float := Curve_Distance (C, Ref.Column, V);
      --  at most the workbook's distance of the limit (plus the 10 m):
      --  the target itself is passed by then
      Max_Cm : constant Integer_64 :=
        (if Wb = No_Value then 0
         else Integer_64 ((Wb + Drive_On_Limit) * 100.0));
   begin
      Driven_Cm := 0;
      if Change_Of (Ref.Column) > 0 or else B.Speed = 0
        or else Wb = No_Value
        or else No_Reference (C) /= R_None
      then
         return;
      end if;
      for I in 1 .. 200_000 loop
         exit when Change_Of (Ref.Column) > 0
           or else (B.Current.Shown
                    and then Our_Distance (B.Current)
                             < Wb - Drive_On_Limit
                               - Tool_Margin (C, V, Long_Float
                                   (B.Current.V_Target) * 0.036))
           or else abs (B.Position - From) > Max_Cm
           or else B.Speed = 0;
         B.Cycle;
      end loop;
      Driven_Cm := abs (B.Position - From);
      if Verbose then
         Put_Line ("      curves: driven on"
                   & Integer_64'Image (Driven_Cm / 100) & " m at "
                   & Img (Integer (V)) & " km/h to "
                   & Img (Integer (B.Position / 100)) & " m"
                   & (if Change_Of (Ref.Column) > 0 then ", our change"
                      else ", no change of the kind"));
      end if;
   end Drive_On;

   --  The judgement of a failed curve expectation at a reference
   --  (B172, B173): not at the sequence's location but where our status
   --  changed (Change_Of): the named end's distance to our target there
   --  against the workbook's distance of the limit at our speed there.
   --  Within the tolerances our curves agree, the sequence's location is
   --  the author's (blocked, R_Placement); else ours is nearer or
   --  further out. A Gamma train's step is not judged (B100), nor a
   --  Lambda step of an SV21 / SV22 sequence whose workbook is its own
   --  (the ERA tool without A.3.12, B170), nor one of a workbook that is
   --  no reference for the sequence (B200, No_Reference)
   --
   --  The distances count to the EOA of an EOA target (the workbook's
   --  origin, its SvL columns included), else to the target location.
   --  Frames: the change's distances are the on-board's own (target and
   --  estimated front end in its ahead coordinates); the target's track
   --  coordinate is the antenna's at the change plus the front end
   --  offset plus that distance (the bench's odometer is exact, so the
   --  on-board's estimated front end is the true one; the sequences'
   --  curve tests run towards increasing track coordinates)
   function Curve_Judgement (Verbose : Boolean) return Judgement_T
   is
      C     : Curve_Set_T renames Seq.Curves (Ref.Set);
      Limit : constant String := Curve_Column_T'Image (Ref.Column);
      N     : constant Natural := Change_Of (Ref.Column);
      Ch    : constant B.Change_T :=
        (if N > 0 then B.Change (N) else B.Current);
      V     : constant Long_Float := Long_Float (Ch.V_Est) * 0.036;
      D_Est : constant Long_Float :=
        Long_Float (if Ch.EOA_Kind then Ch.D_EOA else Ch.D_Loc) / 100.0;
      Ours  : constant Long_Float := Our_Distance (Ch);
      Wb    : constant Long_Float := Curve_Distance (C, Ref.Column, V);
      Diff  : constant Long_Float := Ours - Wb;
      Mg    : constant Long_Float :=
        Tool_Margin (C, V, Long_Float'Rounding
                             (Long_Float (Ch.V_Target) * 0.036));
      --  the named end's distance to our target at the step's location
      Seq_D : constant Long_Float :=
        Long_Float (Ch.Track_Cm + B.Front_Offset - Ref.End_Cm) / 100.0
        + D_Est;
      Res   : Judgement_T;
   begin
      if Verbose and then (N > 0 or else Ch.Shown) then
         Put_Line ("      curves: set" & Natural'Image (Ref.Set) & " "
                   & Image (C.Sheet) & ", " & Limit & " by "
                   & (if N > 0 then B.Change_Kind_T'Image (Ch.Kind)
                      else "no change, now") & " at "
                   & Img (Integer (Ch.Track_Cm / 100)) & " m, "
                   & Img (Integer (V)) & " km/h: ours "
                   & Img (Integer (Ours)) & " m, workbook "
                   & (if Wb = No_Value then "-"
                      else Img (Integer (Wb)) & " m (" & Metres (Diff)
                           & ", margin " & Img (Integer (Mg)) & " m to"
                           & Natural'Image ((Ch.V_Target * 36 + 500) / 1000)
                           & " km/h"
                           & "; the sequence's location "
                           & Img (Integer (Seq_D)) & " m, "
                           & Metres (Seq_D - Wb) & ")"));
      elsif Verbose then
         Put_Line ("      curves: set" & Natural'Image (Ref.Set) & " "
                   & Image (C.Sheet) & ", " & Limit
                   & ": no status change of that kind seen");
         for I in 1 .. Natural'Min (B.Change_Count, 8) loop
            Put_Line ("        change " & B.Change_Kind_T'Image
                        (B.Change (I).Kind) & " at "
                      & Img (Integer (B.Change (I).Track_Cm / 100))
                      & " m, "
                      & Img (B.Change (I).V_Est * 36 / 1000) & " km/h, "
                      & "target" & Integer_64'Image (B.Change (I).D_Loc / 100)
                      & " m, EOA" & Integer_64'Image (B.Change (I).D_EOA / 100)
                      & " m from the estimated front end");
         end loop;
      end if;
      if not Ch.Shown and then Driven_Cm > 0 then
         --  B176: driven on to the workbook's distance of the limit
         --  without a target of ours shown (ceiling speed monitoring)
         Res := Fail ("curve " & Limit & ": no status change of that kind"
                      & " seen, no target of ours shown");
      elsif not Ch.Shown or else (N = 0 and then Wb = No_Value) then
         Res := Fail ("curve " & Limit & ": no status change of that kind"
                      & " seen");
      elsif N = 0 and then Wb /= No_Value and then Diff <= 0.0
        and then Diff >= -(Curve_In + Mg)
      then
         --  B194: the workbook's location passed by less than the
         --  tool's margin without our change: ours agrees
         Res := NJ (R_Placement, "curve " & Limit & ": the sequence's"
                    & " location is off its own workbook by "
                    & Img (Integer (abs (Seq_D - Wb))) & " m");
      elsif N = 0 then
         --  our limit not passed yet: the workbook's location of it not
         --  reached either (ours may agree: the sequence's location is
         --  off), or passed (ours nearer by at least the difference)
         Res := Fail ("curve " & Limit & ": no status change of that kind"
                      & " seen, the workbook's location "
                      & (if Diff > 0.0 then "not reached"
                         else "passed by " & Band (-Diff)));
      elsif Wb = No_Value then
         Res := Fail ("curve " & Limit & ": no workbook value at our speed");
      elsif Diff > Curve_Out then
         Res := Fail ("curve " & Limit & ": ours further out by "
                      & Band (Diff));
      elsif Diff < -(Curve_In + Mg) then
         Res := Fail ("curve " & Limit & ": ours nearer by "
                      & Band (-Diff));
      else
         Res := NJ (R_Placement, "curve " & Limit & ": the sequence's"
                    & " location is off its own workbook by "
                    & Img (Integer (abs (Seq_D - Wb))) & " m");
      end if;
      --  B176: the signature says the train was driven on (a band,
      --  the metres are in the trace)
      if Driven_Cm > 0 then
         declare
            Text : constant String :=
              Image (Res.Sig) & ", driven on "
              & Band (Long_Float (Driven_Cm) / 100.0);
         begin
            Res := (if Res.Verdict = Failed then Fail (Text)
                    else NJ (Res.Reason, Text));
         end;
      end if;
      if No_Reference (C) /= R_None then
         if Verbose and then No_Reference (C) = R_Factors then
            Put_Factors (C);
         end if;
         return NJ (No_Reference (C), Reference_Note (C) & Image (Res.Sig));
      end if;
      return Res;
   end Curve_Judgement;

   procedure Run_Loaded (Verbose : Boolean) is
      Blocked : Boolean := False;
      First_Fail : Natural := 0;

      procedure Record_Result (I : Positive; J : Judgement_T) is
         R : Result_T renames Results (I);
      begin
         R.Verdict := J.Verdict;
         R.Reason := J.Reason;
         R.Signature := J.Sig;
         R.Detail := Field_Gap;
         R.After_First_Failure := J.Verdict = Failed and then First_Fail > 0;
         if J.Verdict = Failed and then First_Fail = 0 then
            First_Fail := I;
         end if;
      end Record_Result;

      procedure Block (I : Positive; J : Judgement_T) is
      begin
         Blocked := True;
         Block_Reason := J.Reason;
         Block_Detail := J.Sig;
         if Outcome_Step = 0 then
            Outcome := Seq_Blocked;
            Outcome_Step := Seq.Steps (I).Number;
            Outcome_Index := I;
         else
            Blocked_Too := True;
         end if;
      end Block;
   begin
      B.Reset;
      --  B191: a sequence that runs the ERA workbook's train (its
      --  "workbook" line) is checked against limits the ERA tool computed
      --  with Q_NVINHSMICPERM 0 and the speed accuracy of SUBSET-041
      --  5.3.1.2 (V_delta0 = f41 (V_est), 3.13.9.3.2.1): the bench's
      --  odometer states that accuracy for these sequences. The others
      --  keep the exact speed they were recorded against (decision: two
      --  sequences without a workbook, 3110500_01 and 3131040_59, place
      --  an Indication and an Overspeed step on the exact speed)
      B.Set_Speed_Accuracy (Seq.Workbook and then not Exact_Speed);
      --  B262: the bench brakes at the conversion model's decelerations
      --  for the brake percentage entered (the workbook's, else 109)
      B.Set_Brake_Percentage (Brake_Percentage);
      for I in 1 .. Seq.Step_Count loop
         if Has (Image (Seq.Steps (I).Comment), "SB must be disabled") then
            B.Set_Service_Brake (False);
         end if;
      end loop;
      --  The radio systems installed (3.5.6.7, 5.4.3.2 D7): the sequences
      --  of feature 3050600 test 3.5.6 with both systems installed (in
      --  3050600_05 3.5.6.7 b holds the set-up while FRMCS is not
      --  registered); every other sequence was recorded with an on-board
      --  that sets up its sessions after a packet 45 of type FRMCS+GSM-R,
      --  which is GSM-R only here, as the port reports no FRMCS
      --  registration (e5/registration decision 2).
      if Image (Seq.Feature) = "3050600" then
         B.Set_Radio_Systems (EVC_Config.Both_Systems);
      else
         B.Set_Radio_Systems (EVC_Config.GSMR_Only);
      end if;
      B.Set_Voltages (S076_Sequences.Engine_Voltages
                        (Seq, EVC_Config.Default_Fixed_Train.Voltages));
      Step_Start_Ms := 0;
      Hold_Speed := False;
      Train_Configuration := 1;
      Explicit_Speed := -1;
      Wait_Used := 0;
      RBC_Stamp := 0;
      RBC_Stamp_Given := False;
      RBC_Alive := (others => False);
      RBC_Current := 1;
      Outcome := Seq_Passed;
      Outcome_Step := 0;
      Outcome_Index := 0;
      Block_Reason := R_None;
      Block_Detail := (others => <>);
      Blocked_Too := False;
      Ref := (others => <>);
      Last_Named := 0;
      Loc_Cm := Integer_64'First;
      Loc_Since := 0;
      Loc_Count := 0;
      Loc_Window := Unsigned_64'Last;
      Loc_Copied := 0;
      for I in 1 .. Seq.Step_Count loop
         Results (I) := (others => <>);
      end loop;
      --  B200: the sets that are no reference, in the trace (those
      --  of other correction factors are known at their steps only)
      for I in 1 .. (if Verbose then Seq.Curve_Count else 0) loop
         if No_Reference (Seq.Curves (I)) not in R_None | R_Factors then
            Put_Line ("curves: set" & Natural'Image (I) & " is no reference: "
                      & Reason_Image (No_Reference (Seq.Curves (I))));
         end if;
      end loop;
      --  a sequence that starts with the on-board in a mode other than No
      --  Power starts powered (its first step is not "powered up")
      for I in 1 .. Seq.Step_Count loop
         if Seq.Steps (I).Well_Formed then
            if Trim (Seq.Steps (I).Mode_Before) /= "NP"
              and then Trim (Seq.Steps (I).Mode_Before) /= "N/A"
            then
               B.Power_On;
               B.Run (Settle_Cycles * B.Cycle_Ms);
            end if;
            exit;
         end if;
      end loop;

      for K in 1 .. Seq.Step_Count loop
         declare
            I  : constant Positive := Step_Order (K);
            St : Step_T renames Seq.Steps (I);
            J  : Judgement_T;
         begin
            Cur := I;
            if Blocked then
               Results (I).Verdict := Not_Run;
            elsif not St.Well_Formed then
               Record_Result (I, NJ (R_Extractor, "step line"));
            elsif Single_Session_Case (St) then
               J := NJ (R_Optional, "not applicable: 3.15.1.3.2, a "
                        & "single-session on-board");
               Record_Result (I, J);
               Block (I, J);
            elsif Defect_Step (St) then
               J := NJ (R_S076_Defect, "the tool's unrounded V_PBD "
                        & "(3.11.11.6 rounds it down to 5 km/h)");
               Record_Result (I, J);
               Block (I, J);
            elsif Linking_Data_Case (St) > 0 then
               J := NJ (R_S076_Defect, "data: "
                        & Linking_Why (Linking_Data_Case (St)));
               Record_Result (I, J);
               Block (I, J);
            elsif Scope (St) /= R_None then
               J := NJ (Scope (St), "level " & Trim (St.Lvl_After)
                        & " mode " & Trim (St.Mode_After));
               Record_Result (I, J);
               Block (I, J);
            elsif Initial_Mode_Excludes (I) then
               Record_Result
                 (I, NJ (R_Optional, "conditional on another initial mode"));
            elsif St.Line.N = 0 then
               J := NJ (R_Unclassified, "step text");
               Record_Result (I, J);
               if St.IO = Input then
                  Block (I, J);
               end if;
            else
               Field_Gap := (others => <>);
               Load_Line (St.Line);
               --  an input opens a new observation window, before the
               --  move to its distance: what happens on the way is the
               --  input's too (a timer that runs out on the way). A
               --  balise group input without telegrams continues the one
               --  before (several rows of one transmission).
               if St.IO = Input
                 and then not (W (2) = "BTM" and then Line.Count < 4)
               then
                  --  an RBC's message at the place of the step before
                  --  keeps the radio messages sent before it listed:
                  --  129 / 136 / 157 after 159 come before or after the
                  --  RBC's 38 depending on the sequence (3040200_01
                  --  after it, most before it)
                  B.New_Window
                    (Keep_Radio =>
                       (W (2) = "RTM" and then W (3) = "message"
                        and then I > 1
                        and then Seq.Steps (I - 1).Dist_Cm = St.Dist_Cm)
                       or else Redelivered (I)
                       or else Ack_After_Group (I)
                       or else Reach_Point_At_Group (I));
                  Wait_Used := 0;
               end if;
               --  an input placed ahead of a train that goes backwards
               --  (more than 5 m) is met going forward again: the train
               --  returned (9990500_02: reversed at 160 m, back to
               --  130 m, then BG2d at 180 m); only an input that places
               --  the train (a balise group, an ODO step), not one that
               --  happens where the train stands (9990500_27 step 47, a
               --  timer at the place of a reach-point of the max safe
               --  front end)
               if St.IO = Input and then B.Direction < 0
                 and then St.Dist_Cm > B.Position + 500
                 and then ((W (2) = "BTM" and then Line.Count >= 4)
                           or else (W (2) = "ODO"
                                    and then not Same (W (3),
                                                 "direction-reversed")
                                    and then not Same (W (3),
                                                 "start-moving")))
               then
                  B.Set_Direction (1);
               end if;
               --  move to the step's distance, unless the input moves
               --  the train itself
               if not (St.IO = Input
                       and then (W (2) = "BTM"
                                 or else (W (2) = "ODO"
                                          and then (Same (W (3), "reach-point")
                                                    or else Same (W (3),
                                                      "start-moving")))))
               then
                  Move_To (St.Dist_Cm);
               end if;
               if St.IO = Input then
                  declare
                     C : Judgement_T;
                  begin
                     Hold_Speed := W (2) = "ODO"
                       and then Same (W (3), "reach-point");
                     J := Apply_Input (St);
                     if W (2) = "BTM" then
                        Group_Input_Ms := B.Now_Ms;
                     end if;
                     if J.Verdict = Failed
                       and then (Starts (Image (St.Comment), "Optional step")
                                 or else Has (Image (St.Comment),
                                              "Optional step"))
                     then
                        --  an optional input the driver cannot make here:
                        --  the sequence's other alternative
                        Record_Result (I, NJ (R_Optional, Image (J.Sig)));
                     elsif J.Verdict = Not_Judged then
                        Record_Result (I, J);
                        Block (I, J);
                     else
                        for K in 1 .. Settle_Cycles loop
                           Wait_Cycle;
                        end loop;
                        Note_Curve_Ref (I);
                        C := Columns (I);
                        if J.Verdict = Failed then
                           Record_Result (I, J);
                        elsif C.Verdict = Failed then
                           Record_Result (I, C);
                        else
                           Record_Result (I, J);
                        end if;
                     end if;
                  end;
               else
                  Note_Curve_Ref (I);
                  J := Expect (St);
                  while J.Verdict = Failed and then Wait_Used < Wait_Limit
                  loop
                     Wait_Cycle;
                     Wait_Used := Wait_Used + 1;
                     J := Expect (St);
                  end loop;
                  if J.Verdict = Failed and then Ref.Valid
                    and then Curve_Kind (Image (J.Sig))
                  then
                     Drive_On (Verbose);
                     J := Curve_Judgement (Verbose);
                  elsif J.Verdict = Failed and then Seq.Workbook
                    and then Curve_Kind (Image (J.Sig))
                    and then Unnamed_Set > 0
                    and then No_Reference (Seq.Curves (Unnamed_Set))
                             /= R_None
                  then
                     --  B200: a curve step naming no limit, of a set
                     --  that is no reference (the set named last, or
                     --  the only one): not judged like a named one
                     J := NJ (No_Reference (Seq.Curves (Unnamed_Set)),
                              Reference_Note (Seq.Curves (Unnamed_Set))
                              & Image (J.Sig) & " (no limit named)");
                     if Verbose and then J.Reason = R_Factors then
                        Put_Factors (Seq.Curves (Unnamed_Set));
                     end if;
                  elsif J.Verdict = Failed and then Seq.Workbook
                    and then Curve_Kind (Image (J.Sig))
                  then
                     --  a curve step of a workbook sequence whose
                     --  location names no limit (or no set): the tag of
                     --  its triage line
                     J := Location_Judgement (St, J, Verbose);
                  elsif J.Verdict = Failed and then Seq.Workbook
                    and then W (2) = "JRU"
                  then
                     J := Location_Judgement (St, J, Verbose, Tag => "");
                  end if;
                  declare
                     C : Judgement_T := Columns (I);
                  begin
                     while C.Verdict = Failed and then Wait_Used < Wait_Limit
                     loop
                        Wait_Cycle;
                        Wait_Used := Wait_Used + 1;
                        C := Columns (I);
                     end loop;
                     --  an optional or implementation dependent step
                     --  (its comment says so), or one of a choice made at
                     --  the sequence's start ("only if USE_FT... has been
                     --  chosen"), that fails is the other alternative: not
                     --  judged
                     if J.Verdict = Failed
                       and then (Starts (Image (St.Comment), "Optional step")
                                 or else Starts (Image (St.Comment),
                                           "Implementation dependent")
                                 or else Has (Image (St.Comment),
                                              "only if USE_FT")
                                 or else Only_In_L2_Elsewhere (St))
                     then
                        Record_Result (I, NJ (R_Optional, Image (J.Sig)));
                     elsif J.Reason in R_Gamma | R_Old_Tool | R_Placement
                       | R_Tool_Target | R_Factors
                     then
                        --  B100: the steps after it run with another
                        --  train than the sequence's
                        Record_Result (I, J);
                        Block (I, J);
                     elsif J.Verdict = Failed then
                        Record_Result (I, J);
                     elsif C.Verdict = Failed then
                        Record_Result (I, C);
                     else
                        Record_Result (I, J);
                     end if;
                  end;
               end if;
            end if;
            Sync_Location_Records;
            Step_Start_Ms := B.Time_Ms;
            if Verbose and then Debug and then B.Powered then
               Put_Line ("      brakes: EB "
                         & Boolean'Image (EVC_Core.Brake_Commands.EB)
                         & " SB " & Boolean'Image (EVC_Core.Brake_Commands.SB)
                         & " protection "
                         & Boolean'Image (EVC_Core.Brake_Commands.Protection)
                         & " back "
                         & Boolean'Image
                             (EVC_Stored_Information.Current.Train
                                .Moving_Backwards)
                         & " ahead "
                         & Boolean'Image
                             (EVC_Stored_Information.Current.Train
                                .Moving_Ahead)
                         & " sup "
                         & Boolean'Image
                             (EVC_Stored_Information.Current.Supervise)
                         & " ma "
                         & Boolean'Image
                             (EVC_Stored_Information.Current.MA.Present)
                         & " ahead-sense "
                         & EVC_Distances.Sense_T'Image
                             (EVC_Stored_Information.Current.Train.Ahead)
                         & " odo "
                         & EVC_Ports.Movement_T'Image (EVC_Odometry.Movement)
                         & " dir" & Integer'Image (B.Direction));
            end if;
            if Verbose and then Debug then
               for K in 1 .. B.JRU_Count loop
                  Put_Line ("      jru" & Natural'Image (B.JRU (K).Event)
                            & Natural'Image (B.JRU (K).B2)
                            & Natural'Image (B.JRU (K).B3)
                            & Natural'Image (B.JRU (K).B4));
               end loop;
            end if;
            if Verbose then
               declare
                  R : Result_T renames Results (I);
               begin
                  Put_Line
                    ("step" & Natural'Image (St.Number) & " @"
                     & Img (Integer (St.Dist_Cm / 100)) & "m "
                     & (case St.IO is when Input => "I ",
                                       when Output => "O ",
                                       when Unknown => "? ")
                     & Image (St.Line)
                     & " [" & Trim (St.Lvl_After) & " "
                     & Trim (St.Mode_After) & "]");
                  Put_Line ("    -> " & Verdict_T'Image (R.Verdict)
                            & (if R.Reason /= R_None
                               then " (" & Reason_Image (R.Reason) & ")"
                               else "")
                            & ": " & Image (R.Signature)
                            & "  | ours: " & Mode_Abbrev (Our_Mode) & " "
                            & Level_Abbrev (Our_Level) & " x="
                            & Img (Integer (B.Position / 100)) & "m v="
                            & Img (B.Speed * 36 / 1000) & "km/h perm="
                            & Img (B.State.V_Perm) & "/" & Img (B.State.V_Cur) & "/sbi" & Img (B.State.V_SBI) & "/st" & Img (B.State.Sup_Status) & (if B.State.EBC then " EB" else "") & (if B.State.SBC then " SB" else "") & " r" & Img (B.State.Reasons) & " tgt" & Img (B.State.V_Target) & "@" & Img (B.State.D_Target) & " ma" & Img (B.State.Plan_MA) & "/c" & Img (B.State.Ceiling) & " t="
                            & Unsigned_64'Image (B.Time_Ms / 100) & "00ms");
               end;
            end if;
         exception
            when E : others =>
               Record_Result (I, NJ (R_Runner, "exception in the runner"));
               Block (I, NJ (R_Runner, "exception in the runner"));
               pragma Unreferenced (E);
         end;
      end loop;

      if First_Fail > 0 then
         if Outcome = Seq_Blocked then
            Blocked_Too := True;
         end if;
         Outcome := Seq_Failed;
         Outcome_Index := First_Fail;
         Outcome_Step := Seq.Steps (First_Fail).Number;
      end if;
   end Run_Loaded;

end S076_Run;
