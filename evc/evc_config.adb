--  ETCS on-board (EVC)
--  The installation configuration of the on-board, implementation.

package body EVC_Config
  with SPARK_Mode => On,
       Refined_State => (State => (Cfg, Is_Loaded, Refused, Pending,
                                   Last))
is

   --  The configuration in use is always valid
   subtype Valid_Config_T is Config_T
     with Dynamic_Predicate => Valid (Valid_Config_T);

   Cfg       : Valid_Config_T := Default;
   Is_Loaded : Boolean := False;
   Refused   : Natural := 0;
   Pending   : Boolean := False;
   Last      : Status_T := Accepted;

   function Current return Config_T is (Cfg)
     with Refined_Global => Cfg;
   function Current_Radio return Radio_Config_T is (Cfg.Radio)
     with Refined_Global => Cfg;
   function Loaded return Boolean is (Is_Loaded)
     with Refined_Global => Is_Loaded;
   function Rejections return Natural is (Refused)
     with Refined_Global => Refused;
   function Report_Pending return Boolean is (Pending)
     with Refined_Global => Pending;
   function Last_Status return Status_T is (Last)
     with Refined_Global => Last;

   ---------------------------------------------------------------------
   --  The image
   ---------------------------------------------------------------------

   Magic : constant Byte_Array (1 .. 4) :=
     (16#45#, 16#56#, 16#43#, 16#46#);   -- "EVCF"

   function CRC_32 (Data : Byte_Array) return Unsigned_32 is
      C : Unsigned_32 := 16#FFFF_FFFF#;
   begin
      for I in Data'Range loop
         C := C xor Unsigned_32 (Data (I));
         for K in 1 .. 8 loop
            --  not unrolled by the proof, nothing needed after the loop
            pragma Loop_Invariant (True);
            if (C and 1) = 1 then
               C := Shift_Right (C, 1) xor 16#EDB8_8320#;
            else
               C := Shift_Right (C, 1);
            end if;
         end loop;
      end loop;
      return C xor 16#FFFF_FFFF#;
   end CRC_32;

   --  The interface codes of the image
   function Interface_Code (I : Special_Brake_Interface_T) return Byte is
     (Byte (Special_Brake_Interface_T'Pos (I)));

   function Decoded (Bytes : Byte_Array) return Decoded_T is
      R : Decoded_T := (Status => Truncated, Config => Default);
      C : Config_T;

      --  the byte at Offset of the image
      function At_Offset (Offset : Natural) return Byte is
        (Bytes (Bytes'First + Offset))
        with Pre => Bytes'Length >= Image_Length
                    and then Offset < Image_Length;

      function U16 (Offset : Natural) return Unsigned_16 is
        (Get_U16 (Bytes, Bytes'First + Offset))
        with Pre => Bytes'Length >= Image_Length
                    and then Offset < Image_Length - 1;

      function U32 (Offset : Natural) return Unsigned_32 is
        (Get_U32 (Bytes, Bytes'First + Offset))
        with Pre => Bytes'Length >= Image_Length
                    and then Offset < Image_Length - 3;

      --  a flag: 0 or 1
      function Flag_OK (Offset : Natural) return Boolean is
        (At_Offset (Offset) <= 1)
        with Pre => Bytes'Length >= Image_Length
                    and then Offset < Image_Length;

      function Flag (Offset : Natural) return Boolean is
        (At_Offset (Offset) = 1)
        with Pre => Bytes'Length >= Image_Length
                    and then Offset < Image_Length;

      function Interface_Of (Offset : Natural)
        return Special_Brake_Interface_T
      is (Special_Brake_Interface_T'Val (At_Offset (Offset)))
        with Pre => Bytes'Length >= Image_Length
                    and then Offset < Image_Length
                    and then At_Offset (Offset) <= 3;
   begin
      --  the header: magic, version, length (8 bytes)
      if Bytes'Length < 8 then
         return R;
      end if;
      if Bytes (Bytes'First .. Bytes'First + 3) /= Magic then
         R.Status := Bad_Magic;
         return R;
      end if;
      if Get_U16 (Bytes, Bytes'First + 4) /= Format_Version then
         R.Status := Bad_Version;
         return R;
      end if;
      if Get_U16 (Bytes, Bytes'First + 6) /= Image_Length then
         R.Status := Bad_Length;
         return R;
      end if;
      if Bytes'Length < Image_Length then
         return R;
      end if;
      if CRC_32 (Bytes (Bytes'First .. Bytes'First + CRC_Offset - 1))
           /= U32 (CRC_Offset)
      then
         R.Status := Bad_CRC;
         return R;
      end if;

      --  the fields
      if not (Flag_OK (8) and then Flag_OK (9) and then Flag_OK (10)
              and then Flag_OK (11) and then Flag_OK (18)
              and then Flag_OK (19)
              and then U16 (12) in 1_000 .. 5_000
              and then At_Offset (14) <= 3 and then At_Offset (15) <= 3
              and then At_Offset (16) <= 3 and then At_Offset (17) <= 3
              and then U32 (20) <= Unsigned_32 (Antenna_Offset_T'Last)
              and then U32 (24) <= Unsigned_32 (Antenna_Offset_T'Last)
              and then U16 (28) <= 60_000
              and then U16 (30) <= 3_000)
      then
         R.Status := Bad_Field;
         return R;
      end if;
      C.Supervision :=
        (Service_Brake_Command       => Flag (8),
         Service_Brake_Feedback      => Flag (9),
         Feedback_From_Cylinder      => Flag (10),
         Traction_Cut_Off            => Flag (11),
         K1_Milli                    => Positive (U16 (12)),
         Special_Brakes              =>
           (Regenerative      => Interface_Of (14),
            Eddy_Current      => Interface_Of (15),
            Magnetic_Shoe     => Interface_Of (16),
            Electro_Pneumatic => Interface_Of (17)),
         Additional_Brake_Allowed    => Flag (18),
         Regenerative_Needs_Catenary => Flag (19),
         SB_Failure_Time_Ms          => Natural (U16 (28)),
         SB_Failure_Decel_Mms2       => Natural (U16 (30)));
      C.Antenna_To_Cab_A := Antenna_Offset_T (U32 (20));
      C.Antenna_To_Cab_B := Antenna_Offset_T (U32 (24));

      --  3.13.2.2.6.1 Table 3
      if not Valid (C) then
         R.Status := Table_3_Violated;
         return R;
      end if;
      return (Status => Accepted, Config => C);
   end Decoded;

   procedure Decode (Bytes  : Byte_Array;
                     Config : out Config_T;
                     OK     : out Boolean)
   is
      R : constant Decoded_T := Decoded (Bytes);
   begin
      Config := R.Config;
      OK := R.Status = Accepted;
   end Decode;

   function Encode (C : Config_T) return Image_T is
      Image : Image_T := (others => 0);

      procedure Put_U16 (Offset : Natural; V : Unsigned_16)
        with Pre => Offset < Image_Length - 1
      is
      begin
         Image (Offset + 1) := Byte_Of (Unsigned_64 (V), 0);
         Image (Offset + 2) := Byte_Of (Unsigned_64 (V), 1);
      end Put_U16;

      procedure Put_U32 (Offset : Natural; V : Unsigned_32)
        with Pre => Offset < Image_Length - 3
      is
      begin
         for N in 0 .. 3 loop
            --  not unrolled by the proof, nothing needed after the loop
            pragma Loop_Invariant (True);
            Image (Offset + 1 + N) := Byte_Of (Unsigned_64 (V), N);
         end loop;
      end Put_U32;

      function Flag (B : Boolean) return Byte is (if B then 1 else 0);

      S : Onboard_Config_T renames C.Supervision;
   begin
      Image (1 .. 4) := Magic;
      Put_U16 (4, Format_Version);
      Put_U16 (6, Image_Length);
      Image (9) := Flag (S.Service_Brake_Command);
      Image (10) := Flag (S.Service_Brake_Feedback);
      Image (11) := Flag (S.Feedback_From_Cylinder);
      Image (12) := Flag (S.Traction_Cut_Off);
      Put_U16 (12, Unsigned_16 (S.K1_Milli));
      Image (15) := Interface_Code (S.Special_Brakes (Regenerative));
      Image (16) := Interface_Code (S.Special_Brakes (Eddy_Current));
      Image (17) := Interface_Code (S.Special_Brakes (Magnetic_Shoe));
      Image (18) := Interface_Code (S.Special_Brakes (Electro_Pneumatic));
      Image (19) := Flag (S.Additional_Brake_Allowed);
      Image (20) := Flag (S.Regenerative_Needs_Catenary);
      Put_U32 (20, Unsigned_32 (C.Antenna_To_Cab_A));
      Put_U32 (24, Unsigned_32 (C.Antenna_To_Cab_B));
      Put_U16 (28, Unsigned_16 (S.SB_Failure_Time_Ms));
      Put_U16 (30, Unsigned_16 (S.SB_Failure_Decel_Mms2));
      Put_U32 (CRC_Offset, CRC_32 (Image (1 .. CRC_Offset)));
      return Image;
   end Encode;

   ---------------------------------------------------------------------
   --  The configuration in use
   ---------------------------------------------------------------------

   procedure Count_Refusal
     with Global => (In_Out => Refused)
   is
   begin
      if Refused < Natural'Last then
         Refused := Refused + 1;
      end if;
   end Count_Refusal;

   procedure Load (Bytes : Byte_Array) is
      R : constant Decoded_T := Decoded (Bytes);
   begin
      if R.Status = Accepted then
         Cfg := R.Config;
         Is_Loaded := True;
      else
         Count_Refusal;
      end if;
      Pending := True;
      Last := R.Status;
   end Load;

   procedure Refuse (Why : Status_T) is
   begin
      Count_Refusal;
      Pending := True;
      Last := Why;
   end Refuse;

   procedure Set_Radio_For_Test (R : Radio_Config_T) is
   begin
      Cfg.Radio := R;
   end Set_Radio_For_Test;

   procedure Report_Taken is
   begin
      Pending := False;
   end Report_Taken;

end EVC_Config;
