--  ETCS DMI
--  Protocol definition for EVC-DMI communication
--  This file provides a structured, bit-packed representation
--  of the DMI state as received from the EVC.

with Interfaces; use Interfaces;

package DMI_Protocol is

   -- For stateless communication, EVC sends whole state to DMI
   
   type Bit_T is mod 2 ** 1 with Size => 1;
   type Two_Bits_T is mod 2 ** 2 with Size => 2;
   type Four_Bits_T is mod 2 ** 4 with Size => 4;

   -- Bit-packed fields representing various DMI status bits
   type DMI_Status_T is record
      Flash_Enable    : Bit_T; -- EVC commands DMI to flash elements
      Vrelease_Exists : Bit_T;
      Show_TAF        : Bit_T;
      Mode            : Four_Bits_T; -- SDI.Mode_T mapping
      Speed_Range     : Two_Bits_T; -- Speed_And_Distance.Speed_Dial_Range_T
      Spare           : Bit_T; -- Just a bit for now
   end record with Pack, Size => 16;
   
   type DMI_Telegram_T is record
      V_Cur    : Unsigned_16; -- current speed (km/h) (2)
      V_Perm   : Unsigned_16; -- permitted speed (km/h) (2)
      V_Targ   : Unsigned_16; -- target speed (km/h) (2)
      V_Rel    : Unsigned_16; -- release speed (km/h) (2)
      D_Targ   : Unsigned_32; -- distance to target (m) (4)
      Status   : DMI_Status_T; -- Bitfield for enums and flags (2)
      Checksum : Unsigned_16; -- CRC-16 (XMODEM/CCITT) (2)
   end record;

   for DMI_Telegram_T use record
      V_Cur    at 0 range 0 .. 15;
      V_Perm   at 2 range 0 .. 15;
      V_Targ   at 4 range 0 .. 15;
      V_Rel    at 6 range 0 .. 15;
      D_Targ   at 8 range 0 .. 31;
      Status   at 12 range 0 .. 15;
      Checksum at 14 range 0 .. 15;
   end record;

   pragma Pack (DMI_Telegram_T);

end DMI_Protocol;
