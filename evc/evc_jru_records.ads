--  ETCS on-board (EVC)
--  JRU events that follow SUBSET-027 messages one to one (the event
--  number is the NID_MESSAGE_JRU of the message, EVC_Ports):
--
--     11 driver's action (4.2.4.11): byte 2 M_DRIVERACTIONS, for the
--        actions no other event of the on-board records (Action_Code,
--        Ack_Code; the start, the levels, the mode acknowledgements,
--        override, maintain shunting, isolation and BMM have their own);
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
--        phase.
--
--  The package says what to record; EVC_Core stamps and puts the records.

with EVC_Bytes;            use EVC_Bytes;
with EVC_Driver_Requests;
with EVC_Track_Conditions;
with Interfaces;           use Interfaces;

package EVC_JRU_Records
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   JRU_Driver_Action    : constant := 11;
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

end EVC_JRU_Records;
