--  ETCS on-board (EVC)

with EVC_Core;
with EVC_JRU_Messages;  use EVC_JRU_Messages;
with EVC_Outbox;
with EVC_Ports;         use EVC_Ports;
with EVC_Test_Support;  use EVC_Test_Support;
with Interfaces;        use Interfaces;

package body EVC_Test_JRU is

   Buf : Byte_Array (1 .. Max_Length);

   --  2026-10-16 12:34:56 UTC in seconds since 2000-01-01
   Reference : constant Unsigned_32 := 845_469_296;

   --  A message NID with header H and the complementary variables F in
   --  Buf (1 .. Last)
   procedure Build (NID : Byte; H : Header_T; F : Fields_T;
                    Last : out Natural)
   is
      Pos : Natural := 0;
   begin
      Buf := (others => 0);
      Put_Header (Buf, Pos, NID, H);
      for I in F'Range loop
         if F (I).Bits > 0 then
            Put_Bits (Buf, Pos, F (I).Value, F (I).Bits);
         end if;
      end loop;
      Last := (Pos + 7) / 8;
      Put_Length (Buf, Last);
   end Build;

   function Same (A, B : Reference_T) return Boolean is
     (A.Q_Scale = B.Q_Scale and then A.NID = B.NID and then A.D = B.D
      and then A.Q_Dir = B.Q_Dir and then A.Q_D = B.Q_D
      and then A.Over = B.Over and then A.Under = B.Under);

   --  SUBSET-027 4.2.2, 4.2.3: the header read back field by field, with
   --  and without the LRBG part; 4.2.4: every message of an event of
   --  EVC_Ports gives the event back (EVC_JRU_Messages.View)
   procedure Scenario_JRU_Format is
      H, G : Header_T;
      Last : Natural;
      NID  : Byte;
      F    : Fields_T;
      type Case_T is record
         Event, B2, B3, B4 : Byte;
         NID               : Byte;
         Bits              : Natural;   -- of the complementary part
      end record;
      Cases : constant array (1 .. 15) of Case_T :=
        ((11, 37, 0, 0, 11, 8), (30, 1, 0, 0, 30, 1), (31, 0, 0, 0, 31, 1),
         (39, 2, 0, 0, 39, 2), (51, 1, 0, 0, 51, 1), (132, 1, 0, 0, 32, 1),
         (38, 1, 1, 0, 38, 3), (38, 1, 0, 0, 38, 2),
         (48, 16#26#, 16#20#, 16#1F#, 48, 24),
         (23, 1, 1, 0, 255, 32), (40, 1, 3, 0, 255, 32),
         (9, 1, 0, 0, 15, 2), (7, 1, 0, 0, 52, 8), (7, 2, 0, 0, 52, 8),
         (7, 0, 0, 0, 255, 32));
      V    : View_T;
   begin
      Set_Time (H, Reference, 100);
      Check (H.Year = 26 and then H.Month = 10 and then H.Day = 16
             and then H.Hour = 12 and then H.Minutes = 34
             and then H.Seconds = 56 and then H.TTS = 2,
             "SUBSET-027 4.2.3.3, 4.2.3.4: DATE and TIME in UTC "
             & "(2026-10-16 12:34:56.10)");
      Set_Time (G, 0, 86_399_950);
      Check (G.Year = 0 and then G.Month = 1 and then G.Day = 1
             and then G.Hour = 23 and then G.Minutes = 59
             and then G.Seconds = 59 and then G.TTS = 19,
             "4.2.3.4: the last 50 ms of 2000-01-01");
      H.Q_LRBG := 2;
      H.SOLR := (Q_Scale => 1, NID => 123 * 2**14 + 7, D => 250,
                 Q_Dir => 1, Q_D => 0, Over => 5, Under => 6);
      H.LRBG := (Q_Scale => 2, NID => 123 * 2**14 + 8, D => 32,
                 Q_Dir => 0, Q_D => 1, Over => 1, Under => 2);
      H.V_Train := 87;
      H.Driver_Id := (others => 0);
      H.Driver_Id (1 .. 4) := (65, 66, 67, 49);
      H.NID_Engine := 16#ABCDEF#;
      H.M_Version := 16#21#;
      H.M_Level := 3;
      H.M_Mode := 0;
      Build (NID_General, H, No_Fields, Last);
      Get_Header (Buf (1 .. Last), G);
      Check (Is_Message (Buf (1 .. Last)) and then Last = 49
             and then Header_Bits (H) = Max_Header_Bits
             and then Body_Bit (Buf (1 .. Last)) = Max_Header_Bits,
             "4.2.2.2: the header with an LRBG other than the SOLR, 386 "
             & "bits in 49 bytes, L_MESSAGE");
      Check (G.Year = 26 and then G.TTS = 2 and then G.Q_LRBG = 2
             and then Same (G.SOLR, H.SOLR) and then Same (G.LRBG, H.LRBG)
             and then G.V_Train = 87 and then G.Driver_Id = H.Driver_Id
             and then G.NID_Engine = 16#ABCDEF# and then G.M_Version = 16#21#
             and then G.M_Level = 3 and then G.M_Mode = 0,
             "4.2.3.3 to 4.2.3.11: the header read back");
      H.Q_LRBG := 1;
      Build (NID_General, H, No_Fields, Last);
      Get_Header (Buf (1 .. Last), G);
      Check (Is_Message (Buf (1 .. Last)) and then Last = 39
             and then G.Q_LRBG = 1 and then Same (G.SOLR, H.SOLR)
             and then G.NID_Engine = 16#ABCDEF# and then G.M_Mode = 0
             and then View (Buf (1 .. Last)).Event = 0,
             "4.2.3.5: the header without the LRBG part (Q_LRBG 1), 311 "
             & "bits in 39 bytes; the general message records no event");
      Check (not Is_Message (Buf (1 .. Last - 1)),
             "4.2.3.2: a payload shorter than L_MESSAGE is no message");
      for C of Cases loop
         Event_Message (C.Event, C.B2, C.B3, C.B4, NID, F);
         Build (NID, H, F, Last);
         V := View (Buf (1 .. Last));
         Check (NID = C.NID and then Is_Message (Buf (1 .. Last))
                and then Last = (Min_Header_Bits + C.Bits + 7) / 8
                and then V.Event = C.Event and then V.B2 = C.B2
                and then V.B3 = C.B3 and then V.B4 = C.B4,
                "4.2.4: the message" & C.NID'Image & " of the event"
                & C.Event'Image & " read back");
      end loop;
      --  4.2.4.12: an unexpected group (event 5) of NID_C 123, NID_BG 7
      Paired_Message (5, 16#07#, 16#C0#, 16#1E#, NID, F);
      Build (NID, H, F, Last);
      Check (NID = NID_BG_Error
             and then Get_Bits (Buf (1 .. Last), Min_Header_Bits, 10) = 123
             and then Get_Bits (Buf (1 .. Last), Min_Header_Bits + 10, 14)
                      = 7
             and then Get_Bits (Buf (1 .. Last), Min_Header_Bits + 24, 8) = 0
             and then View (Buf (1 .. Last)).Event = 0,
             "4.2.4.12: NID_C, NID_ERRORBG and M_ERROR 0 (linking "
             & "consistency) before the proprietary message of the event");
      Paired_Message (10, 7, 0, 0, NID, F);
      Check (NID = 0, "4.2.4.255: no paired message for a new LRBG");
   end Scenario_JRU_Format;

   --  The JRU record I as a message
   function Payload (I : Positive) return Byte_Array is
     (Out_Buf (Recs (I).First .. Recs (I).Last));

   --  SUBSET-027 4.1.1.2, 4.2.3: the header the on-board captures at the
   --  power-up (UTC from EVC_Core.Set_UTC, SB, standstill, the driver
   --  unknown)
   procedure Scenario_JRU_On_Board is
      H     : Header_T;
      Found : Natural := 0;
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      EVC_Core.Set_UTC (Reference);
      EVC_Core.Tick (100);
      Take;
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = JRU and then JRU_NID (I) = NID_General then
            Found := I;
         end if;
      end loop;
      Check (Found /= 0, "4.3.1.1: the general message at the mode change");
      if Found /= 0 then
         Get_Header (Payload (Found), H);
         Check (H.Year = 26 and then H.Month = 10 and then H.Day = 16
                and then H.Hour = 12 and then H.Minutes = 34
                and then H.Seconds = 56 and then H.TTS = 2,
                "4.1.1.2 a), 4.2.3.3, 4.2.3.4: the time of the event, UTC");
         Check (H.M_Mode = 6 and then H.M_Level = 0
                and then H.V_Train = 1023
                and then H.Driver_Id = (1 .. 16 => Character'Pos ('?'))
                and then H.Q_LRBG = 0 and then H.SOLR.NID mod 2**14 = 16383,
                "4.2.3.5 to 4.2.3.11: SB in level 0 at standstill, the "
                & "driver ID and the LRBG unknown");
      end if;
      Check (EVC_Outbox.JRU_Lost = 0, "4.1.1.4: no message lost");
   end Scenario_JRU_On_Board;

end EVC_Test_JRU;
