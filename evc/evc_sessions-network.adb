--  ETCS on-board (EVC)
--  Phase E5 (e5/registration): the radio networks of 3.5.6 (the
--  specification says which clauses and decisions).

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Track_Packets.P45;
with EVC_Bytes;
with Interfaces;   use Interfaces;

package body EVC_Sessions.Network
  with SPARK_Mode => On,
       Refined_State => (State => (Reg, Due, Started, Systems, One_Radio,
                                   Awaiting, Ordered, Ord_Type, Ord_MN,
                                   List_Now, Def_MN))
is

   package R renames EVC_Radio;
   package DR renames EVC_Driver_Requests;
   use type R.Session_State_T;
   use type ETCS_Variables.NID_MN_T;
   use type EVC_Config.Network_Type_T;
   use type EVC_Config.Radio_Systems_T;
   use type ETCS_Catalogue.Packet_Kind_T;

   type Flags_T is array (R.Session_T) of Boolean;

   --  The mobile of each session registered (to the network it was last
   --  ordered to), its registration to order (3.5.6.5, 3.5.6.6)
   Reg       : Flags_T := (others => False);
   Due       : Flags_T := (others => False);
   --  the configuration taken and the power-up registration ordered
   Started   : Boolean := False;
   Systems   : EVC_Config.Radio_Systems_T := EVC_Config.Both_Systems;
   --  5.4.3.2 S3 / S5, DMI 11.3.16: mission with only one radio system
   One_Radio : Boolean := False;
   --  radio_wait 2 (common/dmi_protocol.ads)
   Awaiting  : Boolean := False;
   --  the Radio Network transition order of the cycle (packet 45)
   Ordered   : Boolean := False;
   Ord_Type  : Natural := 0;
   Ord_MN    : ETCS_Variables.NID_MN_T := 0;
   --  3.18.4.3.6.2: the list of networks to send in this cycle
   --  (MSG_RADIO_NETWORKS), the default network of the configuration
   List_Now  : Boolean := False;
   Def_MN    : ETCS_Variables.NID_MN_T := 0;

   procedure Clear is
   begin
      Reg := (others => False);
      Due := (others => False);
      Started := False;
      Systems := EVC_Config.Both_Systems;
      One_Radio := False;
      Awaiting := False;
      Ordered := False;
      Ord_Type := 0;
      Ord_MN := 0;
      List_Now := False;
      Def_MN := 0;
   end Clear;

   --  at least one GSM-R Mobile Terminal registered
   function GSMR_Registered return Boolean is
     (for some S in R.Session_T => Reg (S))
     with Global => Reg;

   --  decision (2): not reported by the port yet
   function FRMCS_Registered return Boolean is (False);

   function GSMR_Installed return Boolean is
     (Systems /= EVC_Config.FRMCS_Only)
     with Global => Systems;

   --  EVC_Radio.Network with Registered from the mobiles
   procedure Publish (N : R.Network_T)
     with Global => (In_Out => R.State, Input => Reg)
   is
      Full : R.Network_T := N;
   begin
      Full.Registered := GSMR_Registered;
      R.Set_Network (Full);
   end Publish;

   --  3.5.6.1, 3.5.6.5 a): order the registration of each mobile the
   --  on-board handles (All_Of) or of those not registered
   procedure Order (All_Of : Boolean)
     with Global => (In_Out => Due, Input => (Reg, Systems, R.State))
   is
   begin
      if not GSMR_Installed then
         return;
      end if;
      for S in R.Session_T loop
         pragma Loop_Invariant (True);
         if R.Usable (S) and then (All_Of or else not Reg (S)) then
            Due (S) := True;
         end if;
      end loop;
   end Order;

   --  3.18.4.3.6.3, 5.4.3.2 S3: the RBC contact, if not "unknown", is
   --  set to "invalid"
   procedure Invalidate_Contact
     with Global => (In_Out => R.State)
   is
      C : R.RBC_Contact_T := R.Contact;
   begin
      if C.Known and then C.Valid then
         C.Valid := False;
         R.Set_Contact (C);
      end if;
   end Invalidate_Contact;

   procedure Take_Event (S : EVC_Radio.Session_T; Registered : Boolean) is
   begin
      if not R.Usable (S) then
         return;
      end if;
      Reg (S) := Registered;
      Awaiting := False;
      Publish (R.Network);
   end Take_Event;

   --  3.5.6.1 c), 3.5.6.5: the type stored; the GSM-R network ordered
   --  to the mobiles not registered to it (decision 4: Produce waits for
   --  a session not Idle, 3.5.6.6)
   procedure Apply_Order (Q_Type : Natural;
                          NID_MN : ETCS_Variables.NID_MN_T)
     with Global => (In_Out => (R.State, Due), Input => (Reg, Systems))
   is
      N   : R.Network_T := R.Network;
      New_MN : Boolean;
   begin
      if Q_Type > 2 then
         return;
      end if;
      N.Net_Type := EVC_Config.Network_Type_T'Val (Q_Type);
      N.Type_Known := True;
      if Q_Type in 1 | 2 then
         New_MN := not N.Known or else N.NID_MN /= NID_MN;
         N.Known := True;
         N.NID_MN := NID_MN;
         Order (All_Of => New_MN);
      end if;
      Publish (N);
   end Apply_Order;

   procedure Take_Order (Q_Type : Natural;
                         NID_MN : ETCS_Variables.NID_MN_T) is
   begin
      Ordered := True;
      Ord_Type := Q_Type;
      Ord_MN := NID_MN;
   end Take_Order;

   procedure Take_Radio_Order is
      pragma Warnings
        (GNATprove, Off, """Rd"" is set by ""Decode"" but not used after*",
         Reason => "the reader of one packet is not used after it");
      Rd : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      P  : ETCS_Track_Packets.P45.Packet_T;
      OK : Boolean;
   begin
      for I in 1 .. EVC_Received.Last_Packet_Count loop
         pragma Loop_Invariant (True);
         if EVC_Received.Last_Packet_Kind (I) = ETCS_Catalogue.Track_P45
         then
            EVC_Received.Open_Message_Packet (I, Rd);
            ETCS_Track_Packets.P45.Decode (Rd, P, OK);
            if OK and then ETCS_Track_Packets.P45.Valid (P) then
               Take_Order (Natural (P.Q_NETWORKTYPE), P.NID_MN);
            end if;
         end if;
      end loop;
   end Take_Radio_Order;

   --  DMI 11.3.4 / Table 49 S3-2-2: the network the driver selected,
   --  its name the NID_MN digits (decision 6: 7.5.1.91.1, one digit per
   --  nibble, left adjusted, F the filler); OK False for anything else
   procedure Parse_MN (T      : DR.Text_T;
                       MN     : out ETCS_Variables.NID_MN_T;
                       OK     : out Boolean)
     with Global => null
   is
      V : Natural range 0 .. 2 ** 24 - 1 := 0;
      D : Natural range 0 .. 15;
   begin
      MN := 0;
      OK := T.Length in 1 .. 6;
      if not OK then
         return;
      end if;
      for I in 1 .. 6 loop
         pragma Loop_Invariant (V < 2 ** 24);
         if I <= T.Length then
            if T.Chars (I) not in Character'Pos ('0') .. Character'Pos ('9')
            then
               OK := False;
               return;
            end if;
            D := Natural (T.Chars (I)) - Character'Pos ('0');
         else
            D := 15;
         end if;
         --  below 16 ** 5 before the sixth digit: the mod changes nothing
         V := (V mod 2 ** 20) * 16 + D;
      end loop;
      MN := ETCS_Variables.NID_MN_T (V);
   end Parse_MN;

   --  3.5.6.1 a), 3.5.6.3, 3.5.6.4: at the first cycle after the
   --  power-up, the defaults of the configuration where nothing was
   --  memorized, and the registration ordered (decision 3)
   procedure Power_Up
     with Global => (In_Out => (R.State, Due),
                     Output => (Systems, Def_MN),
                     Input  => (Reg, EVC_Config.State))
   is
      C : constant EVC_Config.Radio_Config_T := EVC_Config.Current_Radio;
      N : R.Network_T := R.Network;
   begin
      Systems := C.Systems;
      Def_MN := ETCS_Variables.NID_MN_T (C.Default_MN);
      if not N.Type_Known then
         N.Net_Type := C.Default_Type;
      end if;
      if not N.Known then
         N.NID_MN := ETCS_Variables.NID_MN_T (C.Default_MN);
      end if;
      Order (All_Of => True);
      Publish (N);
   end Power_Up;

   --  3.18.4.3.6, 5.4.3.2 S3 / S5: the driver's Radio Network type,
   --  GSM-R network and mission with only one radio system
   procedure Driver_Entries (Stop, Failed : in out Boolean)
     with Global => (In_Out => (R.State, Due, One_Radio, Awaiting),
                     Output => List_Now,
                     Input  => (Reg, Systems, Def_MN, DR.State))
   is
      N  : R.Network_T := R.Network;
      B  : EVC_Bytes.Byte;
      MN : ETCS_Variables.NID_MN_T;
      OK : Boolean;
   begin
      List_Now := False;
      if DR.Entered (DR.Radio_Network_Type) then
         B := DR.Data_Byte (DR.Radio_Network_Type);
         --  DMI Table 43b: 1 FRMCS, 2 FRMCS+GSM-R, 3 GSM-R
         if B in 1 .. 3 then
            if EVC_Config.Network_Type_T'Val (B - 1) /= N.Net_Type then
               --  3.18.4.3.6.1 a), 3.18.4.3.6.3 a)
               Stop := True;
               Invalidate_Contact;
            end if;
            N.Net_Type := EVC_Config.Network_Type_T'Val (B - 1);
            N.Type_Known := True;
            Publish (N);
         end if;
      end if;
      if DR.Entered (DR.One_Radio_System) then
         One_Radio := DR.Data_Byte (DR.One_Radio_System) = 1;
      end if;
      if DR.Entered (DR.GSMR_Network) then
         --  3.18.4.3.6.1 b): the driver elects to modify the network
         Stop := True;
         if DR.GSMR_Network.Length = 0 then
            --  3.18.4.3.6.2: the list acquired and offered in this
            --  cycle; S3 E3 -> A29 when it is empty
            List_Now := True;
            Failed := Offered_Count = 0;
         else
            Parse_MN (DR.GSMR_Network, MN, OK);
            if OK then
               --  3.5.6.1 b), 3.18.4.3.6.2, 3.18.4.3.6.3 b)
               N := R.Network;
               N.Known := True;
               N.NID_MN := MN;
               Order (All_Of => True);
               Awaiting := GSMR_Installed;
               Invalidate_Contact;
               Publish (N);
            end if;
         end if;
      end if;
   end Driver_Entries;

   procedure Evaluate (Stop, Failed : out Boolean) is
   begin
      Stop := False;
      Failed := False;
      if not Started then
         Started := True;
         Power_Up;
      end if;
      if Ordered then
         Ordered := False;
         Apply_Order (Ord_Type, Ord_MN);
      end if;
      Driver_Entries (Stop, Failed);
   end Evaluate;

   --  3.5.6.5 b) c), 3.5.6.6: a mobile whose session is not Idle waits
   procedure Produce is
      N : constant R.Network_T := R.Network;
   begin
      for S in R.Session_T loop
         pragma Loop_Invariant (True);
         if Due (S) and then R.Info (S).State = R.Idle then
            R.Request_Registration (S, N.NID_MN);
            Due (S) := False;
            Reg (S) := False;
         end if;
      end loop;
      Publish (R.Network);
   end Produce;

   --  3.5.6.7 a) to d) (decision 5)
   function Ready return Boolean is
     (case R.Network.Net_Type is
         when EVC_Config.FRMCS =>
            FRMCS_Registered,
         when EVC_Config.GSMR =>
            GSMR_Registered,
         when EVC_Config.FRMCS_GSMR =>
           (case Systems is
               when EVC_Config.FRMCS_Only => FRMCS_Registered,
               when EVC_Config.GSMR_Only  => GSMR_Registered,
               when EVC_Config.Both_Systems =>
                 (if One_Radio
                  then FRMCS_Registered or else GSMR_Registered
                  else FRMCS_Registered and then GSMR_Registered)))
     with Refined_Global => (Reg, Systems, One_Radio, R.State);

   function Radio_Bits return Natural is
     (EVC_Config.Network_Type_T'Pos (R.Network.Net_Type) + 1
      + 4 * (EVC_Config.Radio_Systems_T'Pos (Systems) + 1)
      + (if FRMCS_Registered then 16 else 0)
      + (if GSMR_Registered then 32 else 0)
      + (if One_Radio then 64 else 0))
     with Refined_Global => (Reg, Systems, One_Radio, R.State);

   function Selection_Awaited return Boolean is (Awaiting)
     with Refined_Global => Awaiting;

   function List_Due return Boolean is (List_Now)
     with Refined_Global => List_Now;

   --  a NID_MN names a network when its first BCD digit is one
   function Named (M : ETCS_Variables.NID_MN_T) return Boolean is
     (M / 2 ** 20 <= 9);

   function Stored_Offered return Boolean is
     (R.Network.Known and then R.Network.NID_MN /= Def_MN
      and then Named (R.Network.NID_MN))
     with Global => (Def_MN, R.State);

   function Offered_Count return Natural is
     ((if Named (Def_MN) then 1 else 0)
      + (if Stored_Offered then 1 else 0))
     with Refined_Global => (Def_MN, R.State);

   function Offered (I : Positive) return ETCS_Variables.NID_MN_T is
     (if I = 1 and then Named (Def_MN) then Def_MN else R.Network.NID_MN)
     with Refined_Global => (Def_MN, R.State);

end EVC_Sessions.Network;
