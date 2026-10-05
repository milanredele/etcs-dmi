--  ETCS on-board (EVC)
--  What the on-board received from the track, implementation.

package body EVC_Received
  with SPARK_Mode => On,
       Refined_State => (Store => (Telegram,
                                   Telegram_Kept,
                                   Message,
                                   Message_Kept,
                                   Telegram_Counts,
                                   Message_Counts))
is

   type Telegram_Counts_T is array (ETCS_Telegram.Status_T) of Natural;
   type Message_Counts_T is array (ETCS_Message.Status_T) of Natural;

   Telegram        : ETCS_Telegram.Telegram_T;
   Telegram_Kept   : Boolean := False;
   Message         : ETCS_Message.Message_T;
   Message_Kept    : Boolean := False;
   Telegram_Counts : Telegram_Counts_T := (others => 0);
   Message_Counts  : Message_Counts_T := (others => 0);

   function Telegram_Count (S : ETCS_Telegram.Status_T) return Natural is
     (Telegram_Counts (S))
     with Refined_Global => Telegram_Counts;

   function Message_Count (S : ETCS_Message.Status_T) return Natural is
     (Message_Counts (S))
     with Refined_Global => Message_Counts;

   function Has_Telegram return Boolean is (Telegram_Kept)
     with Refined_Global => Telegram_Kept;

   function Has_Message return Boolean is (Message_Kept)
     with Refined_Global => Message_Kept;

   function Last_Telegram return ETCS_Telegram.Telegram_T is (Telegram)
     with Refined_Global => Telegram;

   function Last_Message return ETCS_Message.Message_T is (Message)
     with Refined_Global => Message;

   function Last_Kind return ETCS_Message_Catalogue.Message_Kind_T is
     (Message.Kind)
     with Refined_Global => Message;

   function Last_Value (Var : ETCS_Variables.Variable_T)
     return Interfaces.Unsigned_64
   is (ETCS_Message.Value (Message, Var))
     with Refined_Global => Message;

   function Last_Packet_Count return Natural is (Message.Count)
     with Refined_Global => Message;

   function Last_Packet_Kind (I : Positive)
     return ETCS_Catalogue.Packet_Kind_T
   is (Message.Index (I).Kind)
     with Refined_Global => Message;

   procedure Copy_Message (M : out ETCS_Message.Message_T)
     with Refined_Global => Message
   is
   begin
      M := Message;
   end Copy_Message;

   procedure Count (Counter : in out Natural) is
   begin
      if Counter < Natural'Last then
         Counter := Counter + 1;
      end if;
   end Count;

   -----------
   -- Clear --
   -----------

   procedure Clear
     with Refined_Global => (Output => (Telegram, Telegram_Kept, Message,
                                        Message_Kept, Telegram_Counts,
                                        Message_Counts))
   is
   begin
      --  (built in place, not in a local copied: every component of the
      --  two types has a default expression)
      Telegram := (others => <>);
      Telegram_Kept := False;
      Message := (others => <>);
      Message_Kept := False;
      Telegram_Counts := (others => 0);
      Message_Counts := (others => 0);
   end Clear;

   ----------------------
   -- Receive_Telegram --
   ----------------------

   procedure Receive_Telegram (Payload : EVC_Bytes.Byte_Array;
                               Status  : out ETCS_Telegram.Status_T)
     with Refined_Global => (In_Out   => (Telegram, Telegram_Kept,
                                          Telegram_Counts),
                             Proof_In => Message_Kept)
   is
      Bits : constant Natural :=
        Natural (EVC_Bytes.Get_U16 (Payload, Payload'First));
      T    : ETCS_Telegram.Telegram_T;
   begin
      ETCS_Telegram.Parse
        (Payload (Payload'First + 2 .. Payload'Last), Bits, T, Status);
      Count (Telegram_Counts (Status));
      if Status = ETCS_Telegram.Accepted then
         Telegram := T;
         Telegram_Kept := True;
      end if;
   end Receive_Telegram;

   ---------------------
   -- Receive_Message --
   ---------------------

   procedure Receive_Message (Payload : EVC_Bytes.Byte_Array;
                              Status  : out ETCS_Message.Status_T)
     with Refined_Global => (In_Out   => (Message, Message_Kept,
                                          Message_Counts),
                             Proof_In => Telegram_Kept)
   is
      M : ETCS_Message.Message_T;
   begin
      --  Every message is taken as sent by an RBC until phase E5 tells
      --  an RIU session from an RBC one: what only an RIU sends (message
      --  37, 8.5.3; packet 143, 7.4.2.37.1) is rejected as Wrong_Sender
      ETCS_Message.Parse (Payload, ETCS_Catalogue.Track_To_Train,
                          ETCS_Catalogue.RBC, M, Status);
      Count (Message_Counts (Status));
      if Status = ETCS_Message.Accepted then
         Message := M;
         Message_Kept := True;
      end if;
   end Receive_Message;

   --------------------------
   -- Open_Telegram_Packet --
   --------------------------

   procedure Open_Telegram_Packet (I : Positive;
                                   R : in out ETCS_Bits.Reader)
     with Refined_Global => Telegram
   is
   begin
      ETCS_Telegram.Open_Packet (Telegram, I, R);
   end Open_Telegram_Packet;

   -------------------------
   -- Open_Message_Packet --
   -------------------------

   procedure Open_Message_Packet (I : Positive;
                                  R : in out ETCS_Bits.Reader)
     with Refined_Global => Message
   is
   begin
      ETCS_Message.Open_Packet (Message, I, R);
   end Open_Message_Packet;

end EVC_Received;
