--  ETCS on-board (EVC)
--  JRU events that follow SUBSET-027 messages, body.

with EVC_Distances; use type EVC_Distances.Cm_T;

package body EVC_JRU_Records
  with SPARK_Mode => On,
       Refined_State => (State => (Cab_A_Recorded, Cab_B_Recorded,
                                   Cab_Recorded,
                                   Last_TC, Last_Inputs))
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
            return (case Arg is
                       when 0      => 8,   -- Supervised Manoeuvre selected
                       when 2      => 9,   -- Exit Supervised Manoeuvre
                       when others => No_Code);
         --  recorded by their own events (EVC_Mission, EVC_Levels,
         --  EVC_Procedures, the mode change) or without a code (ATO,
         --  E5/E6)
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

   function Data_Code (K : Data_Kind_T) return Byte is
     (if K = Language then 29 else No_Code);  -- Selection of Language

   procedure Reset is
   begin
      Cab_A_Recorded := False;
      Cab_B_Recorded := False;
      Cab_Recorded := False;
      Last_TC := (Count => 0, List => (others => (others => 0)));
      Last_Inputs := Power_Up_Inputs;
   end Reset;

   function Input_Event (I : Input_T) return Byte is
     (case I is
         when Sleeping         => 30,
         when Passive_Shunting => 31,
         when Non_Leading      => 132,
         when Direction        => 39,
         when Remote_Shunting  => 51);

   function Direction_Code (TIU_Value : Natural) return Input_Value_T is
     (case TIU_Value is
         when 1      => 2,
         when 2      => 1,
         when others => 0);

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
