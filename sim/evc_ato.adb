--  ETCS DMI test simulator
--  ERTMS/ATO on-board implementation.
--
--  Rules of this simulator (SUBSET-125 is not modelled):
--   * ATO status: ATO03 in AD, ATO04 for Disengage_Time after the
--     driver's "ATO disengage" (with the ATO warning, the ATO releasing
--     traction), ATO02 in FS when a stopping point is ahead and the
--     train may leave the one it stands at, ATO01 otherwise while the
--     selector is "On".
--   * The ATO drives to the next stopping point that is not skipped on
--     a braking curve of A_ATO, gentler than the EVC's service curve,
--     below the permitted speed by Margin_MS.
--   * Standing within Arrival_Window_M of a stopping point is arriving
--     there; the stopping accuracy is within Accurate_M. In AD the ATO
--     then disengages itself (SUBSET-026 4.4.16.3.2.1): AD is no longer
--     requested and the mode goes back to FS ([33]).
--   * At the stopping point: train hold, then the dwell time; the
--     driver is asked to open the doors (Open_Request_S), the doors are
--     open, the ATO closes them (Closing_S before the end) and they are
--     closed at the end of the stop.
--   * A stopping point is passed when the front is Arrival_Window_M
--     beyond it; a skip request ends with it.

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Streams; use Ada.Streams;
with DMI_Protocol; use DMI_Protocol;
with EVC_Track; use EVC_Track;
with EVC_Train;
with Interfaces; use Interfaces;

