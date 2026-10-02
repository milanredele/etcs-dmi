with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Streams;
with EVC_Brake_Commands;
with EVC_Bytes;
with EVC_Config;
with EVC_DMI_Port;
with EVC_Distances;
with EVC_Fixed;
with EVC_Ports;
with EVC_SDM;
with EVC_Stored_Information;
with Interfaces;
with Sim_Onboard_Env;

package body EVC_Test_EMRRLS is

   package SI renames EVC_Stored_Information;
   package SDM renames EVC_SDM;
   package BC renames EVC_Brake_Commands;

   use type EVC_Distances.Cm_T;
   use type EVC_Bytes.Byte_Array;
   use type SDM.Monitoring_T;
   use type SDM.Status_T;
   use type BC.Reasons_T;
   use Ada.Streams;
   use EVC_Ports;
   use Interfaces;

   ---------------------------------------------------------------------
   --  Q_NVEMRRLS (7.5.1.123, 3.13.2.3.7.2): the emergency brake command
   --  of the speed and distance monitoring is revoked at standstill only
   --  (0, the A.3.2 default the bench runs with) or also once the
   --  Permitted speed is no longer exceeded (1, the value of
   --  Scenario_SDM_Mission), in ceiling and target speed monitoring
   --  (Tables 6, 10, 11 r1, r3); in release speed monitoring at
   --  standstill only whatever the value (Table 14 r0). The service
   --  brake and the traction cut-off do not depend on it. Each scenario
   --  runs twice, the value sent in the packet 3 of the mission's group
   --  (Mission_Track), on the mission's line: 140 km/h, 100 from 4 km,
   --  120 from 7 km, the EOA at 10 km with a release speed of 25 km/h.
   --  Every cycle the train's speed is what the scenario says (it obeys
   --  the brake commands only where the scenario makes it); the TIU
   --  output, the JRU records of event 20 and the brake indication of
   --  MSG_STATUS are followed cycle by cycle.
   ---------------------------------------------------------------------

   Only_SDM          : constant BC.Reasons_T :=
     (BC.Speed_Distance => True, others => False);
   Only_Roll_Away    : constant BC.Reasons_T :=
     (BC.Roll_Away => True, others => False);
   SDM_And_Roll_Away : constant BC.Reasons_T :=
     (BC.Speed_Distance | BC.Roll_Away => True, others => False);

   --  The train's speed (cm/s), the last brake indication of MSG_STATUS
   --  (0 none, 1 applied, 2 acknowledgement asked), whether 2 was ever
   --  sent, the JRU records of event 20 since EM_Start
   EM_V     : Natural := 0;
   EM_Brake : Natural := 0;
   EM_Asked : Boolean := False;
   EM_JRU   : Natural := 0;

   --  JRU event 20 (EVC_Ports.JRU_Brake_Commands) of the last Take: the
   --  TIU commands, the reasons, the supervision status
   type Brake_Record_T is record
      Found    : Boolean := False;
      Commands : Natural := 0;
      Reasons  : Natural := 0;
      Status   : Natural := 0;
   end record;

   function Brake_Record return Brake_Record_T is
   begin
      for I in reverse 1 .. Rec_Count loop
         if Recs (I).Port = JRU
           and then Byte_At (I, 1) = EVC_Ports.JRU_Brake_Commands
         then
            --  the commands are bits 0 to 2 of byte 2, bits 3 to 7 the
            --  reasons bits 8 to 12 (phase E4)
            return (True, Byte_At (I, 2) mod 8,
                    Byte_At (I, 3) + 256 * (Byte_At (I, 2) / 8),
                    Byte_At (I, 4));
         end if;
      end loop;
      return (others => <>);
   end Brake_Record;

   function Is_Record (Commands, Reasons, Status : Natural) return Boolean
   is
      R : constant Brake_Record_T := Brake_Record;
   begin
      return R.Found and then R.Commands = Commands
        and then R.Reasons = Reasons and then R.Status = Status;
   end Is_Record;

   function No_Record return Boolean is (not Brake_Record.Found);

   --  The TIU output of commands C for reasons R (EVC_Ports.TIU_Output)
   function TIU (C, R : Natural) return Natural is (C + 256 * R);

   --  Supervision status positions of the JRU records
   S_NoS  : constant := 0;
   S_IndS : constant := 1;
   S_IntS : constant := 4;

   --  One cycle of 100 ms at EM_V, moving ahead
   procedure EM_Cycle is
      Step_Cm : constant Integer_64 := Integer_64 (EM_V) / 10;
   begin
      Speed_Cms := Unsigned_16 (EM_V);
      if Step_Cm /= 0 then
         Feed_X (Step_Cm);
      end if;
      Sample (if EM_V > 0 then 1 else 0);
      Cycle_X;
      if Status_Brake /= 16#FFFF# then
         EM_Brake := Status_Brake;
         EM_Asked := EM_Asked or else EM_Brake = 2;
      end if;
      EM_JRU := EM_JRU + JRU_Count (EVC_Ports.JRU_Brake_Commands);
   end EM_Cycle;

   --  The start of Scenario_SDM_Mission with Q_NVEMRRLS = Q: the group
   --  read in Stand By, the standstill supervision's brake released with
   --  the acknowledgement, the MA supervised in CSM, the train at 0 m
   procedure EM_Start (Q : Natural; Tag : String) is
   begin
      Start_X (Start_Cm => (Mission_Group_M - 13) * 100);
      Mission_Track (Q_NVEMRRLS => Q);
      Bound_Per_Mille := 2;
      Run_X (-Integer_64 (EVC_Config.Default.Antenna_To_Cab_A), 100);
      Stand_X (500);
      Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 5, 0, 0, 0)));
      Stand_X (200);
      EM_V := 0;
      EM_Brake := 0;
      EM_Asked := False;
      EM_JRU := 0;
      Check (SI.Current.Supervise and then not Cmd.EB and then Res.Active
             and then Res.Monitoring = SDM.CSM
             and then SI.Current.National.Q_NVEMRRLS = (Q = 1),
             Tag & "packet 3 read with Q_NVEMRRLS =" & Img (Q)
             & ", the MA supervised in CSM, no brake");
   end EM_Start;

   function Tag_Of (What : String; Q : Natural) return String is
     ("EMRRLS " & What & " (Q_NVEMRRLS =" & Img (Q) & "): ");

   --  (a) 3.13.10.3.3 Tables 5, 6: ceiling speed monitoring at 140 km/h.
   --  The train accelerates at 1 m/s² through the SBI (146.85 km/h) to
   --  the EBI (149.75 km/h), then brakes at 1.5 m/s² to a stop. With 1
   --  the emergency brake goes with the service brake at 140 km/h (r1);
   --  with 0 only the service brake goes there and the emergency brake
   --  stays until standstill (r0). The emergency brake of 3.13.10 asks
   --  no acknowledgement (3.14.1.4; DMI 8.2.2.3.6: released without
   --  one): MSG_STATUS goes from 1 to 0, never 2, and an
   --  acknowledgement sent anyway changes nothing.
   procedure Scenario_EMRRLS_Ceiling is
      V_MRSP : constant Natural := Natural (Cms (140.0));
   begin
      for Q in 0 .. 1 loop
         declare
            Tag      : constant String := Tag_Of ("CSM", Q);
            Held     : Boolean := True;
            Rev_V    : Natural := 0;
            Rev_OK   : Boolean := False;
            After_OK : Boolean := True;
         begin
            EM_Start (Q, Tag);
            loop
               EM_V := EM_V + 10;
               EM_Cycle;
               exit when Cmd.EB or else EM_V > Natural (Cms (160.0));
            end loop;
            Check (Cmd.EB and then Cmd.SB and then Res.EB
                   and then Res.Monitoring = SDM.CSM
                   and then Res.Status = SDM.IntS
                   and then EM_V > Natural (Cms (149.75))
                   and then Cmd.Reasons = Only_SDM,
                   Tag & "t5: the emergency brake at"
                   & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V))) & " km/h, "
                   & "in CSM, Intervention");
            Check (TIU_Out = TIU (3, 1) and then Is_Record (3, 1, S_IntS)
                   and then EM_Brake = 1 and then EM_JRU = 2,
                   Tag & "TIU output EB + SB, reason 1; JRU 20 records "
                   & "the SB, then the EB and SB; MSG_STATUS brake 1");

            --  braking at 1.5 m/s² down to V_MRSP
            while EM_V > V_MRSP loop
               EM_V := EM_V - 15;
               EM_Cycle;
               if EM_V > V_MRSP then
                  Held := Held and then Cmd.EB and then Cmd.SB
                          and then TIU_Out = TIU (3, 1);
               end if;
            end loop;
            Check (Held, Tag & "the EB and the SB held above 140 km/h, the "
                   & "TIU output repeated every cycle");
            if Q = 1 then
               Check (not Cmd.EB and then not Cmd.SB and then not Res.EB
                      and then Res.Status = SDM.NoS
                      and then TIU_Out = TIU (0, 0)
                      and then Is_Record (0, 0, S_NoS)
                      and then EM_Brake = 0,
                      Tag & "r1: at" & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                      & " km/h, moving, the EB is revoked with the SB, "
                      & "Normal; TIU output 0 once, JRU 20 (0, 0), "
                      & "MSG_STATUS brake 0");
            else
               Check (Cmd.EB and then not Cmd.SB and then Res.EB
                      and then Res.Status = SDM.IntS
                      and then TIU_Out = TIU (1, 1)
                      and then Is_Record (1, 1, S_IntS)
                      and then EM_Brake = 1,
                      Tag & "r1: at" & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                      & " km/h the SB is revoked, the EB stays, "
                      & "Intervention; TIU output EB, JRU 20 (1, 1)");
            end if;

            --  on to a stop
            while EM_V > 0 loop
               EM_V := Natural'Max (EM_V - 15, 0);
               EM_Cycle;
               if EM_V > 0 then
                  if Q = 1 then
                     After_OK := After_OK and then not Cmd.EB
                                 and then TIU_Out = 16#FFFF#
                                 and then No_Record;
                  else
                     After_OK := After_OK and then Cmd.EB
                                 and then TIU_Out = TIU (1, 1)
                                 and then No_Record;
                  end if;
               elsif not Cmd.EB then
                  Rev_OK := True;
                  Rev_V := EM_V;
               end if;
            end loop;
            Check (After_OK,
                   Tag & (if Q = 1 then "nothing commanded any more on the "
                          & "way to the stop, no TIU output"
                          else "the EB held every cycle while moving, the "
                          & "TIU output repeated"));
            if Q = 0 then
               Check (Rev_OK and then Rev_V = 0
                      and then Res.Status = SDM.NoS
                      and then TIU_Out = TIU (0, 0)
                      and then Is_Record (0, 0, S_NoS)
                      and then EM_Brake = 0,
                      Tag & "r0: the EB revoked at standstill, Normal; "
                      & "TIU output 0 once, JRU 20 (0, 0), MSG_STATUS "
                      & "brake 0");
            else
               Check (Rev_OK and then TIU_Out = 16#FFFF# and then No_Record,
                      Tag & "at standstill nothing left to revoke");
            end if;
            Check (not EM_Asked and then not Cmd.Ack_Required
                   and then EM_JRU = (if Q = 1 then 3 else 4),
                   Tag & "no acknowledgement asked (3.14.1.4, DMI "
                   & "8.2.2.3.6);" & Img (EM_JRU) & " JRU 20 records");

            --  the driver acknowledges anyway: nothing happens
            Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_ACTION,
                               (2, 5, 0, 0, 0)));
            EM_Cycle;
            Check (not Cmd.EB and then TIU_Out = 16#FFFF# and then No_Record
                   and then EM_Brake = 0,
                   Tag & "an acknowledgement (kind 5) without a request "
                   & "changes nothing");
         end;
      end loop;
   end Scenario_EMRRLS_Ceiling;

   --  (b) 3.13.10.4.10 Tables 8, 10: target speed monitoring of the 100
   --  km/h MRSP target at 4 km (V_target /= 0). The train holds 135
   --  km/h into TSM; from the SBI its service brake is too weak (0.2
   --  m/s²: the SB does not fail, 3.14.1.2), so it reaches the EBI; then
   --  it brakes at 2 m/s² to a stop. The SB and the traction cut-off are
   --  revoked at the same cycle with both values, once r1 or r3 holds
   --  for the target (r3 here, at 102 km/h); the EB with them with 1, at
   --  standstill with 0.
   procedure Scenario_EMRRLS_Target is
      Cruise : constant Natural := Natural (Cms (135.0));
      V_SB_Revoked : array (0 .. 1) of Natural := (others => 0);
   begin
      for Q in 0 .. 1 loop
         declare
            Tag      : constant String := Tag_Of ("TSM", Q);
            SB_Seen  : Boolean := False;
            Held     : Boolean := True;
            Rev_Done : Boolean := False;
            Stop_OK  : Boolean := False;
            Front_M  : Integer_64 := 0;
         begin
            EM_Start (Q, Tag);
            for I in 1 .. 4_000 loop
               if Cmd.SB then
                  SB_Seen := True;
               end if;
               EM_V := (if SB_Seen then EM_V - 2
                        else Natural'Min (EM_V + 10, Cruise));
               EM_Cycle;
               exit when Cmd.EB;
            end loop;
            Front_M := (Train_Cm + Integer_64 (EVC_Config.Default.Antenna_To_Cab_A)) / 100;
            Check (Cmd.EB and then Res.EB and then Res.Monitoring = SDM.TSM
                   and then Res.Status = SDM.IntS
                   and then Speed_Frame.V_Target = 100
                   and then Front_M < 4_000
                   and then Cmd.Reasons = Only_SDM,
                   Tag & "t13: the EB at"
                   & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V))) & " km/h,"
                   & Integer_64'Image (Front_M) & " m, in TSM to the 100 "
                   & "km/h target, Intervention");
            Check (TIU_Out = TIU (7, 1) and then Is_Record (7, 1, S_IntS)
                   and then EM_Brake = 1,
                   Tag & "TIU output EB + SB + TCO, reason 1; JRU 20 "
                   & "(7, 1); MSG_STATUS brake 1");

            while EM_V > 0 loop
               EM_V := Natural'Max (EM_V - 20, 0);
               EM_Cycle;
               exit when EM_V = 0;
               if not Rev_Done and then not Cmd.SB then
                  --  the first cycle with r1 or r3 for the target
                  Rev_Done := True;
                  V_SB_Revoked (Q) := EM_V;
                  if Q = 1 then
                     Check (not Cmd.EB and then not Cmd.TCO
                            and then not Res.EB
                            and then Res.Monitoring = SDM.TSM
                            and then Res.Status = SDM.IndS
                            and then EVC_Fixed.Num (EM_V) <= Res.V_MRSP
                            and then TIU_Out = TIU (0, 0)
                            and then Is_Record (0, 0, S_IndS)
                            and then EM_Brake = 0,
                            Tag & "r1/r3: at"
                            & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                            & " km/h, moving, in TSM, the EB is revoked "
                            & "with the SB and the TCO, Indication; TIU "
                            & "output 0 once, JRU 20 (0, 0), MSG_STATUS "
                            & "brake 0");
                  else
                     Check (Cmd.EB and then not Cmd.TCO and then Res.EB
                            and then Res.Monitoring = SDM.TSM
                            and then Res.Status = SDM.IntS
                            and then TIU_Out = TIU (1, 1)
                            and then Is_Record (1, 1, S_IntS)
                            and then EM_Brake = 1,
                            Tag & "r1/r3: at"
                            & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                            & " km/h the SB and the TCO are revoked, the "
                            & "EB stays, Intervention; TIU output EB, JRU "
                            & "20 (1, 1)");
                  end if;
               elsif Rev_Done then
                  Held := Held
                    and then (if Q = 1
                              then not Cmd.EB and then TIU_Out = 16#FFFF#
                              else Cmd.EB and then TIU_Out = TIU (1, 1))
                    and then No_Record;
               end if;
            end loop;
            if not Cmd.EB then
               Stop_OK := True;
            end if;
            Check (Rev_Done and then Held,
                   Tag & (if Q = 1 then "then nothing commanded on the way "
                          & "to the stop"
                          else "then the EB held every cycle while moving"));
            if Q = 0 then
               Check (Stop_OK and then TIU_Out = TIU (0, 0)
                      and then Brake_Record.Found
                      and then Brake_Record.Commands = 0
                      and then Brake_Record.Reasons = 0
                      and then Res.Status /= SDM.IntS
                      and then EM_Brake = 0,
                      Tag & "r0: the EB revoked at standstill; TIU output 0 "
                      & "once, JRU 20 (0, 0), MSG_STATUS brake 0");
            else
               Check (Stop_OK and then TIU_Out = 16#FFFF# and then No_Record,
                      Tag & "at standstill nothing left to revoke");
            end if;
            Check (not EM_Asked and then not Cmd.Ack_Required,
                   Tag & "no acknowledgement asked;" & Img (EM_JRU)
                   & " JRU 20 records");
         end;
      end loop;
      Check (V_SB_Revoked (0) = V_SB_Revoked (1)
             and then V_SB_Revoked (0) > 0,
             "EMRRLS TSM: the SB and the TCO revoked at the same speed with "
             & "both values (" & Img_LF (Kmh_Of
               (EVC_Fixed.Num (V_SB_Revoked (0)))) & " km/h)");
   end Scenario_EMRRLS_Target;

   --  From EM_Start to the end of the line: the driver keeps 3 km/h
   --  below the Permitted speed; once it is down to 35 km/h in TSM
   --  (the EOA with its release speed of 25 km/h ahead), the train
   --  accelerates at 2 m/s² to the EBI of the EOA: the EB, with the SB
   --  and the traction cut-off, in TSM (Table 9)
   procedure EM_To_EOA_EB (Tag : String) is
      Near : Boolean := False;
   begin
      for I in 1 .. 6_000 loop
         declare
            P : constant Natural :=
              Natural (EVC_Fixed.Max
                         (Res.V_Perm - EVC_Fixed.Num (Cms (3.0)), 0));
         begin
            if not Near and then Res.Monitoring = SDM.TSM
              and then Res.V_Perm <= EVC_Fixed.Num (Cms (35.0))
              and then Res.V_Perm > 0
            then
               Near := True;
            end if;
            if Near then
               EM_V := EM_V + 20;
            elsif EM_V > P then
               EM_V := Natural'Max (EM_V - 8, P);
            else
               EM_V := Natural'Min (EM_V + 10, P);
            end if;
         end;
         EM_Cycle;
         exit when Cmd.EB or else Res.Monitoring = SDM.RSM;
      end loop;
      Check (Near and then Cmd.EB and then Res.EB
             and then Res.Monitoring = SDM.TSM
             and then Cmd.Reasons = Only_SDM
             and then TIU_Out = TIU (7, 1)
             and then Is_Record (7, 1, S_IntS),
             Tag & "the EB triggered in TSM at"
             & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V))) & " km/h,"
             & Integer_64'Image
                 ((Train_Cm + Integer_64 (EVC_Config.Default.Antenna_To_Cab_A)) / 100)
             & " m, approaching the EOA, with the SB and the TCO; JRU 20 "
             & "(7, 1)");
   end EM_To_EOA_EB;

   --  (b) continued, 3.13.10.4.10 Tables 9, 11: the EOA with a release
   --  speed of 25 km/h (V_release /= 0) as the target. From the EB of
   --  EM_To_EOA_EB the train brakes at 3 m/s² to a stop. The SB and the
   --  traction cut-off are revoked in TSM once r1 or r3 holds for the
   --  EOA and the SvL, with both values; the EB with them with 1, at
   --  standstill with 0.
   procedure Scenario_EMRRLS_EOA_Target is
      V_Revoked : array (0 .. 1) of Natural := (others => 0);
   begin
      for Q in 0 .. 1 loop
         declare
            Tag      : constant String := Tag_Of ("TSM to the EOA", Q);
            Rev_Done : Boolean := False;
            Held     : Boolean := True;
         begin
            EM_Start (Q, Tag);
            EM_To_EOA_EB (Tag);
            while EM_V > 0 loop
               EM_V := Natural'Max (EM_V - 30, 0);
               EM_Cycle;
               exit when EM_V = 0;
               if not Rev_Done and then not Cmd.SB then
                  Rev_Done := True;
                  V_Revoked (Q) := EM_V;
                  if Q = 1 then
                     Check (not Cmd.EB and then not Cmd.TCO
                            and then not Res.EB
                            and then Res.Monitoring = SDM.TSM
                            and then Res.Status = SDM.IndS
                            and then TIU_Out = TIU (0, 0)
                            and then Is_Record (0, 0, S_IndS)
                            and then EM_Brake = 0,
                            Tag & "r1/r3: at"
                            & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                            & " km/h, moving, in TSM, the EB is revoked "
                            & "with the SB and the TCO, Indication; TIU "
                            & "output 0 once, JRU 20 (0, 0), MSG_STATUS "
                            & "brake 0");
                  else
                     Check (Cmd.EB and then not Cmd.TCO and then Res.EB
                            and then Res.Monitoring = SDM.TSM
                            and then Res.Status = SDM.IntS
                            and then TIU_Out = TIU (1, 1)
                            and then Is_Record (1, 1, S_IntS)
                            and then EM_Brake = 1,
                            Tag & "r1/r3: at"
                            & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                            & " km/h, in TSM, the SB and the TCO are "
                            & "revoked, the EB stays, Intervention; TIU "
                            & "output EB, JRU 20 (1, 1)");
                  end if;
               elsif Rev_Done then
                  Held := Held
                    and then (if Q = 1
                              then not Cmd.EB and then TIU_Out = 16#FFFF#
                              else Cmd.EB and then TIU_Out = TIU (1, 1))
                    and then No_Record;
               end if;
            end loop;
            Check (Rev_Done and then Held,
                   Tag & (if Q = 1 then "then nothing commanded on the way "
                          & "to the stop"
                          else "then the EB held every cycle while moving"));
            Check (not Cmd.EB and then EM_Brake = 0
                   and then not Res.EOA_Passed
                   and then (if Q = 0
                             then TIU_Out = TIU (0, 0)
                                  and then Brake_Record.Found
                                  and then Brake_Record.Commands = 0
                                  and then Brake_Record.Reasons = 0
                             else TIU_Out = 16#FFFF# and then No_Record),
                   Tag & (if Q = 0 then "r0: the EB revoked at standstill"
                          & " (" & SDM.Monitoring_T'Image (Res.Monitoring)
                          & "); TIU output 0 once, JRU 20 (0, 0)"
                          else "at standstill nothing left to revoke")
                   & ", before the EOA");
            Check (not EM_Asked and then not Cmd.Ack_Required,
                   Tag & "no acknowledgement asked;" & Img (EM_JRU)
                   & " JRU 20 records");
         end;
      end loop;
      Check (V_Revoked (0) = V_Revoked (1) and then V_Revoked (0) > 0,
             "EMRRLS TSM to the EOA: the SB and the TCO revoked at the "
             & "same speed with both values (" & Img_LF (Kmh_Of
               (EVC_Fixed.Num (V_Revoked (0)))) & " km/h)");
   end Scenario_EMRRLS_EOA_Target;

   --  (c) 3.13.10.5.4 Tables 13, 14 and 3.13.10.6.2: release speed
   --  monitoring at the EOA (release speed 25 km/h). After the EB of
   --  EM_To_EOA_EB the train does not brake before the RSM start: the
   --  EB is carried into RSM (the SB and the traction cut-off go at the
   --  transition, 3.13.10.6.3, .4) and held there below the release
   --  speed and V_MRSP with both values: RSM has no revocation but at
   --  standstill (Q_NVEMRRLS is for CSM and TSM, 7.5.1.123). Then from
   --  the stop the train moves again at 20 km/h, 30 km/h triggers the EB
   --  in RSM (t2), and it too holds at 20 km/h until standstill.
   procedure Scenario_EMRRLS_Release is
      V_Rel : constant Natural := Natural (Cms (25.0));
   begin
      for Q in 0 .. 1 loop
         declare
            Tag       : constant String := Tag_Of ("RSM", Q);
            Carried   : Boolean := False;
            Held      : Boolean := True;
            Held_2    : Boolean := True;
            Front_M   : Integer_64 := 0;
         begin
            EM_Start (Q, Tag);
            EM_To_EOA_EB (Tag);
            --  not braking until the RSM start
            for I in 1 .. 600 loop
               exit when Res.Monitoring = SDM.RSM;
               EM_Cycle;
               Held := Held and then Cmd.EB;
            end loop;
            Carried := Res.Monitoring = SDM.RSM and then Cmd.EB;
            Front_M := (Train_Cm + Integer_64 (EVC_Config.Default.Antenna_To_Cab_A)) / 100;
            Check (Carried and then Held and then not Cmd.SB
                   and then not Cmd.TCO and then TIU_Out = TIU (1, 1)
                   and then Is_Record (1, 1, S_IntS),
                   Tag & "3.13.10.6.2 to .4: RSM entered at"
                   & Integer_64'Image (Front_M) & " m,"
                   & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                   & " km/h, the EB of TSM kept, the SB and the TCO revoked"
                   & " at once; JRU 20 (1, 1)");
            --  braking at 3 m/s² to 20 km/h, then 2 s at 20 km/h
            Held := True;
            while EM_V > Natural (Cms (20.0)) loop
               EM_V := Natural'Max (EM_V - 30, Natural (Cms (20.0)));
               EM_Cycle;
               Held := Held and then Cmd.EB;
            end loop;
            for I in 1 .. 20 loop
               EM_Cycle;
               Held := Held and then Cmd.EB and then Res.EB
                       and then Res.Monitoring = SDM.RSM
                       and then EM_V <= V_Rel
                       and then EVC_Fixed.Num (EM_V) <= Res.V_MRSP
                       and then Res.Status = SDM.IntS
                       and then TIU_Out = TIU (1, 1) and then No_Record
                       and then EM_Brake = 1;
            end loop;
            Check (Held,
                   Tag & "Table 14: at 20 km/h, below the release speed and "
                   & "V_MRSP, moving, the EB held in RSM every cycle, "
                   & "TIU output EB, MSG_STATUS brake 1");
            while EM_V > 0 loop
               EM_V := Natural'Max (EM_V - 20, 0);
               EM_Cycle;
               exit when EM_V = 0;
               Held := Held and then Cmd.EB;
            end loop;
            Check (Held and then not Cmd.EB and then Res.Monitoring = SDM.RSM
                   and then Res.Status = SDM.IndS
                   and then TIU_Out = TIU (0, 0)
                   and then Is_Record (0, 0, S_IndS)
                   and then EM_Brake = 0,
                   Tag & "r0: revoked at standstill only, Indication, "
                   & "still RSM; TIU output 0 once, JRU 20 (0, 0), "
                   & "MSG_STATUS brake 0");

            --  t2 in RSM
            for I in 1 .. 5 loop
               EM_V := Natural'Min (EM_V + 20, Natural (Cms (20.0)));
               EM_Cycle;
            end loop;
            Check (not Cmd.EB and then Res.Monitoring = SDM.RSM,
                   Tag & "RSM: moving on at 20 km/h, no command");
            EM_V := Natural (Cms (30.0));
            EM_Cycle;
            Check (Cmd.EB and then Res.Status = SDM.IntS
                   and then TIU_Out = TIU (1, 1)
                   and then Is_Record (1, 1, S_IntS) and then EM_Brake = 1,
                   Tag & "t2: 30 km/h above the release speed, the EB; TIU "
                   & "output EB, JRU 20 (1, 1), MSG_STATUS brake 1");
            EM_V := Natural (Cms (20.0));
            for I in 1 .. 5 loop
               EM_Cycle;
               Held_2 := Held_2 and then Cmd.EB and then Res.EB
                         and then TIU_Out = TIU (1, 1) and then No_Record;
            end loop;
            EM_V := 0;
            EM_Cycle;
            Front_M := (Train_Cm + Integer_64 (EVC_Config.Default.Antenna_To_Cab_A)) / 100;
            Check (Held_2 and then not Cmd.EB
                   and then TIU_Out = TIU (0, 0)
                   and then Is_Record (0, 0, S_IndS)
                   and then EM_Brake = 0 and then not Res.EOA_Passed,
                   Tag & "Table 14: held at 20 km/h, revoked at the stop"
                   & Integer_64'Image (Front_M) & " m, before the EOA");
            Check (not EM_Asked and then not Cmd.Ack_Required,
                   Tag & "no acknowledgement asked;" & Img (EM_JRU)
                   & " JRU 20 records");
         end;
      end loop;
   end Scenario_EMRRLS_Release;

   --  (d) 3.14.1.4, 3.14.1.5, 3.14.1.9, 3.14.1.10: the EB of the speed
   --  and distance monitoring together with a brake that asks the
   --  driver's acknowledgement. As (a) with the direction controller
   --  forwards; while the EB is commanded the driver puts it in neutral
   --  and the moving train runs more than D_NVROLL (2 m): the roll away
   --  protection brakes too (3.14.2.3). Below 140 km/h the speed and
   --  distance monitoring's EB goes with 1 and the EB stays for the roll
   --  away reason; with 0 both stay. At standstill the monitoring's EB
   --  is revoked in both, the acknowledgement is asked (MSG_STATUS brake
   --  2), an acknowledgement before the stop did nothing, and the DMI's
   --  acknowledgement (MSG_DRIVER_ACTION 2, kind 5, as the bench sends
   --  it) releases the EB.
   procedure Scenario_EMRRLS_Acknowledgement is
      V_MRSP : constant Natural := Natural (Cms (140.0));
      Ack    : constant Byte_Array :=
        Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 5, 0, 0, 0));
   begin
      Check (Ack'Length = Sim_Onboard_Env.Brake_Release_Ack'Length
             and then (for all I in Ack'Range =>
                         Natural (Ack (I))
                         = Natural (Sim_Onboard_Env.Brake_Release_Ack
                                      (Sim_Onboard_Env.Brake_Release_Ack'First
                                       + Stream_Element_Offset
                                           (I - Ack'First)))),
             "EMRRLS: the acknowledgement is the bench's Brake_Release_Ack");
      for Q in 0 .. 1 loop
         declare
            Tag   : constant String := Tag_Of ("with roll away", Q);
            Early : Boolean := False;
            Held  : Boolean := True;
         begin
            EM_Start (Q, Tag);
            Input (TIU, (6, 1));
            loop
               EM_V := EM_V + 10;
               EM_Cycle;
               exit when Cmd.EB or else EM_V > Natural (Cms (160.0));
            end loop;
            Input (TIU, (6, 0));
            for I in 1 .. 3 loop
               EM_Cycle;
            end loop;
            Check (Cmd.EB and then Res.EB
                   and then Cmd.Reasons = SDM_And_Roll_Away
                   and then TIU_Out = TIU (3, 1 + 4) and then EM_Brake = 1,
                   Tag & "the EB of CSM and of the roll away protection "
                   & "(neutral, 3.14.2.3); TIU output EB + SB, reasons 1 "
                   & "and 4");
            while EM_V > V_MRSP loop
               EM_V := EM_V - 15;
               EM_Cycle;
            end loop;
            if Q = 1 then
               Check (Cmd.EB and then not Cmd.SB and then not Res.EB
                      and then Res.Status = SDM.NoS
                      and then Cmd.Reasons = Only_Roll_Away
                      and then TIU_Out = TIU (1, 4)
                      and then Is_Record (1, 4, S_NoS)
                      and then EM_Brake = 1,
                      Tag & "r1: the monitoring's EB and SB revoked at"
                      & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                      & " km/h, the EB stays for the roll away; TIU output"
                      & " EB reason 4, JRU 20 (1, 4)");
            else
               Check (Cmd.EB and then not Cmd.SB and then Res.EB
                      and then Res.Status = SDM.IntS
                      and then TIU_Out = TIU (1, 1 + 4)
                      and then Is_Record (1, 1 + 4, S_IntS)
                      and then EM_Brake = 1,
                      Tag & "r1: the SB revoked at"
                      & Img_LF (Kmh_Of (EVC_Fixed.Num (EM_V)))
                      & " km/h, the EB stays for both reasons; TIU output "
                      & "EB reasons 1 and 4, JRU 20 (1, 5)");
            end if;
            --  an acknowledgement while moving does nothing (3.14.1.9)
            Input (DMI, Ack);
            EM_V := EM_V - 15;
            EM_Cycle;
            Early := Cmd.EB and then not Cmd.Ack_Required;
            while EM_V > 0 loop
               EM_V := Natural'Max (EM_V - 15, 0);
               EM_Cycle;
               exit when EM_V = 0;
               Held := Held and then Cmd.EB and then EM_Brake = 1;
            end loop;
            Check (Early and then Held,
                   Tag & "an acknowledgement while moving does nothing, "
                   & "the EB held to the stop, MSG_STATUS brake 1");
            Check (Cmd.EB and then not Res.EB and then Cmd.Ack_Required
                   and then Cmd.Reasons = Only_Roll_Away
                   and then TIU_Out = TIU (1, 4)
                   and then (if Q = 0 then Is_Record (1, 4, S_NoS)
                             else No_Record)
                   and then EM_Brake = 2,
                   Tag & "at standstill the monitoring's EB is revoked"
                   & (if Q = 0 then " (r0, JRU 20 (1, 4))" else "")
                   & ", the roll away's waits: MSG_STATUS brake 2, the "
                   & "acknowledgement asked");
            Input (DMI, Ack);
            EM_Cycle;
            Check (not Cmd.EB and then not Cmd.Ack_Required
                   and then TIU_Out = TIU (0, 0)
                   and then Is_Record (0, 0, S_NoS)
                   and then EM_Brake = 0,
                   Tag & "the acknowledgement (kind 5) releases the EB; "
                   & "TIU output 0 once, JRU 20 (0, 0), MSG_STATUS brake 0");
            EM_Cycle;
            Check (not Cmd.EB and then TIU_Out = 16#FFFF#,
                   Tag & "then nothing on the TIU");
         end;
      end loop;
   end Scenario_EMRRLS_Acknowledgement;

   --  The installation configuration (EVC_Config): data, not code. The
   --  byte image and its checks, EVC_Core.Configure, and for every field
   --  that the supervision or the position reads, what it changes

end EVC_Test_EMRRLS;
