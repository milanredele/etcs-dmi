--  ETCS on-board (EVC)
--  the radio networks of 3.5.6 (the
--  specification says which clauses and decisions).

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Track_Packets.P45;
with EVC_Bytes;
with EVC_Radio_Acceptance;
with Interfaces;   use Interfaces;

package body EVC_Sessions.Network
  with SPARK_Mode => On,
       Refined_State => (State => (Reg, Due, Started, Systems, One_Radio,
                                   Awaiting, Ordered, Ord_Type, Ord_MN,
                                   List_Now, Def_MN, Order_At, Watching,
                                   Timed_Out, Mode_Now, Exit_Seen,
                                   Trip_Stamp, Trip_Pending, FRMCS_Reg,
                                   FRMCS_Seen, FRMCS_At, FRMCS_Watch,
                                   FRMCS_Out, Type_Wait, Rewatch))
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
   --  5.4.3.2 S4: the time the latest registration order was sent, its
   --  outcome watched, the time of A.3.1 elapsed without it
   Order_At  : R.Time_Ms_T := 0;
   Watching  : Boolean := False;
   Timed_Out : Boolean := False;
   --  the desk closed during the start of mission: the wait's outcome to
   --  forget once that start of mission has left S4 (Desk_Closed_In_SoM)
   Rewatch   : Boolean := False;
   --  4.8.4 for packet 45 by radio: the mode, and in PT whether message
   --  6 was received since PT was entered ([1])
   Mode_Now  : Mode_T := M_NP;
   Exit_Seen : Boolean := False;
   --  the on-board's T_TRAIN at the entry into TR (taken by the next
   --  Evaluate, Trip_Pending until then): a message 6 counts for [1]
   --  only with a more recent time stamp
   Trip_Stamp   : ETCS_Variables.T_TRAIN_T := 0;
   Trip_Pending : Boolean := False;
   --  3.5.6.1.3: the FRMCS on-board's latest report, whether it reported
   --  since the power-up and when first (its detection as connected,
   --  5.4.3.2 S4 E71; the power-up's time until it reports), the wait
   --  for it watched, the time of A.3.1 elapsed without its registration
   FRMCS_Reg    : Boolean := False;
   FRMCS_Seen   : Boolean := False;
   FRMCS_At     : R.Time_Ms_T := 0;
   FRMCS_Watch  : Boolean := False;
   FRMCS_Out    : Boolean := False;

   --  5.4.3.2 S3 -> A41: the driver named FRMCS in the Radio Network type
   --  while the FRMCS on-board is installed and not registered; the
   --  on-board waits for the registration to be achieved or considered
   --  failed (A41)
   Type_Wait    : Boolean := False;

   --  5.4.3.2 S4, its time out: SUBSET-026 A.3.1 (page 218), "Time from
   --  the latest Radio Network registration order to a Mobile Terminal
   --  after which the registration is considered as failed": 40 s
   Registration_Time_Ms : constant := 40_000;

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
      Order_At := 0;
      Watching := False;
      Timed_Out := False;
      Mode_Now := M_NP;
      Exit_Seen := False;
      Trip_Stamp := 0;
      Trip_Pending := False;
      FRMCS_Reg := False;
      FRMCS_Seen := False;
      FRMCS_At := 0;
      FRMCS_Watch := False;
      FRMCS_Out := False;
      Type_Wait := False;
      Rewatch := False;
   end Clear;

   --  at least one GSM-R Mobile Terminal registered
   function GSMR_Registered return Boolean is
     (for some S in R.Session_T => Reg (S))
     with Global => Reg;

   --  the FRMCS on-board registered to the FRMCS Radio Network, by its
   --  latest report (the port's events 7 and 8), FRMCS installed
   function FRMCS_Registered return Boolean is
     (FRMCS_Reg and then Systems /= EVC_Config.GSMR_Only)
     with Global => (FRMCS_Reg, Systems);

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
   --  @req 3.5.6.5 a)
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
   --  @req 3.18.4.3.6.3
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

   procedure Take_FRMCS (Registered : Boolean; Now : EVC_Radio.Time_Ms_T) is
   begin
      --  the first report is the detection as connected (S4 E71): the
      --  time of A.3.1 counts from it, replacing the power-up's; a
      --  failure already declared (FRMCS_Out) is not watched again
      if not FRMCS_Seen then
         FRMCS_Seen := True;
         FRMCS_At := Now;
         FRMCS_Watch := not FRMCS_Out;
      end if;
      if Registered then
         --  E61: the wait ends, the failure of A42 is over
         FRMCS_Watch := False;
         FRMCS_Out := False;
      end if;
      FRMCS_Reg := Registered;
   end Take_FRMCS;

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

   --  4.8.4 [1]: the time stamp Stamp is more recent than the on-board's
   --  T_TRAIN at the entry into TR (modulo the clock, up to half of it
   --  ahead; 2**32 - 1 is "unknown", never more recent)
   --  @req 4.8.4.2 Table-footnote [1]
   function Later_Than_Trip (Stamp : Unsigned_64) return Boolean is
     (Stamp < 2**32 - 1
      and then (Stamp + (2**32 - 1) - Unsigned_64 (Trip_Stamp))
                 mod (2**32 - 1) in 1 .. (2**32 - 1) / 2)
     with Global => Trip_Stamp;

   procedure Take_Radio_Order
     (Kind        : ETCS_Message_Catalogue.Message_Kind_T;
      Cab_Active  : Boolean;
      Level_Valid : Boolean;
      Level       : Level_T)
   is
      use type ETCS_Message_Catalogue.Message_Kind_T;
      use type EVC_Radio_Acceptance.Verdict_T;
      pragma Warnings
        (GNATprove, Off, """Rd"" is set by ""Decode"" but not used after*",
         Reason => "the reader of one packet is not used after it");
      Rd : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      P  : ETCS_Track_Packets.P45.Packet_T;
      OK : Boolean;
      C  : constant EVC_Radio_Acceptance.Context_T :=
        (Mode => Mode_Now, Level_Valid => Level_Valid, Level => Level,
         Cab_Active => Cab_Active, Trip_Exit_Known => Exit_Seen,
         others => <>);
   begin
      --  4.8.4 [1]: the recognition of the exit from TR, accepted in PT
      --  only (EVC_Radio_Acceptance, Trip_Exit)
      --  decision: "with a more recent time stamp" is the T_TRAIN of
      --  message 6 later than the on-board's at the entry into TR; a
      --  message 6 sent before the trip does not count
      if Kind = ETCS_Message_Catalogue.Track_M6 and then Mode_Now = M_PT
        and then not Trip_Pending
        and then Later_Than_Trip
                   (EVC_Received.Last_Value (ETCS_Variables.T_TRAIN))
      then
         Exit_Seen := True;
         R.Set_Trip_Exit_Recognised (True);
      end if;
      --  packet 45 by radio: message 24 (the messages 3 and 33 carry it
      --  through EVC_Stored_Information; message 4, the SM authorisation
      --  of 4.8.4 [13], is not taken by this on-board)
      if Kind /= ETCS_Message_Catalogue.Track_M24
        or else EVC_Radio_Acceptance.Verdict
                  (EVC_Radio_Acceptance.Network_Order, C)
                /= EVC_Radio_Acceptance.Accepted
      then
         return;
      end if;
      for I in 1 .. EVC_Received.Last_Packet_Count loop
         pragma Loop_Invariant (True);
         if EVC_Received.Last_Packet_Kind (I) = ETCS_Catalogue.Track_P45
         then
            EVC_Received.Open_Message_Packet (I, Rd);
            ETCS_Track_Packets.P45.Decode (Rd, P, OK);
            --  3.6.3.1.3: valid for the train orientation relative to the
            --  LRBG of the message
            if OK and then ETCS_Track_Packets.P45.Valid (P)
              and then EVC_Position.Radio_Valid_For (Last_LRBG, P.Q_DIR)
            then
               Take_Order (Natural (P.Q_NETWORKTYPE), P.NID_MN);
            end if;
         end if;
      end loop;
   end Take_Radio_Order;

   procedure Mode_Changed (To : Mode_T) is
   begin
      if To /= Mode_Now then
         Exit_Seen := False;
         R.Set_Trip_Exit_Recognised (False);
         if To = M_TR then
            Trip_Pending := True;
         end if;
         if To /= M_SB then
            --  the start of mission left: no S3 to return to
            Type_Wait := False;
         end if;
      end if;
      Mode_Now := To;
   end Mode_Changed;

   function Accepts (Kind        : ETCS_Message_Catalogue.Message_Kind_T;
                     Cab_Active  : Boolean;
                     Level_Valid : Boolean;
                     Level       : Level_T) return Boolean
   is (EVC_Radio_Acceptance."="
         (EVC_Radio_Acceptance.Verdict
            (EVC_Radio_Acceptance.Info_Of (Kind),
             (Mode => Mode_Now, Level_Valid => Level_Valid, Level => Level,
              Cab_Active => Cab_Active, Trip_Exit_Known => Exit_Seen,
              others => <>)),
          EVC_Radio_Acceptance.Accepted))
     with Refined_Global => (Mode_Now, Exit_Seen);

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
   --  memorized, and the registration ordered (decision 3). FRMCS
   --  installed and not reported yet: decision: the time of A.3.1
   --  counts from the power-up (Now), the earliest moment the FRMCS
   --  on-board can be detected (3.5.6.1.3: it reports as soon as it is
   --  powered-up), so that the waits of 5.4.3.2 S3 (A41) and S4 (E71,
   --  A42) end with no report ever; its first report replaces it
   --  (Take_FRMCS)
   --  @req 3.5.6.1 a), 3.5.6.3, 3.5.6.4
   procedure Power_Up (Now : R.Time_Ms_T)
     with Global => (In_Out => (R.State, Due, FRMCS_At, FRMCS_Watch),
                     Output => (Systems, Def_MN),
                     Input  => (Reg, FRMCS_Seen, EVC_Config.State))
   is
      C : constant EVC_Config.Radio_Config_T := EVC_Config.Current_Radio;
      N : R.Network_T := R.Network;
   begin
      Systems := C.Systems;
      if not FRMCS_Seen and then Systems /= EVC_Config.GSMR_Only then
         FRMCS_At := Now;
         FRMCS_Watch := True;
      end if;
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
   --  @req 3.5.6.1 b), 3.18.4.3.6, 3.18.4.3.6.1 a), 3.18.4.3.6.1 b)
   --  @req 3.18.4.3.6.3 a), 3.18.4.3.6.3 b), 5.4.3.2 A29
   --  @req 5.4.3.2 D8, 5.4.3.2 S3, 5.4.5.3 j) 2nd bullet
   --  @req 5.4.3.2 S5
   procedure Driver_Entries (Stop, Failed : in out Boolean)
     with Global => (In_Out => (R.State, Due, One_Radio, Awaiting,
                                Type_Wait),
                     Output => List_Now,
                     Input  => (Reg, Systems, Def_MN, FRMCS_Reg, Mode_Now,
                                DR.State))
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
            --  S3 -> A41: FRMCS or FRMCS+GSM-R selected, FRMCS installed
            --  and not registered (S3 is a step of the start of
            --  mission, in SB); Supervise_Wait goes to A41
            Type_Wait := Mode_Now = M_SB
              and then N.Net_Type /= EVC_Config.GSMR
              and then Systems /= EVC_Config.GSMR_Only
              and then not FRMCS_Reg;
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
            --  cycle; S3 -> A29 when it is empty
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

   --  5.4.3.2 S4, Radio Network type GSM-R or
   --  GSM-R the only system: a mobile registered ends the watch
   --  (-> A31); the time of A.3.1 since the latest order elapsed
   --  without it: A42, the driver informed ("GSM-R network registration
   --  failed", entry 34), then D9 -> S10 (decision: the on-board ends
   --  the wait of S4, MSG_ONBOARD waiting 1, and the set-up request
   --  stays due under 3.5.6.7; the driver's new network is A43's
   --  restart, the next order watched again). FRMCS the only system
   --  for the stored type: its registration ends the watch (E61), the
   --  time since its detection as connected elapsed without it (E71):
   --  A42, "FRMCS network registration failed" (FRMCS_Failed, entry
   --  33). Both systems: both registered end the watch (E62; either,
   --  once the driver elected the mission with one radio system), the
   --  time since the latest GSM-R order elapsed (E72): A42 for each
   --  system not registered. S4 is a step of the start of mission
   --  (In_SoM): outside it the watch goes on silently, so that a start
   --  of mission reaching S4 after the time fails at once (the time
   --  counts from the latest order, or from the FRMCS detection, the
   --  power-up while the FRMCS on-board has not reported: Power_Up).
   --  S3 -> A41 (Type_Wait): decision: "not registered" is read as the
   --  registration considered failed, the time of A.3.1 since the
   --  FRMCS detection elapsed without it (A41 informs that it "has
   --  failed"); until then the on-board waits as at S4 (the hour glass,
   --  EVC_Sessions.SoM_Awaiting_Registration), its registration ends
   --  the wait at S3 with no message; the time elapsed: A41,
   --  "FRMCS network registration failed" (FRMCS_Failed, entry 33),
   --  then D8: S3 again (the stored type FRMCS+GSM-R with both
   --  systems installed) or S10, the wait ended either way
   --  @req 5.4.3.2 A42, 5.4.3.2 S4, 5.4.3.2 A41
   procedure Supervise_Wait (Now          : R.Time_Ms_T;
                             In_SoM       : Boolean;
                             Failed       : in out Boolean;
                             FRMCS_Failed : in out Boolean)
     with Global => (In_Out => (Watching, Timed_Out, FRMCS_Watch,
                                FRMCS_Out, Type_Wait, Rewatch),
                     Input  => (Order_At, Reg, FRMCS_Reg, FRMCS_At,
                                Systems, One_Radio, R.State))
   is
      T     : constant EVC_Config.Network_Type_T := R.Network.Net_Type;
      Alone : constant Boolean :=
        Systems /= EVC_Config.GSMR_Only
        and then (T = EVC_Config.FRMCS
                  or else (T = EVC_Config.FRMCS_GSMR
                           and then Systems = EVC_Config.FRMCS_Only));
      Both  : constant Boolean :=
        T = EVC_Config.FRMCS_GSMR
        and then Systems = EVC_Config.Both_Systems;
   begin
      --  Desk_Closed_In_SoM: In_SoM is the step of the last cycle, so the
      --  ended start of mission's S4 is forgotten once it is left
      if Rewatch and then not In_SoM then
         Rewatch := False;
         Watching := Watching or else Timed_Out;
         Timed_Out := False;
         FRMCS_Watch := FRMCS_Watch or else FRMCS_Out;
         FRMCS_Out := False;
      end if;
      if Type_Wait then
         if FRMCS_Reg then
            Type_Wait := False;
         elsif Now >= FRMCS_At
           and then Now - FRMCS_At >= Registration_Time_Ms
         then
            Type_Wait := False;
            FRMCS_Failed := True;
         end if;
      end if;
      if Alone then
         if FRMCS_Watch and then In_SoM and then Now >= FRMCS_At
           and then Now - FRMCS_At >= Registration_Time_Ms
         then
            FRMCS_Watch := False;
            FRMCS_Out := True;
            FRMCS_Failed := True;
         end if;
         return;
      end if;
      if not Watching then
         return;
      end if;
      if (if not Both then GSMR_Registered
          elsif One_Radio then GSMR_Registered or else FRMCS_Registered
          else GSMR_Registered and then FRMCS_Registered)
      then
         Watching := False;
      elsif In_SoM and then Now >= Order_At
        and then Now - Order_At >= Registration_Time_Ms
      then
         Watching := False;
         Timed_Out := True;
         Failed := Failed or else not GSMR_Registered;
         FRMCS_Failed := FRMCS_Failed
           or else (Both and then not FRMCS_Registered);
      end if;
   end Supervise_Wait;

   --  @req A.3.4.1.3 Table
   procedure Desk_Closed_In_SoM is
   begin
      One_Radio := False;
      Rewatch := True;
   end Desk_Closed_In_SoM;

   procedure Evaluate (Now    : EVC_Radio.Time_Ms_T;
                       In_SoM : Boolean;
                       Stop, Failed, FRMCS_Failed : out Boolean)
   is
   begin
      Stop := False;
      Failed := False;
      FRMCS_Failed := False;
      if Trip_Pending then
         Trip_Stamp := R.T_Train_At (Now);
         Trip_Pending := False;
      end if;
      if not Started then
         Started := True;
         Power_Up (Now);
      end if;
      if Ordered then
         Ordered := False;
         Apply_Order (Ord_Type, Ord_MN);
      end if;
      Driver_Entries (Stop, Failed);
      Supervise_Wait (Now, In_SoM, Failed, FRMCS_Failed);
   end Evaluate;

   --  3.5.6.5 b) c), 3.5.6.6: a mobile whose session is not Idle waits
   procedure Produce (Now : EVC_Radio.Time_Ms_T) is
      N : constant R.Network_T := R.Network;
   begin
      for S in R.Session_T loop
         pragma Loop_Invariant (True);
         if Due (S) and then R.Info (S).State = R.Idle then
            R.Request_Registration (S, N.NID_MN);
            --  5.4.3.2 S4: the latest order, watched from now (A43)
            Order_At := Now;
            Watching := True;
            Timed_Out := False;
            Due (S) := False;
            Reg (S) := False;
         end if;
      end loop;
      Publish (R.Network);
   end Produce;

   --  3.5.6.7 a) to d) (decision 5)
   --  3.5.6.7 a) to d) for the Radio Network type T, GSMR telling
   --  whether a GSM-R Mobile Terminal is registered to the network
   function Ready_For (T : EVC_Config.Network_Type_T; GSMR : Boolean)
     return Boolean
   is
     (case T is
         when EVC_Config.FRMCS =>
            FRMCS_Registered,
         when EVC_Config.GSMR =>
            GSMR,
         when EVC_Config.FRMCS_GSMR =>
           (case Systems is
               when EVC_Config.FRMCS_Only => FRMCS_Registered,
               when EVC_Config.GSMR_Only  => GSMR,
               when EVC_Config.Both_Systems =>
                 (if One_Radio
                  then FRMCS_Registered or else GSMR
                  else FRMCS_Registered and then GSMR)))
     with Global => (Systems, One_Radio, FRMCS_Reg);

   function Ready return Boolean is
     (Ready_For (R.Network.Net_Type, GSMR_Registered))
     with Refined_Global => (Reg, Systems, One_Radio, FRMCS_Reg, R.State);

   --  decision: registered to the ordered GSM-R network when a mobile is
   --  registered, no registration of it is due and the network stored
   --  (or the configured default, Power_Up) is the ordered one; received
   --  together: the order taken in the cycle of the session order, not
   --  applied yet (Evaluate applies it after the session order)
   function Order_Unregistered return Boolean is
     (Ordered and then Ord_Type <= 2
      and then not Ready_For
        (EVC_Config.Network_Type_T'Val (Ord_Type),
         (for some S in R.Session_T => Reg (S) and then not Due (S))
         and then R.Network.NID_MN = Ord_MN))
     with Refined_Global => (Ordered, Ord_Type, Ord_MN, Reg, Due, Systems,
                             One_Radio, FRMCS_Reg, R.State);

   function Radio_Bits return Natural is
     (EVC_Config.Network_Type_T'Pos (R.Network.Net_Type) + 1
      + 4 * (EVC_Config.Radio_Systems_T'Pos (Systems) + 1)
      + (if FRMCS_Registered then 16 else 0)
      + (if GSMR_Registered then 32 else 0)
      + (if One_Radio then 64 else 0))
     with Refined_Global => (Reg, Systems, One_Radio, FRMCS_Reg, R.State);

   function Selection_Awaited return Boolean is (Awaiting)
     with Refined_Global => Awaiting;

   function Registration_Timed_Out return Boolean is
     (Timed_Out or else FRMCS_Out)
     with Refined_Global => (Timed_Out, FRMCS_Out);

   function Type_Awaited return Boolean is (Type_Wait)
     with Refined_Global => Type_Wait;

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
