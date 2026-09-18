--  ETCS DMI
--  Acknowledgement service per DMI 5.4: one acknowledgement is offered at
--  a time, requests are handled in the priority order of 5.4.1.9.1 with a
--  1 second delay between consecutive displays, and each newly displayed
--  request plays Sinfo with its flashing frame (5.4.1.5).

with Supplementary_Driving_Info;

package DMI_Ack is

   -- In the priority order of DMI 5.4.1.9.1 (highest first)
   type Ack_Kind_T is (Level_Transition,
                       Mode_Change,
                       Fixed_Text,
                       Plain_Text,
                       System_Status,
                       Brake_Release,
                       NTC_Text);

   procedure Request_Mode_Ack
     (Mode : Supplementary_Driving_Info.Acknowledgment_Mode_T);

   procedure Request_Level_Ack
     (Level : Supplementary_Driving_Info.Level_T);

   -- For kinds without payload (text messages, brake release)
   procedure Request (Kind : Ack_Kind_T);

   -- Withdraw a pending or displayed request (the triggering condition
   -- disappeared on the EVC side)
   procedure Cancel (Kind : Ack_Kind_T);

   -- The driver acknowledged the currently displayed request
   procedure Acknowledge_Current;

   procedure Tick (Dt_Ms : Natural);

   -- What is currently offered for acknowledgement
   function Current_Valid return Boolean;
   function Current_Kind return Ack_Kind_T
     with Pre => Current_Valid;
   function Current_Mode return Supplementary_Driving_Info.Acknowledgment_Mode_T;
   function Current_Level return Supplementary_Driving_Info.Level_T;

   procedure Reset;

end DMI_Ack;
