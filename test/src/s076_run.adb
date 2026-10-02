--  ETCS on-board (EVC)
--  One SUBSET-076 test sequence replayed against the on-board, body.

pragma Ada_2012;
with Ada.Characters.Handling;
with Ada.Environment_Variables;
with Ada.Streams;             use Ada.Streams;
with Ada.Strings.Fixed;
with Ada.Text_IO;             use Ada.Text_IO;
with Interfaces;              use Interfaces;
with Display;
with Display.C_Area;
with DMI_Ack;
with DMI_Buttons;
with DMI_Conditions;
with DMI_Core;
with DMI_Protocol;
with DMI_System_Status;
with DMI_Windows;             use DMI_Windows;
with EVC_Core;
with EVC_Modes;               use EVC_Modes;
with S076_Bench;
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
         when R_Level_2          => "level 2/3 or RBC needed (E5)",
         when R_Version          =>
            "system version other than 4.0 layout (chapter 6, E7)",
         when R_Euroloop         => "Euroloop (E7)",
         when R_NTC              => "NTC/STM (out of scope)",
         when R_ATO              => "ATO (no ATO port payload yet)",
         when R_DMI_Internal     => "DMI internal, not judged",
         when R_JRU_Not_Modelled => "JRU not modelled",
         when R_Not_Modelled     => "on-board input/output not modelled",
         when R_Unclassified     => "vocabulary unclassified in the sibling",
         when R_Extractor        => "unreadable in the sibling (extractor)",
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

   ---------------------------------------------------------------------
   --  The state of the replay
   ---------------------------------------------------------------------

   Debug : constant Boolean := Ada.Environment_Variables.Exists ("DEBUG");
   Cur            : Natural := 0;       -- the index of the step
   Step_Start_Ms  : Unsigned_64 := 0;   -- the time the last step ended
   Explicit_Speed : Integer := -1;      -- cm/s set by an ODO input
   Wait_Used      : Natural := 0;       -- cycles waited in the window
   Default_Kmh    : constant := 30;

   function Kmh_To_Cms (Kmh : Long_Float) return Natural is
     (Natural (Long_Float'Max (0.0, Kmh) * 100_000.0 / 3600.0));

   --  the chart's speed at the train, km/h, -1 without a chart
   function Chart_Kmh return Long_Float is
     (Chart_Speed (Seq, Long_Float (B.Position) / 100.0));

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
            return Kmh_To_Cms (Long_Float (Default_Kmh));
         end if;
         return Positive'Max (Kmh_To_Cms (C), Kmh_To_Cms (10.0));
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
            B.Set_Speed (if C >= 1.0 then Kmh_To_Cms (C) else 0);
         end;
      end if;
   end Arrive;

   procedure Move_To (To_Cm : Integer_64) is
   begin
      if (B.Direction > 0 and then To_Cm > B.Position + 50)
        or else (B.Direction < 0 and then To_Cm < B.Position - 50)
      then
         B.Move_To (To_Cm, Transit_Cms);
         Arrive;
      end if;
   end Move_To;

   ---------------------------------------------------------------------
   --  The step's level and mode columns
   ---------------------------------------------------------------------

   function Our_Mode return Mode_T is
     (if B.Powered then EVC_Core.Mode else M_NP);

   function Our_Level return Level_Kind_T is
   begin
      if not B.Powered
        or else EVC_Core.Level_Status /= EVC_Modes.Valid
      then
         return K_None;
      end if;
      return (case EVC_Core.Level is
                 when L0 => K_L0, when NTC => K_NTC,
                 when L1 => K_L1, when L2 => K_L2);
   end Our_Level;

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
   --  accepts an unknown level; in No Power the level is not judged.
   type Level_Set_T is array (Level_Kind_T) of Boolean;

   function Columns (I : Positive) return Judgement_T is
      First, Last : Positive := I;
      Modes  : Mode_Set_T := No_Modes;
      Levels : Level_Set_T := (others => False);
      M  : constant Mode_T := Our_Mode;
      Lv : constant Level_Kind_T := Our_Level;
      Any_Level : Boolean := False;

      procedure Add (St : Step_T) is
         Mb : constant Mode_Set_T := Mode_Of (Trim (St.Mode_Before));
         Ma : constant Mode_Set_T := Mode_Of (Trim (St.Mode_After));
      begin
         for X in Mode_T loop
            Modes (X) := Modes (X) or else Mb (X) or else Ma (X);
         end loop;
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
      if Modes /= No_Modes and then not Modes (M) then
         return Fail ("mode " & Trim (Seq.Steps (I).Mode_After) & ", got "
                      & Mode_Abbrev (M));
      end if;
      if Any_Level and then M /= M_NP and then not Levels (Lv) then
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
   procedure Enter_Train_Data is
      function Digits_Of (N : Natural) return String is
         S : constant String := Natural'Image (N);
      begin
         return S (S'First + 1 .. S'Last);
      end Digits_Of;
   begin
      Key (1); Enter_Field (1);               -- train category PASS 1
      Type_Digits (Digits_Of (Train_Length_M)); Enter_Field (2);
      Type_Digits (Digits_Of (Brake_Percentage)); Enter_Field (3);
      Type_Digits ("200"); Enter_Field (4);   -- maximum speed, km/h
      Press (539, 440);                       -- [Next]
      Key (1); Enter_Field (1);               -- axle load category
      Key (7); Enter_Field (2);               -- airtight
      Key (5); Enter_Field (3);               -- loading gauge
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

   --  The level the driver selects: the step's column after, else the
   --  LEVEL of the PDF's DMI event
   function Selected_Level (St : Step_T) return Level_Kind_T is
      K : constant Level_Kind_T := Level_Of (Trim (St.Lvl_After));
      D : constant String := DMI_Data (Seq, St.Number);
   begin
      if K /= K_None then
         return K;
      end if;
      if Has (D, "LEVEL=0") then
         return K_L0;
      elsif Has (D, "LEVEL=1") then
         return K_L1;
      elsif Has (D, "LEVEL=2") then
         return K_L2;
      end if;
      for I in 4 .. Line.Count loop
         if Level_Of (W (I)) /= K_None then
            return Level_Of (W (I));
         end if;
      end loop;
      return K_None;
   end Selected_Level;

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
            return Fail ("DMI confirm " & Item & ": no entry window, top is "
                         & Top_Image);
         end if;
         Enter_Single;
         return Pass ("DMI " & Item & " confirmed");
      elsif Same (Verb, "select") and then Has (Item, "Level")
      then
         declare
            K : constant Level_Kind_T := Selected_Level (St);
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
         Enter_Train_Data;
         return Pass ("DMI Train Data entered");
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
         --  8.2.2.4: the A/B toggle, where the default window shows it
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
      elsif Same (Verb, "isolate") then
         Desk_Isolation;
         return Pass ("DMI isolation");
      elsif Has (Item, "RBC") or else Has (Item, "Radio")
        or else Has (Item, "GSM-R") or else Has (Item, "SM")
        or else Has (Item, "Track-ahead")
      then
         return NJ (R_Level_2, "DMI " & Verb & " " & Item);
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
         B.Run (Natural (Due - Elapsed));
      end if;
   end Run_Timer;

   function Timer_Input (St : Step_T) return Judgement_T is
      Name : constant String := W (4);
      subtype Name_T is String (1 .. 14);
      Known : constant array (1 .. 5) of Name_T :=
        ("T_SECTIONTIMER", "T_ENDTIMER    ", "T_TEXTDISPLAY ",
         "T_ACK         ", "T_LSSMA       ");
      function K (I : Positive) return String is
        (Ada.Strings.Fixed.Trim (Known (I), Ada.Strings.Right));
      Found : Boolean;
      Chosen : Natural := 0;
   begin
      --  the named timer, or one the comment names
      for I in Known'Range loop
         if Same (Name, K (I))
           or else (Name = "" and then Has (Image (St.Comment), K (I)))
         then
            Chosen := I;
            exit;
         end if;
      end loop;
      if Has (Name, "T_NVCONTACT") or else Has (Name, "T_CYCRQST")
        or else Has (Name, "T_CYCLOC")
        or else (Name = "" and then (Has (Image (St.Comment), "radio")
                                     or else Has (Image (St.Comment),
                                                  "registration")
                                     or else Has (Image (St.Comment), "RBC")))
      then
         return NJ (R_Level_2, "timer " & Name);
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
         if not Found or else S >= 1023 then
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
            elsif Has (E, "warning") then
               Kmh := (if Below then S.V_Wsl - 1 else S.V_Wsl + 1);
            elsif Has (E, "V_PERM") or else Has (E, "MRSP")
              or else Has (E, "VMRSP")
            then
               if Much then
                  Kmh := S.V_Perm / 2;
               elsif Below then
                  Kmh := S.V_Perm - 2;
               elsif Has (E, "+6") then
                  Kmh := S.V_Perm + 7;
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

   function TIU_Input return Judgement_T is
      Kind : constant String := W (3);
      Arg  : constant String := W (4);
   begin
      if Same (Kind, "cab") then
         if Same (Arg, "A") then
            B.TIU_Input (2, 0);
            B.TIU_Input (1, 1);
         elsif Same (Arg, "B") then
            B.TIU_Input (1, 0);
            B.TIU_Input (2, 1);
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
      return NJ ((if Same (Kind, "train-integrity")
                    or else Same (Kind, "safe-consist-length")
                  then R_Not_Modelled else R_Runner),
                 "TIU " & Kind);
   end TIU_Input;

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
      --  the packets the step's text names must be in the telegrams: the
      --  extractor of the sibling loses a balise's table now and then
      declare
         Txt : constant String := Image (St.Text);
         P   : Natural := Ada.Strings.Fixed.Index (Txt, "packet ");
      begin
         while P > 0 loop
            declare
               N : Natural := 0;
               K : Natural := P + 7;
               Have : Boolean := False;
            begin
               while K <= Txt'Last and then Txt (K) in '0' .. '9' loop
                  N := N * 10 + Character'Pos (Txt (K)) - 48;
                  K := K + 1;
               end loop;
               if K > P + 7 and then N < 255 then
                  for I in 1 .. Seq.Telegram_Count loop
                     for J in 1 .. Seq.Telegrams (I).Packet_Count loop
                        if Seq.Telegrams (I).Step <= St.Number
                          and then Natural (Seq.Telegrams (I).Packets (J)) = N
                        then
                           Have := True;
                        end if;
                     end loop;
                  end loop;
                  if not Have then
                     return NJ (R_Extractor, "BTM: packet" & Natural'Image (N)
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
            B.Move_To (Target, Transit_Cms);
            B.Set_Speed (Was);
            Arrive;
         else
            B.Cycle;
         end if;
      end;
      return Pass ("BTM" & Natural'Image (Found) & " telegrams");
   end BTM_Input;

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
         elsif Same (Kind, "door-command") then
            return NJ (R_Not_Modelled, "SIM door command");
         end if;
         return NJ (R_Runner, "SIM " & Kind);
      elsif Iface = "TIU" then
         return TIU_Input;
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
         return NJ (R_Level_2, "RTM " & Kind);
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
            Now  : constant Boolean :=
              S.Level_Ann /= B.No_Value and then (S.Level_Ann_Ack or not Ack);
         begin
            for C in 2 .. 5 loop
               In_W := In_W or else Seen.Level_Ann_Ack (C)
                 or else (not Ack and then Seen.Level_Ann (C));
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

   function DMI_Window (St_W : State_Word_T; Name : String)
     return Judgement_T
   is
      Wid : Window_ID_T;
   begin
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
         elsif Has (Name, "Safe-radio-connection") then
            return NJ (R_Level_2, "radio connection symbol");
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
            return NJ (R_Level_2, "TAF");
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
         return Shown (St_W, Speed_Info_Shown, Speed_Info_Shown,
                       "speed and distance information on the DMI");
      elsif Same (Kind, "window") then
         return DMI_Window (St_W, Name);
      elsif Same (Kind, "button") then
         return DMI_Button (St_W, Name);
      elsif Same (Kind, "isolation-indicated") then
         return Check (Our_Mode = M_IS, "isolation", Mode_Abbrev (Our_Mode));
      elsif Same (Kind, "ato-symbol") then
         return NJ (R_ATO, "ATO symbol");
      elsif Same (Kind, "supervised-manoeuvre-symbol") then
         return NJ (R_Level_2, "SM symbol");
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

   function Rec_Matches (R : B.JRU_Record_T; Event : Natural;
                         Sub, B3 : Integer) return Boolean is
     (R.Event = Event and then (Sub < 0 or else R.B2 = Sub)
      and then (B3 < 0 or else R.B3 = B3));

   function Any_Rec (Event : Natural; Sub, B3 : Integer) return Boolean is
   begin
      for I in 1 .. B.JRU_Count loop
         if Rec_Matches (B.JRU (I), Event, Sub, B3) then
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
            return (Any_Rec (41, 6, M) or else Any_Rec (23, 4, M)) = Positive;
         when Mode_Acked =>
            return (Any_Rec (41, 7, M) or else Any_Rec (23, 5, M)) = Positive;
         when Brake_Change =>
            for I in 1 .. B.JRU_Count loop
               declare
                  R : constant B.JRU_Record_T := B.JRU (I);
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
            for I in 1 .. B.JRU_Count loop
               declare
                  R : constant B.JRU_Record_T := B.JRU (I);
               begin
                  if R.Event = 20
                    and then ((R.B2 mod 4) /= 0) = (F.Value = 1)
                  then
                     return Positive;
                  end if;
               end;
            end loop;
            return not Positive;
         when Trip_Reason =>
            for I in 1 .. F.B3_List.Count loop
               if Any_Rec (23, 1, F.B3_List.List (I)) then
                  return Positive;
               end if;
            end loop;
            return not Positive;
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
                    & Img (B.JRU_Level));
   end Bit_Set;

   --  The header fields every record carries (4.2.2.2): the mode, the
   --  level, the driver
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

   function JRU_Expect return Judgement_T is
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
                       ((for some I in 1 .. B.JRU_Count => B.JRU (I).Event = 20
                          and then (B.JRU (I).B2 / 2**Bit) mod 2
                                   /= (B.JRU (I).Prev / 2**Bit) mod 2)
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
                     if Eq > 0 and then Same (Wd (Wd'First .. Eq - 1),
                                              "M_DRIVERACTIONS")
                     then
                        Alternatives (Wd (Eq + 1 .. Wd'Last), 2, V, N, Ok);
                        if not Ok then
                           return NJ (R_Unclassified, "JRU 11 " & Wd);
                        end if;
                        for I in 1 .. N loop
                           declare
                              F : constant Fact_T := Driver_Action_Fact (V (I));
                           begin
                              if F.Kind = No_Fact then
                                 return NJ (R_JRU_Not_Modelled,
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
               return NJ (R_JRU_Not_Modelled, "11 without M_DRIVERACTIONS");
            when 21 | 23 =>
               for K in 5 .. Line.Count loop
                  declare
                     Wd : constant String := W (K);
                     Eq : constant Natural := Ada.Strings.Fixed.Index (Wd, "=");
                  begin
                     if Eq > 0 then
                        return Bit_Set
                          (Wd (Eq + 1 .. Wd'Last),
                           (if Id = 21 then Symbol_Fact'Access
                            else System_Status_Fact'Access),
                           Positive, Img (Id));
                     end if;
                  end;
               end loop;
               return NJ (R_JRU_Not_Modelled, Img (Id) & " without bits");
            when 12 =>
               if Line.Count > 4 then
                  return NJ (R_JRU_Not_Modelled, "12.M_ERROR");
               end if;
               return Check ((Any_Rec (4, -1, -1) or else Any_Rec (5, -1, -1)
                              or else Any_Rec (6, -1, -1)) = Positive,
                             "JRU balise group error"
                             & (if Positive then "" else " not"),
                             "events 4 to 6");
            when 20 =>
               declare
                  Mon, Sup : Integer := -1;
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
                           if not Ok or else N /= 1 then
                              return NJ (R_Unclassified, "JRU 20 " & Wd);
                           end if;
                           if Same (Name, "M_SDMTYPE") then
                              Mon := V (1);
                           else
                              Sup := V (1);
                           end if;
                        elsif not Same (Name, "M_MODE")
                          and then not Same (Name, "M_LEVEL")
                        then
                           return NJ (R_JRU_Not_Modelled, "20." & Name);
                        end if;
                     end;
                  end loop;
                  if Mon < 0 and then Sup < 0 then
                     return NJ (R_JRU_Not_Modelled,
                                "20 without M_SDMTYPE / M_SDMSUPSTAT");
                  end if;
                  --  event 21 is recorded when the monitoring or the
                  --  status changes: a record of message 20 for another
                  --  change carries the values of the last one
                  Result := Check ((Any_Rec (21, Mon, Sup)
                                    or else (Positive
                                             and then (Mon < 0
                                                       or else B.JRU_Monitoring
                                                                 = Mon)
                                             and then (Sup < 0
                                                       or else B.JRU_Sup_Status
                                                                 = Sup)))
                                   = Positive,
                                   "JRU supervision monitoring" & Img (Mon)
                                   & " status" & Img (Sup)
                                   & (if Positive then "" else " not"),
                                   "monitoring" & Img (B.JRU_Monitoring)
                                   & " status" & Img (B.JRU_Sup_Status));
                  if Result.Verdict /= Passed then
                     return Result;
                  end if;
               end;
            when others =>
               declare
                  Map : constant JRU_Map_T := Message_Event (Id);
                  Found : Boolean := False;
               begin
                  if not Map.Known then
                     return NJ (R_JRU_Not_Modelled, Img (Id));
                  end if;
                  for I in 1 .. B.JRU_Count loop
                     if Rec_Matches (B.JRU (I), Map.Event, Map.Sub, -1)
                       and then (Map.B4 < 0 or else B.JRU (I).B4 = Map.B4)
                     then
                        Found := True;
                     end if;
                  end loop;
                  Result := Check (Found = Positive,
                                   "JRU" & Id_S & " as event" & Img (Map.Event)
                                   & (if Positive then "" else " not"),
                                   (if Found then "recorded" else "none"));
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
                          and then not (Eq > 0 and then Eq < Wd'Last
                                        and then Wd (Eq + 1) not in '0' .. '9')
                        then
                           return NJ (R_JRU_Not_Modelled,
                                      Img (Id) & "." & Name);
                        end if;
                     end;
                  end loop;
               end;
         end case;
      end if;
      --  the header fields
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
         begin
            if Same (Name, "M_MODE") or else Same (Name, "M_LEVEL")
              or else Same (Name, "DRIVER_ID") or else Id = 0
            then
               Any_Field := True;
               J := Header_Field (Name, Value, Positive, Handled);
               if J.Verdict /= Passed then
                  return J;
               end if;
            end if;
         end;
      end loop;
      if Id = 0 and then not Any_Field then
         return NJ (R_JRU_Not_Modelled, "ALL");
      end if;
      return Result;
   end JRU_Expect;

   function Expect (St : Step_T) return Judgement_T is
      Iface : constant String := W (2);
   begin
      if Iface = "JRU" then
         return JRU_Expect;
      elsif Iface = "DMI" then
         return DMI_Expect (St);
      elsif Iface = "TIU" then
         return TIU_Expect;
      elsif Iface = "RTM" then
         return NJ (R_Level_2, "RTM " & W (3));
      elsif Iface = "ATO" then
         return NJ (R_ATO, "ATO " & W (3));
      end if;
      return NJ (R_Unclassified, "expect " & Iface);
   end Expect;

   ---------------------------------------------------------------------
   --  The sequence
   ---------------------------------------------------------------------

   --  A step out of the scope of this phase: level 2 / 3, NTC
   function Scope (St : Step_T) return Reason_T is
      Lb : constant Level_Kind_T := Level_Of (Trim (St.Lvl_Before));
      La : constant Level_Kind_T := Level_Of (Trim (St.Lvl_After));
   begin
      if Lb in K_L2 | K_L3 or else La in K_L2 | K_L3 then
         return R_Level_2;
      elsif Lb = K_NTC or else La = K_NTC
        or else Trim (St.Mode_Before) = "SN" or else Trim (St.Mode_After) = "SN"
      then
         return R_NTC;
      end if;
      return R_None;
   end Scope;

   procedure Run_Loaded (Verbose : Boolean) is
      Blocked : Boolean := False;
      First_Fail : Natural := 0;

      procedure Record_Result (I : Positive; J : Judgement_T) is
         R : Result_T renames Results (I);
      begin
         R.Verdict := J.Verdict;
         R.Reason := J.Reason;
         R.Signature := J.Sig;
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
      Step_Start_Ms := 0;
      Explicit_Speed := -1;
      Wait_Used := 0;
      Outcome := Seq_Passed;
      Outcome_Step := 0;
      Outcome_Index := 0;
      Block_Reason := R_None;
      Block_Detail := (others => <>);
      Blocked_Too := False;
      for I in 1 .. Seq.Step_Count loop
         Results (I) := (others => <>);
      end loop;

      for I in 1 .. Seq.Step_Count loop
         Cur := I;
         declare
            St : Step_T renames Seq.Steps (I);
            J  : Judgement_T;
         begin
            if Blocked then
               Results (I).Verdict := Not_Run;
            elsif not St.Well_Formed then
               Record_Result (I, NJ (R_Extractor, "step line"));
            elsif Scope (St) /= R_None then
               J := NJ (Scope (St), "level " & Trim (St.Lvl_After)
                        & " mode " & Trim (St.Mode_After));
               Record_Result (I, J);
               Block (I, J);
            elsif St.Line.N = 0 then
               J := NJ (R_Unclassified, "step text");
               Record_Result (I, J);
               if St.IO = Input then
                  Block (I, J);
               end if;
            else
               Load_Line (St.Line);
               --  an input opens a new observation window, before the
               --  move to its distance: what happens on the way is the
               --  input's too (a timer that runs out on the way). A
               --  balise group input without telegrams continues the one
               --  before (several rows of one transmission).
               if St.IO = Input
                 and then not (W (2) = "BTM" and then Line.Count < 4)
               then
                  B.New_Window;
                  Wait_Used := 0;
               end if;
               --  move to the step's distance, unless the input moves
               --  the train itself
               if not (St.IO = Input
                       and then (W (2) = "BTM"
                                 or else (W (2) = "ODO"
                                          and then Same (W (3), "reach-point"))))
               then
                  Move_To (St.Dist_Cm);
               end if;
               if St.IO = Input then
                  declare
                     C : Judgement_T;
                  begin
                     J := Apply_Input (St);
                     if J.Verdict = Not_Judged then
                        Record_Result (I, J);
                        Block (I, J);
                     else
                        B.Run (Settle_Cycles * B.Cycle_Ms);
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
                  J := Expect (St);
                  while J.Verdict = Failed and then Wait_Used < Wait_Cycles
                  loop
                     B.Cycle;
                     Wait_Used := Wait_Used + 1;
                     J := Expect (St);
                  end loop;
                  declare
                     C : Judgement_T := Columns (I);
                  begin
                     while C.Verdict = Failed and then Wait_Used < Wait_Cycles
                     loop
                        B.Cycle;
                        Wait_Used := Wait_Used + 1;
                        C := Columns (I);
                     end loop;
                     if J.Verdict = Failed then
                        Record_Result (I, J);
                     elsif C.Verdict = Failed then
                        Record_Result (I, C);
                     else
                        Record_Result (I, J);
                     end if;
                  end;
               end if;
            end if;
            Step_Start_Ms := B.Time_Ms;
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
