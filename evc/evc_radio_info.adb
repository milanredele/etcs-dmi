--  ETCS on-board (EVC)
--  Phase E5: the radio messages of the cycle for the stores
--  (implementation).

package body EVC_Radio_Info
  with SPARK_Mode => On,
       Refined_State => (State => (Messages, Slots, N, Refused_N, MAR))
is

   type Message_Array_T is array (Index_T) of ETCS_Message.Message_T;
   type Slot_Array_T is array (Index_T) of Slot_T;

   Messages  : Message_Array_T := (others => (others => <>));
   Slots     : Slot_Array_T := (others => (others => <>));
   N         : Count_T := 0;
   Refused_N : Natural := 0;
   MAR       : Unsigned_64 range 0 .. Max_T_MAR_Ms := 0;

   function T_MAR_Ms return Unsigned_64 is (MAR)
     with Refined_Global => MAR;

   procedure Set_T_MAR (Ms : Unsigned_64)
     with Refined_Global => (Output => MAR)
   is
   begin
      MAR := Ms;
   end Set_T_MAR;

   function Count return Count_T is (N)
     with Refined_Global => N;

   function Slot (I : Index_T) return Slot_T is (Slots (I));

   function Kind (I : Index_T) return ETCS_Message_Catalogue.Message_Kind_T
   is (Messages (I).Kind);

   function Packet_Count (I : Index_T) return ETCS_Message.Packet_Count_T is
     (Messages (I).Count);

   function Packet_Entry (I : Index_T; P : Positive)
     return ETCS_Packet_Index.Entry_T
   is (Messages (I).Index (P));

   function Refused return Natural is (Refused_N)
     with Refined_Global => Refused_N;

   procedure Open_Packet (I : Index_T;
                          P : Positive;
                          R : in out ETCS_Bits.Reader)
   is
   begin
      ETCS_Message.Open_Packet (Messages (I), P, R);
   end Open_Packet;

   procedure Clear
     with Refined_Global => (Output => (Messages, Slots, N, Refused_N, MAR))
   is
   begin
      MAR := 0;
      Messages := (others => (others => <>));
      Slots := (others => (others => <>));
      N := 0;
      Refused_N := 0;
   end Clear;

   procedure Empty
     with Refined_Global => (Output => N)
   is
   begin
      N := 0;
   end Empty;

   procedure Put_Last (S : Slot_T)
     with Refined_Global => (In_Out => (Messages, Slots, N, Refused_N),
                             Input  => EVC_Received.Store)
   is
   begin
      if N = Max_Messages then
         if Refused_N < Natural'Last then
            Refused_N := Refused_N + 1;
         end if;
         return;
      end if;
      N := N + 1;
      EVC_Received.Copy_Message (Messages (N));
      Slots (N) := S;
   end Put_Last;

end EVC_Radio_Info;
