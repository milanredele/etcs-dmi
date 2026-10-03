--  ETCS on-board (EVC)
--  JRU events that follow SUBSET-027 messages, body.

with EVC_Distances; use type EVC_Distances.Cm_T;

package body EVC_JRU_Records
  with SPARK_Mode => On,
       Refined_State => (State => (Cab_A_Recorded, Cab_B_Recorded,
                                   Cab_Recorded,
                                   Last_TC))
is

   use EVC_Driver_Requests;

   Cab_A_Recorded : Boolean := False;
   Cab_B_Recorded : Boolean := False;
   Cab_Recorded   : Boolean := False;
   Last_TC        : TC_Changes_T :=
     (Count => 0, List => (others => (others => 0)));

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
            | BMM_Inhibition | Maintain_Shunting | Isolate =>
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
   end Reset;

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

end EVC_JRU_Records;
