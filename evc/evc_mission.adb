--  ETCS on-board (EVC)
--  The mission data, the start and the end of mission, implementation.

with ETCS_Variables; use ETCS_Variables;

package body EVC_Mission
  with SPARK_Mode => On,
       Refined_State => (State => (Driver_S, Driver_V, TRN_S, TRN_V,
                                   Train_Known, Engaged, Mission_On,
                                   Proposal, Proposal_Mode, Acked_Now,
                                   Acked_M, Desk_Closed_Now, SR_V, SR_D,
                                   Continue_On, NL_Lost, NL_Input,
                                   TD_Now, Events, Event_N))
is

   type Event_Array is array (1 .. Max_Events) of Event_T;

   Driver_S        : Data_Status_T := Unknown;
   Driver_V        : Text_T;
   TRN_S           : Data_Status_T := Unknown;
   TRN_V           : Text_T;
   --  Train Data were entered since the power-up
   Train_Known     : Boolean := False;
   Engaged         : Boolean := False;
   Mission_On      : Boolean := False;
   Proposal        : Boolean := False;
   Proposal_Mode   : Mode_T := M_SR;
   Acked_Now       : Boolean := False;
   Acked_M         : Mode_T := M_SR;
   Desk_Closed_Now : Boolean := False;
   SR_V            : Speed_Cms_T := 0;
   SR_D            : EVC_Odometry.Virtual_T;
   Continue_On     : Boolean := False;
   --  4.4.15.1.1.3: the input lost in this cycle, the input of the last
   NL_Lost         : Boolean := False;
   NL_Input        : Boolean := False;
   --  Train Data validated in this cycle
   TD_Now          : Boolean := False;
   Events          : Event_Array;
   Event_N         : Natural range 0 .. Max_Events := 0;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Driver_ID_Status return Data_Status_T is (Driver_S)
     with Refined_Global => Driver_S;
   function Driver_ID return Text_T is (Driver_V)
     with Refined_Global => Driver_V;
   function TRN_Status return Data_Status_T is (TRN_S)
     with Refined_Global => TRN_S;
   function TRN return Text_T is (TRN_V)
     with Refined_Global => TRN_V;
   function Train_Data_Status return Data_Status_T is
     (if not Train_Known then Unknown
      elsif EVC_Train_Data.Valid then Valid
      else Invalid)
     with Refined_Global => (Train_Known, EVC_Train_Data.State);
   function SoM_Engaged return Boolean is (Engaged)
     with Refined_Global => Engaged;
   function Mission return Boolean is (Mission_On)
     with Refined_Global => Mission_On;
   function Proposed return Boolean is (Proposal)
     with Refined_Global => Proposal;
   function Proposed_Mode return Mode_T is (Proposal_Mode)
     with Refined_Global => Proposal_Mode;
   function Acknowledged (M : Mode_T) return Boolean is
     (Acked_Now and then Acked_M = M)
     with Refined_Global => (Acked_Now, Acked_M);
   function Ack_Taken return Boolean is (Acked_Now)
     with Refined_Global => Acked_Now;
   function Train_Data_Validated return Boolean is (TD_Now)
     with Refined_Global => TD_Now;
   function Desk_Closed_In_SoM return Boolean is (Desk_Closed_Now)
     with Refined_Global => Desk_Closed_Now;
   function SR_Speed return Speed_Cms_T is (SR_V)
     with Refined_Global => SR_V;
   function SR_Distance return EVC_Odometry.Virtual_T is (SR_D)
     with Refined_Global => SR_D;
   function SR_Distance_Passed return Boolean is
     (SR_D.Active and then EVC_Odometry.Remaining_Estimated (SR_D) < 0)
     with Refined_Global => (SR_D, EVC_Odometry.State);
   function Continue_Shunting return Boolean is (Continue_On)
     with Refined_Global => Continue_On;
   function NL_No_Longer_Permitted return Boolean is (NL_Lost)
     with Refined_Global => NL_Lost;
   function Event_Count return Natural is (Event_N)
     with Refined_Global => Event_N;
   function Event (I : Positive) return Event_T is (Events (I))
     with Refined_Global => (Input => Events, Proof_In => Event_N);

   procedure Put_Event (Kind, B3, B4 : Natural)
     with Global => (In_Out => (Events, Event_N))
   is
   begin
      if Event_N < Max_Events then
         Event_N := Event_N + 1;
         Events (Event_N) := (Kind => Unsigned_8 (Kind mod 256),
                              B3   => Unsigned_8 (B3 mod 256),
                              B4   => Unsigned_8 (B4 mod 256));
      end if;
   end Put_Event;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Driver_S := Unknown;
      Driver_V := (others => <>);
      TRN_S := Unknown;
      TRN_V := (others => <>);
      Train_Known := False;
      Engaged := False;
      Mission_On := False;
      Proposal := False;
      Proposal_Mode := M_SR;
      Acked_Now := False;
      Acked_M := M_SR;
      Desk_Closed_Now := False;
      SR_V := 0;
      SR_D := (others => <>);
      Continue_On := False;
      NL_Lost := False;
      NL_Input := False;
      TD_Now := False;
      Events := (others => (others => <>));
      Event_N := 0;
   end Clear;

   ---------------------------------------------------------------------
   --  The entries
   ---------------------------------------------------------------------

   --  DMI 11.3.3: a driver ID of 1 to 16 printable characters
   function Valid_Driver_ID (T : Text_T) return Boolean is
     (T.Length >= 1
      and then (for all I in 1 .. T.Length => T.Chars (I) in 32 .. 126));

   --  A.3.11, NID_OPERATIONAL (7.5.1.98): 1 to 8 digits
   function Valid_TRN (T : Text_T) return Boolean is
     (T.Length in 1 .. 8
      and then (for all I in 1 .. T.Length =>
                  T.Chars (I) in Character'Pos ('0') .. Character'Pos ('9')));

   --  The Train Data of an entry with the fixed ones of the installation
   --  (OK False: an item out of its range)
   procedure Train_Data_Of (E  : Train_Entry_T;
                            F  : EVC_Config.Fixed_Train_T;
                            D  : out Train_Data_T;
                            Cs : out EVC_Train_Data.Categories_T;
                            OK : out Boolean)
   is
      Def : constant EVC_Train_Data.Categories_T :=
        EVC_Train_Data.Default_Categories;
   begin
      D := (others => <>);
      Cs := Def;
      OK := E.Length_M in 1 .. 4_095                       -- L_TRAIN
        and then E.Brake_Percentage in 10 .. 250            -- A.3.11
        and then E.Max_Speed_Kmh in 5 .. 600                -- V_MAXTRAIN
        and then (E.Cant_Deficiency <= 10                   -- NC_CDTRAIN
                  or else E.Cant_Deficiency = 16#FF#)
        and then E.Other_Categories <= 7                    -- NC_TRAIN
        and then (E.Axle_Load <= 12 or else E.Axle_Load = 16#FF#)
        and then (E.Airtight <= 1 or else E.Airtight = 16#FF#)
        and then (E.Loading_Gauge <= 4 or else E.Loading_Gauge = 16#FF#);
      if not OK then
         return;
      end if;
      D :=
        (Length                => Length_T (E.Length_M) * 100,
         --  km/h to cm/s, rounded down (the ceiling never above)
         Max_Speed             =>
           Speed_Cms_T (Natural (E.Max_Speed_Kmh) * 250 / 9),
         Model                 => F.Model,
         Brake_Percentage      => Natural (E.Brake_Percentage),
         --  7.5.1.84: bit 2 passenger train, bit 1 freight train in G,
         --  bit 0 freight train in P; a passenger train is in P
         Brake_Position        =>
           (if (E.Other_Categories and 4) /= 0 then Passenger_P
            elsif (E.Other_Categories and 2) /= 0 then Freight_G
            elsif (E.Other_Categories and 1) /= 0 then Freight_P
            else Passenger_P),
         A_Brake_Emergency     => (Count => 0, Steps => (others => (0, 0))),
         A_Brake_Service       => (Count => 0, Steps => (others => (0, 0))),
         A_Brake_Normal        => (Count => 0, Steps => (others => (0, 0))),
         T_Brake_Emergency     => 0,
         T_Brake_Service       => 0,
         Has_Regenerative      => F.Has_Regenerative,
         Has_Eddy_Current      => F.Has_Eddy_Current,
         Has_Magnetic_Shoe     => F.Has_Magnetic_Shoe,
         Has_Electro_Pneumatic => F.Has_Electro_Pneumatic,
         T_Traction_Cut_Off    => F.T_Traction_Cut_Off);
      Cs :=
        (Cant_Deficiency =>
           (if E.Cant_Deficiency = 16#FF# then Def.Cant_Deficiency
            else NC_CDTRAIN_T (E.Cant_Deficiency)),
         Other           => NC_TRAIN_T (E.Other_Categories),
         Axle_Load       =>
           (if E.Axle_Load = 16#FF# then Def.Axle_Load
            else M_AXLELOADCAT_T (E.Axle_Load)),
         Loading_Gauge   =>
           (if E.Loading_Gauge = 16#FF# then Def.Loading_Gauge
            else M_LOADINGGAUGE_T (E.Loading_Gauge)),
         Voltages        => F.Voltages);
   end Train_Data_Of;

   --  4.4.15.1.1.3: the non-leading input lost in NL; 4.4.20.1.5:
   --  "Continue Shunting on desk closure" in SH; 5.4.3.2.1, A.3.4.1.2
   --  k): the desk closed during the start of mission; 5.4.3.2 S0: the
   --  start of mission engaged in SB with a desk open
   procedure Take_Desk (C : Context_T; M : Mode_T)
     with Global => (Output => NL_Lost,
                     In_Out => (NL_Input, Continue_On, Engaged,
                                Desk_Closed_Now, Driver_S, TRN_S,
                                Events, Event_N, EVC_Train_Data.State),
                     Input  => EVC_Driver_Requests.State)
   is
   begin
      --  4.4.15.1.1.3: the non-leading input lost while in NL
      NL_Lost := M = M_NL and then NL_Input and then not C.Non_Leading;
      NL_Input := C.Non_Leading;
      if NL_Lost then
         Put_Event (Event_NL_Lost, 0, 0);
      end if;

      --  4.4.20.1.5: "Continue Shunting on desk closure" in SH (4.7.2)
      if Maintain_Shunting_Selected and then M = M_SH
        and then not Continue_On
      then
         Continue_On := True;
         Put_Event (Event_Continue, 1, 0);
      end if;

      --  5.4.3.2.1, A.3.4.1.2 k): the desk closed during the start of
      --  mission
      if Engaged and then not C.Desk_Open then
         Desk_Closed_Now := True;
         if Driver_S = Valid then
            Driver_S := Invalid;
         end if;
         if TRN_S = Valid then
            TRN_S := Invalid;
         end if;
         EVC_Train_Data.Invalidate;
      end if;
      --  5.4.3.2 S0 (no communication session in levels 0, 1, NTC)
      if (M = M_SB and then C.Desk_Open) /= Engaged then
         Engaged := not Engaged;
         Put_Event (Event_SoM, (if Engaged then 1 else 0), 0);
      end if;
   end Take_Desk;

   --  4.7.2: the driver ID (DMI 11.3.3) and the train running number
   --  (A.3.11) entered in a mode where they may be
   procedure Take_Identity (M : Mode_T)
     with Global => (In_Out => (Driver_S, Driver_V, TRN_S, TRN_V,
                                Proposal, Events, Event_N),
                     Input  => EVC_Driver_Requests.State)
   is
   begin
      --  the driver ID (4.7.2: SB, SH, SM, FS, AD, LS, SR, OS, NL, UN,
      --  SN)
      if Entered (EVC_Driver_Requests.Driver_ID) then
         if M in M_SB | M_SH | M_SM | M_FS | M_AD | M_LS | M_SR | M_OS
               | M_NL | M_UN | M_SN
           and then Valid_Driver_ID (EVC_Driver_Requests.Driver_ID)
         then
            Driver_V := EVC_Driver_Requests.Driver_ID;
            Driver_S := Valid;
            Put_Event (Event_Driver_ID, Driver_V.Length, 0);
            Proposal := False;
         else
            Put_Event (Event_Refused, 0, 0);
         end if;
      end if;

      --  the train running number (4.7.2: SB, SM, FS, AD, LS, SR, OS,
      --  NL, UN, SN)
      if Entered (Train_Running_Number) then
         if M in M_SB | M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_NL
               | M_UN | M_SN
           and then Valid_TRN (EVC_Driver_Requests.Train_Running_Number)
         then
            TRN_V := EVC_Driver_Requests.Train_Running_Number;
            TRN_S := Valid;
            Put_Event (Event_TRN, TRN_V.Length, 0);
            Proposal := False;
         else
            Put_Event (Event_Refused, 1, 0);
         end if;
      end if;
   end Take_Identity;

   --  4.7.2, DMI Table 33 #3: the Train Data entered at standstill;
   --  4.4.11.1.5: the SR speed limit and distance entered at standstill
   --  in SR
   procedure Take_Data (C : Context_T; M : Mode_T)
     with Global => (In_Out => (Train_Known, TD_Now, Proposal, SR_V, SR_D,
                                Events, Event_N, EVC_Train_Data.State),
                     Input  => (EVC_Driver_Requests.State,
                                EVC_Odometry.State, EVC_Config.State))
   is
   begin
      --  the Train Data (4.7.2: SB, FS, AD, LS, SR, OS, UN, SN), at
      --  standstill (DMI Table 33 #3)
      if Entered (EVC_Driver_Requests.Train_Data) then
         declare
            D  : Train_Data_T;
            Cs : EVC_Train_Data.Categories_T;
            OK : Boolean;
            E  : constant Train_Entry_T := EVC_Driver_Requests.Train_Data;
         begin
            Train_Data_Of (E, EVC_Config.Current.Train, D, Cs, OK);
            if OK and then C.Standstill
              and then M in M_SB | M_FS | M_AD | M_LS | M_SR | M_OS | M_UN
                          | M_SN
            then
               EVC_Train_Data.Set (D, Cs);
               Train_Known := True;
               TD_Now := True;
               Put_Event (Event_Train_Data,
                          Natural (E.Length_M) / 100,
                          Natural (E.Brake_Percentage) / 2);
               Proposal := False;
            else
               Put_Event (Event_Refused, 2, 0);
            end if;
         end;
      end if;

      --  4.4.11.1.5: the SR speed limit and distance, at standstill in SR
      if Entered (EVC_Driver_Requests.SR_Data) then
         declare
            E : constant SR_Entry_T := EVC_Driver_Requests.SR_Data;
         begin
            if M = M_SR and then C.Standstill
              and then E.Speed_Kmh in 5 .. 600
            then
               SR_V := Speed_Cms_T (Natural (E.Speed_Kmh) * 250 / 9);
               --  4.4.11.1.3.1 b): from the entry
               SR_D := EVC_Odometry.Start_Virtual
                 (Length_T (E.Distance_M) * 100, C.Sense);
               Put_Event (Event_SR_Data, Natural (E.Speed_Kmh) / 5,
                          Natural'Min (Natural (E.Distance_M) / 100, 255));
            else
               Put_Event (Event_Refused, 3, 0);
            end if;
         end;
      end if;
   end Take_Data;

   --  5.4.3.2 S20, 5.4.5.3 h), 4.4.14.1.6: 'Start' and the mode it
   --  proposes; 4.6.3 [8], [58], [60]: the driver's acknowledgement of
   --  the mode proposed
   procedure Take_Start (C : Context_T; M : Mode_T)
     with Global => (In_Out => (Proposal, Proposal_Mode, Acked_Now,
                                Acked_M, Events, Event_N),
                     Input  => (Engaged, Driver_S, Train_Known,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State))
   is
   begin
      --  'Start' (5.4.3.2 S20; 5.4.5.3 h: at S10 with valid Train Data,
      --  so a valid train running number, which S13 asks before S20, is
      --  not a condition; 4.4.14.1.6)
      if Start_Selected then
         if M = M_SB and then Engaged and then C.Standstill
           and then Driver_S = Valid
           and then Train_Known and then EVC_Train_Data.Valid
           and then C.Level_Valid
         then
            if C.Level = L2 and then C.In_Communication then
               --  5.4.5.3 h): level 2 with a session open, S21: the MA
               --  request (EVC_Radio_Authority), no mode proposed here
               --  (the SR authorisation or the MA decide, E26 / E27 /
               --  E29)
               Put_Event (Event_Start, 1, 0);
            else
               Proposal := True;
               Proposal_Mode := (case C.Level is
                                    when L0      => M_UN,   -- S23
                                    when NTC     => M_SN,   -- S22
                                    when L1 | L2 => M_SR);  -- S24
               Put_Event (Event_Start, 1, 0);
               Put_Event (Event_Proposed, Mode_T'Pos (Proposal_Mode), 0);
            end if;
         elsif M = M_PT and then C.Standstill and then C.Level_Valid
           and then C.Level = L1 and then EVC_Train_Data.Valid
         then
            Proposal := True;
            Proposal_Mode := M_SR;
            Put_Event (Event_Start, 1, 0);
            Put_Event (Event_Proposed, Mode_T'Pos (M_SR), 0);
         else
            Put_Event (Event_Start, 0, 0);
         end if;
      end if;

      --  a proposal lives in SB (the start of mission engaged) and PT
      if Proposal
        and then not ((M = M_SB and then Engaged) or else M = M_PT)
      then
         Proposal := False;
      end if;

      --  the driver's acknowledgement of the mode proposed (DMI ack kind
      --  1): 4.6.3 [8], [58], [60]
      if Proposal and then Mode_Acknowledged then
         Acked_Now := True;
         Acked_M := Proposal_Mode;
         Put_Event (Event_Acked, Mode_T'Pos (Proposal_Mode), 0);
      end if;
   end Take_Start;

   --------------
   -- Evaluate --
   --------------

   procedure Evaluate (C : Context_T) is
      M : constant Mode_T := C.Mode;
   begin
      Event_N := 0;
      Acked_Now := False;
      Desk_Closed_Now := False;
      TD_Now := False;

      Take_Desk (C, M);
      Take_Identity (M);
      Take_Data (C, M);
      Take_Start (C, M);
   end Evaluate;

   --------------------
   -- Override_In_SR --
   --------------------

   procedure Override_In_SR (C : Context_T) is
   begin
      SR_V := C.V_NVSTFF;
      if C.D_NVSTFF < Max_Cm then
         SR_D := EVC_Odometry.Start_Virtual (C.D_NVSTFF, C.Sense);
      else
         SR_D := (others => <>);
      end if;
      Put_Event (Event_SR_Data,
                 Natural (C.V_NVSTFF) * 36 / 1000 / 5,
                 Natural (Length_T'Min (C.D_NVSTFF / 10_000, 255)));
   end Override_In_SR;

   ------------------
   -- Set_For_Test --
   ------------------

   procedure Set_For_Test (M : Mode_T; C : Context_T) is
   begin
      if M = M_SR then
         SR_V := C.V_NVSTFF;
         if C.D_NVSTFF < Max_Cm then
            SR_D := EVC_Odometry.Start_Virtual (C.D_NVSTFF, C.Sense);
         else
            SR_D := (others => <>);
         end if;
      end if;
   end Set_For_Test;

   ------------------
   -- Mode_Entered --
   ------------------

   procedure Mode_Entered (From, To : Mode_T; C : Context_T) is
   begin
      Proposal := False;
      Acked_Now := False;
      --  4.4.20.1.7: one transition SH -> PS, inactive once SH is left
      if From = M_SH and then Continue_On then
         Continue_On := False;
         Put_Event (Event_Continue, 0, Mode_T'Pos (To));
      end if;
      --  5.4.3.2 S0 in the mode entered (5.4.3.2.1: the procedure ends
      --  with the transition to another mode than SB)
      if (To = M_SB and then C.Desk_Open) /= Engaged then
         Engaged := not Engaged;
         Put_Event (Event_SoM, (if Engaged then 1 else 0), 0);
      end if;

      --  4.10: the driver ID and the train running number are to be
      --  revalidated in SB, deleted in SL; the Train Data revalidated in
      --  SB, SH, SM and NL
      if To = M_SB then
         if Driver_S = Valid then
            Driver_S := Invalid;
         end if;
         if TRN_S = Valid then
            TRN_S := Invalid;
         end if;
      elsif To = M_SL then
         Driver_S := Unknown;
         Driver_V := (others => <>);
         TRN_S := Unknown;
         TRN_V := (others => <>);
      end if;
      if To in M_SB | M_SH | M_SM | M_NL then
         EVC_Train_Data.Invalidate;
      end if;

      --  5.5.2: the end of mission
      if (To = M_SB
          and then (From in M_FS | M_AD | M_LS | M_OS | M_SM | M_UN | M_NL
                          | M_SR | M_RV | M_SN
                    or else (From = M_PT and then Mission_On)))
        or else
         (To = M_SH
          and then (From in M_FS | M_AD | M_LS | M_OS | M_SR | M_SM | M_SN
                          | M_UN
                    or else (From = M_PT and then Mission_On)))
      then
         Put_Event (Event_EoM, Mode_T'Pos (To), Mode_T'Pos (From));
         Mission_On := False;
      end if;
      --  5.4.6.1: the start of a mission
      if Mission_Mode (To) and then not Mission_On then
         Mission_On := True;
         Put_Event (Event_Mission, Mode_T'Pos (To), Mode_T'Pos (From));
      end if;

      --  4.4.11.1.6.2: the national values when SR is entered, the SR
      --  distance from there (4.4.11.1.3.1 a); 4.10: deleted on leaving
      --  SR but in PT
      if To = M_SR then
         SR_V := C.V_NVSTFF;
         if C.D_NVSTFF < Max_Cm then
            SR_D := EVC_Odometry.Start_Virtual (C.D_NVSTFF, C.Sense);
         else
            SR_D := (others => <>);
         end if;
      elsif To /= M_PT then
         SR_V := 0;
         SR_D := (others => <>);
      end if;
   end Mode_Entered;

end EVC_Mission;
