--  ETCS on-board (EVC)
--  JRU events that follow SUBSET-027 messages one to one (the event
--  number is the NID_MESSAGE_JRU of the message, EVC_Ports):
--
--     11 driver's action (4.2.4.11): byte 2 M_DRIVERACTIONS, for the
--        actions no other event of the on-board records (Action_Code,
--        Ack_Code; the start, the levels, the mode acknowledgements,
--        override, maintain shunting, isolation and BMM have their own);
--     13 radio error: byte 2 M_ERROR (SUBSET-026
--        7.5.1.64), recorded when a radio message is found inconsistent
--        and reported to the RBC (3.16.3.1.1.2, EVC_Sessions.Error_Noted);
--     38 cab status (4.2.4.38): byte 2 M_CAB_A_STATUS, byte 3 Q_CAB_B (1:
--        this on-board has two cabs, EVC_Ports TIU inputs 1 and 2), byte
--        4 M_CAB_B_STATUS; recorded when the status received from the
--        train interface (SUBSET-034 2.5.1) changes, and at the first
--        one received after the power-up;
--     45 track conditions (4.2.4.45): byte 2 M_TRACKCOND_TI, byte 3 the
--        phase of the item (0 its start ahead of the max safe front end:
--        D_MAXSFE_TO_START given; 1 the start passed, "not relevant"
--        -32768, and its end not; 2 its end passed), byte 4 its id;
--        recorded when an item of the information for the external
--        functions of 5.20 (the second TIU output) appears or changes its
--        phase;
--     30, 31, 39 the sleeping input (4.2.4.30: byte 2 M_SLEEPING), the
--        passive shunting input (.31: M_PASSIVE_SHUNTING), the direction
--        controller (.39: M_DIRECTION_CONTROLLER, Direction_Code), and
--     132 the non leading input (4.2.4.32: byte 2 M_NON_LEADING; 32 is
--        the stored information's event), recorded when the input from
--        the train interface (SUBSET-034 2.2.1 to 2.2.3, 2.5.2) is first
--        known and when it changes (Inputs);
--     51 remote shunting state (4.2.4.51): byte 2 M_REMOTE_SHUNTING_STATE,
--        1 while the mode is Shunting (the information "ready for remote
--        shunting" of SUBSET-026 4.4.8.1.4), recorded when it changes;
--     124 RBC contact information entered by the driver (4.2.4.24; 24 is
--        the text messages' event): byte 2 Q_RBCENTRY (RBC_Entry_Code),
--        bytes 3 and 4 NID_RBC (high, low) when entered; NID_C and
--        NID_RADIO do not fit the record;
--     48 GSM-R network entered by the driver (4.2.4.48): bytes 2 to 4
--        NID_MN (MN_Code).
--
--  The package says what to record; EVC_Core stamps and puts the records.

with EVC_Bytes;            use EVC_Bytes;
with EVC_Driver_Requests;
with EVC_Supervision_Input;
with EVC_Train_Data;
with EVC_JRU_Messages;
with EVC_Track_Conditions;
with Interfaces;           use Interfaces;

--  @req 3.16.3.1.1.2
package EVC_JRU_Records
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   JRU_Driver_Action    : constant := 11;
   JRU_Radio_Error      : constant := 13;
   JRU_Cab_Status       : constant := 38;
   JRU_Track_Conditions : constant := 45;

   --  No M_DRIVERACTIONS for it here
   No_Code : constant Byte := 16#FF#;

   --  SUBSET-027 4.2.4.11: the code of an action of the DMI with its
   --  argument (dmi_protocol.ads MSG_DRIVER_ACTION), No_Code when another
   --  event records it or SUBSET-027 has no code for it
   function Action_Code (A   : EVC_Driver_Requests.Action_T;
                         Arg : Unsigned_16) return Byte
     with Global => null;

   --  The same for an acknowledgement of kind K (the id: a system status
   --  message is 16#8000# + its catalogue entry)
   function Ack_Code (K  : EVC_Driver_Requests.Ack_Kind_T;
                      Id : Unsigned_16) return Byte
     with Global => null;

   --  The data entries with a code: the language (29)
   function Data_Code (K : EVC_Driver_Requests.Data_Kind_T) return Byte
     with Global => null;

   --  Power-up: no cab active recorded, no track condition item
   procedure Reset
     with Global => (Output => State);

   --  The cab status of the cycle, Received when the train interface sent
   --  a cab status since the power-up: Changed (to be recorded) at the
   --  first one received and when it differs from the last one recorded
   procedure Cab_Status (Cab_A, Cab_B, Received : Boolean;
                         Changed : out Boolean)
     with Global => (In_Out => State);

   --  M_TRACKCOND_TI of a kind of the second TIU output (EVC_Ports)
   function Trackcond_TI (Kind : Natural) return Byte
     with Global => null;

   type TC_Change_T is record
      TI    : Byte := 0;
      Phase : Byte := 0;
      Id    : Byte := 0;
   end record;
   type TC_Change_Array is
     array (1 .. EVC_Track_Conditions.Max_External) of TC_Change_T;
   type TC_Changes_T is record
      Count : Natural range 0 .. EVC_Track_Conditions.Max_External := 0;
      List  : TC_Change_Array := (others => (others => 0));
   end record;

   --  The items of Info that are new or changed their phase since the
   --  last call
   procedure Track_Conditions (Info    : EVC_Track_Conditions.External_T;
                               Changes : out TC_Changes_T)
     with Global => (In_Out => State);

   --  The inputs and states recorded when they change (SUBSET-027
   --  4.2.4.30, .31, .32, .39, .51)
   type Input_T is (Sleeping, Passive_Shunting, Non_Leading, Direction,
                    Remote_Shunting);
   --  Their values in SUBSET-027's coding, No_Value while not known
   No_Value : constant := -1;
   subtype Input_Value_T is Integer range No_Value .. 3;
   type Input_Values_T is array (Input_T) of Input_Value_T;
   type Input_Changes_T is array (Input_T) of Boolean;

   --  The event of an input (the header: 132 for record 32)
   function Input_Event (I : Input_T) return Byte
     with Global => null;

   --  M_DIRECTION_CONTROLLER of the TIU direction controller input
   --  (EVC_Ports: 0 neutral, 1 forward, 2 reverse): 0 neutral, 1
   --  backward, 2 forward
   function Direction_Code (TIU_Value : Natural) return Input_Value_T
     with Global => null,
          Post => Direction_Code'Result in 0 .. 2;

   --  The inputs of the cycle: Changes (I) when Now (I) is known and
   --  differs from the last one recorded (the first one known included;
   --  remote shunting is recorded as not permitted at the power-up)
   procedure Inputs (Now : Input_Values_T; Changes : out Input_Changes_T)
     with Global => (In_Out => State),
          Post => (for all I in Input_T =>
                     (if Changes (I) then Now (I) /= No_Value));

   --  The radio data entered by the driver (SUBSET-027 4.2.4.24, .48):
   --  Q_RBCENTRY of the choice of MSG_DRIVER_DATA kind 5 (0 entered: 3,
   --  the RBC data with GSM-R, the only radio of this on-board; 1
   --  'Contact last RBC': 0; 2 'Use short number': 1), No_Code otherwise
   function RBC_Entry_Code (Choice : Byte) return Byte
     with Global => null;

   --  NID_MN of the GSM-R network the driver entered (7.5.1.91): the
   --  first six characters as BCD digits, left adjusted, F where there
   --  is no digit, in three bytes
   type MN_Bytes_T is array (1 .. 3) of Byte;
   function MN_Code (T : EVC_Driver_Requests.Text_T) return MN_Bytes_T
     with Global => null;

   --  NID_OPERATIONAL of the train running number the driver entered
   --  (SUBSET-027 4.2.4.49, SUBSET-026 7.5.1.92): the first eight
   --  characters as BCD digits, left adjusted, F where there is no digit
   --  (the digits F rightmost, as 6.6.3.2.3 [10] gives it)
   function TRN_Code (T : EVC_Driver_Requests.Text_T) return Unsigned_32
     with Global => null;

   --  A message body of more variables than EVC_JRU_Messages.Fields_T
   --  holds, written bit by bit (EVC_Outbox.Put_JRU's Data)
   Max_Body : constant := 128;
   subtype Body_T is Byte_Array (1 .. Max_Body);

   --  SUBSET-027 4.2.4.2: the Train Data D with the categories C as the
   --  on-board uses them. Decisions: V_MAXTRAIN, L_TRAIN, the categories
   --  and the traction systems as packet 11 gives them to the RBC
   --  (EVC_Sessions.Mission: NID_CTRACTION 0, N_AXLE 0, no national
   --  system, M_AIRTIGHT 0); M_NOM_ROT_MASS 16 "unknown" (not part of
   --  the Train Data of SUBSET-026 3.18.3.4); one brake configuration
   --  (N_BRAKE_CONF 0, the number minus one),
   --  the special brakes the train has (lambda: regenerative, eddy
   --  current, ep; gamma: and magnetic shoe); a lambda train's service
   --  brake times those of the conversion model (A.3.9) for its length
   --  and brake position; a gamma train's deceleration steps as
   --  sections, the first seven, each from the speed of the step before;
   --  the rolling stock correction factors 1.00, those the braking
   --  applies (the Train Data give none)
   procedure Train_Data_Body (D    : EVC_Supervision_Input.Train_Data_T;
                              C    : EVC_Train_Data.Categories_T;
                              Buf  : out Body_T;
                              Bits : out Natural)
     with Global => null,
          Post => Bits <= 8 * Max_Body;

   --  SUBSET-027 4.2.4.45: the track conditions of the information for
   --  the external functions (SUBSET-026 5.20), written when an item
   --  appears or changes its phase (Track_Conditions), the whole list.
   --  Decisions: Q_SCALE 1 m; the distances of the second TIU output
   --  (EVC_Track_Conditions.External_Item_T) in metres; an end not
   --  generated is the largest distance, a start not generated (passed)
   --  D_MAXSFE_TO_START -32768 "not relevant"
   procedure Track_Conditions_Body
     (Info : EVC_Track_Conditions.External_T;
      Buf  : out Body_T;
      Bits : out Natural)
     with Global => null,
          Post => Bits <= 8 * Max_Body;

   --  SUBSET-027 4.2.4.47: the brake and traction interface of the
   --  installation configuration C (SUBSET-026 3.13.2.2.6 to 3.13.2.2.8).
   --  Decision: a special brake whose status affects the emergency brake
   --  only is coded as affecting both where its variable has no such
   --  value (the electro pneumatic brake)
   procedure Interface_Fields (C      : EVC_Supervision_Input.Onboard_Config_T;
                               Fields : out EVC_JRU_Messages.Fields_T)
     with Global => null;

   --  4.2.4.24: the complementary variables of the RBC contact
   --  information the driver entered (MSG_DRIVER_DATA kind 5,
   --  dmi_protocol.ads): Q_RBCENTRY Q; with Q 2 or 3 NID_C and NID_RBC
   --  of the RBC ID (NID_C above the 14 bits of NID_RBC); with Q 3
   --  NID_RADIO, the phone number as 16 BCD digits padded with F
   --  (SUBSET-026 7.5.1.95), read as EVC_Sessions.Mission reads it
   procedure RBC_Entry_Fields (RBC    : EVC_Driver_Requests.Bytes_23_T;
                               Q      : Byte;
                               Fields : out EVC_JRU_Messages.Fields_T)
     with Global => null;

end EVC_JRU_Records;
