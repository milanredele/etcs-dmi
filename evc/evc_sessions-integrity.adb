--  ETCS on-board (EVC)
--  Phase E5: the train integrity information of 3.6.5.2

with EVC_Ports;

package body EVC_Sessions.Integrity
  with SPARK_Mode => On,
       Refined_State => (State => (Current, Input, Was_Up, Sent,
                                   T0_Pos, T0_Under, T0_Length))
is
   use type EVC_Ports.Movement_T;

   subtype Length_T is EVC_Distances.Length_T;
   subtype Dist_T is EVC_Distances.Dist_T;

   --  The input of the TIU not yet evaluated: none, or its value
   type Input_T is (None, Unknown, Confirmed, Lost);

   Current   : Status_T := No_Information;
   Input     : Input_T := None;
   Was_Up    : Boolean := False;
   --  a report with the confirmation was sent (Table 2c [5])
   Sent      : Boolean := False;
   --  at the time the train was last known to be integer: the estimated
   --  front end in the odometer's frame, its under-reading amount from
   --  the LRBG, the train length
   T0_Pos    : Dist_T := 0;
   T0_Under  : Length_T := 0;
   T0_Length : Length_T := 0;

   procedure Clear is
   begin
      Current := No_Information;
      Input := None;
      Was_Up := False;
      Sent := False;
      T0_Pos := 0;
      T0_Under := 0;
      T0_Length := 0;
   end Clear;

   procedure Take_Input (Value : Natural) is
   begin
      Input := (case Value is
                   when Input_Unknown   => Unknown,
                   when Input_Confirmed => Confirmed,
                   when Input_Lost      => Lost,
                   when others          => None);
   end Take_Input;

   function Status return Status_T is (Current);

   function Q_Integrity return Natural is (Status_T'Pos (Current));

   --  The travel of the estimated front end since the time the train was
   --  last known to be integer, towards the active cab (decision 4)
   function Travel return Length_T
     with Global => (Input => (T0_Pos, EVC_Odometry.State,
                               EVC_Position.State))
   is
      D : constant Dist_T := EVC_Odometry.Position;
      F : constant EVC_Distances.Cm_T :=
        (case EVC_Position.Active_Cab is
            when EVC_Position.Cab_A  => D - T0_Pos,
            when EVC_Position.Cab_B  => T0_Pos - D,
            when EVC_Position.No_Cab => abs (D - T0_Pos));
   begin
      return (if F <= 0 then 0
              elsif F >= EVC_Distances.Max_Cm then EVC_Distances.Max_Cm
              else F);
   end Travel;

   --  Figure 15: from the min safe rear end at T0 to the estimated front
   --  end now, in cm (saturated)
   function Length_Cm return Length_T
     with Global => (Input => (T0_Pos, T0_Under, T0_Length,
                               EVC_Odometry.State, EVC_Position.State))
   is
      Sum : constant Long_Long_Integer :=
        Long_Long_Integer (T0_Length) + Long_Long_Integer (T0_Under)
        + Long_Long_Integer (Travel);
   begin
      return (if Sum >= Long_Long_Integer (EVC_Distances.Max_Cm)
              then EVC_Distances.Max_Cm else Length_T (Sum));
   end Length_Cm;

   function Confirmed_Length return Natural is
      L : constant Length_T := Length_Cm;
   begin
      return (if L >= Max_Length then 32_767
              else Natural ((L + 99) / 100));
   end Confirmed_Length;

   --  The time the train was last known to be integer is now
   procedure Set_T0
     with Global => (Output => (T0_Pos, T0_Under, T0_Length),
                     Input  => (EVC_Odometry.State, EVC_Position.State,
                                EVC_Train_Data.State))
   is
   begin
      T0_Pos := EVC_Odometry.Position;
      T0_Under := EVC_Position.Doubt_Under;
      T0_Length := EVC_Train_Data.Length;
   end Set_T0;

   --  Table 2b with the conditions of Table 2c, by priority (p1 first)
   procedure Evaluate (Mode : EVC_Modes.Mode_T; Report : out Boolean) is
      Up       : constant Boolean := EVC_Radio.In_Communication;
      Valid_TD : constant Boolean := EVC_Train_Data.Valid;
      Pos_OK   : constant Boolean :=
        EVC_Position.Status = EVC_Position.Valid
        and then EVC_Position.LRBG.Valid;
      Acked    : constant Boolean :=
        Valid_TD and then EVC_Radio.Train_Data_Acknowledged;
      Cab      : constant EVC_Position.Cab_T := EVC_Position.Active_Cab;
      Move     : constant EVC_Ports.Movement_T := EVC_Odometry.Movement;
      C2 : constant Boolean :=
        EVC_Odometry.Standstill and then Acked and then Pos_OK
        and then EVC_Driver_Requests.Selected
                   (EVC_Driver_Requests.Train_Integrity);
      C3 : constant Boolean :=
        Input = Confirmed and then Acked and then Pos_OK
        and then EVC_Train_Data.Length <= Max_Length
        and then EVC_Position.Doubt_Under
                   <= Max_Length - EVC_Train_Data.Length;
      C4 : constant Boolean := Input = Lost and then Valid_TD;
      --  [7], [8], [9]
      C789 : constant Boolean :=
        not Valid_TD or else EVC_Train_Data.Length /= T0_Length
        or else (Cab = EVC_Position.Cab_A
                 and then Move = EVC_Ports.Towards_Cab_B)
        or else (Cab = EVC_Position.Cab_B
                 and then Move = EVC_Ports.Towards_Cab_A)
        or else Length_Cm > Max_Length;
      Before : Status_T;
   begin
      --  3.6.5.2.6
      if Up and then not Was_Up then
         Current := No_Information;
         Sent := False;
      end if;
      Was_Up := Up;
      Before := Current;
      case Current is
         when No_Information =>
            if C2 then
               Current := By_Driver;
            elsif C4 then
               Current := Lost;
            elsif C3 then
               Current := By_External;
            end if;
         when By_Driver =>
            if Sent then
               Current := No_Information;
            end if;
         when By_External =>
            if C4 then
               Current := Lost;
            elsif C2 then
               Current := By_Driver;
            elsif Sent or else C789 then
               Current := No_Information;
            elsif C3 then
               --  a new confirmation: the train known integer again
               Set_T0;
            end if;
         when Lost =>
            if C2 then
               Current := By_Driver;
            elsif C3 then
               Current := By_External;
            elsif not Valid_TD or else Input = Unknown then
               Current := No_Information;
            end if;
      end case;
      if Current /= Before and then Current in By_Driver | By_External then
         Set_T0;
      end if;
      --  4.4.15.1.3: none in NL, whatever is available on-board
      if Mode = EVC_Modes.M_NL then
         Current := No_Information;
      end if;
      Sent := False;
      Input := None;
      --  3.6.5.1.4 c), d)
      Report := Current /= Before and then Current in By_Driver | Lost;
   end Evaluate;

   procedure Reported is
   begin
      if Current in By_External | By_Driver then
         Sent := True;
      end if;
   end Reported;

end EVC_Sessions.Integrity;
