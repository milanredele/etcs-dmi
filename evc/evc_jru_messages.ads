--  ETCS on-board (EVC)
--  The juridical recording messages of SUBSET-027 4.2: the common
--  header of 4.2.2.2 (fields 1 to 11, each as 4.2.3.x gives it, the
--  variables "by analogy to" chapter 7 of SUBSET-026 with chapter 7's
--  lengths), the complementary variables of 4.2.4.N after it, the
--  whole bit-packed most significant bit first and rounded up to bytes
--  (4.2.2.2), signed values in two's complement (4.2.2.3). One message
--  is one payload of the JRU port (EVC_Ports).
--
--  The header, with Q_LRBG = 2, is 386 bits; with Q_LRBG 0 or 1, 311.
--  The position: this on-board has no location reference other than the
--  LRBG, so the SOLR of 4.2.3.5 is the LRBG (Q_LRBG 1) when one is
--  known, and the values "unknown" of the position report (3.6.2.2.2.1,
--  Q_LRBG 0) when none is.
--
--  The messages the on-board writes (EVC_Core, EVC_Outbox.Put_JRU):
--     1 general message (4.2.4.1), at a mode change, followed by a 255;
--     6 telegram from balise (4.2.4.6): the telegram as received;
--     9 message from RBC (4.2.4.9): NID_C, NID_RBC, the message;
--    11 driver's actions: M_DRIVERACTIONS;
--    13 radio error: NID_C, NID_RBC, M_ERROR;
--    20 speed and distance monitoring information: M_SDMTYPE,
--       M_SDMSUPSTAT, V_PERM, V_SBI, V_TARGET, D_TARGET, V_RELEASE,
--       M_TTI;
--    24 RBC contact information entered by the driver: Q_RBCENTRY, NID_C
--       and NID_RBC (Q_RBCENTRY 2 or 3), NID_RADIO (3);
--    30, 31, 32, 39, 51 the TIU inputs and the remote shunting state:
--       their one variable;
--    38 cab status: M_CAB_A_STATUS, Q_CAB_B, M_CAB_B_STATUS (Q_CAB_B 1);
--    48 GSM-R radio network ID entered by the driver: NID_MN;
--   255 proprietary juridical data (4.2.4.255): every other event of
--       the on-board (EVC_Ports), its number u8 and its three bytes.
--
--  For the readers (the bench's sink, the tests, the SUBSET-076 runner)
--  View gives back the event of EVC_Ports a message records, with the
--  three bytes the record of 16 bytes carried before this format: the
--  event numbers of the readers stay those of EVC_Ports (21 for the
--  message 20, 124 for 24, 132 for 32, 2 for 6, 3 for 9: the numbers
--  20, 24 and 32 are events of the on-board too).

with EVC_Bytes;  use EVC_Bytes;
with EVC_Ports;
with Interfaces; use Interfaces;

package EVC_JRU_Messages
  with SPARK_Mode => On
is

   --  The longest message: the header, NID_C and NID_RBC, a radio
   --  message of 1023 bytes (SUBSET-026 7.5.1.48)
   Max_Length : constant := EVC_Ports.JRU_Max_Length;
   --  The shortest: the header without the LRBG part
   Min_Header_Bits : constant := 311;
   Max_Header_Bits : constant := 386;

   NID_General        : constant := 1;
   NID_Telegram       : constant := 6;
   NID_From_RBC       : constant := 9;
   NID_Driver_Actions : constant := 11;
   NID_Radio_Error    : constant := 13;
   NID_SDM            : constant := 20;
   NID_RBC_Entry      : constant := 24;
   NID_Sleeping       : constant := 30;
   NID_Passive_SH     : constant := 31;
   NID_Non_Leading    : constant := 32;
   NID_Cab_Status     : constant := 38;
   NID_Direction      : constant := 39;
   NID_Network        : constant := 48;
   NID_Remote_SH      : constant := 51;
   NID_Proprietary    : constant := 255;

   subtype Width_T is Positive range 1 .. 64;

   subtype U2 is Natural range 0 .. 3;
   subtype U3 is Natural range 0 .. 7;
   subtype U4 is Natural range 0 .. 15;
   subtype U5 is Natural range 0 .. 31;
   subtype U6 is Natural range 0 .. 63;
   subtype U7 is Natural range 0 .. 127;
   subtype U10 is Natural range 0 .. 1023;
   subtype U15 is Natural range 0 .. 32767;
   subtype U24 is Natural range 0 .. 2**24 - 1;

   type Driver_Id_T is array (1 .. 16) of Byte;

   --  A location reference (4.2.3.5): Q_SCALE, NID_C * 2**14 + NID_BG,
   --  D, Q_DIR, Q_D, L_DOUBTOVER, L_DOUBTUNDER
   type Reference_T is record
      Q_Scale : U2 := 1;
      NID     : U24 := 16383;
      D       : U15 := 32767;
      Q_Dir   : U2 := 2;
      Q_D     : U2 := 2;
      Over    : U15 := 32767;
      Under   : U15 := 32767;
   end record;

   --  The fields 3 to 11 (4.2.3.3 to 4.2.3.11); the defaults are the
   --  values "unknown"
   type Header_T is record
      Year       : U7 := 127;
      Month      : U4 := 15;
      Day        : U5 := 0;
      Hour       : U5 := 31;
      Minutes    : U6 := 63;
      Seconds    : U6 := 63;
      TTS        : U5 := 31;
      SOLR       : Reference_T;
      Q_LRBG     : U2 := 0;
      LRBG       : Reference_T;   -- only with Q_LRBG 2
      V_Train    : U10 := 1023;
      Driver_Id  : Driver_Id_T := (others => Character'Pos ('?'));
      NID_Engine : U24 := 0;
      M_Version  : U7 := 0;
      M_Level    : U3 := 0;
      M_Mode     : U5 := 0;
   end record;

   --  The UTC date and time (4.2.3.3, 4.2.3.4) of Seconds since
   --  2000-01-01 00:00:00 UTC and Ms more milliseconds
   procedure Set_Time (H       : in out Header_T;
                       Seconds : Unsigned_32;
                       Ms      : Natural)
     with Global => null;

   --  The header's length in bits
   function Header_Bits (H : Header_T) return Natural is
     (if H.Q_LRBG = 2 then Max_Header_Bits else Min_Header_Bits)
     with Global => null;

   --  Writing: Value on Bits bits at bit Pos of Buf (0 the most
   --  significant bit of Buf'First), Pos moved past it
   procedure Put_Bits (Buf   : in out Byte_Array;
                       Pos   : in out Natural;
                       Value : Unsigned_64;
                       Bits  : Width_T)
     with Global => null,
          Pre  => Buf'Length <= 2**16
                  and then Pos <= 8 * Buf'Length
                  and then Bits <= 8 * Buf'Length - Pos,
          Post => Pos = Pos'Old + Bits;

   --  NID_MESSAGE, L_MESSAGE 0 (Patch_Length writes it), the header
   procedure Put_Header (Buf : in out Byte_Array;
                         Pos : in out Natural;
                         NID : Byte;
                         H   : Header_T)
     with Global => null,
          Pre  => Buf'Length <= 2**16
                  and then Pos <= 8 * Buf'Length
                  and then Header_Bits (H) <= 8 * Buf'Length - Pos,
          Post => Pos = Pos'Old + Header_Bits (H);

   --  L_MESSAGE (4.2.3.2, at most 2047) of the message in Buf
   procedure Put_Length (Buf : in out Byte_Array; Length : Natural)
     with Global => null,
          Pre => Buf'Length >= 3;

   --  Reading: Bits bits from bit At_Bit of P; 0 beyond its end
   function Get_Bits (P      : Byte_Array;
                      At_Bit : Natural;
                      Bits   : Width_T) return Unsigned_64
     with Global => null,
          Pre => P'Length <= 2**16;

   --  P is a message: at least a header long and L_MESSAGE its length
   function Is_Message (P : Byte_Array) return Boolean
     with Global => null,
          Pre => P'Length <= 2**16;

   function NID_Of (P : Byte_Array) return Byte is
     (if P'Length = 0 then 0 else P (P'First))
     with Global => null;

   --  The header of a message (the defaults when P is not one)
   procedure Get_Header (P : Byte_Array; H : out Header_T)
     with Global => null,
          Pre => P'Length <= 2**16;

   --  The first bit of the complementary variables of a message
   function Body_Bit (P : Byte_Array) return Natural
     with Global => null,
          Pre  => P'Length <= 2**16,
          Post => Body_Bit'Result in Min_Header_Bits | Max_Header_Bits;

   --  The event of EVC_Ports a message records and its three bytes (the
   --  heading of this package); Event 0 for message 1 and what is not a
   --  message of this on-board
   type View_T is record
      Event      : Byte := 0;
      B2, B3, B4 : Byte := 0;
   end record;
   function View (P : Byte_Array) return View_T
     with Global => null,
          Pre => P'Length <= 2**16;

   --  The complementary variables of a message: at most Max_Fields,
   --  Bits 0 an unused entry
   Max_Fields : constant := 10;
   type Field_T is record
      Value : Unsigned_64 := 0;
      Bits  : Natural range 0 .. 64 := 0;
   end record;
   type Fields_T is array (1 .. Max_Fields) of Field_T;
   No_Fields : constant Fields_T := (others => (Value => 0, Bits => 0));

   --  The message of an event of EVC_Ports given by its three bytes:
   --  11, 30, 31, 39, 51, 132 (as 32), 38 and 48 as the heading gives
   --  them, every other event as the message 255
   procedure Event_Message (Event      : Byte;
                            B2, B3, B4 : Byte;
                            NID        : out Byte;
                            Fields     : out Fields_T)
     with Global => null;

end EVC_JRU_Messages;
