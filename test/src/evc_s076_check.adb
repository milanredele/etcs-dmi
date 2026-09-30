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
--        width in bits, VALUE its coded value (decimal, or 0x.. hex)
--    message <step> <dist> nid <n> bits <count> <hex>
--        a radio message, also followed by "var" rows
--    dmi ..., chart ..., wb ..., raw: ...
--        not read here (no bits of ours to check them against)
--
--  For every telegram / message, this runner:
--    - decodes the hex with our own codec, exactly as the BTM
--      (ETCS_Telegram.Parse) and RTM (ETCS_Message.Parse) ports do,
--      and checks that it is Accepted;
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
--  A message is read as track to train, from an RBC (EVC_Received's own
--  default until phase E5 tells an RIU session from an RBC one).
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
with Ada.Text_IO;        use Ada.Text_IO;
with Interfaces;         use Interfaces;
with ETCS_Bits;          use ETCS_Bits;
with ETCS_Catalogue;     use ETCS_Catalogue;
with ETCS_Message;
with ETCS_Telegram;
with ETCS_Variables;
with Scn_Reader;         use Scn_Reader;

use type Ada.Directories.File_Kind;
use type ETCS_Telegram.Status_T;
use type ETCS_Message.Status_T;

procedure EVC_S076_Check is

   Verbose : constant Boolean :=
     Ada.Environment_Variables.Exists ("VERBOSE");

   Telegrams, Messages, Failures, Skipped : Natural := 0;

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
   end Set_Path;

   procedure Fail (Line_No : Natural; Msg : String) is
   begin
      Failures := Failures + 1;
      Put_Line ("FAIL " & Cur_Path (1 .. Cur_Len) & ":" & Line_No'Image
                & ": " & Msg);
   end Fail;

   procedure Skip (Line_No : Natural; Msg : String) is
   begin
      Skipped := Skipped + 1;
      if Verbose then
         Put_Line ("skip " & Cur_Path (1 .. Cur_Len) & ":" & Line_No'Image
                   & ": " & Msg);
      end if;
   end Skip;

   ---------------------------------------------------------------------
   --  Numbers of the sequence files: exact integers, never raise.
   --  LEN and the header's "bits" / "nid" are small decimal naturals;
   --  VALUE is a coded field, decimal or "0x" / "0X" hex, up to 64 bits
   --  (a modular type: it wraps rather than overflows).
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

   function To_U64 (S : String; OK : out Boolean) return Unsigned_64 is
      V    : Unsigned_64 := 0;
      Hex  : constant Boolean :=
        S'Length > 2 and then S (S'First) = '0'
        and then (S (S'First + 1) = 'x' or else S (S'First + 1) = 'X');
      From : constant Positive := (if Hex then S'First + 2 else S'First);
   begin
      OK := S'Length > 0 and then S'Length <= 20 and then From <= S'Last;
      if OK then
         for C of S (From .. S'Last) loop
            case C is
               when '0' .. '9' =>
                  V := V * (if Hex then 16 else 10)
                       + Unsigned_64 (Character'Pos (C) - Character'Pos ('0'));
               when 'a' .. 'f' =>
                  if not Hex then
                     OK := False;
                     exit;
                  end if;
                  V := V * 16
                       + Unsigned_64 (Character'Pos (C)
                                      - Character'Pos ('a') + 10);
               when 'A' .. 'F' =>
                  if not Hex then
                     OK := False;
                     exit;
                  end if;
                  V := V * 16
                       + Unsigned_64 (Character'Pos (C)
                                      - Character'Pos ('A') + 10);
               when others =>
                  OK := False;
                  exit;
            end case;
         end loop;
      end if;
      return (if OK then V else 0);
   end To_U64;

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
   begin
      Len := 0;
      OK := Hex'Length mod 2 = 0 and then Hex'Length / 2 <= Data'Length
            and then Hex'Length / 2 <= Max_Payload;
      if not OK then
         return;
      end if;
      for I in 0 .. Hex'Length / 2 - 1 loop
         declare
            Hi : constant Character := Hex (Hex'First + 2 * I);
            Lo : constant Character := Hex (Hex'First + 2 * I + 1);
            Hv : constant Unsigned_8 := Nibble (Hi, OK);
            Lv : constant Unsigned_8 := Nibble (Lo, OK);
         begin
            Data (Data'First + I) := Hv * 16 + Lv;
         end;
         exit when not OK;
      end loop;
      Len := (if OK then Hex'Length / 2 else 0);
   end Hex_To_Bytes;

   ---------------------------------------------------------------------
   --  The pending telegram / message block: the "telegram" or
   --  "message" line that opened it, and the "var" rows read since
   ---------------------------------------------------------------------

   type Block_Kind_T is (None, Telegram_Block, Message_Block);
   Block      : Block_Kind_T := None;
   Block_Line : Natural := 0;

   Data     : ETCS_Bits.Byte_Array (1 .. Max_Payload) := (others => 0);
   Data_Len : Natural := 0;   -- bytes
   Bit_Len  : Natural := 0;   -- telegram user bits ("bits" of the line)

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
                  Fail (Vars (I).Line,
                        "var " & Var_Name (I) & ": our catalogue has"
                        & ETCS_Variables.Bits (Var)'Image & " bits, the"
                        & " sequence" & Len'Image);
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
         when None =>
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
                  Fail (Block_Line, "telegram decode: " & S'Image);
               else
                  Check_Packet_List (T.Count, NID'Access);
               end if;
               Check_Fields (Bit_Len);
            end;
         when Message_Block =>
            declare
               M : ETCS_Message.Message_T;
               S : ETCS_Message.Status_T;

               function NID (I : Positive) return Natural is
                 (Natural (M.Index (I).NID));
            begin
               ETCS_Message.Parse (Data (1 .. Data_Len), Track_To_Train,
                                   RBC, M, S);
               if S /= ETCS_Message.Accepted then
                  Fail (Block_Line, "message decode: " & S'Image);
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
            return;
         end if;
         Bit_Len := Count;
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
         return;
      end if;
      declare
         Count_OK, Hex_OK : Boolean;
         Count : constant Natural := To_Nat (Word (L, Idx + 1), Count_OK);
      begin
         Hex_To_Bytes (Word (L, Idx + 2), Data, Data_Len, Hex_OK);
         if not Count_OK or else not Hex_OK or else Count > 8 * Data_Len then
            Skip (Line_No, "message: bad bits/hex");
            return;
         end if;
         Block := Message_Block;
         Block_Line := Line_No;
         Var_Count := 0;
         Messages := Messages + 1;
      end;
   end Start_Message;

   procedure Add_Var (L : Line_T; Line_No : Positive) is
   begin
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
         Value          : constant Unsigned_64 :=
           To_U64 (Word (L, 4), Val_OK);
      begin
         if not Len_OK or else not Val_OK or else Name'Length = 0 then
            Skip (Line_No, "bad var line");
            return;
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
             & Messages'Image & " messages," & Failures'Image
             & " failures," & Skipped'Image & " skipped");
   if Failures > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end EVC_S076_Check;
