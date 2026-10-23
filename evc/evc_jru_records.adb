--  ETCS on-board (EVC)
--  JRU events that follow SUBSET-027 messages, body.

with EVC_Braking;
with EVC_Distances; use type EVC_Distances.Cm_T;
with EVC_Fixed;

package body EVC_JRU_Records
  with SPARK_Mode => On,
       Refined_State => (State => (Cab_A_Recorded, Cab_B_Recorded,
                                   Cab_Recorded,
                                   Last_TC, Last_Inputs, Shown,
                                 Last_LSSMA))
is

   use EVC_Driver_Requests;

   Cab_A_Recorded : Boolean := False;
   Cab_B_Recorded : Boolean := False;
   Cab_Recorded   : Boolean := False;
   Last_TC        : TC_Changes_T :=
     (Count => 0, List => (others => (others => 0)));
   --  The inputs last recorded (remote shunting: not permitted)
   Power_Up_Inputs : constant Input_Values_T :=
     (Remote_Shunting => 0, others => No_Value);
   Last_Inputs : Input_Values_T := Power_Up_Inputs;
   --  the system status messages displayed (System_Status)
   Shown : Unsigned_32 := 0;
   --  V_LSSMA last recorded (LSSMA)
   Last_LSSMA : Natural := V_LSSMA_None;

   function Action_Code (A   : Action_T;
                         Arg : Unsigned_16) return Byte is
   begin
      case A is
         --  SUBSET-027 4.2.4.11, the values of M_DRIVERACTIONS
         when Shunting         => return 11;  -- Shunting selected
         when Non_Leading      => return 12;  -- Non Leading selected
         when Exit_Shunting    => return 17;  -- Exit of Shunting selected
         when Train_Data_Entry => return 20;  -- Train Data Entry requested
         when TAF_Yes          => return 22;  -- Confirmation of TAF
         when Train_Integrity  => return 26;  -- Train integrity confirmation
         --  the toggles carry the new state, 1 shown
         when Speed_Toggle  => return (if Arg = 1 then 27 else 25);
         when Geo_Toggle    => return (if Arg = 1 then 30 else 31);
         when Tunnel_Toggle => return (if Arg = 1 then 39 else 40);
         when Adhesion      => return (if Arg = 1 then 32 else 33);
         when Supervised_Manoeuvre =>
            --  decision: 'Continue in SM' (1) is the selection of
            --  Supervised Manoeuvre in SM (5.21.2.2 S0, E015); SUBSET-027
            --  has no value of its own for it
            return (case Arg is
                       when 0 | 1  => 8,   -- Supervised Manoeuvre selected
                       when 2      => 9,   -- Exit Supervised Manoeuvre
                       when others => No_Code);
         --  recorded by their own events (EVC_Mission, EVC_Levels,
         --  EVC_Procedures, the mode change) or without a code (ATO,
         --  the others)
         when Acknowledge | Start | Override | Level | ATO_Engage
            | Skip_Stopping_Point | ATO_Selector | Main_Window_Button
            | BMM_Inhibition | Maintain_Shunting | Isolate
            | Train_Data_Left | SR_Data_Entry | SR_Data_Left =>
            return No_Code;
      end case;
   end Action_Code;

   function Ack_Code (K  : Ack_Kind_T;
                      Id : Unsigned_16) return Byte is
   begin
      case K is
         when Brake_Release => return 16;  -- Brake release acknowledgement
         when Plain_Text    => return 23;  -- Ack of Plain Text information
         when Fixed_Text    => return 24;  -- Ack of Fixed Text information
         when System_Status =>
            --  Ack of NL no longer permitted (4.4.15.1.1.3): the
            --  catalogue entry SS_NL_No_Longer_Permitted, 35, of
            --  common/dmi_protocol.ads
            return (if Id = 16#8000# + 35 then 7 else No_Code);
         when Level_Transition | Mode_Change | NTC_Text =>
            return No_Code;
      end case;
   end Ack_Code;

   --  decision: the network type and the one-radio choice are recorded
   --  from their data entries (kinds 6 and 7 of MSG_DRIVER_DATA, the
   --  values of DMI Table 43b and 11.3.16), so the DMI protocol carries
   --  no driver action of its own for them; a value outside them has no
   --  code
   function Data_Code (K : Data_Kind_T; B : Byte) return Byte is
     (case K is
         when Language => 29,  -- Selection of Language
         when Radio_Network_Type =>
           (case B is
               when 1      => 51,  -- Radio Network type FRMCS selected
               when 2      => 52,  -- FRMCS+GSM-R selected
               when 3      => 53,  -- GSM-R selected
               when others => No_Code),
         when One_Radio_System =>
           (case B is
               when 1      => 54,  -- "Perform mission with only one radio"
               when 0      => 55,  -- "Do not perform ..."
               when others => No_Code),
         when others => No_Code);

   procedure Reset is
   begin
      Cab_A_Recorded := False;
      Cab_B_Recorded := False;
      Cab_Recorded := False;
      Last_TC := (Count => 0, List => (others => (others => 0)));
      Last_Inputs := Power_Up_Inputs;
      Shown := 0;
      Last_LSSMA := V_LSSMA_None;
   end Reset;

   procedure LSSMA (Kmh     : Natural;
                    V       : out Natural;
                    Changed : out Boolean) is
   begin
      V := (if Kmh >= V_LSSMA_None then V_LSSMA_None
            else Natural'Min (Kmh, 600));
      Changed := V /= Last_LSSMA;
      Last_LSSMA := V;
   end LSSMA;

   --  SUBSET-027 4.2.4.23 against the catalogue of the DMI's chapter 15
   --  (EVC_DMI_Port): the entries of one message (the brake and the trip
   --  rows of a balise read error, ...) share its bit; bit 31 "Safe
   --  consist length no longer available" has no entry of the on-board
   function SS_Bit (Entry_Number : Byte) return Natural is
     (case Entry_Number is
         when 1 | 2   => 1,   -- Balise read error
         when 3       => 2,   -- Trackside malfunction
         when 4 | 5   => 3,   -- Communication error
         when 6       => 4,   -- Entering FS
         when 7       => 5,   -- Entering OS
         when 9       => 6,   -- Runaway movement
         when 12      => 7,   -- SH refused
         when 14      => 8,   -- SH request failed
         when 15 | 16 => 9,   -- Trackside not compatible
         when 17 | 18 => 10,  -- Train data changed
         when 20      => 11,  -- Train is rejected
         when 21      => 12,  -- Unauthorized passing of EOA / LOA
         when 22      => 13,  -- No MA received at level transition
         when 23      => 14,  -- SR distance exceeded
         when 24      => 15,  -- SH stop order
         when 25      => 16,  -- SR stop order
         when 26      => 17,  -- Emergency stop
         when 27      => 18,  -- RV distance exceeded
         when 29      => 19,  -- No track description
         when 32      => 20,  -- Route unsuitable - axle load category
         when 30      => 21,  -- Route unsuitable - loading gauge
         when 31      => 22,  -- Route unsuitable - traction system
         when 34      => 23,  -- GSM-R network registration failed
         when 33      => 24,  -- FRMCS network registration failed
         when 28      => 25,  -- PT distance exceeded
         when 35      => 26,  -- NL no longer permitted
         when 36      => 27,  -- Odometer impaired
         when 10      => 28,  -- SM refused
         when 11      => 29,  -- SM request failed
         when 8       => 30,  -- Entering SM
         when others  => 0);

   --  decision: the on-board sees the starts and the ends it sends
   --  (EVC_DMI_Port MSG_SYSTEM_STATUS) and the driver's acknowledgements;
   --  the ends the DMI owns alone (its 30 s timers, the mode changes of
   --  its 15.1.1.2 and 15.1.1.6, the Main window's buttons) are not seen
   procedure System_Status (Entry_Number, Event : Byte;
                            Changed : in out Boolean)
     with Refined_Global => (In_Out => Shown)
   is
      N   : constant Natural := SS_Bit (Entry_Number);
      Old : constant Unsigned_32 := Shown;
   begin
      if N > 0 and then Event = 0 then
         Shown := Shown or Shift_Left (1, N - 1);
      elsif N > 0 and then Event = 1 then
         Shown := Shown and not Shift_Left (1, N - 1);
      end if;
      Shown := Shown and (2 ** 31 - 1);
      Changed := Changed or else Shown /= Old;
   end System_Status;

   procedure System_Status_Acknowledged (Entry_Number : Byte;
                                         Changed : in out Boolean)
     with Refined_Global => (In_Out => Shown)
   is
   begin
      System_Status (Entry_Number, 1, Changed);
   end System_Status_Acknowledged;

   function Status_Shown return Unsigned_32 is (Shown and (2 ** 31 - 1))
     with Refined_Global => Shown;

   function Input_Event (I : Input_T) return Byte is
     (case I is
         when Sleeping         => 30,
         when Passive_Shunting => 31,
         when Non_Leading      => 132,
         when Direction        => 39,
         when Integrity        => 50,
         when Remote_Shunting  => 51);

   function Direction_Code (TIU_Value : Natural) return Input_Value_T is
     (case TIU_Value is
         when 1      => 2,
         when 2      => 1,
         when others => 0);

   function Integrity_Code (TIU_Value : Natural) return Input_Value_T is
     (case TIU_Value is
         when 1      => 0,
         when 2      => 1,
         when others => 2);

   procedure Inputs (Now : Input_Values_T; Changes : out Input_Changes_T)
   is
   begin
      Changes := (others => False);
      for I in Input_T loop
         pragma Loop_Invariant
           (for all J in Input_T =>
              (if Changes (J) then J < I and then Now (J) /= No_Value));
         if Now (I) /= No_Value and then Now (I) /= Last_Inputs (I) then
            Changes (I) := True;
            Last_Inputs (I) := Now (I);
         end if;
      end loop;
   end Inputs;

   function RBC_Entry_Code (Choice : Byte) return Byte is
     (case Choice is
         when 0      => 3,
         when 1      => 0,
         when 2      => 1,
         when others => No_Code);

   function TRN_Code (T : EVC_Driver_Requests.Text_T) return Unsigned_32 is
      Code : Unsigned_32 := 0;
      D    : Byte;
   begin
      for I in 1 .. 8 loop
         pragma Loop_Invariant (Code < 2**(4 * (I - 1)));
         D := (if I <= T.Length and then T.Chars (I) in 48 .. 57
               then T.Chars (I) - 48 else 16#F#);
         Code := Code * 16 + Unsigned_32 (D);
      end loop;
      return Code;
   end TRN_Code;

   --  V on W bits at Pos when it fits, at most the largest value of W
   procedure Put (Buf : in out Body_T;
                  Pos : in out Natural;
                  V   : Natural;
                  W   : EVC_JRU_Messages.Width_T)
     with Global => null,
          Pre  => W <= 32 and then Pos <= 8 * Max_Body,
          Post => Pos <= 8 * Max_Body
   is
      Max : constant Unsigned_64 := Shift_Left (1, W) - 1;
   begin
      if Pos <= 8 * Max_Body - W then
         EVC_JRU_Messages.Put_Bits
           (Buf, Pos, Unsigned_64'Min (Unsigned_64 (V), Max), W);
      end if;
   end Put;

   --  M_KDRY_RST and M_KWET_RST 1.00 (0.05 per unit): the correction
   --  factors the on-board's braking applies to every train, the default
   --  of EVC_Supervision_Input.Train_Data_Extra_T, the Train Data of
   --  SUBSET-026 3.18.3.4 giving none (the variables have no unknown
   --  value, 0 to 1.55 all valid)
   No_Correction : constant := 20;

   --  N_BRAKE_CONF of one configuration. Decision: 4 bits for the range
   --  1 to 16 (SUBSET-027 4.2.4.2) code the number minus one, the only
   --  reading in which 16 configurations can be written
   One_Configuration : constant := 0;

   --  The sections of a deceleration curve (N_BRAKE_SECTIONS, then the
   --  speed and deceleration of each, with the ten M_KDRY_RST and the
   --  M_KWET_RST when Factors), the first seven steps
   procedure Put_Sections (Buf     : in out Body_T;
                           Pos     : in out Natural;
                           Curve   : EVC_Supervision_Input.Decel_Curve_T;
                           Factors : Boolean)
     with Global => null,
          Pre  => Pos <= 8 * Max_Body,
          Post => Pos <= 8 * Max_Body
   is
      N : constant Natural := Natural'Min (Curve.Count, 7);
   begin
      Put (Buf, Pos, N, 3);
      for M in 1 .. N loop
         pragma Loop_Invariant (Pos <= 8 * Max_Body);
         Put (Buf, Pos,
              (if M = 1 then 0
               else Curve.Steps (M - 1).Speed * 36 / 1000), 10);
         Put (Buf, Pos, Curve.Steps (M).Decel / 10, 8);
         if Factors then
            for K in 0 .. 10 loop
               pragma Loop_Invariant (Pos <= 8 * Max_Body);
               Put (Buf, Pos, No_Correction, 5);
            end loop;
         end if;
      end loop;
   end Put_Sections;

   procedure Train_Data_Body (D    : EVC_Supervision_Input.Train_Data_T;
                              C    : EVC_Train_Data.Categories_T;
                              Buf  : out Body_T;
                              Bits : out Natural)
   is
      use EVC_Supervision_Input;
      Pos    : Natural := 0;
      Length : constant EVC_Fixed.Num :=
        EVC_Fixed.Num'Min (EVC_Fixed.Num'Max (EVC_Fixed.Num (D.Length), 0),
                           150_000);
      N      : Natural := 0;
   begin
      Buf := (others => 0);
      Put (Buf, Pos, Natural'Min ((D.Max_Speed * 36 + 500) / 1000 / 5, 120),
           7);
      Put (Buf, Pos, Natural (C.Cant_Deficiency), 4);
      Put (Buf, Pos, Natural (C.Other), 15);
      Put (Buf, Pos, Natural'Min (Natural (Length / 100), 4095), 12);
      Put (Buf, Pos, D.T_Traction_Cut_Off / 10, 12);
      Put (Buf, Pos, Brake_Position_T'Pos (D.Brake_Position), 2);
      Put (Buf, Pos, 16, 5);
      if D.Model = Lambda then
         declare
            T0 : constant EVC_Braking.Times_T := EVC_Braking.Conversion_Service
              (D.Brake_Position, Length, True);
            T1 : constant EVC_Braking.Times_T := EVC_Braking.Conversion_Service
              (D.Brake_Position, Length, False);
         begin
            Put (Buf, Pos, 0, 1);
            Put (Buf, Pos, D.Brake_Percentage, 8);
            Put (Buf, Pos, One_Configuration, 4);
            Put (Buf, Pos, (if D.Has_Regenerative then 1 else 0)
                           + (if D.Has_Eddy_Current then 2 else 0)
                           + (if D.Has_Electro_Pneumatic then 4 else 0), 3);
            Put (Buf, Pos, Natural (T0.React / 50), 12);
            Put (Buf, Pos, Natural (T0.Build_Up / 50), 12);
            Put (Buf, Pos, Natural (T1.Build_Up / 50), 12);
         end;
      else
         Put (Buf, Pos, 1, 1);
         Put (Buf, Pos, One_Configuration, 4);
         Put (Buf, Pos, (if D.Has_Regenerative then 1 else 0)
                        + (if D.Has_Eddy_Current then 2 else 0)
                        + (if D.Has_Magnetic_Shoe then 4 else 0)
                        + (if D.Has_Electro_Pneumatic then 8 else 0), 4);
         Put (Buf, Pos, 0, 12);
         Put (Buf, Pos, D.T_Brake_Emergency / 50, 12);
         Put_Sections (Buf, Pos, D.A_Brake_Emergency, True);
         Put (Buf, Pos, 0, 12);
         Put (Buf, Pos, D.T_Brake_Service / 50, 12);
         Put_Sections (Buf, Pos, D.A_Brake_Service, False);
      end if;
      Put (Buf, Pos, Natural (C.Loading_Gauge), 8);
      Put (Buf, Pos, 0, 10);
      Put (Buf, Pos, Natural (C.Axle_Load), 7);
      for V in 1 .. 15 loop
         pragma Loop_Invariant (N < V);
         if (C.Voltages / 2**V) mod 2 = 1 then
            N := N + 1;
         end if;
      end loop;
      Put (Buf, Pos, N, 5);
      for V in 1 .. 15 loop
         pragma Loop_Invariant (Pos <= 8 * Max_Body);
         if (C.Voltages / 2**V) mod 2 = 1 then
            Put (Buf, Pos, V, 4);
            Put (Buf, Pos, 0, 10);
         end if;
      end loop;
      Put (Buf, Pos, 0, 5);
      Put (Buf, Pos, 0, 2);
      Bits := Pos;
   end Train_Data_Body;

   --  A distance in cm as signed metres on W bits (two's complement),
   --  clamped to Low .. 2**(W-1) - 1
   function Metres (D : EVC_Distances.Dist_T; Low : Integer; W : Positive)
     return Natural
     with Pre => W in 15 .. 16 and then Low in -2**15 .. 0
   is
      M : constant Integer := (if W = 15 then 2**15 else 2**16);
      V : constant Integer :=
        Integer'Max (Low, Integer (EVC_Distances.Dist_T'Min
          (EVC_Distances.Dist_T'Max (D / 100, -2**15),
           EVC_Distances.Dist_T (M / 2 - 1))));
   begin
      return Natural ((V + M) mod M);
   end Metres;

   procedure Track_Conditions_Body
     (Info : EVC_Track_Conditions.External_T;
      Buf  : out Body_T;
      Bits : out Natural)
   is
      Pos : Natural := 0;
      TI  : Natural;
   begin
      Buf := (others => 0);
      Put (Buf, Pos, 1, 2);
      Put (Buf, Pos, Info.Count, 5);
      for I in 1 .. Info.Count loop
         pragma Loop_Invariant (Pos <= 8 * Max_Body);
         declare
            E : EVC_Track_Conditions.External_Item_T renames Info.List (I);
         begin
            TI := Natural (Trackcond_TI (E.Kind));
            Put (Buf, Pos, TI, 4);
            if TI in 0 | 1 | 9 then
               Put (Buf, Pos, (if E.Has_End then Metres (E.To_End, -2**15, 16)
                               else 2**15 - 1), 16);
            elsif TI in 2 .. 6 then
               Put (Buf, Pos, (if E.Has_End then Metres (E.To_End, 0, 15)
                               else 2**15 - 1), 15);
            elsif TI = 7 then
               Put (Buf, Pos, E.Value / 1024, 4);
               if E.Value / 1024 /= 0 then
                  Put (Buf, Pos, E.Value mod 1024, 10);
               end if;
            elsif TI = 8 then
               Put (Buf, Pos, E.Value, 10);
            end if;
            if TI = 9 then
               Put (Buf, Pos, E.Value / 4, 4);
               Put (Buf, Pos, E.Value mod 4, 2);
            end if;
            Put (Buf, Pos, (if E.Has_Start
                            then Metres (E.To_Start, -2**15 + 1, 16)
                            else 2**15), 16);
         end;
      end loop;
      Bits := Pos;
   end Track_Conditions_Body;

   procedure Interface_Fields (C      : EVC_Supervision_Input.Onboard_Config_T;
                               Fields : out EVC_JRU_Messages.Fields_T)
   is
      use EVC_Supervision_Input;
      function Flag (B : Boolean) return EVC_JRU_Messages.Field_T is
        ((Value => (if B then 1 else 0), Bits => 1));
      --  00 none, 01 the emergency brake only, 10 the service brake
      --  only, 11 both (M_REGENERATIVEBRAKE, M_EDDYCURRENTBRAKE): the
      --  order of Special_Brake_Interface_T
      function Code (I : Special_Brake_Interface_T)
        return EVC_JRU_Messages.Field_T
      is ((Value => Unsigned_64 (Special_Brake_Interface_T'Pos (I)),
           Bits  => 2));
      S : constant Special_Brake_Interfaces_T := C.Special_Brakes;
   begin
      Fields := EVC_JRU_Messages.No_Fields;
      Fields (1) := Flag (C.Service_Brake_Command);
      Fields (2) := Flag (C.Service_Brake_Feedback);
      Fields (3) := Code (S (Regenerative));
      Fields (4) := Code (S (Eddy_Current));
      Fields (5) := (Value => (if S (Magnetic_Shoe) = No_Interface then 0
                               else 1),
                     Bits  => 2);
      Fields (6) := (Value => (case S (Electro_Pneumatic) is
                                  when No_Interface => 0,
                                  when Service_Only => 1,
                                  when others       => 2),
                     Bits  => 2);
      Fields (7) := Flag (C.Additional_Brake_Allowed);
      Fields (8) := Flag (C.Traction_Cut_Off);
   end Interface_Fields;

   function MN_Code (T : EVC_Driver_Requests.Text_T) return MN_Bytes_T is
      Code : MN_Bytes_T := (others => 16#FF#);
      D    : Byte;
   begin
      for I in 1 .. 6 loop
         pragma Loop_Invariant (True);
         D := (if I <= T.Length and then T.Chars (I) in 48 .. 57
               then T.Chars (I) - 48 else 16#F#);
         if I mod 2 = 1 then
            Code ((I + 1) / 2) := Shift_Left (D, 4) or 16#F#;
         else
            Code (I / 2) := (Code (I / 2) and 16#F0#) or D;
         end if;
      end loop;
      return Code;
   end MN_Code;

   procedure Cab_Status (Cab_A, Cab_B, Received : Boolean;
                         Changed : out Boolean) is
   begin
      Changed := Received
        and then (not Cab_Recorded or else Cab_A /= Cab_A_Recorded
                  or else Cab_B /= Cab_B_Recorded);
      if Changed then
         Cab_Recorded := True;
         Cab_A_Recorded := Cab_A;
         Cab_B_Recorded := Cab_B;
      end if;
   end Cab_Status;

   --  The kinds of EVC_Ports (1 pantograph, 2 main power switch, 3 air
   --  tightness, 4 regenerative brake, 5 eddy current service, 6 eddy
   --  current emergency, 7 magnetic shoe, 8 traction system, 9 current
   --  consumption, 10 station platform) to SUBSET-027 M_TRACKCOND_TI
   function Trackcond_TI (Kind : Natural) return Byte is
     (case Kind is
         when 1 => 0, when 2 => 1, when 3 => 2, when 4 => 3,
         when 5 => 6, when 6 => 5, when 7 => 4, when 8 => 7,
         when 9 => 8, when 10 => 9,
         when others => 15);

   procedure Track_Conditions (Info    : EVC_Track_Conditions.External_T;
                               Changes : out TC_Changes_T)
   is
      Now : TC_Changes_T := (Count => 0, List => (others => (others => 0)));
   begin
      Changes := (Count => 0, List => (others => (others => 0)));
      for I in 1 .. Info.Count loop
         pragma Loop_Invariant
           (Now.Count = I - 1 and then Changes.Count <= I - 1);
         declare
            E : constant EVC_Track_Conditions.External_Item_T :=
              Info.List (I);
            C : constant TC_Change_T :=
              (TI    => Trackcond_TI (E.Kind),
               Phase => (if E.Has_Start and then E.To_Start > 0 then 0
                         elsif E.Has_End and then E.To_End < 0 then 2
                         else 1),
               Id    => Byte (E.Id));
         begin
            Now.Count := I;
            Now.List (I) := C;
            if (for all J in 1 .. Last_TC.Count => Last_TC.List (J) /= C)
            then
               Changes.Count := Changes.Count + 1;
               Changes.List (Changes.Count) := C;
            end if;
         end;
      end loop;
      Last_TC := Now;
   end Track_Conditions;

   procedure RBC_Entry_Fields (RBC    : EVC_Driver_Requests.Bytes_23_T;
                               Q      : Byte;
                               Fields : out EVC_JRU_Messages.Fields_T)
   is
      Id    : constant Unsigned_32 :=
        Unsigned_32 (RBC (2))
        or Shift_Left (Unsigned_32 (RBC (3)), 8)
        or Shift_Left (Unsigned_32 (RBC (4)), 16)
        or Shift_Left (Unsigned_32 (RBC (5)), 24);
      N     : constant Natural := Natural'Min (Natural (RBC (6)), 16);
      Radio : Unsigned_64 := 0;
   begin
      Fields := EVC_JRU_Messages.No_Fields;
      Fields (1) := (Unsigned_64 (Q and 3), 2);
      if Q >= 2 then
         Fields (2) := (Unsigned_64 (Shift_Right (Id, 14) and 16#3FF#), 10);
         Fields (3) := (Unsigned_64 (Id and 16#3FFF#), 14);
      end if;
      if Q = 3 then
         for I in 1 .. 16 loop
            pragma Loop_Invariant (True);
            Radio := Shift_Left (Radio, 4)
              or (if I <= N and then RBC (6 + I) in 48 .. 57
                  then Unsigned_64 (RBC (6 + I) - 48) else 16#F#);
         end loop;
         Fields (4) := (Radio, 64);
      end if;
   end RBC_Entry_Fields;

end EVC_JRU_Records;
