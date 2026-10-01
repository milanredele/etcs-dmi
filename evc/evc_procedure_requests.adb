--  ETCS on-board (EVC)
--  The driver's actions of the procedures, implementation (interim, see
--  the specification).

package body EVC_Procedure_Requests
  with SPARK_Mode => On,
       Refined_State => (State => (Latched, Current))
is

   type Text_Acks_T is array (1 .. Max_Text_Acks) of Unsigned_16;

   type Actions_T is record
      Override_EOA      : Boolean := False;
      Shunting_Request  : Boolean := False;
      Exit_Shunting     : Boolean := False;
      Maintain_Shunting : Boolean := False;
      Exit_SM           : Boolean := False;
      BMM_Inhibition    : Boolean := False;
      BMM_Revoke        : Boolean := False;
      Tunnel_Toggle     : Boolean := False;
      Mode_Ack          : Boolean := False;
      Text_N            : Natural range 0 .. Max_Text_Acks := 0;
      Texts             : Text_Acks_T := (others => 0);
   end record;

   None : constant Actions_T := (others => <>);

   Latched : Actions_T := None;
   Current : Actions_T := None;

   function Override_EOA return Boolean is (Current.Override_EOA)
     with Refined_Global => Current;
   function Shunting_Request return Boolean is (Current.Shunting_Request)
     with Refined_Global => Current;
   function Exit_Shunting return Boolean is (Current.Exit_Shunting)
     with Refined_Global => Current;
   function Maintain_Shunting return Boolean is (Current.Maintain_Shunting)
     with Refined_Global => Current;
   function Exit_Supervised_Manoeuvre return Boolean is (Current.Exit_SM)
     with Refined_Global => Current;
   function BMM_Inhibition return Boolean is (Current.BMM_Inhibition)
     with Refined_Global => Current;
   function Revoke_BMM_Inhibition return Boolean is (Current.BMM_Revoke)
     with Refined_Global => Current;
   function Tunnel_Toggle return Boolean is (Current.Tunnel_Toggle)
     with Refined_Global => Current;
   function Mode_Acknowledged return Boolean is (Current.Mode_Ack)
     with Refined_Global => Current;
   function Text_Ack_Count return Natural is (Current.Text_N)
     with Refined_Global => Current;
   function Text_Ack (I : Positive) return Unsigned_16 is
     (Current.Texts (I))
     with Refined_Global => Current;

   function Text_Acknowledged (Id : Unsigned_16) return Boolean
     with Refined_Global => Current
   is
   begin
      for I in 1 .. Current.Text_N loop
         if Current.Texts (I) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Text_Acknowledged;

   procedure Clear
     with Refined_Global => (Output => (Latched, Current))
   is
   begin
      Latched := None;
      Current := None;
   end Clear;

   procedure Latch (Frame : Byte_Array)
     with Refined_Global => (In_Out => Latched)
   is
      H      : constant Positive := Frame'First + EVC_DMI_Port.Header_Length;
      Action : Byte;
      Arg    : Unsigned_16;
   begin
      if not EVC_DMI_Port.Is_Driver_Action (Frame) then
         return;
      end if;
      --  a valid MSG_DRIVER_ACTION has three or five payload bytes
      Action := Frame (H);
      Arg := Get_U16 (Frame, H + 1);
      case Action is
         when EVC_DMI_Port.Action_Ack =>
            --  the long form only (Valid_Input_Frame): kind, then the id
            if Frame'Length = EVC_DMI_Port.Header_Length
                                + EVC_DMI_Port.Driver_Ack_Length
            then
               case Arg is
                  when Ack_Mode_Change =>
                     Latched.Mode_Ack := True;
                  when Ack_Fixed_Text | Ack_Plain_Text =>
                     if Latched.Text_N < Max_Text_Acks then
                        Latched.Text_N := Latched.Text_N + 1;
                        Latched.Texts (Latched.Text_N) :=
                          Get_U16 (Frame, H + 3);
                     end if;
                  when others =>
                     null;
               end case;
            end if;
         when Action_Tunnel_Toggle =>
            Latched.Tunnel_Toggle := True;
         when Action_Override_EOA =>
            Latched.Override_EOA := True;
         when Action_Shunting_Request =>
            Latched.Shunting_Request := True;
         when Action_Exit_Shunting =>
            Latched.Exit_Shunting := True;
         when Action_Supervised_Manoeuvre =>
            if Arg = 2 then
               Latched.Exit_SM := True;
            end if;
         when Action_BMM_Inhibition =>
            if Arg = 0 then
               Latched.BMM_Inhibition := True;
            elsif Arg = 1 then
               Latched.BMM_Revoke := True;
            end if;
         when Action_Maintain_Shunting =>
            Latched.Maintain_Shunting := True;
         when others =>
            null;
      end case;
   end Latch;

   procedure Take
     with Refined_Global => (In_Out => Latched, Output => Current)
   is
   begin
      Current := Latched;
      Latched := None;
   end Take;

end EVC_Procedure_Requests;
