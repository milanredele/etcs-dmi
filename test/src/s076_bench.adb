--  ETCS on-board (EVC)
--  The test bench of the SUBSET-076 runner, body.

pragma Ada_2012;
with Ada.Streams;     use Ada.Streams;
with DMI_Core;
with DMI_Protocol;
with EVC_Core;
with EVC_Distances;
with EVC_Outbox;
with EVC_Ports;       use EVC_Ports;
with EVC_Position;

package body S076_Bench is


   use type EVC_Bytes.Byte_Array;

   ---------------------------------------------------------------------
   --  State of the world
   ---------------------------------------------------------------------

   Is_Powered : Boolean := False;
   Clock      : Unsigned_64 := 0;

   X_Cm      : Integer_64 := 0;     -- antenna, track position
   V_Cms     : Natural := 0;
   Dir       : Integer := 1;
   Odo_Over  : Integer_64 := 0;
   Odo_Under : Integer_64 := 0;
   Acc       : Integer_64 := Accuracy_Per_Mille;

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
   Last_Mode, Last_Level_Status, Last_Level : Natural := No_Value;
   Last_Commands : Natural := 0;
   Last_Mon, Last_Sup : Natural := 0;
   LRBG_Known : Boolean := False;
   TC_Phase   : array (0 .. 255) of Integer := (others => -1);

   Texts   : array (1 .. Max_Events) of Text_Event_T;
   Texts_N : Natural := 0;
   SSs     : array (1 .. Max_Events) of SS_Event_T;
   SSs_N   : Natural := 0;
   Sent_N  : Natural := 0;

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

   procedure To_DMI (Frame : Byte_Array) is
      --  type u8, length u32, payload
      Len : constant Natural := Frame'Length - 5;
      P   : Stream_Element_Array (1 .. Stream_Element_Offset (Len));
   begin
      for I in 1 .. Len loop
         P (Stream_Element_Offset (I)) :=
           Stream_Element (Frame (Frame'First + 4 + I));
      end loop;
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

   procedure Observe_JRU (P : Byte_Array) is
   begin
      if P'Length < 4 then
         return;
      end if;
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
      elsif P (P'First) = 8 and then P (P'First + 1) = 0 then
         --  the train position unknown
         LRBG_Known := False;
      elsif P (P'First) = 45 then
         TC_Phase (Natural (P (P'First + 1))) := Natural (P (P'First + 2));
      end if;
   end Observe_JRU;

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
      for I in Now.TC'Range loop
         Win.TC (I) := Win.TC (I) or else Now.TC (I);
         Win.TIU_TC (I) := Win.TIU_TC (I) or else Now.TIU_TC (I);
      end loop;
   end Fold;

   procedure New_Window is
   begin
      Win := (others => <>);
      Cycles := 0;
      JRU_N := 0;
      Texts_N := 0;
      SSs_N := 0;
      Sent_N := 0;
   end New_Window;

   function Window_Cycles return Natural is (Cycles);

   ---------------------------------------------------------------------
   --  Power and time
   ---------------------------------------------------------------------

   procedure Reset is
   begin
      Is_Powered := False;
      Clock := 0;
      X_Cm := 0;
      V_Cms := 0;
      Dir := 1;
      Odo_Over := 0;
      Odo_Under := 0;
      Acc := Accuracy_Per_Mille;
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
      TC_Phase := (others => -1);
      New_Window;
   end Reset;

   procedure Power_On is
   begin
      EVC_Core.Initialise;
      DMI_Core.Initialise;
      Is_Powered := True;
      Pending_Count := 0;
      Now := (others => <>);
      Last_Mode := No_Value;
      Last_Level_Status := No_Value;
      Last_Level := No_Value;
      LRBG_Known := False;
      TC_Phase := (others => -1);
      Last_Commands := 0;
      Last_Mon := 0;
      Last_Sup := 0;
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

   procedure Sample is
      Movement : constant EVC_Bytes.Byte :=
        (if V_Cms = 0 then 0 elsif Dir > 0 then 1 else 2);
      V : constant Natural := Natural'Min (V_Cms, 65_535);
   begin
      EVC_Core.Handle_Input
        (Odometer,
         U32 (X_Cm) & U32 (Odo_Over) & U32 (Odo_Under)
         & U16 (V) & U16 (V) & U16 (V)
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

   procedure Cycle is
      Old_X : constant Integer_64 := X_Cm;
      Step  : constant Integer_64 :=
        Integer_64 (V_Cms) * Cycle_Ms / 1000 * Integer_64 (Dir);
      New_X : constant Integer_64 := X_Cm + Step;
   begin
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
         EVC_Core.Tick (Cycle_Ms);
         Take_Outputs;
         DMI_Core.Tick (Cycle_Ms);
         Take_DMI;
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
   function Speed return Natural is (V_Cms);
   function Direction return Integer is (Dir);

   procedure Set_Speed (Cms : Natural) is
   begin
      V_Cms := Cms;
   end Set_Speed;

   procedure Set_Direction (Dir : Integer) is
   begin
      S076_Bench.Dir := (if Dir < 0 then -1 else 1);
   end Set_Direction;

   procedure Move_To (To_Cm : Integer_64; Cms : Positive;
                      Max_Ms : Natural := 3_600_000) is
      Elapsed : Natural := 0;
   begin
      V_Cms := Cms;
      if To_Cm = X_Cm then
         return;
      end if;
      Dir := (if To_Cm > X_Cm then 1 else -1);
      while (if Dir > 0 then X_Cm < To_Cm else X_Cm > To_Cm)
        and then Elapsed < Max_Ms
      loop
         declare
            Left : constant Integer_64 := abs (To_Cm - X_Cm);
            Full : constant Integer_64 := Integer_64 (Cms) * Cycle_Ms / 1000;
         begin
            --  the last cycle ends at the target
            if Left < Full then
               V_Cms := Natural (Integer_64'Max (1, Left * 1000 / Cycle_Ms));
            end if;
            Cycle;
            V_Cms := Cms;
            Elapsed := Elapsed + Cycle_Ms;
            exit when Full = 0;
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
   function JRU_TC_Phase (TI : Natural) return Integer is
     (if TI <= 255 then TC_Phase (TI) else -1);
   function Text_Count return Natural is (Texts_N);
   function Text (I : Positive) return Text_Event_T is (Texts (I));
   function SS_Count return Natural is (SSs_N);
   function SS (I : Positive) return SS_Event_T is (SSs (I));
   function DMI_Sent return Natural is (Sent_N);

end S076_Bench;
