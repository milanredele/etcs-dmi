--  ETCS on-board (EVC)
--  The driver's requests and entries from the DMI, implementation.

package body EVC_Driver_Requests
  with SPARK_Mode => On,
       Refined_State => (State => (Latched, Now, Ignored_N))
is

   MSG_DRIVER_ACTION : constant Byte := 16#40#;
   MSG_DRIVER_DATA   : constant Byte := 16#41#;
   Header_Length     : constant := 5;
   --  The largest frame the DMI port accepts (EVC_DMI_Port)
   Max_Frame         : constant := 512;

   type Selected_Array is array (Action_T) of Boolean;
   type Arg_Array is array (Action_T) of Unsigned_16;
   type Ack_Array is array (Ack_Kind_T) of Boolean;
   type Ack_Id_Array is array (Ack_Kind_T) of Unsigned_16;
   type Entered_Array is array (Data_Kind_T) of Boolean;
   type Data_Bytes_Array is array (Data_Kind_T) of Byte;
   type Code_Array is array (Data_Kind_T) of Unsigned_32;

   type Requests_T is record
      Selected : Selected_Array := (others => False);
      Args     : Arg_Array := (others => 0);
      Acks     : Ack_Array := (others => False);
      Ack_Ids  : Ack_Id_Array := (others => 0);
      Entered  : Entered_Array := (others => False);
      Driver   : Text_T;
      TRN      : Text_T;
      GSMR     : Text_T;
      Train    : Train_Entry_T;
      SR       : SR_Entry_T;
      RBC      : Bytes_23_T := (others => 0);
      Bytes    : Data_Bytes_Array := (others => 0);
      Codes    : Code_Array := (others => 0);
   end record;

   None : constant Requests_T := (others => <>);

   Latched   : Requests_T := None;
   Now       : Requests_T := None;
   Ignored_N : Natural := 0;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Selected (A : Action_T) return Boolean is (Now.Selected (A))
     with Refined_Global => Now;
   function Argument (A : Action_T) return Unsigned_16 is (Now.Args (A))
     with Refined_Global => Now;
   function Acknowledged (K : Ack_Kind_T) return Boolean is (Now.Acks (K))
     with Refined_Global => Now;
   function Ack_Id (K : Ack_Kind_T) return Unsigned_16 is (Now.Ack_Ids (K))
     with Refined_Global => Now;
   function Entered (K : Data_Kind_T) return Boolean is (Now.Entered (K))
     with Refined_Global => Now;
   function Driver_ID return Text_T is (Now.Driver)
     with Refined_Global => Now;
   function Train_Running_Number return Text_T is (Now.TRN)
     with Refined_Global => Now;
   function GSMR_Network return Text_T is (Now.GSMR)
     with Refined_Global => Now;
   function Train_Data return Train_Entry_T is (Now.Train)
     with Refined_Global => Now;
   function SR_Data return SR_Entry_T is (Now.SR)
     with Refined_Global => Now;
   function RBC_Data return Bytes_23_T is (Now.RBC)
     with Refined_Global => Now;
   function Data_Byte (K : Data_Kind_T) return Byte is (Now.Bytes (K))
     with Refined_Global => Now;
   function VBC_Code (K : Data_Kind_T) return Unsigned_32 is (Now.Codes (K))
     with Refined_Global => Now;
   function Isolation_Latched return Boolean is (Latched.Selected (Isolate))
     with Refined_Global => Latched;
   function Ignored return Natural is (Ignored_N)
     with Refined_Global => Ignored_N;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Latched := None;
      Now := None;
      Ignored_N := 0;
   end Clear;

   ----------
   -- Take --
   ----------

   procedure Take is
   begin
      Now := Latched;
      Latched := None;
   end Take;

   -------------
   -- Receive --
   -------------

   procedure Receive (Frame : Byte_Array) is

      procedure Ignore
        with Global => (In_Out => Ignored_N)
      is
      begin
         if Ignored_N < Natural'Last then
            Ignored_N := Ignored_N + 1;
         end if;
      end Ignore;

      --  A text entry: len u8 and len bytes at Frame (P .. Last)
      procedure Take_Text (P    : Positive;
                           Last : Natural;
                           T    : out Text_T;
                           OK   : out Boolean)
        with Pre => P >= Frame'First and then P <= Last
                       and then Last = Frame'Last
      is
         Len : constant Natural := Natural (Frame (P));
      begin
         T := (others => <>);
         OK := Len <= Max_Text and then Last - P = Len;
         if OK then
            T.Length := Len;
            for I in 1 .. Len loop
               T.Chars (I) := Frame (P + I);
            end loop;
         end if;
      end Take_Text;

   begin
      if Frame'Length < Header_Length + 1
        or else Frame'Length > Max_Frame
        or else Get_U32 (Frame, Frame'First + 1)
                  /= Unsigned_32 (Frame'Length - Header_Length)
      then
         return;
      end if;
      declare
         P : constant Positive := Frame'First + Header_Length;
         N : constant Positive := Frame'Length - Header_Length;
      begin
         if Frame (Frame'First) = MSG_DRIVER_ACTION then
            --  action u8, arg u16; action 2: kind u16, id u16
            if N = 3 and then Frame (P) <= 20 and then Frame (P) /= 2 then
               declare
                  A : constant Action_T := Action_T'Val (Frame (P));
               begin
                  Latched.Selected (A) := True;
                  Latched.Args (A) := Get_U16 (Frame, P + 1);
               end;
            elsif N = 5 and then Frame (P) = 2
              and then Get_U16 (Frame, P + 1) <= 6
            then
               declare
                  K : constant Ack_Kind_T :=
                    Ack_Kind_T'Val (Get_U16 (Frame, P + 1));
               begin
                  Latched.Selected (Acknowledge) := True;
                  Latched.Args (Acknowledge) := Get_U16 (Frame, P + 1);
                  Latched.Acks (K) := True;
                  Latched.Ack_Ids (K) := Get_U16 (Frame, P + 3);
               end;
            end if;

         elsif Frame (Frame'First) = MSG_DRIVER_DATA then
            if Frame (P) > 10 then
               Ignore;
               return;
            end if;
            declare
               K  : constant Data_Kind_T := Data_Kind_T'Val (Frame (P));
               OK : Boolean := False;
               T  : Text_T;
            begin
               case K is
                  when Driver_ID =>
                     if N >= 2 then
                        Take_Text (P + 1, Frame'Last, T, OK);
                        if OK then
                           Latched.Driver := T;
                        end if;
                     end if;
                  when Train_Running_Number =>
                     if N >= 2 then
                        Take_Text (P + 1, Frame'Last, T, OK);
                        if OK then
                           Latched.TRN := T;
                        end if;
                     end if;
                  when GSMR_Network =>
                     if N >= 2 then
                        Take_Text (P + 1, Frame'Last, T, OK);
                        if OK then
                           Latched.GSMR := T;
                        end if;
                     end if;
                  when Train_Data =>
                     OK := N = 13;
                     if OK then
                        Latched.Train :=
                          (Length_M         => Get_U16 (Frame, P + 1),
                           Brake_Percentage => Get_U16 (Frame, P + 3),
                           Max_Speed_Kmh    => Get_U16 (Frame, P + 5),
                           Cant_Deficiency  => Frame (P + 7),
                           Other_Categories => Get_U16 (Frame, P + 8),
                           Axle_Load        => Frame (P + 10),
                           Airtight         => Frame (P + 11),
                           Loading_Gauge    => Frame (P + 12));
                     end if;
                  when SR_Data =>
                     OK := N = 5;
                     if OK then
                        Latched.SR :=
                          (Speed_Kmh  => Get_U16 (Frame, P + 1),
                           Distance_M => Get_U16 (Frame, P + 3));
                     end if;
                  when RBC_Data =>
                     OK := N = 24;
                     if OK then
                        for I in Bytes_23_T'Range loop
                           Latched.RBC (I) := Frame (P + I);
                        end loop;
                     end if;
                  when Radio_Network_Type | One_Radio_System =>
                     OK := N = 2;
                     if OK then
                        Latched.Bytes (K) := Frame (P + 1);
                     end if;
                  when Set_VBC | Remove_VBC =>
                     OK := N = 5;
                     if OK then
                        Latched.Codes (K) := Get_U32 (Frame, P + 1);
                     end if;
                  when Language =>
                     OK := N = 3;
                     if OK then
                        Latched.Bytes (K) := Frame (P + 1);
                        Latched.Codes (K) :=
                          Unsigned_32 (Frame (P + 1))
                          + 256 * Unsigned_32 (Frame (P + 2));
                     end if;
               end case;
               if OK then
                  Latched.Entered (K) := True;
               else
                  Ignore;
               end if;
            end;
         end if;
      end;
   end Receive;

end EVC_Driver_Requests;
