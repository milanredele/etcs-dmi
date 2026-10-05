--  ETCS on-board (EVC)
--  The radio communication of the on-board that the halves of phase E5
--  share (doc/EVC-PLAN.md §13): the communication sessions with RBCs
--  (SUBSET-026 3.5), their time stamps (3.16.3), the roles of two RBCs in
--  a handover (3.15.1), the RBC contact information (kept over No Power,
--  4.10) and the outbox of what the on-board sends on the RTM port
--  (EVC_Ports: the messages of chapter 8 and the requests to the radio).
--  This unit decides nothing; it holds the state and its queries.
--
--  Ownership of the state (who writes what):
--    - EVC_Sessions (the session and link half, e5/session) is the only
--      writer of the session table (Set_State, Set_Peer, Set_Version,
--      Note_Received, Reset_Session), of the roles (Set_Roles), of the
--      RBC contact information (Set_Contact) and of the radio network
--      (Set_Network). It owns 3.5 (the states and their transitions),
--      3.16.3 (the time stamps and the link supervision), 3.15.1 (which
--      session supervises and which accepts) and the acceptance of radio
--      information (4.8, the transition buffer 4.8.5).
--    - EVC_Radio_Authority (the authority half, e5/authority) reads the
--      table through the queries and sends (Send).
--    - Both halves send their messages through Send and the requests
--      through Request_*; Send records the T_TRAIN of what it queued as
--      the last one sent on the session (3.16.3), mechanically.
--    - EVC_Core clears the unit at each power-up (Clear, with the
--      number of sessions of the installation, EVC_Config), restores
--      the RBC contact information kept over No Power ("to be
--      revalidated": Restore_Contact, from EVC_Retained), saves it at
--      the end of each cycle (Contact into EVC_Retained.Kept_T.RBC),
--      and drains the outbox to the RTM port at the end of its outputs
--      (Drain).
--    Each half keeps its private state in its own unit: the session half
--    its timers (T_NVCONTACT, the waiting times of A.3.1), repetitions,
--    the transition buffer and the position report parameters; the
--    authority half the MA request, the emergency stops, the
--    acknowledgements it owes.
--
--  The sessions are numbered 1 and 2 (EVC_Ports.RTM_Session_T), the
--  number of the RTM port, whatever RBC each is with; an on-board that
--  handles one session only (EVC_Config.Radio_Config_T) uses session 1
--  and refuses to send on session 2.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Bytes;
with EVC_Modes;      use EVC_Modes;
with EVC_Outbox;
with EVC_Ports;      use EVC_Ports;
with ETCS_Variables; use ETCS_Variables;
with Interfaces;     use Interfaces;

package EVC_Radio
  with SPARK_Mode => On,
       Abstract_State => (State, Queue),
       Initializes => (State, Queue)
is

   Max_Sessions : constant := RTM_Max_Sessions;
   subtype Session_T is RTM_Session_T;
   subtype Session_Count_T is Positive range 1 .. Max_Sessions;

   --  A session or none (the roles of 3.15.1)
   type Session_Ref_T is range 0 .. Max_Sessions;
   No_Session : constant Session_Ref_T := 0;

   subtype Time_Ms_T is Unsigned_64;   -- on-board time (EVC_Core.Time_Ms)

   ---------------------------------------------------------------------
   --  Identities
   ---------------------------------------------------------------------

   --  An RBC (NID_C, NID_RBC of chapter 7)
   type RBC_Id_T is record
      NID_C   : NID_C_T := 0;
      NID_RBC : NID_RBC_T := 0;
   end record;

   No_RBC : constant RBC_Id_T := (NID_C => 0, NID_RBC => 0);

   --  The RBC contact information (3.5.3.7, 3.5.3.13, 5.4.3.2 D7): the
   --  RBC and its phone number, NID_RADIO as coded. Kept over No Power
   --  (4.10 column NP, EVC_Retained.Kept_T.RBC): restored "to be
   --  revalidated" (Valid False) by EVC_Core.Power_Up; written by
   --  EVC_Sessions (from the trackside, the driver, 5.4).
   type RBC_Contact_T is record
      Known : Boolean := False;
      Valid : Boolean := False;
      RBC   : RBC_Id_T;
      Radio : NID_RADIO_T := 0;
   end record;

   No_Contact : constant RBC_Contact_T :=
     (Known => False, Valid => False, RBC => No_RBC, Radio => 0);

   --  The GSM-R radio network (3.5.6): the one ordered (from trackside or
   --  the driver, or the default of 3.5.6.3) and whether the mobiles are
   --  registered to it. Written by EVC_Sessions.
   type Network_T is record
      Known      : Boolean := False;
      NID_MN     : NID_MN_T := 0;
      Registered : Boolean := False;
   end record;

   ---------------------------------------------------------------------
   --  The session table
   ---------------------------------------------------------------------

   --  The state of a communication session, as 3.5 names its steps
   type Session_State_T is
     (Idle,             -- no session: none set up, or terminated
                        --  (3.5.5.2 c), the safe radio connection released
      Connecting,       -- 3.5.3.7 a: the set-up of a safe radio connection
                        --  requested (and repeated)
      Initiating,       -- 3.5.3.7 b, c: the safe radio connection is set
                        --  up, Initiation of communication session (155)
                        --  sent; the system version is awaited (3.5.3.8:
                        --  "being established" from Connecting to here)
      Established,      -- 3.5.3.7 d: the system version received, the
                        --  session established (the acknowledgement of e
                        --  may still be awaited, 3.5.3.7.4)
      Connection_Lost,  -- 3.5.4.1: established, the safe radio connection
                        --  lost and not set up again yet; still considered
                        --  established for the defined time (A.3.1)
      Terminating);     -- 3.5.5.2 a: Termination of communication session
                        --  (156) sent, its acknowledgement (39) awaited;
                        --  3.5.5.6: the other messages are ignored

   --  One session (3.5, 3.16.3, 3.17)
   type Session_Info_T is record
      State         : Session_State_T := Idle;
      --  the RBC of the session and the number it was called on
      RBC           : RBC_Id_T;
      Radio         : NID_RADIO_T := 0;
      --  the system version agreed (3.5.3.7 d, 3.17.3): M_VERSION of
      --  message 32
      Version_Known : Boolean := False;
      Version       : M_VERSION_T := 0;
      --  3.16.3: T_TRAIN of the last message received in the session
      --  (its time stamp) and the on-board time it was taken (the
      --  supervision of T_NVCONTACT, 3.16.3.4); Received: one was
      Received      : Boolean := False;
      Last_Received : T_TRAIN_T := 0;
      Received_Ms   : Time_Ms_T := 0;
      --  3.16.3: T_TRAIN of the last message the on-board sent (Send)
      Sent          : Boolean := False;
      Last_Sent     : T_TRAIN_T := 0;
   end record;

   No_Info : constant Session_Info_T :=
     (State         => Idle,
      RBC           => No_RBC,
      Radio         => 0,
      Version_Known => False,
      Version       => 0,
      Received      => False,
      Last_Received => 0,
      Received_Ms   => 0,
      Sent          => False,
      Last_Sent     => 0);

   --  The sessions this on-board handles (EVC_Config, taken at Clear)
   function Sessions return Session_Count_T
     with Global => State;

   --  The session S
   function Info (S : Session_T) return Session_Info_T
     with Global => State;

   --  3.15.1: the session with the Supervising RBC and the one with the
   --  Accepting RBC during a handover (No_Session when none)
   function Supervising return Session_Ref_T
     with Global => State;
   function Accepting return Session_Ref_T
     with Global => State;

   function Contact return RBC_Contact_T
     with Global => State;

   function Network return Network_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Queries (what each half asks of the other)
   ---------------------------------------------------------------------

   --  The on-board handles the session S (Sessions)
   function Usable (S : Session_T) return Boolean is
     (Natural (S) <= Sessions)
     with Global => State;

   --  3.5.3.7 d, 3.5.4.1: the session S is established (also while its
   --  safe radio connection is lost, for the defined time)
   function Established (S : Session_T) return Boolean is
     (Info (S).State in Established | Connection_Lost)
     with Global => State;

   --  3.5.3.8: the session S is being established
   function Being_Established (S : Session_T) return Boolean is
     (Info (S).State in Connecting | Initiating)
     with Global => State;

   --  3.5.3.4.1: a session with R is established or being established
   function In_Session_With (R : RBC_Id_T) return Boolean is
     (for some S in Session_T =>
        Info (S).State /= Idle and then Info (S).RBC = R)
     with Global => State;

   --  The roles are consistent: a role names a session the on-board
   --  handles, and two roles are two sessions
   function Roles_Consistent return Boolean is
     (Natural (Supervising) <= Sessions
      and then Natural (Accepting) <= Sessions
      and then (Supervising = No_Session
                or else Supervising /= Accepting))
     with Global => State;

   --  The on-board is in communication with an RBC (4.8 "in
   --  communication with the RBC", the mode conditions): the session of
   --  the Supervising RBC is established
   function In_Communication return Boolean is
     (Supervising /= No_Session
      and then Established (Session_T (Supervising)))
     with Global => State;

   --  The Supervising RBC (No_RBC when none)
   function Supervising_RBC return RBC_Id_T is
     (if Supervising = No_Session then No_RBC
      else Info (Session_T (Supervising)).RBC)
     with Global => State;

   --  3.15.1: a handover is under way (an Accepting RBC is known)
   function Handover return Boolean is
     (Accepting /= No_Session)
     with Global => State;

   --  The system version agreed with the Supervising RBC is known
   function Supervising_Version_Known return Boolean is
     (Supervising /= No_Session
      and then Info (Session_T (Supervising)).Version_Known)
     with Global => State;

   ---------------------------------------------------------------------
   --  The context of a cycle, for the halves (EVC_Core builds it)
   ---------------------------------------------------------------------

   type Context_T is record
      Mode   : Mode_T := M_NP;
      Now_Ms : Time_Ms_T := 0;
   end record;

   ---------------------------------------------------------------------
   --  Operations of EVC_Core
   ---------------------------------------------------------------------

   --  The power-up: no session (every one Idle), no role, no contact, no
   --  network, the outbox empty; N sessions (EVC_Config)
   procedure Clear (N : Session_Count_T)
     with Global => (Output => (State, Queue)),
          Post => Sessions = N
                  and then (for all S in Session_T => Info (S) = No_Info)
                  and then Supervising = No_Session
                  and then Accepting = No_Session
                  and then Contact = No_Contact
                  and then not Network.Known
                  and then Queued = 0
                  and then Refused = 0;

   --  4.10 column NP, 4.11: the RBC contact information kept over No
   --  Power, "to be revalidated"
   procedure Restore_Contact (C : RBC_Contact_T)
     with Global => (In_Out => State),
          Post => Contact.Known = C.Known
                  and then Contact.RBC = C.RBC
                  and then Contact.Radio = C.Radio
                  and then not Contact.Valid
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   ---------------------------------------------------------------------
   --  Operations of EVC_Sessions (the only writer of the table)
   ---------------------------------------------------------------------

   procedure Set_State (S : Session_T; To : Session_State_T)
     with Global => (In_Out => State),
          Post => Info (S).State = To
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   --  The RBC of the session and the number it is called on
   procedure Set_Peer (S : Session_T; RBC : RBC_Id_T; Radio : NID_RADIO_T)
     with Global => (In_Out => State),
          Post => Info (S).RBC = RBC
                  and then Info (S).Radio = Radio
                  and then Info (S).State = Info (S).State'Old
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   procedure Set_Version (S : Session_T; Version : M_VERSION_T)
     with Global => (In_Out => State),
          Post => Info (S).Version_Known
                  and then Info (S).Version = Version
                  and then Info (S).State = Info (S).State'Old
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   --  3.16.3: a message received in the session S, its T_TRAIN, taken
   --  at the on-board time Now_Ms
   procedure Note_Received (S       : Session_T;
                            T_Train : T_TRAIN_T;
                            Now_Ms  : Time_Ms_T)
     with Global => (In_Out => State),
          Post => Info (S).Received
                  and then Info (S).Last_Received = T_Train
                  and then Info (S).Received_Ms = Now_Ms
                  and then Info (S).State = Info (S).State'Old
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   --  The session S back to Idle, everything of it forgotten
   procedure Reset_Session (S : Session_T)
     with Global => (In_Out => State),
          Post => Info (S) = No_Info
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   --  3.15.1: the roles (a handover gives the Accepting RBC, the border
   --  makes it the Supervising one)
   procedure Set_Roles (Supervising, Accepting : Session_Ref_T)
     with Global => (In_Out => State),
          Pre  => Natural (Supervising) <= Sessions
                  and then Natural (Accepting) <= Sessions
                  and then (Supervising = No_Session
                            or else Supervising /= Accepting),
          Post => EVC_Radio.Supervising = Supervising
                  and then EVC_Radio.Accepting = Accepting
                  and then Sessions = Sessions'Old
                  and then Roles_Consistent;

   procedure Set_Contact (C : RBC_Contact_T)
     with Global => (In_Out => State),
          Post => Contact = C
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   procedure Set_Network (N : Network_T)
     with Global => (In_Out => State),
          Post => Network = N
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old;

   ---------------------------------------------------------------------
   --  The outbox (both halves): what leaves on the RTM port
   ---------------------------------------------------------------------

   --  Bytes of static storage for the outputs waiting for the RTM port
   --  (records: length u16, then the output of EVC_Ports); a train to
   --  track message of the longest L_MESSAGE fits
   Queue_Capacity : constant := 2048;
   Queue_Header   : constant := 2;

   --  Bytes queued
   function Queued return Natural
     with Global => Queue,
          Post => Queued'Result <= Queue_Capacity;

   --  Outputs refused since Clear (no room, or a session the on-board
   --  does not handle), saturating
   function Refused return Natural
     with Global => Queue;

   --  T_TRAIN of a train to track message, bits 18 to 49 (8.4.4.7.1);
   --  0 for a message too short to carry it
   function T_Train_Of (Message : EVC_Bytes.Byte_Array) return T_TRAIN_T
     with Pre => Valid_RTM (Message);

   --  Queue Message (a train to track message of chapter 8, built with
   --  ETCS_Message) to be sent in the session S. Never fails: when S is
   --  not Usable or the outbox has no room, the message is refused and
   --  counted (Refused). Queued, its T_TRAIN is the last one sent in S
   --  (3.16.3). Send does not look at the state of the session: what
   --  may be sent when (3.5.4.5, 3.5.5.3) is the halves'.
   procedure Send (S : Session_T; Message : EVC_Bytes.Byte_Array)
     with Global => (In_Out => (State, Queue)),
          Pre  => Valid_RTM (Message),
          Post => Queued >= Queued'Old
                  and then Sessions = Sessions'Old
                  and then Supervising = Supervising'Old
                  and then Accepting = Accepting'Old
                  and then Info (S).State = Info (S).State'Old;

   --  3.5.3.7 a: request the set-up of a safe radio connection in the
   --  session S with RBC on the number Radio, over the radio system
   --  FRMCS (else GSM-R, 3.5.3.7.1); refused and counted as Send
   procedure Request_Set_Up (S     : Session_T;
                             RBC   : RBC_Id_T;
                             Radio : NID_RADIO_T;
                             FRMCS : Boolean)
     with Global => (In_Out => Queue, Input => State),
          Post => Queued >= Queued'Old;

   --  3.5.3.7.3, 3.5.3.8, 3.5.5.2 c: request the release of the safe
   --  radio connection of the session S
   procedure Request_Release (S : Session_T)
     with Global => (In_Out => Queue, Input => State),
          Post => Queued >= Queued'Old;

   --  3.5.6.1, 3.5.6.5: order the registration of the mobile of the
   --  session S to the GSM-R radio network NID_MN
   procedure Request_Registration (S : Session_T; NID_MN : NID_MN_T)
     with Global => (In_Out => Queue, Input => State),
          Post => Queued >= Queued'Old;

   --  EVC_Core, at the end of its outputs: move the queued outputs, in
   --  their order, to EVC_Outbox (port RTM) as long as they fit there;
   --  the others wait for the next cycle
   procedure Drain
     with Global => (In_Out => (Queue, EVC_Outbox.Queue)),
          Post => Queued <= Queued'Old;

end EVC_Radio;
