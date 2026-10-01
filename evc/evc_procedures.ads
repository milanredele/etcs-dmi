--  ETCS on-board (EVC)
--  The procedures of SUBSET-026 chapter 5 that phase E4 implements in its
--  second half (doc/EVC-PLAN.md §10, branch e4/procedures): shunting
--  initiated by the driver and ordered by the trackside (5.6, 5.7) with
--  Passive Shunting, override (5.8, the override function related speed
--  restriction of 3.11.10), On Sight (5.9), train trip and post trip
--  (5.11), reversing (5.13), Limited Supervision (5.19), supervised
--  manoeuvre (its exit, 5.21), the inhibition of the balise
--  transmission alarm reaction (5.22) and the mode related speed
--  restrictions of 3.11.7. The text messages of 3.12.3 are
--  EVC_Text_Messages.
--
--  The joint with the mode machine. A transition of 4.6.2 is taken by
--  the mode machine of EVC_Core when one of its conditions of 4.6.3
--  holds (EVC_Transition_Conditions.Holds). The conditions of this half
--  are computed here once per cycle by Evaluate, between the speed and
--  distance monitoring and the mode machine, and read with Condition;
--  after the mode machine EVC_Core calls Mode_Changed with the mode left
--  and the mode entered, and the procedures do what entering the mode
--  means for them (the trip of 5.11 A025 / A035, the end of override
--  5.8.4.1 i, the acknowledgement asked after an entry, the brake
--  reasons revoked or kept by 4.12).
--
--  One cycle (Evaluate), with the context of the cycle (Context_T, what
--  EVC_Core knows of the mode, the level, the desk and the train
--  interface), the snapshot the supervision read and its result:
--    1. the packets of the balise groups taken into account in the
--       cycle that the procedures own: danger for shunting (132, "stop
--       if in shunting"), stop shunting on desk opening (135), the list
--       of balise groups for the SH area (49), stop if in SR (137), the
--       reversing area (138) and supervision (139), and the text
--       messages (73, 74, to EVC_Text_Messages);
--    2. the override function (5.8): selection (5.8.2.1), the former
--       EOA (5.8.3.1.1), its end conditions (5.8.4.1 a to h);
--    3. the mode profile (3.12.4) against the train position: which
--       On Sight, Limited Supervision or Shunting area the train
--       position confidence interval overlaps, the furthest one, the
--       acknowledgement areas, the requests for acknowledgement (the
--       "rectangle" of 5.7.3.2, 5.9.3.2, 5.19.3.2), never taken back
--       (5.7.3.3, 5.9.3.4, 5.19.3.4);
--    4. the trip conditions (the EOA passed, the trip order, the linking
--       reactions, the balise groups of a shunting area, the system
--       version, the track description) and the reaction of a linking
--       error set to the service brake (3.16.2.3, 3.14.1.6);
--    5. the post trip supervision (4.4.14.1.3), the reversing (5.13,
--       3.15.4), the inhibition of the BTM alarm reaction (5.22);
--    6. the conditions of 4.6.3 of this half.
--  After the mode machine, Brake_Demand is what the procedures command
--  (3.14.1.3, 3.14.1.6, 3.14.1.7.1, 3.14.1.7.3, 3.14.1.7.4, 4.4.13.1.2),
--  and the queries below what the DMI and the JRU are told.
--
--  Positions are frame positions of the odometer frame (EVC_Distances),
--  "ahead" the sense of the snapshot (EVC_Supervision_Input). The
--  locations the procedures keep (the former EOA, the reversing area, the
--  start of the post trip movement) are frame positions taken when the
--  information is received or the procedure starts, not relocated with
--  the reference balise group: a choice, the relocation moves a location
--  by less than the confidence interval it already had.
--
--  Not in this unit, with the phase that brings it: the RBC parts (the
--  Shunting and Supervised Manoeuvre requests of level 2, the
--  unconditional emergency stop [20], T_NVCONTACT [41], the balise beyond
--  the EOA in release speed monitoring [11]: E5); the level transitions
--  ([34], [61], [71] read Context_T.Level_Switched, which the modes half
--  sets); the National System ([35], [38], [63] in level NTC: out of
--  scope, PLAN.md); the SR distance and the list of balise groups in SR
--  authority ([36], [42]: the SR mode of the modes half).

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Brake_Commands;
with EVC_Distances;         use EVC_Distances;
with EVC_Modes;             use EVC_Modes;
with EVC_Movement_Authority;
with EVC_Origins;
with EVC_Position;
with EVC_Procedure_Requests;
with EVC_SDM;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with EVC_Track_Conditions;
with EVC_Track_Description;
with Interfaces;            use Interfaces;

package EVC_Procedures
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   ---------------------------------------------------------------------
   --  The context of a cycle
   ---------------------------------------------------------------------

   type Context_T is record
      Mode             : Mode_T := M_SB;
      --  the stored level and whether it is valid (5.4.3.2 D2)
      Level_Valid      : Boolean := False;
      Level            : Level_T := L0;
      --  4.6.3 [34], [61], [71]: the level switched to 1 or 2 in this
      --  cycle (the level transitions of the modes half; False until
      --  then)
      Level_Switched   : Boolean := False;
      --  a desk is open (SUBSET-034 2.5.1: a cab is active)
      Desk_Open        : Boolean := False;
      --  SUBSET-034 2.2.2: "Passive shunting permitted"
      Passive_Shunting : Boolean := False;
      --  SUBSET-034 2.5.2: the direction controller of the active desk
      Controller       : EVC_Brake_Commands.Controller_T :=
        EVC_Brake_Commands.Unknown;
      --  3.18.3: valid Train Data are stored; 3.18.4 the train running
      --  number is valid (5.8.2.1 c)
      Train_Data_Valid : Boolean := True;
      TRN_Valid        : Boolean := True;
      --  the speed the override is compared with (5.8.2.1 a): the upper
      --  bound of the odometer's speed
      Speed_Max        : Speed_Cms_T := 0;
      --  the balise antenna from the front end of the engine, cm (the
      --  min safe antenna position of [12] and [43])
      Antenna_Offset   : Length_T := 0;
      --  3.14.1.5 kind of acknowledgement of a brake release (DMI ack
      --  kind 5) in this cycle that the brake commands of 3.14.1.5 did
      --  not take (EVC_Core)
      Brake_Release_Ack : Boolean := False;
      --  the on-board time, ms
      Now_Ms           : Unsigned_64 := 0;
      --  5.17.2.2 E0: a change of the input information from the train
      --  interface that affects Train Data in this cycle (EVC_Ports, TIU
      --  input 13), whether the data need the driver's validation (D0)
      --  and whether they are the train category, axle load category,
      --  traction systems or loading gauge (D1)
      TD_Change        : Boolean := False;
      TD_Validation    : Boolean := False;
      TD_Category      : Boolean := False;
   end record;

   ---------------------------------------------------------------------
   --  The conditions of 4.6.3 this half computes
   ---------------------------------------------------------------------

   subtype Condition_T is Positive range 1 .. 84;

   --  Whether condition C of 4.6.3 holds in the cycle (computed by
   --  Evaluate; the conditions of the other half are False here)
   function Condition (C : Condition_T) return Boolean
     with Global => State;

   ---------------------------------------------------------------------
   --  Train trip (5.11)
   ---------------------------------------------------------------------

   --  The reason of the train trip (4.4.13.1.3), with the condition of
   --  4.6.3 it comes from
   type Trip_Reason_T is
     (No_Trip,
      EOA_Passed,            -- [12], [16]
      Trip_Order,            -- [18]
      Former_EOA_Passed,     -- [43]
      Linking_Error,         -- [17]
      Wrong_Direction,       -- [66]
      SH_Stop_Order,         -- [49]
      SH_Balise_Not_Listed,  -- [52]
      SR_Stop_Order,         -- [54]
      Version_Not_Supported, -- [65]
      No_Track_Description); -- [69]

   function Trip_Reason return Trip_Reason_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Override (5.8)
   ---------------------------------------------------------------------

   function Override_Active return Boolean
     with Global => State;

   ---------------------------------------------------------------------
   --  What the DMI is told
   ---------------------------------------------------------------------

   --  A request for the acknowledgement of a mode is displayed (On
   --  Sight, Shunting, Limited Supervision, Reversing, Trip)
   function Ack_Requested return Boolean
     with Global => State;
   function Ack_Mode return Mode_T
     with Global => State;

   --  5.8.3.7: the status "override active"
   function Override_Indicated return Boolean
     with Global => State;

   --  5.17.2.2 S6: the driver is requested to re-enter or re-validate
   --  the Train Data (the Train Data entry of the start of mission, the
   --  modes half, shows it; E6, the data validated, ends the request
   --  there: Train_Data_Revalidated)
   function Train_Data_Revalidation return Boolean
     with Global => State;

   --  3.15.4.7: reversing is permitted (MSG_STATUS reversing)
   function Reversing_Possible return Boolean
     with Global => State;

   --  5.22.4.1: the inhibition of the BTM alarm reaction is active
   --  (MSG_ONBOARD train bit 4)
   function BMM_Inhibited return Boolean
     with Global => State;

   --  The system status messages of the catalogue of DMI chapter 15
   --  that started or ended in the cycle (MSG_SYSTEM_STATUS: entry, event
   --  0 start, 1 end, 2 the event that starts its 30 s)
   Max_Status_Events : constant := 8;
   type Status_Event_T is record
      Entry_Number : Natural range 0 .. 255 := 0;
      Event        : Natural range 0 .. 2 := 0;
   end record;
   function Status_Event_Count return Natural
     with Global => State,
          Post => Status_Event_Count'Result <= Max_Status_Events;
   function Status_Event (I : Positive) return Status_Event_T
     with Global => State,
          Pre => I <= Status_Event_Count;

   ---------------------------------------------------------------------
   --  What the train interface is told
   ---------------------------------------------------------------------

   --  The brake commands of the procedures, with their reasons
   type Brake_Demand_T is record
      EB              : Boolean := False;
      SB              : Boolean := False;
      --  3.14.1.3, 4.4.13.1.2: the trip
      Trip            : Boolean := False;
      --  3.14.1.7.3: a mode change ordered from trackside not
      --  acknowledged (the brake indication "applied because an
      --  acknowledgement is pending", MSG_STATUS brake 3)
      Ack_Missing     : Boolean := False;
      --  3.14.1.6, 3.14.1.7.1, 3.14.1.7.4: the linking reaction, the
      --  reverse movement distances of RV and PT; 5.17.2.2 S2, S4: the
      --  Train Data changed by another source
      Other           : Boolean := False;
      --  3.14.1.9: the acknowledgement of the release is asked
      Ack_Required    : Boolean := False;
   end record;

   function Brake_Demand return Brake_Demand_T
     with Global => State,
          Post => (if Brake_Demand'Result.Trip
                   then Brake_Demand'Result.EB);

   ---------------------------------------------------------------------
   --  The mode related speed restrictions (3.11.7, 3.11.10)
   ---------------------------------------------------------------------

   --  The ceiling of the MRSP of the mode M: the national value of the
   --  mode, or the speed the trackside gave (3.11.7.1.1: the mode
   --  profile; 3.11.7.1.2: the reversing supervision information), under
   --  the override speed while the override function is active
   --  (3.11.10.1, only in levels 0, 1 and 2: 5.8.3.6); No_Speed_Limit
   --  for a mode without one
   function Mode_Speed (M : Mode_T; NV : National_Values_T)
     return Speed_Cms_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Juridical recording (EVC_Ports: event 23, procedures)
   ---------------------------------------------------------------------

   Max_Events : constant := 8;
   type Event_T is record
      Kind, B3, B4 : Unsigned_8 := 0;
   end record;
   function Event_Count return Natural
     with Global => State,
          Post => Event_Count'Result <= Max_Events;
   function Event (I : Positive) return Event_T
     with Global => State,
          Pre => I <= Event_Count;

   --  The kinds of event 23 (byte 2): 1 train trip (byte 3 the reason,
   --  Trip_Reason_T'Pos), 2 override started (byte 3 1: started again,
   --  5.8.3.9), 3 override ended (byte 3 the condition of 5.8.4.1, 1 for
   --  a) .. 9 for i)), 4 acknowledgement requested (byte 3 the mode,
   --  Mode_T'Pos; byte 4 1: after the transition, with the service brake
   --  after T_ACK), 5 acknowledged, 6 brake of the procedures commanded
   --  or released (byte 3 EB, byte 4 SB), 7 shunting information (byte 3
   --  1 stop shunting on desk opening stored, 2 a list of balise groups
   --  for the SH area stored, byte 4 its length; 3 danger for shunting
   --  "stop"), 8 reversing (byte 3 1 area stored, 2 supervision stored,
   --  3 reversing possible, 4 the distance overpassed), 9 BTM alarm
   --  reaction inhibition (byte 3 1 started, 0 ended), 10 post trip
   --  distance overpassed, 11 Train Data changed by another source
   --  (5.17: byte 3 1 the change detected, 2 the driver informed (A1),
   --  3 the service brake commanded (S2, S4), 4 released (A5, A6), 5
   --  the re-validation requested (S6), 6 considered changed (A7))
   Event_Trip           : constant := 1;
   Event_Override_Start : constant := 2;
   Event_Override_End   : constant := 3;
   Event_Ack_Request    : constant := 4;
   Event_Ack_Given      : constant := 5;
   Event_Brake          : constant := 6;
   Event_Shunting       : constant := 7;
   Event_Reversing      : constant := 8;
   Event_BMM            : constant := 9;
   Event_PT_Distance    : constant := 10;
   Event_Train_Data     : constant := 11;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: no procedure running, nothing stored
   procedure Clear
     with Global => (Output => State),
          Post => not Override_Active and then not Ack_Requested
                  and then Trip_Reason = No_Trip
                  and then (for all C in Condition_T => not Condition (C));

   --  3.17.3.5, 4.6.3 [65]: a balise telegram of a system version X above
   --  the highest this on-board supports was received in the cycle
   --  (EVC_Core, when the ports are read)
   procedure Note_Version_Not_Supported
     with Global => (In_Out => State);

   --  5.17.2.2 E6: the Train Data were validated by the driver while
   --  the re-validation was requested (the modes half calls it with the
   --  Train Data entry); A7 follows
   procedure Train_Data_Revalidated
     with Global => (In_Out => State),
          Post => not Train_Data_Revalidation;

   --  One cycle (see above)
   procedure Evaluate (C   : Context_T;
                       S   : Snapshot_T;
                       SDM : EVC_SDM.Result_T)
     with Global => (In_Out => (State,
                                --  5.16: the substitution of a level
                                --  crossing not protected
                                EVC_Track_Description.State),
                     Input  => (EVC_Position.State, EVC_Origins.State,
                                EVC_Movement_Authority.State,
                                EVC_Procedure_Requests.State,
                                EVC_Track_Conditions.State));

   --  The mode machine took the transition From -> To in this cycle
   --  (From /= To), the context of the cycle
   procedure Mode_Changed (From, To : Mode_T; C : Context_T;
                           S : Snapshot_T)
     with Global => (In_Out => State),
          Post => (if To = M_TR then Brake_Demand.EB);

   --  The brake demand and the outputs after the mode machine, in the
   --  mode of the end of the cycle
   procedure Finish_Cycle (C : Context_T; Mode : Mode_T; S : Snapshot_T)
     with Global => (In_Out => State),
          Post => (if Mode = M_TR then Brake_Demand.EB);

end EVC_Procedures;
