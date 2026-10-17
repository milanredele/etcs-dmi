--  ETCS on-board (EVC)
--  The test bench of the SUBSET-076 runner, body.

pragma Ada_2012;
with Ada.Environment_Variables;
with Ada.Streams;     use Ada.Streams;
with DMI_Core;
with DMI_Protocol;
with EVC_Braking;
with EVC_Build_Up;
with EVC_Core;
with EVC_Distances;
with EVC_DMI_Port;
with EVC_Modes;
with EVC_National_Values;
with EVC_Supervision_Input;
with EVC_Fixed;
with EVC_Outbox;
with EVC_Ports;       use EVC_Ports;
with EVC_Position;
with EVC_SDM;

package body S076_Bench is


   use type EVC_Bytes.Byte_Array;

   ---------------------------------------------------------------------
   --  State of the world
   ---------------------------------------------------------------------

   Is_Powered : Boolean := False;
   --  the on-board was powered since Reset: a power-up after it keeps
   --  the data of 4.10 column NP (EVC_Core.Power_Up), the first one is
   --  that of a new on-board (EVC_Core.Initialise)
   Was_Powered : Boolean := False;
   Radio_Systems : EVC_Config.Radio_Systems_T := EVC_Config.Both_Systems;
   Voltages : Natural := EVC_Config.Default_Fixed_Train.Voltages;
   Clock      : Unsigned_64 := 0;

   X_Cm      : Integer_64 := 0;     -- antenna, track position
   V_Cms     : Natural := 0;
   Dir       : Integer := 1;
   Odo_Over  : Integer_64 := 0;
   Odo_Under : Integer_64 := 0;
   Acc       : Integer_64 := Accuracy_Per_Mille;
   --  B191: the speed's confidence interval of SUBSET-041 5.3.1.2
   Speed_Acc : Boolean := False;
   --  B262: the speed asked for (Set_Speed), the braking model's
   --  percentage (0: none), and whether the train is below the speed
   --  asked for because of a brake
   Demand_Cms : Natural := 0;
   Lambda     : Natural := 0;
   Is_Braked  : Boolean := False;
   Spent      : Boolean := False;   -- Forced_Spent
   Service_On     : Boolean := True;
   Floor_Cms  : Natural := 0;

   Max_Balises : constant := 64;
   type Balise_T is record
      At_Cm : Integer_64 := 0;
      Bits  : Natural := 0;
      Data  : Byte_Array (1 .. 104) := (others => 0);
      Used  : Boolean := False;
      --  already passed when placed: delivered at the next cycle
      Immediate : Boolean := False;
   end record;
   Balises : array (1 .. Max_Balises) of Balise_T;

   --  frames of the DMI for the on-board's next cycle
   Max_Pending : constant := 32;
   type Frame_Slot_T is record
      Data   : Byte_Array (1 .. 600) := (others => 0);
      Length : Natural := 0;
   end record;
   Pending       : array (1 .. Max_Pending) of Frame_Slot_T;
   Pending_Count : Natural := 0;

   Now     : State_T;
   Win     : Seen_T;
   Cycles  : Natural := 0;

   JRU_List  : array (1 .. Max_JRU) of JRU_Record_T;
   JRU_N     : Natural := 0;

   --  The messages of the window, as received on the port JRU
   type Message_Slot_T is record
      Length : Natural := 0;
      Data   : Byte_Array (1 .. EVC_Ports.JRU_Max_Length) := (others => 0);
   end record;
   Messages   : array (1 .. Max_Messages) of Message_Slot_T;
   Messages_N : Natural := 0;
   Last_Mode, Last_Level_Status, Last_Level : Natural := No_Value;
   Last_Commands : Natural := 0;
   Last_Mon, Last_Sup : Natural := 0;

   --  The ring of the supervision changes (Change_T), the commands and
   --  status of the last cycle
   Changes      : array (1 .. Max_Changes) of Change_T;
   Change_Head  : Natural := 0;   -- the latest
   Changes_Kept : Natural := 0;
   Prev_Status  : EVC_SDM.Status_T := EVC_SDM.NoS;
   Prev_SB, Prev_EB, Prev_TCO : Boolean := False;
   LRBG_Known : Boolean := False;
   --  the identity (u24 of the JRU events 2 and 10) of the LRBG and of
   --  the last balise group whose telegram was accepted, No_Value before
   LRBG_Id, Last_BG_Id : Natural := No_Value;
   TC_Phase   : array (0 .. 255) of Integer := (others => -1);

   Texts   : array (1 .. Max_Events) of Text_Event_T;
   Texts_N : Natural := 0;
   SSs     : array (1 .. Max_Events) of SS_Event_T;
   SSs_N   : Natural := 0;
   Sent_N  : Natural := 0;

   Radio_List : array (1 .. Max_Radio) of Radio_Out_T;
   Radio_N    : Natural := 0;
   type Per_Session_I64 is array (1 .. RTM_Max_Sessions) of Integer_64;
   type Per_Session_U64 is array (1 .. RTM_Max_Sessions) of Unsigned_64;
   type Per_Session_Nat is array (1 .. RTM_Max_Sessions) of Natural;
   type By_Nid_T is array (1 .. RTM_Max_Sessions, 0 .. 255) of Integer_64;
   Last_T    : Per_Session_I64 := (others => -1);
   Last_Ms   : Per_Session_U64 := (others => 0);
   Last_Req  : Per_Session_Nat := (others => 0);
   --  e5/registration: the mobile of a session registers to the
   --  network it is ordered to in the next cycle (the sequences
   --  give SA-REGISTRATION.Indication in 12 cases only, "usually
   --  not specified"; the power-up registration of 3.5.6.1 a is
   --  silent in all)
   Registering : array (1 .. RTM_Max_Sessions) of Boolean :=
     (others => False);
   T_By_Nid  : By_Nid_T := (others => (others => -1));

   procedure Clear_Radio is
   begin
      Last_T := (others => -1);
      Last_Ms := (others => 0);
      Last_Req := (others => 0);
      Registering := (others => False);
      T_By_Nid := (others => (others => -1));
   end Clear_Radio;

   ---------------------------------------------------------------------
   --  Byte helpers
   ---------------------------------------------------------------------

   function Get16 (B : Byte_Array; I : Natural) return Natural is
     (Natural (B (I)) + 256 * Natural (B (I + 1)));

   function Get32 (B : Byte_Array; I : Natural) return Unsigned_32 is
     (Unsigned_32 (B (I)) + 256 * (Unsigned_32 (B (I + 1))
      + 256 * (Unsigned_32 (B (I + 2)) + 256 * Unsigned_32 (B (I + 3)))));

   function U32 (V : Integer_64) return Byte_Array is
      U : constant Unsigned_32 := Unsigned_32'Mod (V);
   begin
      return (EVC_Bytes.Byte (U and 16#FF#),
              EVC_Bytes.Byte (Shift_Right (U, 8) and 16#FF#),
              EVC_Bytes.Byte (Shift_Right (U, 16) and 16#FF#),
              EVC_Bytes.Byte (Shift_Right (U, 24) and 16#FF#));
   end U32;

   function U16 (V : Natural) return Byte_Array is
     (EVC_Bytes.Byte (V mod 256), EVC_Bytes.Byte (V / 256 mod 256));

   ---------------------------------------------------------------------
   --  Outputs of the on-board
   ---------------------------------------------------------------------

   Radio_Status_Model : constant Boolean :=
     Ada.Environment_Variables.Exists ("S076_RADIO_STATUS");

   procedure To_DMI (Frame : Byte_Array) is
      --  type u8, length u32, payload
      Len : constant Natural := Frame'Length - 5;
      P   : Stream_Element_Array (1 .. Stream_Element_Offset (Len));
   begin
      for I in 1 .. Len loop
         P (Stream_Element_Offset (I)) :=
           Stream_Element (Frame (Frame'First + 4 + I));
      end loop;
      --  A verification aid, off by default (S076_RADIO_STATUS=1): the
      --  on-board does not report the radio equipment in the MSG_ONBOARD
      --  radio byte yet (network type GSM-R, installed GSM-R only,
      --  registered: bits 0 .. 5); with it the runner shows what the
      --  sequences do once it does. It hides that gap, so it never
      --  belongs in the baseline.
      if Radio_Status_Model and then Frame (Frame'First) = 16#0A#
        and then Len >= 9
      then
         P (9) := P (9) or 43;
      end if;
      DMI_Core.Handle_Message (DMI_Protocol.Msg_Type_T (Frame (Frame'First)),
                               P);
   end To_DMI;

   procedure Observe_DMI (Frame : Byte_Array) is
      T : constant Natural := Natural (Frame (Frame'First));
      P : constant Byte_Array := Frame (Frame'First + 5 .. Frame'Last);
      B : constant Natural := P'First;
   begin
      case T is
         when 16#02# =>   -- MSG_MODE_LEVEL
            if P'Length >= 9 then
               Now.Mode := Natural (P (B));
               Now.Level := Natural (P (B + 1));
               Now.Mode_Ack := Natural (P (B + 2));
               Now.Level_Ann := Natural (P (B + 3));
               Now.Level_Ann_Ack := P (B + 4) /= 0;
               Now.Override := P (B + 5) /= 0;
               Now.TAF := P (B + 6) /= 0;
               --  a value of the LSSMA shown that changed: the JRU record
               --  44 (none when the display stops, 4080300_17 step 178)
               if Get16 (P, B + 7) /= Now.LSSMA
                 and then Get16 (P, B + 7) /= 16#FFFF#
               then
                  Win.LSSMA_Changed := True;
               end if;
               Now.LSSMA := Get16 (P, B + 7);
            end if;
         when 16#0A# =>   -- MSG_ONBOARD
            if P'Length >= 11 then
               Now.Onboard := P (B .. B + 10);
               Now.Has_Onboard := True;
            end if;
         when 16#07# =>   -- MSG_STATUS
            if P'Length >= 23 then
               Now.Brake := Natural (P (B));
               Now.Radio := Natural (P (B + 1));
               Now.Adhesion := P (B + 2) /= 0;
               Now.BMM := P (B + 3) /= 0;
               Now.Reversing := P (B + 4) /= 0;
               Now.Tunnel := Natural (P (B + 11));
               Now.Geo_Known := Get32 (P, B + 16) /= 16#FFFF_FFFF#;
            end if;
         when 16#01# =>   -- MSG_SPEED_STATE
            if P'Length >= 21 then
               Now.Has_Speed := True;
               Now.V_Cur := Get16 (P, B);
               Now.V_Perm := Get16 (P, B + 2);
               Now.V_Target := Get16 (P, B + 4);
               Now.V_Release := Get16 (P, B + 6);
               Now.V_SBI := Get16 (P, B + 8);
               Now.V_Wsl := Get16 (P, B + 10);
               Now.D_Target := Natural (Get32 (P, B + 12) and 16#7FFF_FFFF#);
               Now.Monitoring := Natural (P (B + 16));
               Now.Flags := Natural (P (B + 18));
               Now.Sup_Status := Natural (P (B + 19));
            end if;
         when 16#06# =>   -- MSG_PLANNING
            if P'Length >= 9 then
               declare
                  G : constant Natural := Natural (P (B + 8));
                  S_At : constant Natural := B + 9 + 3 * G;
               begin
                  Now.Has_Planning := True;
                  Now.Plan_MA := Get16 (P, B);
                  Now.Ceiling := Get16 (P, B + 6);
                  Now.Indication := Get16 (P, B + 2) /= 16#FFFF#;
                  Now.Gradients := G;
                  if S_At <= P'Last then
                     Now.Speeds := Natural (P (S_At));
                     declare
                        O_At : constant Natural := S_At + 1 + 4 * Now.Speeds;
                     begin
                        Now.Orders :=
                          (if O_At <= P'Last then Natural (P (O_At)) else 0);
                     end;
                  end if;
               end;
            end if;
         when 16#05# =>   -- MSG_TRACK_COND
            if P'Length >= 1 then
               Now.TC := (others => False);
               for I in 1 .. Natural (P (B)) loop
                  exit when B + 2 * I > P'Last;
                  if Natural (P (B + 2 * I)) <= 63 then
                     Now.TC (Natural (P (B + 2 * I))) := True;
                  end if;
               end loop;
            end if;
         when 16#03# =>   -- MSG_TEXT
            if P'Length >= 6 and then Texts_N < Max_Events then
               Texts_N := Texts_N + 1;
               Texts (Texts_N) :=
                 (Remove => False, Id => Get16 (P, B),
                  Class  => Natural (P (B + 2)) / 4 mod 4,
                  Ack    => P (B + 2) mod 2 = 1);
            end if;
         when 16#04# =>   -- MSG_TEXT_REMOVE
            if P'Length >= 2 and then Texts_N < Max_Events then
               Texts_N := Texts_N + 1;
               Texts (Texts_N) :=
                 (Remove => True, Id => Get16 (P, B), Class => 0,
                  Ack => False);
            end if;
         when 16#0C# =>   -- MSG_SYSTEM_STATUS
            if P'Length >= 2 and then SSs_N < Max_Events then
               SSs_N := SSs_N + 1;
               SSs (SSs_N) := (Natural (P (B)), Natural (P (B + 1)));
            end if;
         when 16#0E# =>   -- MSG_SYSTEM_VERSION
            if P'Length >= 2 then
               Now.SV_X := Natural (P (B));
               Now.SV_Y := Natural (P (B + 1));
            end if;
         when others =>
            null;
      end case;
   end Observe_DMI;

   procedure Observe_TIU (P : Byte_Array) is
   begin
      if Is_TIU_TC_Output (P) then
         Now.TIU_TC := (others => False);
         declare
            Count : constant Natural := Natural (P (P'First + 2));
         begin
            for I in 0 .. Count - 1 loop
               declare
                  K : constant Natural := P'First + TIU_TC_Header_Length
                                          + I * TIU_TC_Entry_Length;
               begin
                  exit when K > P'Last;
                  if Natural (P (K)) <= 63 then
                     Now.TIU_TC (Natural (P (K))) := True;
                  end if;
               end;
            end loop;
         end;
      elsif P'Length >= 3 then
         Now.EBC := (P (P'First) and TIU_EBC) /= 0;
         Now.SBC := (P (P'First) and TIU_SBC) /= 0;
         Now.TCO := (P (P'First) and TIU_TCO) /= 0;
         Now.Reasons := Get16 (P, P'First + 1);
      end if;
   end Observe_TIU;

   --  the u24 of bytes 2 to 4 of a JRU event, least significant first
   --  (EVC_Position.Put_Identity_Event, EVC_JRU_Messages.View)
   function Identity (P : Byte_Array) return Natural is
     (Natural (P (P'First + 3)) * 65536 + Natural (P (P'First + 2)) * 256
      + Natural (P (P'First + 1)));

   --  A JRU output, a message of SUBSET-027, as the event of EVC_Ports it
   --  records (EVC_JRU_Messages.View): the event and its three bytes
   procedure Observe_Event (P : Byte_Array);

   procedure Observe_JRU (P : Byte_Array) is
      V : EVC_JRU_Messages.View_T;
   begin
      if P'Length > 2**16 or else not EVC_JRU_Messages.Is_Message (P) then
         return;
      end if;
      if Messages_N < Max_Messages and then P'Length <= JRU_Max_Length then
         Messages_N := Messages_N + 1;
         Messages (Messages_N).Length := P'Length;
         Messages (Messages_N).Data (1 .. P'Length) := P;
      end if;
      V := EVC_JRU_Messages.View (P);
      if V.Event /= 0 then
         Observe_Event ((V.Event, V.B2, V.B3, V.B4));
      end if;
   end Observe_JRU;

   procedure Observe_Event (P : Byte_Array) is
   begin
      if JRU_N < Max_JRU then
         JRU_N := JRU_N + 1;
         JRU_List (JRU_N) := (Natural (P (P'First)), Natural (P (P'First + 1)),
                              Natural (P (P'First + 2)),
                              Natural (P (P'First + 3)), Last_Commands);
      end if;
      if P (P'First) = 1 then
         Last_Mode := Natural (P (P'First + 1));
         Last_Level_Status := Natural (P (P'First + 2));
         Last_Level := Natural (P (P'First + 3));
      elsif P (P'First) = 40 and then P (P'First + 1) = 1 then
         --  EVC_Levels: level switched
         Last_Level_Status := 2;
         Last_Level := Natural (P (P'First + 2));
      elsif P (P'First) = 20 then
         Last_Commands := Natural (P (P'First + 1));
      elsif P (P'First) = 21 then
         Last_Mon := Natural (P (P'First + 1));
         Last_Sup := Natural (P (P'First + 2));
      elsif P (P'First) = 10 then
         --  a new LRBG
         LRBG_Known := True;
         LRBG_Id := Identity (P);
      elsif P (P'First) = 2 then
         Last_BG_Id := Identity (P);
      elsif P (P'First) = 8 and then P (P'First + 1) = 0 then
         --  the train position unknown
         LRBG_Known := False;
      elsif P (P'First) = 45 then
         TC_Phase (Natural (P (P'First + 1))) := Natural (P (P'First + 2));
      end if;
   end Observe_Event;

   --  An RTM output (EVC_Ports: RTM_Tag_Message, session, message;
   --  RTM_Tag_Request, session, request, its bytes)
   procedure Observe_RTM (P : Byte_Array) is
      R : Radio_Out_T;
   begin
      if P'Length < 3 or else Radio_N = Max_Radio
        or else P (P'First + 1) not in 1 .. RTM_Max_Sessions
      then
         return;
      end if;
      R.Session := Natural (P (P'First + 1));
      R.Is_Request := P (P'First) = RTM_Tag_Request;
      if P (P'First) = RTM_Tag_Message then
         R.Code := Natural (P (P'First + 2));
         R.Length := Natural'Min (P'Length - 2, Max_Radio_Bytes);
         R.Data (1 .. R.Length) := P (P'First + 2 .. P'First + 1 + R.Length);
         if P'Length >= 2 + 8 then
            --  T_TRAIN: bits 18 .. 49 of the message (8.4.4.7.1)
            declare
               M : constant Natural := P'First + 2;
               T : Unsigned_64 := 0;
            begin
               for K in 0 .. 5 loop
                  T := T * 256 + Unsigned_64 (P (M + 2 + K));
               end loop;
               --  the 48 bits from bit 16 on: T_TRAIN is bits 2 .. 33
               T := Shift_Right (T, 14) and 16#FFFF_FFFF#;
               Last_T (R.Session) := Integer_64 (T);
               Last_Ms (R.Session) := Clock;
               T_By_Nid (R.Session, R.Code) := Integer_64 (T);
            end;
         end if;
      elsif R.Is_Request then
         R.Code := Natural (P (P'First + 2));
         R.Length := Natural'Min (P'Length - 3, Max_Radio_Bytes);
         R.Data (1 .. R.Length) := P (P'First + 3 .. P'First + 2 + R.Length);
         Last_Req (R.Session) := R.Code;
         if R.Code = RTM_Request_T'Pos (Request_Registration) + 1 then
            Registering (R.Session) := True;
         end if;
      else
         return;
      end if;
      Radio_N := Radio_N + 1;
      Radio_List (Radio_N) := R;
      Radio_List (Radio_N).At_Ms := Clock;
   end Observe_RTM;

   Out_Buf : Byte_Array (1 .. EVC_Outbox.Capacity + 16);

   procedure Take_Outputs is
      Last : Natural;
      Pos  : Natural;
   begin
      loop
         EVC_Core.Take_Outputs (Out_Buf, Last);
         exit when Last < Out_Buf'First;
         Pos := 0;
         while Pos + 3 <= Last loop
            declare
               Port_Pos : constant Natural := Natural (Out_Buf (Pos + 1));
               Len      : constant Natural := Get16 (Out_Buf, Pos + 2);
               First    : constant Natural := Pos + 4;
               L        : constant Natural := Pos + 3 + Len;
            begin
               exit when L > Last or else Port_Pos > Port_T'Pos (Port_T'Last);
               declare
                  P : constant Byte_Array := Out_Buf (First .. L);
               begin
                  case Port_T'Val (Port_Pos) is
                     when DMI =>
                        if P'Length >= 5 then
                           Observe_DMI (P);
                           To_DMI (P);
                        end if;
                     when TIU =>
                        Observe_TIU (P);
                     when JRU =>
                        Observe_JRU (P);
                     when RTM =>
                        Observe_RTM (P);
                     when others =>
                        null;
                  end case;
               end;
               Pos := L;
            end;
         end loop;
      end loop;
   end Take_Outputs;

   ---------------------------------------------------------------------
   --  The DMI's outputs
   ---------------------------------------------------------------------

   DMI_Buf : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);

   procedure Take_DMI is
      Last : Stream_Element_Offset;
      Pos  : Stream_Element_Offset := 0;
   begin
      DMI_Core.Take_Outbox (DMI_Buf, Last, With_Sounds => True);
      while Pos + 5 <= Last loop
         declare
            T   : constant Natural := Natural (DMI_Buf (Pos + 1));
            Len : constant Stream_Element_Offset :=
              Stream_Element_Offset (DMI_Buf (Pos + 2))
              + 256 * Stream_Element_Offset (DMI_Buf (Pos + 3));
            L   : constant Stream_Element_Offset := Pos + 5 + Len;
         begin
            exit when L > Last;
            if (T = 16#40# or else T = 16#41#)
              and then Pending_Count < Max_Pending
              and then Natural (L - Pos) <= Pending (1).Data'Length
            then
               Pending_Count := Pending_Count + 1;
               for I in Pos + 1 .. L loop
                  Pending (Pending_Count).Data (Natural (I - Pos)) :=
                    EVC_Bytes.Byte (DMI_Buf (I));
               end loop;
               Pending (Pending_Count).Length := Natural (L - Pos);
               Sent_N := Sent_N + 1;
            end if;
            Pos := L;
         end;
      end loop;
   end Take_DMI;

   ---------------------------------------------------------------------
   --  The window
   ---------------------------------------------------------------------

   procedure Fold is
   begin
      Cycles := Cycles + 1;
      if Now.Mode <= 63 then
         Win.Mode (Now.Mode) := True;
      end if;
      if Now.Mode_Ack <= 63 then
         Win.Mode_Ack (Now.Mode_Ack) := True;
      end if;
      if Now.Level <= 63 then
         Win.Level (Now.Level) := True;
      end if;
      if Now.Level_Ann <= 63 then
         if Now.Level_Ann_Ack then
            Win.Level_Ann_Ack (Now.Level_Ann) := True;
         else
            Win.Level_Ann (Now.Level_Ann) := True;
         end if;
      end if;
      Win.Override := Win.Override or else Now.Override;
      Win.Brake_Shown := Win.Brake_Shown or else Now.Brake /= 0;
      Win.Brake_Ack := Win.Brake_Ack or else Now.Brake = 2;
      Win.EBC := Win.EBC or else Now.EBC;
      Win.SBC := Win.SBC or else Now.SBC;
      Win.TCO := Win.TCO or else Now.TCO;
      Win.Not_EBC := Win.Not_EBC or else not Now.EBC;
      Win.Not_SBC := Win.Not_SBC or else not Now.SBC;
      Win.Not_TCO := Win.Not_TCO or else not Now.TCO;
      Win.Speed_Shown := Win.Speed_Shown or else Now.Has_Speed;
      Win.Planning_Shown := Win.Planning_Shown or else Now.Has_Planning;
      Win.Indication := Win.Indication or else Now.Indication;
      Win.Gradients := Win.Gradients or else Now.Gradients > 0;
      Win.Geo := Win.Geo or else Now.Geo_Known;
      Win.Reversing := Win.Reversing or else Now.Reversing;
      Win.Adhesion := Win.Adhesion or else Now.Adhesion;
      Win.Radio_Up := Win.Radio_Up or else Now.Radio = 1;
      Win.Radio_Lost := Win.Radio_Lost or else Now.Radio = 2;
      Win.TAF := Win.TAF or else Now.TAF;
      for I in Now.TC'Range loop
         Win.TC (I) := Win.TC (I) or else Now.TC (I);
         Win.TIU_TC (I) := Win.TIU_TC (I) or else Now.TIU_TC (I);
      end loop;
   end Fold;

   Win_Ms : Unsigned_64 := 0;

   function Window_Ms return Unsigned_64 is (Win_Ms);
   function Now_Ms return Unsigned_64 is (Clock);

   procedure New_Window (Keep_Radio : Boolean := False) is
   begin
      Win_Ms := Clock;
      Win := (others => <>);
      Cycles := 0;
      JRU_N := 0;
      Messages_N := 0;
      Texts_N := 0;
      SSs_N := 0;
      Sent_N := 0;
      if not Keep_Radio or else Radio_N > Max_Radio / 2 then
         Radio_N := 0;
      end if;
   end New_Window;

   function Window_Cycles return Natural is (Cycles);

   ---------------------------------------------------------------------
   --  Power and time
   ---------------------------------------------------------------------

   procedure Reset is
   begin
      Is_Powered := False;
      Was_Powered := False;
      Clock := 0;
      X_Cm := 0;
      V_Cms := 0;
      Demand_Cms := 0;
      Lambda := 0;
      Is_Braked := False;
      Spent := False;
      Service_On := True;
      Floor_Cms := 0;
      Dir := 1;
      Odo_Over := 0;
      Odo_Under := 0;
      Acc := Accuracy_Per_Mille;
      Speed_Acc := False;
      for B of Balises loop
         B.Used := False;
      end loop;
      Pending_Count := 0;
      Now := (others => <>);
      Last_Mode := No_Value;
      Last_Level_Status := No_Value;
      Last_Level := No_Value;
      Last_Commands := 0;
      Last_Mon := 0;
      Last_Sup := 0;
      LRBG_Known := False;
      LRBG_Id := No_Value;
      Last_BG_Id := No_Value;
      TC_Phase := (others => -1);
      Change_Head := 0;
      Changes_Kept := 0;
      Prev_Status := EVC_SDM.NoS;
      Prev_SB := False;
      Prev_EB := False;
      Prev_TCO := False;
      Clear_Radio;
      New_Window;
   end Reset;

   --  The quantities of a change in this cycle (Change_T)
   function Current return Change_T is
      use type EVC_SDM.Monitoring_T;
      use type EVC_Distances.Cm_T;
      R : constant EVC_SDM.Result_T := EVC_Core.Supervision;
   begin
      return
        (Kind     => To_Indication,
         Time_Ms  => Natural (Clock mod 2**31),
         Track_Cm => X_Cm,
         V_Est    => Natural (R.V_Est),
         Shown    => R.Monitoring /= EVC_SDM.CSM or else R.CSM_Target,
         V_Target => Natural (R.V_Target),
         EOA_Kind => R.Shown_At.Target_EOA /= R.Shown_At.Target_X,
         D_Loc    => Integer_64 (R.Shown_At.Target_X - R.Shown_At.X_Est),
         D_EOA    => Integer_64 (R.Shown_At.Target_EOA - R.Shown_At.X_Est),
         Over     => Doubt_Over);
   end Current;

   --  The changes of this cycle's supervision into the ring (B172)
   procedure Note_Changes is
      use type EVC_SDM.Status_T;
      R : constant EVC_SDM.Result_T := EVC_Core.Supervision;

      procedure Add (K : Change_Kind_T) is
         C : Change_T := Current;
      begin
         C.Kind := K;
         Change_Head := Change_Head mod Max_Changes + 1;
         Changes_Kept := Natural'Min (Changes_Kept + 1, Max_Changes);
         Changes (Change_Head) := C;
      end Add;
   begin
      if R.Status /= Prev_Status and then R.Status /= EVC_SDM.NoS then
         Add (Change_Kind_T'Val (EVC_SDM.Status_T'Pos (R.Status) - 1));
      end if;
      if R.SB and then not Prev_SB then
         Add (SB_On);
      end if;
      if R.EB and then not Prev_EB then
         Add (EB_On);
      end if;
      if R.TCO and then not Prev_TCO then
         Add (TCO_On);
      end if;
      Prev_Status := R.Status;
      Prev_SB := R.SB;
      Prev_EB := R.EB;
      Prev_TCO := R.TCO;
   end Note_Changes;

   function Change_Count return Natural is (Changes_Kept);
   function Change (I : Positive) return Change_T is
     (Changes ((Change_Head - I + Max_Changes) mod Max_Changes + 1));

   procedure Set_Radio_Systems (Systems : EVC_Config.Radio_Systems_T) is
   begin
      Radio_Systems := Systems;
   end Set_Radio_Systems;

   procedure Set_Voltages (Voltages : Natural) is
   begin
      S076_Bench.Voltages := Natural'Min (Voltages, 2**16 - 1);
   end Set_Voltages;

   procedure Power_On is
   begin
      --  The ETCS identity of the on-board the sequences were recorded
      --  with (NID_ENGINE 76000 in nearly all of them, e5/session-3)
      EVC_Config.Set_Radio_For_Test
        ((Sessions => EVC_Config.Current.Radio.Sessions,
          Engine_Id => 76_000, Systems => Radio_Systems, others => <>));
      EVC_Config.Set_Voltages_For_Test (Voltages);
      if Was_Powered then
         EVC_Core.Power_Up;
      else
         EVC_Core.Initialise;
      end if;
      --  the bench page's UTC reference, 2026-01-01 00:00:00 at the
      --  on-board time 0 (Sim_Onboard_Env): the JRU messages' DATE and
      --  TIME known (SUBSET-027 4.2.3.3, 4.2.3.4)
      EVC_Core.Set_UTC (820_540_800);
      DMI_Core.Initialise;
      Is_Powered := True;
      Was_Powered := True;
      Pending_Count := 0;
      Now := (others => <>);
      Last_Mode := No_Value;
      Last_Level_Status := No_Value;
      Last_Level := No_Value;
      LRBG_Known := False;
      LRBG_Id := No_Value;
      Last_BG_Id := No_Value;
      TC_Phase := (others => -1);
      Last_Commands := 0;
      Last_Mon := 0;
      Last_Sup := 0;
      Clear_Radio;
      --  the odometer's first sample: the frame starts at the train
      Cycle;
   end Power_On;

   procedure Power_Off is
   begin
      Is_Powered := False;
      Pending_Count := 0;
   end Power_Off;

   function Powered return Boolean is (Is_Powered);

   procedure Fault is
   begin
      if Is_Powered then
         EVC_Core.Enter_Failure;
      end if;
   end Fault;

   function Time_Ms return Unsigned_64 is (Clock);

   --  SUBSET-041 5.3.1.2: the speed accuracy, 2 km/h up to 30 km/h,
   --  then linearly up to 12 km/h at 500 km/h, cm/s rounded up:
   --  (640 + 0.36 V) / 470 km/h = (64 000 + 36 V) / 1692 cm/s. The
   --  bench's own copy of the formula (EVC_Limits.F41 is the
   --  on-board's): the odometer states it, the on-board takes V_ura
   --  from it (SUBSET-026 3.13.9.3.2.1)
   function F41 (V : Natural) return Natural is
     ((Natural'Max (64_000 + 36 * V, 94_000) + 1_691) / 1_692);

   --  The odometer frame of EVC_Ports: d_est, over, under, then v_est,
   --  v_min, v_max (B191: the interval of F41 while Speed_Acc, the
   --  exact speed otherwise; the three speeds 0 at standstill)
   procedure Sample is
      Movement : constant EVC_Bytes.Byte :=
        (if V_Cms = 0 then 0 elsif Dir > 0 then 1 else 2);
      V : constant Natural := Natural'Min (V_Cms, 65_535);
      D : constant Natural := (if Speed_Acc and V > 0 then F41 (V) else 0);
      V_Min : constant Natural := (if V > D then V - D else 0);
      V_Max : constant Natural := Natural'Min (V + D, 65_535);
   begin
      EVC_Core.Handle_Input
        (Odometer,
         U32 (X_Cm) & U32 (Odo_Over) & U32 (Odo_Under)
         & U16 (V) & U16 (V_Min) & U16 (V_Max)
         & Byte_Array'(Movement, 0) & U16 (0));
   end Sample;

   procedure Deliver (I : Positive) is
      B : Balise_T renames Balises (I);
      N : constant Natural := (B.Bits + 7) / 8;
   begin
      if Is_Powered then
         EVC_Core.Handle_Input
           (BTM, U32 (B.At_Cm) & U16 (B.Bits) & B.Data (1 .. N));
      end if;
      B.Used := False;
      B.Immediate := False;
   end Deliver;

   procedure Settle;

   procedure Cycle is
   begin
      Settle;
      Cycle (Integer_64 (V_Cms) * Cycle_Ms / 1000);
   end Cycle;

   procedure Brake_Cycle;

   procedure Cycle (Distance_Cm : Integer_64) is
      Old_X : constant Integer_64 := X_Cm;
      Step  : constant Integer_64 := Distance_Cm * Integer_64 (Dir);
      New_X : constant Integer_64 := X_Cm + Step;
   begin
      Settle;
      Clock := Clock + Cycle_Ms;
      --  the balises placed behind the antenna, in their order
      loop
         declare
            Best : Natural := 0;
         begin
            for I in Balises'Range loop
               if Balises (I).Used and then Balises (I).Immediate
                 and then (Best = 0
                           or else (if Dir > 0
                                    then Balises (I).At_Cm
                                         < Balises (Best).At_Cm
                                    else Balises (I).At_Cm
                                         > Balises (Best).At_Cm))
               then
                  Best := I;
               end if;
            end loop;
            exit when Best = 0;
            Deliver (Best);
         end;
      end loop;
      --  the balises passed during the cycle, in the order of passing
      if Step /= 0 then
         loop
            declare
               Best : Natural := 0;
            begin
               for I in Balises'Range loop
                  if Balises (I).Used and then not Balises (I).Immediate
                    and then (if Step > 0
                              then Balises (I).At_Cm > Old_X
                                   and then Balises (I).At_Cm <= New_X
                              else Balises (I).At_Cm < Old_X
                                   and then Balises (I).At_Cm >= New_X)
                    and then (Best = 0
                              or else (if Step > 0
                                       then Balises (I).At_Cm
                                            < Balises (Best).At_Cm
                                       else Balises (I).At_Cm
                                            > Balises (Best).At_Cm))
                  then
                     Best := I;
                  end if;
               end loop;
               exit when Best = 0;
               Deliver (Best);
            end;
         end loop;
         Odo_Over := Odo_Over + abs Step * Acc / 1000;
         Odo_Under := Odo_Under + abs Step * Acc / 1000;
      end if;
      X_Cm := New_X;
      if Is_Powered then
         Sample;
         for I in 1 .. Pending_Count loop
            EVC_Core.Handle_Input
              (DMI, Pending (I).Data (1 .. Pending (I).Length));
         end loop;
         Pending_Count := 0;
         for S in Registering'Range loop
            if Registering (S) then
               Registering (S) := False;
               EVC_Core.Handle_Input
                 (RTM, (RTM_Tag_Event, Byte (S),
                        Byte (RTM_Event_T'Pos (Registered) + 1)));
            end if;
         end loop;
         EVC_Core.Tick (Cycle_Ms);
         Take_Outputs;
         DMI_Core.Tick (Cycle_Ms);
         Take_DMI;
         Note_Changes;
         Brake_Cycle;
      end if;
      Fold;
   end Cycle;

   procedure Run (Ms : Natural) is
   begin
      for I in 1 .. (Ms + Cycle_Ms - 1) / Cycle_Ms loop
         Cycle;
      end loop;
   end Run;

   ---------------------------------------------------------------------
   --  The train
   ---------------------------------------------------------------------

   function Position return Integer_64 is (X_Cm);
   --  B262: the on-board commands a brake the model applies (the
   --  service brake unless disabled; none in Trip, see Brake_Cycle)
   function Braking return Boolean is
     (Lambda > 0 and then Is_Powered
      and then (Now.EBC or else (Now.SBC and then Service_On))
      and then Now.Mode /= Natural (EVC_DMI_Port.Mode_Code (EVC_Modes.M_TR)));

   --  B262: the speed of the next cycle, from the train's (V_Cms, after
   --  the last cycle) and the speed asked for (Set_Speed: the last one
   --  asked for before the cycle counts): a lower one at once (the
   --  driver's own braking is not modelled), a higher one at once
   --  unless a brake is commanded (then no speed is gained but the
   --  crawl, Set_Brake_Floor) or the train regains its speed after one
   function Settled return Natural is
     (if Demand_Cms <= V_Cms then Demand_Cms
      elsif Braking
      then Natural'Max (V_Cms, Natural'Min (Floor_Cms, Demand_Cms))
      elsif Is_Braked then V_Cms
      else Demand_Cms);

   procedure Settle is
      V : constant Natural := Settled;
   begin
      Is_Braked := V < Demand_Cms and then (Is_Braked or else Braking);
      V_Cms := V;
   end Settle;

   function Speed return Natural is (Settled);
   function Direction return Integer is (Dir);

   --  B262: see Settled
   procedure Set_Speed (Cms : Natural) is
   begin
      Demand_Cms := Cms;
   end Set_Speed;

   function Braked return Boolean is (Is_Braked);

   function Forced_Spent return Boolean is (Spent);

   procedure Force_Speed (Cms : Natural) is
   begin
      V_Cms := Cms;
      Demand_Cms := Cms;
      Is_Braked := False;
      Spent := False;
   end Force_Speed;

   procedure Set_Brake_Floor (Cms : Natural) is
   begin
      Floor_Cms := Cms;
   end Set_Brake_Floor;

   --  B262: the decelerations of the conversion model (A.3.7), cached
   --  per percentage: the emergency brake at Lambda, the service brake
   --  at min (Lambda, 135) (A.3.7.1)
   EB_Decel, SB_Decel : EVC_Braking.Steps_T := EVC_Braking.No_Steps;

   procedure Set_Service_Brake (On : Boolean) is
   begin
      Service_On := On;
   end Set_Service_Brake;

   procedure Set_Brake_Percentage (Lambda : Natural) is
   begin
      S076_Bench.Lambda :=
        (if Lambda in 10 .. EVC_Braking.Lambda_T'Last then Lambda else 0);
      if S076_Bench.Lambda > 0 then
         EB_Decel := EVC_Braking.Basic_Deceleration (S076_Bench.Lambda);
         SB_Decel := EVC_Braking.Basic_Deceleration
           (Natural'Min (S076_Bench.Lambda, 135));
      end if;
   end Set_Brake_Percentage;

   --  B262: one cycle of the braking model, after the on-board's outputs
   --  of the cycle: under a brake command the speed falls by the
   --  deceleration at the speed (Decel_Unit, 10 um/s2: a cycle of 100 ms
   --  takes Value / 10 000 cm/s, rounded) down to standstill; released,
   --  it regains the speed asked for at Regain_Mms2
   procedure Brake_Cycle is
      Per_Cycle : constant Natural := Regain_Mms2 * Cycle_Ms / 10_000;
   begin
      if Lambda = 0 then
         return;
      elsif Now.Mode = Natural (EVC_DMI_Port.Mode_Code (EVC_Modes.M_TR))
      then
         --  decision: in Trip the train follows the speed asked for (the
         --  chart's stop is the sequence's own train braking, more gently
         --  than the conversion model of lambda 109: 5170200_01 expects
         --  the train still moving 20 m after the trip, 4080300_03 at
         --  standstill 175 m after it at 52 km/h, 0.6 m/s2)
         Is_Braked := False;
      elsif Now.EBC or else (Now.SBC and then Service_On) then
         declare
            D : constant Natural :=
              (Natural (EVC_Braking.Value_At
                 ((if Now.EBC then EB_Decel else SB_Decel),
                  EVC_Fixed.Num (Natural'Min (V_Cms, EVC_Fixed.Max_Speed))))
               * Cycle_Ms / 100 + 5_000) / 10_000;
         begin
            V_Cms := Natural'Max ((if V_Cms > D then V_Cms - D else 0),
                                  Natural'Min (Floor_Cms, Demand_Cms));
            Is_Braked := V_Cms < Demand_Cms or else Is_Braked;
         end;
      elsif Is_Braked then
         Spent := True;
         V_Cms := Natural'Min (Demand_Cms, V_Cms + Per_Cycle);
         Is_Braked := V_Cms < Demand_Cms;
      end if;
   end Brake_Cycle;

   function Grade_Acceleration (Grades : S076_Sequences.Grades_T;
                                Before_M : Long_Float; Length_M : Natural)
                                return Long_Float
   is
      Front : constant Long_Float := Grades.Target_M - Before_M;
      Rear  : constant Long_Float := Front - Long_Float (Length_M);
      Low   : Long_Float := Long_Float'Last;
   begin
      for I in 1 .. Natural'Min (Grades.Grade_Count, Grades.Bound_Count) loop
         declare
            From : constant Long_Float := Grades.Bounds (I);
            To   : constant Long_Float :=
              (if I < Grades.Bound_Count then Grades.Bounds (I + 1)
               else Long_Float'Last);
         begin
            if From <= Front and then To >= Rear then
               Low := Long_Float'Min (Low, Grades.Permil (I));
            end if;
         end;
      end loop;
      if Low = Long_Float'Last then
         return 0.0;
      end if;
      return 9.81 * Low / (1000.0 + (if Low > 0.0 then 150.0 else 20.0));
   end Grade_Acceleration;

   function Ebd_Distance (Lambda, Position, Length_M : Natural;
                          From_Kmh, To_Kmh : Long_Float;
                          Grades : S076_Sequences.Grades_T := (others => <>);
                          With_Bec : Boolean := False)
                          return Long_Float
   is
      use EVC_Braking;
      use EVC_Supervision_Input;
      use type EVC_Fixed.Num;
      E   : constant Steps_T :=
        Basic_Deceleration (if Lambda in 10 .. Lambda_T'Last then Lambda
                            else 100);
      P   : constant Brake_Position_T :=
        (case Position is
            when 2 => Freight_P, when 3 => Freight_G,
            when others => Passenger_P);
      NV  : constant National_Values_T := EVC_National_Values.Current.Values;
      Kv  : constant Steps_T := Kv_Int (NV, P, A_Ebmax (E, 5_556));
      Kr  : constant Long_Float :=
        Long_Float (Kr_Int (NV.Kr_Int,
                            EVC_Fixed.Num
                              (Natural'Min (Length_M, 1_500) * 100)))
        / 1.0E6;
      Top : constant Long_Float := Long_Float'Min (From_Kmh, 2_000.0) / 3.6;
      V   : Long_Float := Long_Float'Max (To_Kmh, 0.0) / 3.6;
      D   : Long_Float := 0.0;
      --  A.3.12.2.2, .3: the least brake deceleration and the greatest
      --  one with the gradient on the way, m/s2
      A_EB, A_Safe_Max : Long_Float := -1.0;
   begin
      --  in steps of 0.05 m/s, the deceleration at the middle of each
      while V < Top loop
         declare
            Dv  : constant Long_Float := Long_Float'Min (0.05, Top - V);
            Mid : constant Long_Float := V + Dv / 2.0;
            Cms : constant EVC_Fixed.Num :=
              EVC_Fixed.Num (Long_Float'Min (Mid * 100.0, 60_000.0));
            A_B : constant Long_Float :=
              Long_Float (Value_At (E, Cms)) * 1.0E-5
              * Long_Float (Value_At (Kv, Cms)) / 1.0E6 * Kr;
            A   : constant Long_Float :=
              A_B + Grade_Acceleration (Grades, D, Length_M);
         begin
            A_EB := (if A_EB < 0.0 then A_B else Long_Float'Min (A_EB, A_B));
            A_Safe_Max := Long_Float'Max (A_Safe_Max, A);
            if A > 0.0 then
               D := D + Mid * Dv / A;
            end if;
            V := V + Dv;
         end;
      end loop;
      if not With_Bec or else A_EB <= 0.0 then
         return D;
      end if;
      declare
         Low : constant Long_Float := Long_Float'Max (To_Kmh, 0.0) / 3.6;
         T   : constant Times_T :=
           Conversion_Emergency
             (P, EVC_Fixed.Num (Natural'Min (Length_M, 1_500) * 100),
              Zero_Speed => Low = 0.0);
         --  3.13.6.2.2.3: T_be = Kt_int * T_brake_emergency
         function Kt (X : EVC_Fixed.Num) return EVC_Fixed.Num is
           (EVC_Fixed.Min
              (EVC_Fixed.Div_Ceil (X * EVC_Fixed.Num (NV.Kt_Int), 1_000),
               EVC_Fixed.Max_Time));
         I : constant EVC_Build_Up.Input_T :=
           (Kind       => (if Low = 0.0 then EVC_Build_Up.Zero_Target
                           else EVC_Build_Up.Speed_Target),
            V_Est      => EVC_Fixed.Num (Top * 100.0),
            V_Target   => EVC_Fixed.Num (Low * 100.0),
            T_Be_React => Kt (T.React),
            T_Be       => Kt (T.Build_Up),
            A_EB       => EVC_Fixed.Num (A_EB * 1.0E5),
            A_Safe_Max => EVC_Fixed.Num (Long_Float'Max (A_Safe_Max, 0.0)
                                         * 1.0E5),
            others     => <>);
      begin
         return D + Top * Long_Float (EVC_Build_Up.T_Be_Reduced (I)) / 1000.0;
      end;
   end Ebd_Distance;

   function Sbd_Terms (Lambda, Position, Length_M : Natural;
                       V_Kmh, To_Kmh : Long_Float;
                       Grades : S076_Sequences.Grades_T := (others => <>))
                       return Sbd_Terms_T
   is
      use EVC_Braking;
      use EVC_Supervision_Input;
      use type EVC_Fixed.Num;
      L   : constant Natural := (if Lambda in 10 .. 250 then Lambda else 100);
      E   : constant Steps_T := Basic_Deceleration (Natural'Min (L, 135));
      Top : constant Long_Float :=
        Long_Float'Min (Long_Float'Max (V_Kmh, 0.0), 500.0) / 3.6;
      Low : constant Long_Float :=
        Long_Float'Min (Long_Float'Max (To_Kmh, 0.0) / 3.6, Top);
      P   : constant Brake_Position_T :=
        (case Position is
            when 2 => Freight_P, when 3 => Freight_G,
            when others => Passenger_P);
      T   : constant Times_T :=
        Conversion_Service
          (P, EVC_Fixed.Num (Natural'Min (Length_M, 1_500) * 100),
           Zero_Speed => Low = 0.0);
      V   : Long_Float := Low;
      D   : Long_Float := 0.0;
      A_Lo, A_Hi : EVC_Fixed.Num :=
        Value_At (E, EVC_Fixed.Num (Low * 100.0));
   begin
      --  in steps of 0.05 m/s, the deceleration at the middle of each;
      --  the extremes at the sampled speeds and at V_Kmh
      while V < Top loop
         declare
            Dv  : constant Long_Float := Long_Float'Min (0.05, Top - V);
            Mid : constant Long_Float := V + Dv / 2.0;
            A   : constant EVC_Fixed.Num :=
              Value_At (E, EVC_Fixed.Num (Mid * 100.0))
              + EVC_Fixed.Num
                  (Grade_Acceleration (Grades, D, Length_M) * 1.0E5);
         begin
            A_Lo := EVC_Fixed.Min (A_Lo, A);
            A_Hi := EVC_Fixed.Max (A_Hi, A);
            if A > 0 then
               D := D + Mid * Dv / (Long_Float (A) * 1.0E-5);
            end if;
            V := V + Dv;
         end;
      end loop;
      A_Lo := EVC_Fixed.Min (A_Lo, Value_At (E, EVC_Fixed.Num (Top * 100.0)));
      A_Hi := EVC_Fixed.Max (A_Hi, Value_At (E, EVC_Fixed.Num (Top * 100.0)));
      declare
         I : constant EVC_Build_Up.Input_T :=
           (Kind           => (if Low = 0.0 then EVC_Build_Up.EOA_Target
                               else EVC_Build_Up.Speed_Target),
            V_Est          => EVC_Fixed.Num (Top * 100.0),
            V_Target       => EVC_Fixed.Num (Low * 100.0),
            T_Bs_React     => T.React,
            T_Bs           => T.Build_Up,
            A_SB           => A_Lo,
            A_Expected_Max => A_Hi,
            others         => <>);
      begin
         return (D_Sbd => D,
                 T_Bs  => Long_Float (EVC_Build_Up.T_Bs_Reduced (I)) / 1000.0);
      end;
   end Sbd_Terms;

   procedure Set_Direction (Dir : Integer) is
   begin
      S076_Bench.Dir := (if Dir < 0 then -1 else 1);
   end Set_Direction;

   procedure Move_To (To_Cm : Integer_64; Cms : Positive;
                      Max_Ms : Natural := 3_600_000) is
      Elapsed : Natural := 0;
      Held : Natural := 0;  -- ms at standstill under a brake command
   begin
      Set_Speed (Cms);
      if To_Cm = X_Cm then
         return;
      end if;
      Dir := (if To_Cm > X_Cm then 1 else -1);
      while (if Dir > 0 then X_Cm < To_Cm else X_Cm > To_Cm)
        and then Elapsed < Max_Ms and then Held < 10_000
      loop
         declare
            Left : constant Integer_64 := abs (To_Cm - X_Cm);
            Full : constant Integer_64 :=
              Integer_64 (Settled) * Cycle_Ms / 1000;
         begin
            --  the last cycle ends at the target, at the speed (B224);
            --  the train's speed is that of the braking model (B262)
            if Left < Full then
               Cycle (Left);
            else
               Cycle;
            end if;
            Set_Speed (Cms);
            Elapsed := Elapsed + Cycle_Ms;
            Held := (if V_Cms = 0 then Held + Cycle_Ms else 0);
         end;
      end loop;
   end Move_To;

   procedure Place_Balise (At_Cm : Integer_64; Bits : Natural;
                           Data : Byte_Array) is
   begin
      for B of Balises loop
         if not B.Used then
            B.At_Cm := At_Cm;
            B.Bits := Bits;
            B.Data := (others => 0);
            B.Data (1 .. Natural'Min (Data'Length, 104)) :=
              Data (Data'First .. Data'First
                                  + Natural'Min (Data'Length, 104) - 1);
            B.Used := True;
            B.Immediate := (if Dir > 0 then At_Cm <= X_Cm else At_Cm >= X_Cm);
            return;
         end if;
      end loop;
   end Place_Balise;

   function Balises_Pending return Natural is
      N : Natural := 0;
   begin
      for B of Balises loop
         if B.Used then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Balises_Pending;

   function Doubt_Over return Integer_64 is
     (if Is_Powered then Integer_64 (EVC_Position.Doubt_Over) else 0);
   function Doubt_Under return Integer_64 is
     (if Is_Powered then Integer_64 (EVC_Position.Doubt_Under) else 0);
   function Front_Offset return Integer_64 is
     (Integer_64 (EVC_Position.Front_Offset (EVC_Distances.Plus)));

   ---------------------------------------------------------------------
   --  Other inputs
   ---------------------------------------------------------------------

   procedure TIU_Input (Signal : Natural; Value : Natural) is
   begin
      if Is_Powered then
         EVC_Core.Handle_Input
           (TIU, (EVC_Bytes.Byte (Signal mod 256),
                  EVC_Bytes.Byte (Value mod 256)));
      end if;
   end TIU_Input;

   procedure DMI_Frame (Frame : Byte_Array) is
   begin
      if Is_Powered then
         EVC_Core.Handle_Input (DMI, Frame);
      end if;
   end DMI_Frame;

   procedure Set_Accuracy (Per_Mille : Natural) is
   begin
      Acc := Integer_64 (Per_Mille);
   end Set_Accuracy;

   procedure Set_Speed_Accuracy (On : Boolean) is
   begin
      Speed_Acc := On;
   end Set_Speed_Accuracy;

   procedure Odometer_Error (Extra_Cm : Natural) is
   begin
      Odo_Over := Odo_Over + Integer_64 (Extra_Cm);
      Odo_Under := Odo_Under + Integer_64 (Extra_Cm);
   end Odometer_Error;

   procedure Pointer (Event : Natural; X, Y : Natural) is
      P : constant Stream_Element_Array :=
        (Stream_Element (Event),
         Stream_Element (X mod 256), Stream_Element (X / 256),
         Stream_Element (Y mod 256), Stream_Element (Y / 256));
   begin
      if Is_Powered then
         DMI_Core.Handle_Message (DMI_Protocol.MSG_POINTER, P);
      end if;
   end Pointer;

   procedure Touch (X, Y : Natural; Hold_Ms : Natural := 0) is
   begin
      Pointer (0, X, Y);
      Run (Natural'Max (Cycle_Ms, Hold_Ms));
      Pointer (1, X, Y);
      Cycle;
   end Touch;

   ---------------------------------------------------------------------
   --  Observations
   ---------------------------------------------------------------------

   function State return State_T is (Now);
   function Seen return Seen_T is (Win);
   function JRU_Count return Natural is (JRU_N);
   function JRU (I : Positive) return JRU_Record_T is (JRU_List (I));
   function JRU_Mode return Natural is (Last_Mode);
   function JRU_Level_Status return Natural is (Last_Level_Status);
   function JRU_Level return Natural is (Last_Level);
   function JRU_Monitoring return Natural is (Last_Mon);
   function JRU_Sup_Status return Natural is (Last_Sup);
   function JRU_LRBG_Known return Boolean is (LRBG_Known);
   function JRU_LRBG_Id return Natural is (LRBG_Id);
   function JRU_Last_BG_Id return Natural is (Last_BG_Id);
   function JRU_TC_Phase (TI : Natural) return Integer is
     (if TI <= 255 then TC_Phase (TI) else -1);
   function Message_Count return Natural is (Messages_N);
   function Message_NID (I : Positive) return Natural is
     (if I <= Messages_N and then Messages (I).Length > 0
      then Natural (Messages (I).Data (1)) else 0);

   function Message_Header (I : Positive) return EVC_JRU_Messages.Header_T
   is
      H : EVC_JRU_Messages.Header_T;
   begin
      if I <= Messages_N then
         EVC_JRU_Messages.Get_Header
           (Messages (I).Data (1 .. Messages (I).Length), H);
      end if;
      return H;
   end Message_Header;

   function Text_Count return Natural is (Texts_N);
   function Text (I : Positive) return Text_Event_T is (Texts (I));
   function SS_Count return Natural is (SSs_N);
   function SS (I : Positive) return SS_Event_T is (SSs (I));
   function DMI_Sent return Natural is (Sent_N);

   procedure RTM_Input (Payload : Byte_Array) is
   begin
      if Is_Powered then
         EVC_Core.Handle_Input (RTM, Payload);
      end if;
   end RTM_Input;

   function Radio_Count return Natural is (Radio_N);
   function Radio (I : Positive) return Radio_Out_T is (Radio_List (I));
   function Last_T_Train (Session : Positive) return Integer_64 is
     (if Session <= RTM_Max_Sessions then Last_T (Session) else -1);
   function Last_Sent_Ms (Session : Positive) return Unsigned_64 is
     (if Session <= RTM_Max_Sessions then Last_Ms (Session) else 0);
   function T_Train_Of (Session : Positive; Nid : Natural) return Integer_64
   is (if Session <= RTM_Max_Sessions and then Nid <= 255
       then T_By_Nid (Session, Nid) else -1);
   function Last_Request (Session : Positive) return Natural is
     (if Session <= RTM_Max_Sessions then Last_Req (Session) else 0);

end S076_Bench;
