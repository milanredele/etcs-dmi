--  ETCS DMI
--  Acknowledgement service per DMI 5.4.1.
--
--  Every request is held individually in a FIFO queue (5.4.1.9): the
--  requests are offered one at a time (5.4.1.7) in their order of
--  arrival, the next one 1 second after the current one has been
--  acknowledged or revoked. The order of 5.4.1.9.1 only sorts requests
--  that are triggered simultaneously, which is taken here as: received
--  between two consecutive calls of Tick (one DMI cycle). A request is
--  therefore never displayed before the Tick that follows its arrival.
--  Each newly displayed request plays Sinfo with its flashing frame
--  (5.4.1.5).
--
--  Storage is static. There is at most one request per object kind
--  (level transition, mode change, brake release) and one per text
--  message id. The queue holds Text_Capacity text message requests plus
--  one slot reserved for each object kind, so that an object request is
--  never refused. A text message request that does not fit is refused
--  (Accepted = False) and nothing else changes; the text message store
--  keeps such a message and enters it as soon as a slot is free (see
--  DMI_Text_Messages.Tick), so it can still be acknowledged.

with Supplementary_Driving_Info;

package DMI_Ack is

   -- In the order of DMI 5.4.1.9.1 (first in the sequence first)
   type Ack_Kind_T is (Level_Transition,
                       Mode_Change,
                       Fixed_Text,
                       Plain_Text,
                       System_Status,
                       Brake_Release,
                       NTC_Text);

   subtype Text_Kind_T is Ack_Kind_T
     with Static_Predicate =>
       Text_Kind_T in Fixed_Text | Plain_Text | System_Status | NTC_Text;

   -- The objects of 5.4.1.9.1 that are not text messages
   subtype Object_Kind_T is Ack_Kind_T
     with Static_Predicate =>
       Object_Kind_T in Level_Transition | Mode_Change | Brake_Release;

   Text_Capacity : constant := 8;

   -- A request for the same kind with another mode / level replaces the
   -- old one: the old request is revoked, the new one joins the queue.
   procedure Request_Mode_Ack
     (Mode : Supplementary_Driving_Info.Acknowledgment_Mode_T);

   procedure Request_Level_Ack
     (Level : Supplementary_Driving_Info.Level_T);

   procedure Request_Brake_Release_Ack;

   -- One request per text message. Accepted is False when the queue
   -- cannot take another text message request; True also when the
   -- message already has a request (which keeps its place).
   procedure Request_Text_Ack (Kind     : Text_Kind_T;
                               ID       : Natural;
                               Accepted : out Boolean);

   -- Revoke the request of an object kind, waiting or displayed (the
   -- triggering condition disappeared on the EVC side)
   procedure Cancel (Kind : Object_Kind_T);

   -- Revoke the request of this text message only
   procedure Cancel_Text (ID : Natural);

   -- The driver acknowledged the currently displayed request
   procedure Acknowledge_Current;

   procedure Tick (Dt_Ms : Natural);

   -- What is currently offered for acknowledgement
   function Current_Valid return Boolean;
   function Current_Kind return Ack_Kind_T
     with Pre => Current_Valid;
   function Current_Mode return Supplementary_Driving_Info.Acknowledgment_Mode_T;
   function Current_Level return Supplementary_Driving_Info.Level_T;
   -- Meaningful while a text message request is offered
   function Current_Text_ID return Natural;

   -- Number of requests held (waiting + displayed)
   function Pending_Count return Natural;

   procedure Reset;

end DMI_Ack;
