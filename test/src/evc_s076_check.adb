--  ETCS on-board (EVC)
--  Runner of the SUBSET-076 test sequences against the bit codec
--  (host only).
--
--  A sibling repository (../etcs-subset076, or --check/$S076_CHECKOUT)
--  generates conformance test sequences sequences/<SV>/*.scn in the
--  same line oriented family as test/efs/*.scn (Scn_Reader), with its
--  own keywords: sequence, meta, case, step, text:, comment:, result:,
--  and (what this runner reads):
--
--    telegram <step> <group> <k>/<n> <dist> [rel <m>] bits <count> <hex>
--        a balise telegram, its user bits as hex, followed by the
--        fields the reference tool decoded it into:
--    var NAME LEN VALUE [; comment]
--        one row per field, in the order they lie on the wire, LEN its
--        width in bits, VALUE its coded value as the PDF prints it:
--        the digits, possibly in groups ("011 0000"), then the unit
--        "b" (binary), "d" (decimal) or "h" (hex); no unit is decimal
--    message <step> <dist> nid <n> bits <count> <hex>
--        a radio message, also followed by "var" rows
--    dmi ..., chart ..., wb ..., raw: ...
--        not read here (no bits of ours to check them against)
--
--  For every telegram / message, this runner:
--    - decodes the hex with our own codec, exactly as the BTM
--      (ETCS_Telegram.Parse) and RTM (ETCS_Message.Parse) ports do; one
--      the codec refuses is counted as "rejected" with the reason, not
--      as a failure: the sequences carry telegrams and messages meant
--      to be refused (spare values, unknown NID_MESSAGE, a packet after
--      the end of information, system version 1.y), and whether the
--      refusal is the right reaction is for the runner of phase E4;
--      Euroloop messages (group LOOP) are skipped, there is no LTM;
--    - checks that the packets found (Telegram_T.Index / Message_T.Index)
--      equal the "var NID_PACKET" rows, in order (the packet 255 that
--      ends a telegram is not itself a packet: its row, NID_PACKET 255,
--      is not one of Telegram_T.Index either, and is left out of both
--      sides of this comparison);
--    - walks the "var" rows in order with an ETCS_Bits.Reader directly
--      on the telegram/message bits, reading each row's own LEN bits
--      (so that a field this on-board does not know still advances the
--      position correctly) and, where NAME is a variable of our
--      catalogue (evc/language/etcs_language.toml, ETCS_Variables),
--      checking that its width is Bits (that variable) and that the
--      value read equals VALUE. A name that is not one of ours is left
--      uncompared, not a failure: SUBSET-076 may describe fields (or
--      name them) this on-board does not model.
--
--  The sequences tabulate the messages of both directions: what the RBC
--  sends and what the on-board is expected to send. A message is read in
--  the direction its NID_MESSAGE belongs to in our catalogue, the RBC
--  taken as the other end (EVC_Received's own default until phase E5
--  tells an RIU session from an RBC one). The hex of a line holds the
--  bits rounded up to whole nibbles, so it may have an odd length.
--
--  Usage:  obj/evc_s076_check            $S076_CHECKOUT, else
--                                        ../etcs-subset076
--          obj/evc_s076_check DIR        that checkout
--          VERBOSE=1 obj/evc_s076_check  why a line or file was skipped
--  Exit status 1 on a failure. The checkout is optional, like the EFS
--  one (test/efs/README.md): absent, the runner says so and succeeds.
--  Never raises on any content of a sequence file.

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;        use Ada.Text_IO;
with Interfaces;         use Interfaces;
with ETCS_Bits;          use ETCS_Bits;
with ETCS_Catalogue;     use ETCS_Catalogue;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Telegram;
with ETCS_Variables;
with Scn_Reader;         use Scn_Reader;

use type Ada.Directories.File_Kind;
use type ETCS_Telegram.Status_T;
use type ETCS_Message.Status_T;

procedure EVC_S076_Check is

   Verbose : constant Boolean :=
     Ada.Environment_Variables.Exists ("VERBOSE");

   Telegrams, Messages, Rejected, Failures, Skipped : Natural := 0;

   --  The M_VERSION of the telegrams and of the RBC's message 32 of a
   --  sequence by step: the system version the on-board operates in
   --  after a step is that of the last one before it (3.17.3), which
   --  chooses the layout of what it
   --  sends (chapter 6: before 2.2 M_MODE has 4 bits and packet 0
   --  carries Q_LENGTH; the catalogue of this on-board is the 4.0.0
   --  layout, the earlier ones are phase E7). The file lists the
   --  telegrams before the messages, so the table is complete when a
   --  message is checked.
   Version_2_2  : constant := 34;
   Max_Versions : constant := 2048;
   type Version_R is record
      Step, Code : Natural := 0;
   end record;
   Versions      : array (1 .. Max_Versions) of Version_R;
   Version_Count : Natural := 0;

   --  The system version code in force at Step: of the telegram with
   --  the greatest step before it; 48 (3.0) when there is none
   function Version_At (Step : Natural) return Natural is
      Best_Step : Natural := 0;
      Code      : Natural := 48;
   begin
      for I in 1 .. Version_Count loop
         if Versions (I).Step < Step and then Versions (I).Step >= Best_Step
         then
            Best_Step := Versions (I).Step;
            Code := Versions (I).Code;
         end if;
      end loop;
      return Code;
   end Version_At;

   Cur_Path : String (1 .. 300) := (others => ' ');
   Cur_Len  : Natural := 0;

   procedure Set_Path (S : String) is
      N : constant Natural := Natural'Min (S'Length, Cur_Path'Length);
   begin
      Cur_Path (1 .. N) := S (S'First .. S'First + N - 1);
      Cur_Len := N;
      for I in N + 1 .. Cur_Path'Length loop
         Cur_Path (I) := ' ';
      end loop;
      Version_Count := 0;
   end Set_Path;

   procedure Fail (Line_No : Natural; Msg : String) is
   begin
      Failures := Failures + 1;
      Put_Line ("FAIL " & Cur_Path (1 .. Cur_Len) & ":" & Line_No'Image
                & ": " & Msg);
   end Fail;

   --  Our codec refused the telegram or message. Not a failure of the
   --  bit check: the sequences carry telegrams meant to be rejected
   --  (spare values, an unknown NID_MESSAGE, packets after the end of
   --  information, M_DUP 11, telegrams of system version 1.y) and the
   --  step text says what the on-board is to do; the runner of phase
   --  E4 judges that. The fields are still compared row by row.
   procedure Reject (Line_No : Natural; Msg : String) is
   begin
      Rejected := Rejected + 1;
      if Verbose then
         Put_Line ("reject " & Cur_Path (1 .. Cur_Len) & ":" & Line_No'Image
                   & ": " & Msg);
      end if;
   end Reject;

   procedure Skip (Line_No : Natural; Msg : String) is
   begin
      Skipped := Skipped + 1;
      if Verbose then
         Put_Line ("skip " & Cur_Path (1 .. Cur_Len) & ":" & Line_No'Image
                   & ": " & Msg);
      end if;
   end Skip;

   --  Known differences between the sequences and SUBSET-026 4.0.0: a
   --  field width the bit check would report, by sequence and step, with
   --  the reason. A row here is counted as rejected, not failed.
   function Pad (S : String; To : Positive := 60) return String is
     (Ada.Strings.Fixed.Head (S, To));

   type Known_R is record
      Sequence : String (1 .. 36);
      Step     : Natural;
      Reason   : String (1 .. 60);
   end record;
   Known : constant array (Positive range <>) of Known_R :=
     ((Sequence => Pad ("Subset-076-6-3_5180200_01_v400_SV30", 36), Step => 60,
       Reason   => Pad ("packet 0 with a 4 bit M_MODE and L_PACKET 114 under 3.0")),
      (Sequence => Pad ("Subset-076-6-3_9990200_06_v400_SV30", 36), Step => 57,
       Reason   => Pad ("packet 0 with a 4 bit M_MODE and L_PACKET 114 under 3.0")),
      (Sequence => Pad ("Subset-076-6-3_4080433_01_v400_SV30", 36), Step => 287,
       Reason   => Pad ("packet 0 with a 4 bit M_MODE and L_PACKET 114 under 3.0")));

   --  The reason of the known difference at Step of the current file,
   --  "" when there is none
   function Known_Reason (Step : Natural) return String is
   begin
      for K of Known loop
         declare
            Name : constant String :=
              Ada.Strings.Fixed.Trim (K.Sequence, Ada.Strings.Right);
         begin
            if K.Step = Step and then Cur_Len >= Name'Length + 4
              and then Cur_Path (Cur_Len - Name'Length - 3 .. Cur_Len)
                       = Name & ".scn"
            then
               return Ada.Strings.Fixed.Trim (K.Reason, Ada.Strings.Right);
            end if;
         end;
      end loop;
      return "";
   end Known_Reason;


   ---------------------------------------------------------------------
   --  Numbers of the sequence files: exact integers, never raise.
   --  LEN and the header's "bits" / "nid" / step are small decimal
   --  naturals; VALUE is read by Var_Value below.
   ---------------------------------------------------------------------

   function To_Nat (S : String; OK : out Boolean) return Natural is
      V : Natural := 0;
   begin
      OK := S'Length > 0 and then S'Length <= 6;
      if OK then
         for C of S loop
            if C not in '0' .. '9' then
               OK := False;
               exit;
            end if;
            V := V * 10 + (Character'Pos (C) - Character'Pos ('0'));
         end loop;
      end if;
      return (if OK then V else 0);
   end To_Nat;


   Max_Payload : constant := 1024;   -- ETCS_Message.Max_Bytes

   procedure Hex_To_Bytes
     (Hex  : String;
      Data : out ETCS_Bits.Byte_Array;
      Len  : out Natural;
      OK   : out Boolean)
   is
      function Nibble (C : Character; Good : in out Boolean)
        return Unsigned_8
      is
      begin
         case C is
            when '0' .. '9' =>
               return Unsigned_8 (Character'Pos (C) - Character'Pos ('0'));
            when 'a' .. 'f' =>
               return Unsigned_8 (Character'Pos (C)
                                  - Character'Pos ('a') + 10);
            when 'A' .. 'F' =>
               return Unsigned_8 (Character'Pos (C)
                                  - Character'Pos ('A') + 10);
            when others =>
               Good := False;
               return 0;
         end case;
      end Nibble;
      --  an odd number of nibbles: the last byte's low nibble is 0
      Bytes : constant Natural := (Hex'Length + 1) / 2;
   begin
      Len := 0;
      OK := Hex'Length > 0 and then Bytes <= Data'Length
            and then Bytes <= Max_Payload;
      if not OK then
         return;
      end if;
      for I in 0 .. Bytes - 1 loop
         declare
            Hi : constant Character := Hex (Hex'First + 2 * I);
            Lo : constant Character :=
              (if Hex'First + 2 * I + 1 <= Hex'Last
               then Hex (Hex'First + 2 * I + 1) else '0');
            Hv : constant Unsigned_8 := Nibble (Hi, OK);
            Lv : constant Unsigned_8 := Nibble (Lo, OK);
         begin
            Data (Data'First + I) := Hv * 16 + Lv;
         end;
         exit when not OK;
      end loop;
      Len := (if OK then Bytes else 0);
   end Hex_To_Bytes;

   ---------------------------------------------------------------------
   --  The pending telegram / message block: the "telegram" or
   --  "message" line that opened it, and the "var" rows read since
   ---------------------------------------------------------------------

   --  Skipped_Block: the header line was skipped (Euroloop, no bits):
   --  its var rows are passed over without a count of their own
   type Block_Kind_T is (None, Skipped_Block, Telegram_Block, Message_Block);
   Block      : Block_Kind_T := None;
   Block_Line : Natural := 0;

   Data     : ETCS_Bits.Byte_Array (1 .. Max_Payload) := (others => 0);
   Data_Len : Natural := 0;   -- bytes
   Bit_Len  : Natural := 0;   -- telegram user bits ("bits" of the line)
   Msg_NID  : Natural := 0;   -- "nid" of a message line
   Blk_Step : Natural := 0;   -- the step of the telegram / message line

   Max_Vars : constant := 512;
   type Var_R is record
      Name  : String (1 .. 24) := (others => ' ');
      NLen  : Natural := 0;
      Len   : Natural := 0;
      Value : Unsigned_64 := 0;
      Line  : Natural := 0;
   end record;
   Vars      : array (1 .. Max_Vars) of Var_R;
   Var_Count : Natural := 0;

   function Var_Name (I : Positive) return String is
     (Vars (I).Name (1 .. Vars (I).NLen));

   ---------------------------------------------------------------------
   --  The generic field walk, shared by a telegram and a message: the
   --  "var" rows in order against an ETCS_Bits.Reader on the payload
   ---------------------------------------------------------------------

   procedure Check_Fields (Limit_Bits : Natural) is
      R : ETCS_Bits.Reader (Data'Length);
   begin
      ETCS_Bits.Load (R, Data (1 .. Data_Len), Limit_Bits);
      if ETCS_Bits.Failed (R) then
         Fail (Block_Line, "fewer bits than the declared length");
         return;
      end if;
      for I in 1 .. Var_Count loop
         declare
            Len : constant Natural := Vars (I).Len;
         begin
            if Len not in 1 .. 64 then
               Skip (Vars (I).Line, "var " & Var_Name (I) & ": bad length");
               return;
            end if;
            if ETCS_Bits.Remaining (R) < Len then
               Fail (Vars (I).Line,
                     "var " & Var_Name (I) & ": past the end of the "
                     & "telegram/message");
               return;
            end if;
            declare
               V     : Unsigned_64;
               Var   : ETCS_Variables.Variable_T;
               Known : Boolean := True;
            begin
               begin
                  Var := ETCS_Variables.Variable_T'Value (Var_Name (I));
               exception
                  when others =>
                     Known := False;
               end;
               ETCS_Bits.Read (R, ETCS_Bits.Width (Len), V);
               if Known
                 and then ETCS_Variables.Bits (Var) /= ETCS_Bits.Width (Len)
               then
                  if Known_Reason (Blk_Step) /= "" then
                     Reject (Vars (I).Line,
                             "var " & Var_Name (I) & ":" & Len'Image
                             & " bits, a known difference of SUBSET-076: "
                             & Known_Reason (Blk_Step));
                  elsif Version_At (Blk_Step) < Version_2_2 then
                     Reject (Vars (I).Line,
                             "var " & Var_Name (I) & ":" & Len'Image
                             & " bits, the layout of system version code"
                             & Version_At (Blk_Step)'Image
                             & " (chapter 6, E7); ours"
                             & ETCS_Variables.Bits (Var)'Image);
                  else
                     Fail (Vars (I).Line,
                           "var " & Var_Name (I) & ": our catalogue has"
                           & ETCS_Variables.Bits (Var)'Image & " bits, the"
                           & " sequence" & Len'Image);
                  end if;
               elsif Known and then V /= Vars (I).Value then
                  Fail (Vars (I).Line,
                        "var " & Var_Name (I) & ": ours" & V'Image
                        & ", the sequence" & Vars (I).Value'Image);
               end if;
            end;
         end;
      end loop;
   end Check_Fields;

   --  The var "NID_PACKET" rows (packet 255, the telegram terminator,
   --  excluded: it is not a packet of Index either), against the
   --  Count packets whose NID Packet_NID gives, in order
   procedure Check_Packet_List
     (Count : Natural; Packet_NID : not null access
        function (I : Positive) return Natural)
   is
      Idx : Natural := 0;
      OK  : Boolean := True;
   begin
      for I in 1 .. Var_Count loop
         if Var_Name (I) = "NID_PACKET" and then Vars (I).Value /= 255 then
            Idx := Idx + 1;
            if Count < Idx
              or else Packet_NID (Idx) /= Natural (Vars (I).Value)
            then
               OK := False;
            end if;
         end if;
      end loop;
      if Idx /= Count then
         OK := False;
      end if;
      if not OK then
         Fail (Block_Line, "the packets found do not match the "
               & "var NID_PACKET rows");
      end if;
   end Check_Packet_List;

   procedure Flush_Block is
   begin
      case Block is
         when None | Skipped_Block =>
            null;
         when Telegram_Block =>
            declare
               T : ETCS_Telegram.Telegram_T;
               S : ETCS_Telegram.Status_T;

               function NID (I : Positive) return Natural is
                 (Natural (T.Index (I).NID));
            begin
               ETCS_Telegram.Parse (Data (1 .. Data_Len), Bit_Len, T, S);
               if S /= ETCS_Telegram.Accepted then
                  Reject (Block_Line, "telegram: " & S'Image);
               else
                  Check_Packet_List (T.Count, NID'Access);
               end if;
               Check_Fields (Bit_Len);
            end;
         when Message_Block =>
            declare
               use type ETCS_Message_Catalogue.Message_Kind_T;
               M : ETCS_Message.Message_T;
               S : ETCS_Message.Status_T;
               --  the direction the NID_MESSAGE belongs to; an unknown
               --  NID is read as track to train and reported by Parse
               Dir : constant Direction_T :=
                 (if ETCS_Message_Catalogue.Kind (Train_To_Track, Msg_NID)
                     /= ETCS_Message_Catalogue.Unknown
                    and then ETCS_Message_Catalogue.Kind
                               (Track_To_Train, Msg_NID)
                             = ETCS_Message_Catalogue.Unknown
                  then Train_To_Track else Track_To_Train);
               Kind : constant ETCS_Message_Catalogue.Message_Kind_T :=
                 ETCS_Message_Catalogue.Kind (Dir, Msg_NID);
               --  the other end of the session: the RBC, unless the
               --  catalogue has this message for the RIU only (radio
               --  infill, 8.5.2 / 8.5.3)
               Sender : constant Sender_T :=
                 (if Kind = ETCS_Message_Catalogue.Unknown
                    or else ETCS_Message_Catalogue.Sent_By (Kind) (RBC)
                    or else not ETCS_Message_Catalogue.Sent_By (Kind) (RIU)
                  then RBC else RIU);

               function NID (I : Positive) return Natural is
                 (Natural (M.Index (I).NID));
            begin
               ETCS_Message.Parse (Data (1 .. Data_Len), Dir, Sender, M, S);
               if S /= ETCS_Message.Accepted then
                  Reject (Block_Line, "message: " & S'Image);
               else
                  Check_Packet_List (M.Count, NID'Access);
               end if;
               Check_Fields (8 * Data_Len);
            end;
      end case;
      Block := None;
      Var_Count := 0;
   end Flush_Block;

   ---------------------------------------------------------------------
   --  One line of a sequence file
   ---------------------------------------------------------------------

   --  The word "bits" (or another marker) among L's words, from K on;
   --  0 when there is none
   function Find (L : Line_T; Marker : String; From : Positive := 2)
     return Natural
   is
   begin
      for I in From .. L.Count loop
         if Word (L, I) = Marker then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   procedure Start_Telegram (L : Line_T; Line_No : Positive) is
      Idx : constant Natural := Find (L, "bits");
   begin
      if Idx = 0 or else Idx + 2 > L.Count then
         Skip (Line_No, "telegram: no bits/hex");
         Block := Skipped_Block;
         return;
      end if;
      --  a Euroloop message (the group column says LOOP): the loop
      --  transmission module is optional and this on-board has none
      if L.Count >= 3 and then Word (L, 3) = "LOOP" then
         Skip (Line_No, "Euroloop message: no LTM on this on-board");
         Block := Skipped_Block;
         return;
      end if;
      declare
         Count_OK, Hex_OK : Boolean;
         Count : constant Natural := To_Nat (Word (L, Idx + 1), Count_OK);
      begin
         Hex_To_Bytes (Word (L, Idx + 2), Data, Data_Len, Hex_OK);
         if not Count_OK or else not Hex_OK or else Count > 8 * Data_Len
           or else Count not in ETCS_Telegram.Short_Bits
                              | ETCS_Telegram.Long_Bits
         then
            Skip (Line_No, "telegram: bad bits/hex");
            Block := Skipped_Block;
            return;
         end if;
         Bit_Len := Count;
         declare
            Step_OK : Boolean;
         begin
            Blk_Step := (if L.Count >= 2 then To_Nat (Word (L, 2), Step_OK)
                         else 0);
         end;
         Block := Telegram_Block;
         Block_Line := Line_No;
         Var_Count := 0;
         Telegrams := Telegrams + 1;
      end;
   end Start_Telegram;

   procedure Start_Message (L : Line_T; Line_No : Positive) is
      Idx : constant Natural := Find (L, "bits");
   begin
      if Idx = 0 or else Idx + 2 > L.Count then
         Skip (Line_No, "message: no bits/hex");
         Block := Skipped_Block;
         return;
      end if;
      declare
         Count_OK, Hex_OK : Boolean;
         Count : constant Natural := To_Nat (Word (L, Idx + 1), Count_OK);
      begin
         Hex_To_Bytes (Word (L, Idx + 2), Data, Data_Len, Hex_OK);
         if not Count_OK or else not Hex_OK or else Count > 8 * Data_Len then
            Skip (Line_No, "message: bad bits/hex");
            Block := Skipped_Block;
            return;
         end if;
         declare
            N      : constant Natural := Find (L, "nid");
            NID_OK : Boolean := False;
         begin
            Msg_NID := (if N > 0 and then N < L.Count
                        then To_Nat (Word (L, N + 1), NID_OK) else 0);
            if not NID_OK then
               Skip (Line_No, "message: no nid");
               Block := Skipped_Block;
               return;
            end if;
         end;
         declare
            Step_OK : Boolean;
         begin
            Blk_Step := (if L.Count >= 2 then To_Nat (Word (L, 2), Step_OK)
                         else 0);
         end;
         Block := Message_Block;
         Block_Line := Line_No;
         Var_Count := 0;
         Messages := Messages + 1;
      end;
   end Start_Message;

   --  VALUE of a var row: the words from the fourth up to the unit
   --  ("b" binary, "d" decimal, "h" hex; none: decimal) or up to a ";"
   --  (the comment), the digit groups joined ("011 0000 b" is 48).
   --  OK is False for anything else (a text value, no digits).
   function Var_Value (L : Line_T; OK : out Boolean) return Unsigned_64 is
      Last   : Natural := L.Count;
      Base   : Unsigned_64 := 10;
      V      : Unsigned_64 := 0;
      N_Digits : Natural := 0;
   begin
      for I in 4 .. L.Count loop
         if Word (L, I) = ";" then
            Last := I - 1;
            exit;
         end if;
      end loop;
      OK := Last >= 4;
      if not OK then
         return 0;
      end if;
      declare
         U : constant String := Word (L, Last);
      begin
         if U = "b" then
            Base := 2;
            Last := Last - 1;
         elsif U = "h" then
            Base := 16;
            Last := Last - 1;
         elsif U = "d" then
            Last := Last - 1;
         end if;
      end;
      OK := Last >= 4;
      for I in 4 .. Last loop
         for C of Word (L, I) loop
            declare
               D : Natural;
            begin
               case C is
                  when '0' .. '9' =>
                     D := Character'Pos (C) - Character'Pos ('0');
                  when 'a' .. 'f' =>
                     D := Character'Pos (C) - Character'Pos ('a') + 10;
                  when 'A' .. 'F' =>
                     D := Character'Pos (C) - Character'Pos ('A') + 10;
                  when others =>
                     OK := False;
                     return 0;
               end case;
               --  more digits than 64 bits hold: not a field value
               if Unsigned_64 (D) >= Base
                 or else N_Digits >= (case Base is
                                       when 2 => 64, when 16 => 16,
                                       when others => 19)
               then
                  OK := False;
                  return 0;
               end if;
               V := V * Base + Unsigned_64 (D);
               N_Digits := N_Digits + 1;
            end;
         end loop;
      end loop;
      OK := OK and then N_Digits > 0;
      return (if OK then V else 0);
   end Var_Value;

   procedure Add_Var (L : Line_T; Line_No : Positive) is
   begin
      if Block = Skipped_Block then
         return;
      end if;
      if Block = None then
         Skip (Line_No, "var without a telegram/message");
         return;
      end if;
      if L.Count < 4 then
         Skip (Line_No, "bad var line");
         return;
      end if;
      if Var_Count >= Max_Vars then
         Skip (Line_No, "too many var rows");
         return;
      end if;
      declare
         Name           : constant String := Word (L, 2);
         Len_OK, Val_OK : Boolean;
         Len            : constant Natural := To_Nat (Word (L, 3), Len_OK);
         Value          : constant Unsigned_64 := Var_Value (L, Val_OK);
      begin
         if not Len_OK or else Name'Length = 0 then
            Skip (Line_No, "bad var line");
            return;
         end if;
         if not Val_OK then
            --  a text value (the PDF prints some fields as words): the
            --  row still advances the reader by LEN bits, uncompared
            Var_Count := Var_Count + 1;
            if Var_Count > Max_Vars then
               Var_Count := Max_Vars;
               Skip (Line_No, "too many var rows");
               return;
            end if;
            Vars (Var_Count) := (Name => (others => ' '), NLen => 0,
                                 Len => Len, Value => 0, Line => Line_No);
            Skip (Line_No, "var " & Name & ": text value, not compared");
            return;
         end if;
         --  the trackside's version: a balise telegram's, or the RBC's
         --  in its message 32 (RBC/RIU system version)
         if (Block = Telegram_Block
             or else (Block = Message_Block and then Msg_NID = 32))
           and then Name = "M_VERSION"
           and then Value <= 127 and then Version_Count < Max_Versions
         then
            Version_Count := Version_Count + 1;
            Versions (Version_Count) := (Blk_Step, Natural (Value));
         end if;
         Var_Count := Var_Count + 1;
         declare
            V : Var_R renames Vars (Var_Count);
            N : constant Natural := Natural'Min (Name'Length, V.Name'Length);
         begin
            V.Name (1 .. N) := Name (Name'First .. Name'First + N - 1);
            for J in N + 1 .. V.Name'Length loop
               V.Name (J) := ' ';
            end loop;
            V.NLen := N;
            V.Len := Len;
            V.Value := Value;
            V.Line := Line_No;
         end;
      end;
   end Add_Var;

   procedure On_Line (L : Line_T; Line_No : Positive) is
      K : constant String := Word (L, 1);
   begin
      if K /= "var" then
         Flush_Block;
      end if;
      if K = "telegram" then
         Start_Telegram (L, Line_No);
      elsif K = "message" then
         Start_Message (L, Line_No);
      elsif K = "var" then
         Add_Var (L, Line_No);
      end if;
      --  sequence, meta, case, step, text:, comment:, result:, dmi,
      --  chart, wb, raw:, other comments: nothing to check bits against
   exception
      when others =>
         Skip (Line_No, "invalid line");
         Block := None;
         Var_Count := 0;
   end On_Line;

   ---------------------------------------------------------------------
   --  A sequence file, and the sibling checkout
   ---------------------------------------------------------------------

   procedure Check_File (Path : String) is
      Ok : Boolean;
   begin
      Set_Path (Path);
      Block := None;
      Var_Count := 0;
      Scn_Reader.Read_File (Path, On_Line'Access, Ok);
      Flush_Block;
      if not Ok then
         Put_Line ("evc_s076_check: " & Path & " unreadable, skipped");
         Skipped := Skipped + 1;
      end if;
   end Check_File;

   Root : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Command_Line.Argument (1)
      elsif Ada.Environment_Variables.Exists ("S076_CHECKOUT")
      then Ada.Environment_Variables.Value ("S076_CHECKOUT")
      else "../etcs-subset076");

   Paths : Scn_Reader.Paths_T;
   Count : Natural := 0;
begin
   if not Ada.Directories.Exists (Root)
     or else Ada.Directories.Kind (Root) /= Ada.Directories.Directory
   then
      Put_Line ("evc_s076_check: " & Root & " absent, skipped");
      return;
   end if;
   Scn_Reader.List_Scn_Files (Root & "/sequences", Recurse => True,
                              Paths => Paths, Count => Count);
   for I in 1 .. Count loop
      Check_File (Paths (I).S (1 .. Paths (I).N));
   end loop;
   Put_Line ("evc_s076_check:" & Telegrams'Image & " telegrams,"
             & Messages'Image & " messages," & Rejected'Image
             & " rejected," & Failures'Image
             & " failures," & Skipped'Image & " skipped");
   if Failures > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end EVC_S076_Check;