package body EVC_ATO is

   use type EVC_Mock.Mode_T;

   A_ATO            : constant Float := 0.5;  -- m/s^2, braking curve
   Margin_MS        : constant Float := 1.5;  -- below the permitted speed
   Arrival_Window_M : constant Float := 30.0;
   Accurate_M       : constant Float := 2.0;
   Disengage_Time   : constant Float := 1.5;  -- s
   Open_Request_S   : constant Float := 3.0;  -- s
   Closing_S        : constant Float := 6.0;  -- s
   Coasting_M       : constant Float := 400.0; -- coasting before braking

   subtype Stop_Index_T is Positive range
     Stopping_Points'First .. Stopping_Points'Last + 1;

   On                : Boolean := False;       -- the ATO selector
   Next              : Stop_Index_T := Stopping_Points'First;
   At_Stop           : Boolean := False;       -- standing at Next
   Stop_Elapsed      : Float := 0.0;           -- s since the arrival
   Stop_Error_M      : Float := 0.0;           -- front - stopping point
   Skip_Next         : Boolean := False;
   Disengaging_Left  : Float := 0.0;           -- s of ATO04

   function Position return Float is (EVC_Train.Position_M);

   function Stop_Duration return Float is
     (if Next in Stopping_Points'Range
      then Float (Stopping_Points (Next).Hold_S
                  + Stopping_Points (Next).Dwell_S)
      else 0.0);

   function May_Depart return Boolean is
     (not At_Stop or else Stop_Elapsed >= Stop_Duration);

   -- the stopping point the ATO drives to: the next one, or the one
   -- after it when the next one is skipped or the train stands there
   function Target return Stop_Index_T is
      T : Stop_Index_T := Next;
   begin
      if (At_Stop or else Skip_Next) and then T in Stopping_Points'Range then
         T := T + 1;
      end if;
      return T;
   end Target;

   function Journey_Ahead return Boolean is (Target in Stopping_Points'Range);

   function Distance_To (Index : Stop_Index_T) return Float is
     (if Index in Stopping_Points'Range
      then Float (Stopping_Points (Index).At_M) - Position
      else 0.0);

   function In_FS_Or_AD return Boolean is
     (EVC_Mock.Mode in EVC_Mock.FS | EVC_Mock.AD);

   -- the speed the ATO drives at, m/s
   function Profile_MS return Float is
      Perm : constant Float :=
        Float'Max (Float (EVC_Mock.Permitted_Speed) / 3.6 - Margin_MS, 0.0);
   begin
      if not May_Depart then
         return 0.0;
      end if;
      if Journey_Ahead then
         return Float'Min
           (Perm, Sqrt (2.0 * A_ATO * Float'Max (Distance_To (Target), 0.0)));
      end if;
      return Perm;
   end Profile_MS;

   ---------------------------------------------------------------------
   -- Driver requests
   ---------------------------------------------------------------------

   procedure Set_Selector (Arg : Natural) is
   begin
      case Arg is
         when 1 =>
            On := False;
            -- SUBSET-026 4.6 [53]: the driver sets the selector to
            -- "Stand-by"
            if EVC_Mock.Mode = EVC_Mock.AD then
               EVC_Mock.Mode := EVC_Mock.FS;
            end if;
            Disengaging_Left := 0.0;
            Skip_Next := False;
         when 2 =>
            On := True;
         when others =>
            null;
      end case;
   end Set_Selector;

   function Status return Unsigned_8 is
   begin
      if not On then
         return 0;
      elsif Disengaging_Left > 0.0 then
         return 4;                                  -- ATO04
      elsif EVC_Mock.Mode = EVC_Mock.AD then
         return 3;                                  -- ATO03
      elsif EVC_Mock.Mode = EVC_Mock.FS and then Journey_Ahead
        and then May_Depart and then not EVC_Train.Brake_Commanded
      then
         return 2;                                  -- ATO02
      else
         return 1;                                  -- ATO01
      end if;
   end Status;

   procedure Engage_Request (Arg : Natural) is
   begin
      if Arg = 1 and then Status = 2 then
         -- SUBSET-026 4.6 [80]: the driver selects "ATO engage"
         EVC_Mock.Mode := EVC_Mock.AD;
      elsif Arg = 0 and then EVC_Mock.Mode = EVC_Mock.AD
        and then Disengaging_Left = 0.0
      then
         -- [53] once the ATO has released the train
         Disengaging_Left := Disengage_Time;
      end if;
   end Engage_Request;

   procedure Skip_Request (Arg : Natural) is
   begin
      if On and then not At_Stop and then Next in Stopping_Points'Range then
         Skip_Next := Arg = 1;
      end if;
   end Skip_Request;

   ---------------------------------------------------------------------
   -- Journey
   ---------------------------------------------------------------------

   procedure Update (Dt_S : Float) is
   begin
      if Disengaging_Left > 0.0 then
         Disengaging_Left := Float'Max (Disengaging_Left - Dt_S, 0.0);
         if Disengaging_Left = 0.0 and then EVC_Mock.Mode = EVC_Mock.AD then
            EVC_Mock.Mode := EVC_Mock.FS;
         end if;
      end if;

      if At_Stop then
         Stop_Elapsed := Stop_Elapsed + Dt_S;
         -- departure: the front has left the stopping point
         if Position > Float (Stopping_Points (Next).At_M) + 5.0
           or else not On
         then
            At_Stop := False;
            Next := Next + 1;
         end if;
         return;
      end if;

      if Next not in Stopping_Points'Range then
         return;
      end if;

      declare
         Error : constant Float :=
           Position - Float (Stopping_Points (Next).At_M);
      begin
         if Error > Arrival_Window_M then
            -- passed without stopping (skipped, or driven by hand)
            Next := Next + 1;
            Skip_Next := False;
         elsif On and then In_FS_Or_AD and then not Skip_Next
           and then EVC_Train.Speed_MS = 0.0
           and then abs Error <= Arrival_Window_M
         then
            At_Stop := True;
            Stop_Elapsed := 0.0;
            Stop_Error_M := Error;
            -- SUBSET-026 4.4.16.3.2.1: the ATO disengages itself after
            -- it has stopped the train at an operational stopping point
            if EVC_Mock.Mode = EVC_Mock.AD then
               EVC_Mock.Mode := EVC_Mock.FS;
            end if;
         end if;
      end;
   end Update;

   function Demand return Integer is
      V  : constant Float := EVC_Train.Speed_MS;
      VT : constant Float := Profile_MS;
   begin
      if Disengaging_Left > 0.0 then
         return 0; -- the ATO releases traction
      elsif VT < 0.05 and then V < 0.5 then
         return -100; -- holds the train
      elsif V > VT + 0.2 then
         return -Integer (Float'Min (100.0, 30.0 + (V - VT) * 100.0));
      elsif V < VT - 0.5 then
         return 60;
      else
         return 0;
      end if;
   end Demand;

   function Advising return Boolean is
     (On and then EVC_Mock.Mode = EVC_Mock.FS);

   -- where the train starts braking for the next stopping point, from
   -- the front; the coasting advice covers Coasting_M before it
   function Braking_Point_M return Float is
      V : constant Float := EVC_Train.Speed_MS;
   begin
      return Distance_To (Target) - V * V / (2.0 * A_ATO);
   end Braking_Point_M;

   -- SUBSET-026 4.7.2: the advice is given in FS only, outside
   -- stopping points
   function Advice_Given return Boolean is
     (Advising and then not At_Stop and then Journey_Ahead);

   function Coasting return Boolean is
     (Advice_Given
      and then Braking_Point_M > 0.0
      and then Braking_Point_M <= Coasting_M);

   function Advice_Change_M return Natural is
      B : Float;
   begin
      if not Advice_Given then
         return 16#FFFF#;
      end if;
      B := Braking_Point_M;
      if B > Coasting_M then
         return Natural (Float'Min (B - Coasting_M, 32_000.0));
      elsif B > 0.0 then
         return Natural (B);
      end if;
      return 16#FFFF#;
   end Advice_Change_M;

   ---------------------------------------------------------------------
   -- MSG_ATO
   ---------------------------------------------------------------------

   procedure Send (Emit : EVC_Mock.Sink_T; Clock_S : Float) is
      Shown : constant Boolean := On and then In_FS_Or_AD;
      Name_Of : constant Stop_Index_T := Target;

      function Name return String is
      begin
         if not Shown or else At_Stop
           or else Name_Of not in Stopping_Points'Range
         then
            return "";
         end if;
         declare
            N    : constant String := Stopping_Points (Name_Of).Name;
            Last : Natural := N'Last;
         begin
            while Last >= N'First and then N (Last) = ' ' loop
               Last := Last - 1;
            end loop;
            return N (N'First .. Last);
         end;
      end Name;

      The_Name : constant String := Name;

      -- stopping points ahead: from the one the train stands at
      function Stop_Count return Natural is
        (if Shown and then Next in Stopping_Points'Range
         then Stopping_Points'Last - Next + 1 else 0);

      Count   : constant Natural := Stop_Count;
      Payload : Stream_Element_Array
        (1 .. Stream_Element_Offset
                (ATO_Fixed_Length + The_Name'Length
                 + Count * ATO_Stop_Entry_Length));
      Offset  : Stream_Element_Offset := Payload'First;

      procedure U8 (V : Natural) is
      begin
         Put_U8 (Payload, Offset, Unsigned_8 (V mod 256));
      end U8;

      procedure U16 (V : Natural) is
      begin
         Put_U16 (Payload, Offset, Unsigned_16 (V mod 65536));
      end U16;

      Doors   : Natural := 0;
      Dwell   : Natural := 16#FFFF#;
      Hold    : Boolean := False;
      Accuracy : Natural := 0;
   begin
      if Shown and then At_Stop then
         declare
            P     : Stopping_Point_T renames Stopping_Points (Next);
            Total : constant Float := Stop_Duration;
         begin
            Accuracy := (if Stop_Error_M > Accurate_M then 1       -- ATO06
                         elsif Stop_Error_M < -Accurate_M then 2   -- ATO07
                         else 3);                                  -- ATO08
            Hold := Stop_Elapsed < Float (P.Hold_S);
            if not Hold and then Stop_Elapsed < Total then
               Dwell := Natural (Float'Ceiling (Total - Stop_Elapsed));
            end if;
            if Stop_Elapsed < Open_Request_S then
               Doors := (case P.Doors is
                            when Both  => 1,                       -- ATO10
                            when Left  => 2,                       -- ATO11
                            when Right => 3);                      -- ATO12
            elsif Stop_Elapsed < Total - Closing_S then
               Doors := 4;                                         -- ATO13
            elsif Stop_Elapsed < Total then
               Doors := 6;                                         -- ATO15
            else
               Doors := 7;                                         -- ATO16
            end if;
         end;
      end if;

      U8 ((if On then 2 else 1));                          -- selector
      U8 (Natural (Status));
      U8 ((if Disengaging_Left > 0.0 then 1 else 0));      -- warning
      U8 ((if Shown and then At_Stop then 1 else 0));      -- location
      U8 (Accuracy);
      U16 (Dwell);
      U8 ((if Hold then 1 else 0));
      U8 (Doors);
      -- skip stopping point status: outside stopping points
      U8 ((if Shown and then not At_Stop and then Next in Stopping_Points'Range
           then (if Skip_Next then 3 else 1) else 0));
      -- target advice speed (FS only, 4.7.2)
      U16 ((if Advice_Given
            then Natural (Float'Rounding (Profile_MS * 3.6))
            else 16#FFFF#));
      U8 ((if Coasting then 1 else 0));
      -- estimated arrival time at the next stopping point: the rest of
      -- the way at the profile speed, plus the braking at its end
      if The_Name'Length > 0 then
         declare
            V_Ref : constant Float :=
              Float'Max (Float (EVC_Mock.Permitted_Speed) / 3.6 - Margin_MS,
                         8.0);
            T     : constant Natural := Natural
              (Clock_S + Float'Max (Distance_To (Name_Of), 0.0) / V_Ref
               + V_Ref / (2.0 * A_ATO));
         begin
            U8 ((T / 3600) mod 24);
            U8 ((T / 60) mod 60);
            U8 (T mod 60);
         end;
      else
         U8 (16#FF#);
         U8 (0);
         U8 (0);
      end if;
      U8 (The_Name'Length);
      for C of The_Name loop
         U8 (Character'Pos (C));
      end loop;
      U8 (Count);
      if Count > 0 then
         for I in Next .. Stopping_Points'Last loop
            U16 (Natural (Float'Min (Float'Max (Distance_To (I), 0.0),
                                     65_535.0)));
         end loop;
      end if;
      Emit (MSG_ATO, Payload);
   end Send;

   procedure Reset is
   begin
      On := False;
      Next := Stopping_Points'First;
      At_Stop := False;
      Stop_Elapsed := 0.0;
      Stop_Error_M := 0.0;
      Skip_Next := False;
      Disengaging_Left := 0.0;
   end Reset;

   function Selector_On return Boolean is (On);
   function At_Stopping_Point return Boolean is (At_Stop);
   function Next_Stopping_Point return Positive is (Next);

end EVC_ATO;
