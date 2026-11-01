--  ETCS on-board (EVC)
--  The installation configuration of the on-board, implementation.

package body EVC_Config
  with SPARK_Mode => On,
       Refined_State => (State => (Cfg, Is_Loaded, Refused, Pending,
                                   Last, Gam))
is

   --  The configuration in use is always valid
   subtype Valid_Config_T is Config_T
     with Dynamic_Predicate => Valid (Valid_Config_T);

   Cfg       : Valid_Config_T := Default;
   Is_Loaded : Boolean := False;
   Refused   : Natural := 0;
   Pending   : Boolean := False;
   Last      : Status_T := Accepted;
   --  the gamma train of the image loaded (No_Gamma for a lambda train)
   Gam       : Gamma_T := No_Gamma;

   function Current return Config_T is (Cfg)
     with Refined_Global => Cfg;
   function Current_Radio return Radio_Config_T is (Cfg.Radio)
     with Refined_Global => Cfg;
   function Current_Zones return Zone_Table_T is (Cfg.Zones)
     with Refined_Global => Cfg;
   function Loaded return Boolean is (Is_Loaded)
     with Refined_Global => Is_Loaded;
   function Rejections return Natural is (Refused)
     with Refined_Global => Refused;
   function Report_Pending return Boolean is (Pending)
     with Refined_Global => Pending;
   function Last_Status return Status_T is (Last)
     with Refined_Global => Last;

   --  The image

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

   --  The decoder of the train of format version 2: Pos the offset of
   --  the next field, Last the offset of the CRC; S stays Accepted while
   --  every field read lies before the CRC and inside its range.
   subtype Field_Status_T is Status_T
     with Static_Predicate => Field_Status_T in Accepted | Bad_Length
                                                | Bad_Field;

   --  The field of Size bytes (1 or 2) at Pos, of range 0 .. Max, into V
   --  (0 once S is not Accepted)
   procedure Get (Bytes : Byte_Array;
                  Pos   : in out Natural;
                  Last  : Natural;
                  Size  : Positive;
                  Max   : Natural;
                  V     : out Natural;
                  S     : in out Field_Status_T)
     with Global => null,
          Pre  => Last <= Bytes'Length and then Pos <= Last
                  and then Size <= 2,
          Post => Pos in Pos'Old .. Last and then V <= Max
   is
   begin
      V := 0;
      if S /= Accepted then
         return;
      elsif Last - Pos < Size then
         S := Bad_Length;
         return;
      end if;
      V := (if Size = 1 then Natural (Bytes (Bytes'First + Pos))
            else Natural (Get_U16 (Bytes, Bytes'First + Pos)));
      Pos := Pos + Size;
      if V > Max then
         S := Bad_Field;
         V := 0;
      end if;
   end Get;

   --  A curve at Pos (a count byte, then the steps of speed and
   --  deceleration, the speeds strictly rising), of Min_Count to
   --  Max_Curve_Steps steps, into C
   --  @req 3.13.2.2.3.1.1, 3.13.2.2.3.1.2, 3.13.2.2.3.1.4
   procedure Get_Curve (Bytes     : Byte_Array;
                        Pos       : in out Natural;
                        Last      : Natural;
                        Min_Count : Natural;
                        C         : out Decel_Curve_T;
                        S         : in out Field_Status_T)
     with Global => null,
          Pre  => Last <= Bytes'Length and then Pos <= Last,
          Post => Pos in Pos'Old .. Last
   is
      Start        : constant Natural := Pos;
      N, Speed, De : Natural;
   begin
      C := No_Decel_Curve;
      Get (Bytes, Pos, Last, 1, Max_Curve_Steps, N, S);
      if S = Accepted and then N < Min_Count then
         S := Bad_Field;
      end if;
      for K in 1 .. N loop
         pragma Loop_Invariant (Pos in Start .. Last);
         Get (Bytes, Pos, Last, 2, Speed_Cms_T'Last, Speed, S);
         Get (Bytes, Pos, Last, 2, Decel_Mms2_T'Last, De, S);
         if S = Accepted and then K > 1
           and then Speed <= C.Steps (K - 1).Speed
         then
            S := Bad_Field;
         end if;
         C.Steps (K) := (Speed => Speed, Decel => De);
      end loop;
      C.Count := (if S = Accepted then N else 0);
   end Get_Curve;

   --  Kdry_rst by M_NVEBCL, then Kwet_rst, 8 factors each, into X
   --  @req 3.13.2.2.9.1.1, 3.13.2.2.9.1.3, 3.13.2.2.9.1.5
   procedure Get_Factors (Bytes : Byte_Array;
                          Pos   : in out Natural;
                          Last  : Natural;
                          X     : in out Train_Data_Extra_T;
                          S     : in out Field_Status_T)
     with Global => null,
          Pre  => Last <= Bytes'Length and then Pos <= Last,
          Post => Pos in Pos'Old .. Last
   is
      Start : constant Natural := Pos;
      V     : Natural;
   begin
      for EBCL in 0 .. 9 loop
         pragma Loop_Invariant (Pos in Start .. Last);
         for K in 1 .. Max_Curve_Steps loop
            pragma Loop_Invariant (Pos in Start .. Last);
            Get (Bytes, Pos, Last, 2, Factor_Milli_T'Last, V, S);
            X.Kdry_Rst (EBCL) (K) := V;
         end loop;
      end loop;
      for K in 1 .. Max_Curve_Steps loop
         pragma Loop_Invariant (Pos in Start .. Last);
         Get (Bytes, Pos, Last, 2, Factor_Milli_T'Last, V, S);
         X.Kwet_Rst (K) := V;
      end loop;
   end Get_Factors;

   --  The two sets of three normal service models with their pivots, if
   --  given, into X
   --  @req 3.13.2.2.3.1.9, 3.13.2.2.3.1.10
   procedure Get_Normal_Service (Bytes : Byte_Array;
                                 Pos   : in out Natural;
                                 Last  : Natural;
                                 X     : in out Train_Data_Extra_T;
                                 S     : in out Field_Status_T)
     with Global => null,
          Pre  => Last <= Bytes'Length and then Pos <= Last,
          Post => Pos in Pos'Old .. Last
   is
      Start    : constant Natural := Pos;
      Given, V : Natural;
   begin
      Get (Bytes, Pos, Last, 1, 1, Given, S);
      if Given = 1 then
         Get (Bytes, Pos, Last, 2, Decel_Mms2_T'Last, V, S);
         X.A_SB01 := V;
         Get (Bytes, Pos, Last, 2, Decel_Mms2_T'Last, V, S);
         X.A_SB12 := V;
         for N in 0 .. 2 loop
            pragma Loop_Invariant (Pos in Start .. Last);
            Get_Curve (Bytes, Pos, Last, 0, X.Normal_Service_G (N), S);
         end loop;
         for N in 0 .. 2 loop
            pragma Loop_Invariant (Pos in Start .. Last);
            Get_Curve (Bytes, Pos, Last, 0, X.Normal_Service_P (N), S);
         end loop;
      end if;
   end Get_Normal_Service;

   --  The models and brake times by combination of the special brakes in
   --  use, if given, into X
   --  @req 3.13.2.2.3.1.7, 3.13.2.2.3.2.8
   procedure Get_Combinations (Bytes : Byte_Array;
                               Pos   : in out Natural;
                               Last  : Natural;
                               X     : in out Train_Data_Extra_T;
                               S     : in out Field_Status_T)
     with Global => null,
          Pre  => Last <= Bytes'Length and then Pos <= Last,
          Post => Pos in Pos'Old .. Last
   is
      Start  : constant Natural := Pos;
      By     : Natural;
      R, B   : Natural;
   begin
      Get (Bytes, Pos, Last, 1, 1, By, S);
      X.By_Combination := By = 1;
      if By /= 1 then
         return;
      end if;
      for C in Brake_Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Last);
         Get_Curve (Bytes, Pos, Last, 1, X.A_Emergency_Combination (C), S);
      end loop;
      for C in Brake_Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Last);
         Get_Curve (Bytes, Pos, Last, 1, X.A_Service_Combination (C), S);
      end loop;
      for C in Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Last);
         Get (Bytes, Pos, Last, 2, 60_000, R, S);
         Get (Bytes, Pos, Last, 2, 60_000, B, S);
         X.T_Emergency_Combination (C) := (React => R, Build_Up => B);
      end loop;
      for C in Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Last);
         Get (Bytes, Pos, Last, 2, 60_000, R, S);
         Get (Bytes, Pos, Last, 2, 60_000, B, S);
         X.T_Service_Combination (C) := (React => R, Build_Up => B);
      end loop;
   end Get_Combinations;

   --  The gamma train of an image of format version 2 whose CRC is at
   --  Last into G, and the status of its fields
   --  @req 3.13.2.2.3.2.2, 3.13.2.2.3.2.5, 3.13.2.2.9.2.1
   --  @req 3.13.2.2.10.1, 3.18.3.2 c), 3.18.3.2 c) 4th bullet
   --  @req 3.18.3.2 c) 5th bullet
   procedure Get_Gamma (Bytes : Byte_Array;
                        Last  : Natural;
                        G     : out Gamma_T;
                        S     : out Field_Status_T)
     with Global => null,
          Pre  => Last <= Bytes'Length and then Last >= 34
   is
      Pos : Natural := 34;
      V   : Natural;
   begin
      G := No_Gamma;
      S := Accepted;
      Get (Bytes, Pos, Last, 2, 60_000, V, S);
      G.Extra.T_Brake_Emergency_React := V;
      Get (Bytes, Pos, Last, 2, 60_000, V, S);
      G.T_Brake_Emergency := V;
      Get (Bytes, Pos, Last, 2, 60_000, V, S);
      G.Extra.T_Brake_Service_React := V;
      Get (Bytes, Pos, Last, 2, 60_000, V, S);
      G.T_Brake_Service := V;
      Get_Curve (Bytes, Pos, Last, 1, G.A_Brake_Emergency, S);
      Get_Curve (Bytes, Pos, Last, 1, G.A_Brake_Service, S);
      Get_Curve (Bytes, Pos, Last, 0, G.A_Brake_Normal, S);
      Get_Factors (Bytes, Pos, Last, G.Extra, S);
      Get_Curve (Bytes, Pos, Last, 0, G.Extra.Kn_Plus, S);
      Get_Curve (Bytes, Pos, Last, 0, G.Extra.Kn_Minus, S);
      Get (Bytes, Pos, Last, 1, 100, V, S);
      G.Extra.M_Rotating_Nom := V;
      Get_Normal_Service (Bytes, Pos, Last, G.Extra, S);
      Get_Combinations (Bytes, Pos, Last, G.Extra, S);
      if S = Accepted and then Pos /= Last then
         S := Bad_Length;
      end if;
   end Get_Gamma;

   --  The status of the gamma train of an image of format version 2
   --  whose CRC is at Last
   function Gamma_Status (Bytes : Byte_Array; Last : Natural)
     return Field_Status_T
     with Pre => Last <= Bytes'Length and then Last >= 34
   is
      G : Gamma_T;
      S : Field_Status_T;
   begin
      Get_Gamma (Bytes, Last, G, S);
      --  (Get_Gamma refuses an emergency model without a step already)
      return (if S = Accepted and then G.A_Brake_Emergency.Count = 0
              then Bad_Field else S);
   end Gamma_Status;

   --  The length L is that of an image of the format Version
   function Length_OK (Version, L : Natural) return Boolean is
     (if Version = 1 then L = Image_Length
      elsif Version = 2 then L in Min_Image_V2_Length .. Max_Image_V2_Length
      else L in Min_Image_V3_Length .. Max_Image_Length);

   --  The zones of an image of format version 3 at Offset: the count,
   --  then Zone_Max entries of a u16 first NID_C, a u16 last NID_C, a
   --  u16 standard offset + 720 minutes and a u8 summer-time rule (0
   --  none, 1 EU); the entries after the count are not read
   procedure Get_Zones (Bytes  : Byte_Array;
                        Offset : Natural;
                        Z      : out Zone_Table_T;
                        S      : out Field_Status_T)
     with Global => null,
          Pre  => Bytes'Length >= Zone_Image_Length
                  and then Offset <= Bytes'Length - Zone_Image_Length,
          Post => (if S = Accepted
                   then (for all I in 1 .. Z.Count =>
                           Z.Zones (I).First <= Z.Zones (I).Last))
   is
      N : constant Byte := Bytes (Bytes'First + Offset);
   begin
      Z := No_Zones;
      S := Accepted;
      if N > Zone_Max then
         S := Bad_Field;
         return;
      end if;
      for I in 1 .. Natural (N) loop
         declare
            P    : constant Positive := Bytes'First + Offset + 1 + 7 * (I - 1);
            Lo   : constant Unsigned_16 := Get_U16 (Bytes, P);
            Hi   : constant Unsigned_16 := Get_U16 (Bytes, P + 2);
            Off  : constant Unsigned_16 := Get_U16 (Bytes, P + 4);
            Rule : constant Byte := Bytes (P + 6);
         begin
            if Hi > 1_023 or else Lo > Hi or else Off > 1_560
              or else Rule > 1
            then
               Z := No_Zones;
               S := Bad_Field;
               return;
            end if;
            Z.Zones (I) :=
              (First      => NID_C_T (Lo),
               Last       => NID_C_T (Hi),
               Offset_Min => Integer (Off) - 720,
               Summer     => (if Rule = 1 then EU_Summer else No_Summer));
            Z.Count := I;
         end;
         pragma Loop_Invariant
           (Z.Count = I
            and then (for all J in 1 .. I =>
                        Z.Zones (J).First <= Z.Zones (J).Last));
      end loop;
   end Get_Zones;

   --  The train of an image of format version 2 of length L into T: the
   --  model, the special brakes, the gamma train (its status) or the CRC
   procedure Get_Train (Bytes : Byte_Array;
                        L     : Natural;
                        T     : in out Fixed_Train_T;
                        S     : out Field_Status_T)
     with Global => null,
          Pre  => L in Min_Image_V2_Length .. Bytes'Length
   is
      Model    : constant Byte := Bytes (Bytes'First + 32);
      Brakes   : constant Byte := Bytes (Bytes'First + 33);
   begin
      if Model > 1 or else Brakes > 15 then
         S := Bad_Field;
         return;
      end if;
      T.Model := (if Model = 1 then Gamma else Lambda);
      T.Has_Regenerative := (Brakes and 1) /= 0;
      T.Has_Eddy_Current := (Brakes and 2) /= 0;
      T.Has_Magnetic_Shoe := (Brakes and 4) /= 0;
      T.Has_Electro_Pneumatic := (Brakes and 8) /= 0;
      S := (if T.Model = Gamma then Gamma_Status (Bytes, L - 4)
            elsif L /= Min_Image_V2_Length then Bad_Length
            else Accepted);
   end Get_Train;

   --  The train of an image of format version 2 or 3 of length L, and
   --  the zones of version 3 between the train and the CRC
   procedure Get_Tail (Bytes   : Byte_Array;
                       Version : Natural;
                       L       : Natural;
                       T       : in out Fixed_Train_T;
                       Z       : out Zone_Table_T;
                       S       : out Field_Status_T)
     with Global => null,
          Pre  => Version in 2 .. 3 and then L <= Bytes'Length
                  and then Length_OK (Version, L),
          Post => (if S = Accepted
                   then (for all I in 1 .. Z.Count =>
                           Z.Zones (I).First <= Z.Zones (I).Last))
   is
   begin
      Z := No_Zones;
      if Version = 2 then
         Get_Train (Bytes, L, T, S);
      else
         Get_Train (Bytes, L - Zone_Image_Length, T, S);
         if S = Accepted then
            Get_Zones (Bytes, L - 4 - Zone_Image_Length, Z, S);
         end if;
      end if;
   end Get_Tail;

   function Decoded (Bytes : Byte_Array) return Decoded_T is
      R : Decoded_T := (Status => Truncated, Config => Default);
      C : Config_T;
      --  the format version and the length of the header
      Version, L : Natural;

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
      Version := Natural (Get_U16 (Bytes, Bytes'First + 4));
      L := Natural (Get_U16 (Bytes, Bytes'First + 6));
      if Version not in 1 .. Format_Version then
         R.Status := Bad_Version;
         return R;
      end if;
      if not Length_OK (Version, L) then
         R.Status := Bad_Length;
         return R;
      end if;
      if Bytes'Length < L then
         return R;
      end if;
      if CRC_32 (Bytes (Bytes'First .. Bytes'First + (L - 5)))
           /= Get_U32 (Bytes, Bytes'First + (L - 4))
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

      --  the train of version 2: the model, the special brakes, the gamma
      --  train or the CRC
      if Version >= 2 then
         Get_Tail (Bytes, Version, L, C.Train, C.Zones, R.Status);
         if R.Status /= Accepted then
            return R;
         end if;
      end if;

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
      --  the format version 1
      Put_U16 (4, 1);
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

   --  The encoder of the train of format version 2: Pos the offset of the
   --  next field; a field that would reach the CRC's 4 bytes at the end
   --  of the longest image is left out (never with the counts of the
   --  types: the longest image is their sum)

   --  V (clamped to Size bytes) at Pos
   procedure Put (Image : in out Max_Image_T;
                  Pos   : in out Natural;
                  Size  : Positive;
                  V     : Natural)
     with Global => null,
          Pre  => Size <= 2 and then Pos <= Max_Image_V2_Length - 4,
          Post => Pos in Pos'Old .. Max_Image_V2_Length - 4
   is
      W : constant Unsigned_64 :=
        Unsigned_64 (Natural'Min (V, (if Size = 1 then 255 else 65_535)));
   begin
      if Pos + Size > Max_Image_V2_Length - 4 then
         return;
      end if;
      Image (Pos + 1) := Byte_Of (W, 0);
      if Size = 2 then
         Image (Pos + 2) := Byte_Of (W, 1);
      end if;
      Pos := Pos + Size;
   end Put;

   --  The curve C at Pos
   procedure Put_Curve (Image : in out Max_Image_T;
                        Pos   : in out Natural;
                        C     : Decel_Curve_T)
     with Global => null,
          Pre  => Pos <= Max_Image_V2_Length - 4,
          Post => Pos in Pos'Old .. Max_Image_V2_Length - 4
   is
      Start : constant Natural := Pos;
   begin
      Put (Image, Pos, 1, C.Count);
      for K in 1 .. C.Count loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         Put (Image, Pos, 2, C.Steps (K).Speed);
         Put (Image, Pos, 2, C.Steps (K).Decel);
      end loop;
   end Put_Curve;

   --  The models and brake times by combination of X at Pos
   procedure Put_Combinations (Image : in out Max_Image_T;
                               Pos   : in out Natural;
                               X     : Train_Data_Extra_T)
     with Global => null,
          Pre  => Pos <= Max_Image_V2_Length - 4,
          Post => Pos in Pos'Old .. Max_Image_V2_Length - 4
   is
      Start : constant Natural := Pos;
   begin
      for C in Brake_Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         Put_Curve (Image, Pos, X.A_Emergency_Combination (C));
      end loop;
      for C in Brake_Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         Put_Curve (Image, Pos, X.A_Service_Combination (C));
      end loop;
      for C in Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         Put (Image, Pos, 2, X.T_Emergency_Combination (C).React);
         Put (Image, Pos, 2, X.T_Emergency_Combination (C).Build_Up);
      end loop;
      for C in Combination_T loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         Put (Image, Pos, 2, X.T_Service_Combination (C).React);
         Put (Image, Pos, 2, X.T_Service_Combination (C).Build_Up);
      end loop;
   end Put_Combinations;

   --  The rest of the gamma train G after its models at Pos: the
   --  factors, Kn, the rotating mass, the normal service sets (given
   --  when one of their curves has a step), the combinations
   procedure Put_Extra (Image : in out Max_Image_T;
                        Pos   : in out Natural;
                        X     : Train_Data_Extra_T)
     with Global => null,
          Pre  => Pos <= Max_Image_V2_Length - 4,
          Post => Pos in Pos'Old .. Max_Image_V2_Length - 4
   is
      Start : constant Natural := Pos;
      Sets  : constant Boolean :=
        (for some N in 0 .. 2 =>
           X.Normal_Service_G (N).Count > 0
           or else X.Normal_Service_P (N).Count > 0);
   begin
      for EBCL in 0 .. 9 loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         for K in 1 .. Max_Curve_Steps loop
            pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
            Put (Image, Pos, 2, X.Kdry_Rst (EBCL) (K));
         end loop;
      end loop;
      for K in 1 .. Max_Curve_Steps loop
         pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
         Put (Image, Pos, 2, X.Kwet_Rst (K));
      end loop;
      Put_Curve (Image, Pos, X.Kn_Plus);
      Put_Curve (Image, Pos, X.Kn_Minus);
      Put (Image, Pos, 1, X.M_Rotating_Nom);
      Put (Image, Pos, 1, (if Sets then 1 else 0));
      if Sets then
         Put (Image, Pos, 2, X.A_SB01);
         Put (Image, Pos, 2, X.A_SB12);
         for N in 0 .. 2 loop
            pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
            Put_Curve (Image, Pos, X.Normal_Service_G (N));
         end loop;
         for N in 0 .. 2 loop
            pragma Loop_Invariant (Pos in Start .. Max_Image_V2_Length - 4);
            Put_Curve (Image, Pos, X.Normal_Service_P (N));
         end loop;
      end if;
      Put (Image, Pos, 1, (if X.By_Combination then 1 else 0));
      if X.By_Combination then
         Put_Combinations (Image, Pos, X);
      end if;
   end Put_Extra;

   procedure Encode_V2 (C      : Config_T;
                        G      : Gamma_T;
                        Image  : out Max_Image_T;
                        Length : out Natural)
   is
      V1  : constant Image_T := Encode (C);
      T   : Fixed_Train_T renames C.Train;
      Pos : Natural := 34;
      CRC : Unsigned_32;
   begin
      Image := (others => 0);
      Image (1 .. CRC_Offset) := V1 (1 .. CRC_Offset);
      Image (5) := 2;
      Image (33) := (if T.Model = Gamma then 1 else 0);
      Image (34) := Byte ((if T.Has_Regenerative then 1 else 0)
                          + (if T.Has_Eddy_Current then 2 else 0)
                          + (if T.Has_Magnetic_Shoe then 4 else 0)
                          + (if T.Has_Electro_Pneumatic then 8 else 0));
      if T.Model = Gamma then
         Put (Image, Pos, 2, G.Extra.T_Brake_Emergency_React);
         Put (Image, Pos, 2, G.T_Brake_Emergency);
         Put (Image, Pos, 2, G.Extra.T_Brake_Service_React);
         Put (Image, Pos, 2, G.T_Brake_Service);
         Put_Curve (Image, Pos, G.A_Brake_Emergency);
         Put_Curve (Image, Pos, G.A_Brake_Service);
         Put_Curve (Image, Pos, G.A_Brake_Normal);
         Put_Extra (Image, Pos, G.Extra);
      end if;
      Length := Pos + 4;
      Image (7) := Byte_Of (Unsigned_64 (Length), 0);
      Image (8) := Byte_Of (Unsigned_64 (Length), 1);
      CRC := CRC_32 (Image (1 .. Pos));
      for N in 0 .. 3 loop
         pragma Loop_Invariant (True);
         Image (Pos + 1 + N) := Byte_Of (Unsigned_64 (CRC), N);
      end loop;
   end Encode_V2;

   procedure Encode_V3 (C      : Config_T;
                        G      : Gamma_T;
                        Image  : out Max_Image_T;
                        Length : out Natural)
   is
      Pos : Natural;
      CRC : Unsigned_32;
   begin
      Encode_V2 (C, G, Image, Length);
      --  the zones in place of the CRC of version 2
      Pos := Length - 4;
      Image (5) := 3;
      Image (Pos + 1 .. Pos + Zone_Image_Length) := (others => 0);
      Image (Pos + 1) := Byte (C.Zones.Count);
      for I in 1 .. C.Zones.Count loop
         pragma Loop_Invariant (True);
         declare
            Z : Zone_T renames C.Zones.Zones (I);
            P : constant Natural := Pos + 1 + 7 * (I - 1);
            O : constant Unsigned_64 := Unsigned_64 (Z.Offset_Min + 720);
         begin
            Image (P + 1) := Byte_Of (Unsigned_64 (Z.First), 0);
            Image (P + 2) := Byte_Of (Unsigned_64 (Z.First), 1);
            Image (P + 3) := Byte_Of (Unsigned_64 (Z.Last), 0);
            Image (P + 4) := Byte_Of (Unsigned_64 (Z.Last), 1);
            Image (P + 5) := Byte_Of (O, 0);
            Image (P + 6) := Byte_Of (O, 1);
            Image (P + 7) := (if Z.Summer = EU_Summer then 1 else 0);
         end;
      end loop;
      Pos := Pos + Zone_Image_Length;
      Length := Pos + 4;
      Image (7) := Byte_Of (Unsigned_64 (Length), 0);
      Image (8) := Byte_Of (Unsigned_64 (Length), 1);
      CRC := CRC_32 (Image (1 .. Pos));
      for N in 0 .. 3 loop
         pragma Loop_Invariant (True);
         Image (Pos + 1 + N) := Byte_Of (Unsigned_64 (CRC), N);
      end loop;
   end Encode_V3;

   --  The years of the clock: the seconds since 2000 of an Unsigned_32
   --  end in 2136
   subtype Year_T is Natural range 2000 .. 2137;

   --  The days from 2000-01-01 to the first of January of Y: the leap
   --  years from 2000 to Y - 1 (every fourth, not a hundredth, a
   --  four hundredth)
   function Days_Before_Year (Y : Year_T) return Natural is
     (365 * (Y - 2000) + (Y - 2000 + 3) / 4 - (Y - 2000 + 99) / 100
      + (Y - 2000 + 399) / 400)
     with Global => null;

   function Leap (Y : Year_T) return Boolean is
     (Y mod 4 = 0 and then (Y mod 100 /= 0 or else Y mod 400 = 0))
     with Global => null;

   --  The year of the day Days since 2000-01-01: the estimate of four
   --  years in 1461 days is exact up to 2100 and one day late at most
   --  after it, which one step either way corrects
   function Year_Of (Days : Natural) return Year_T
     with Global => null,
          Pre  => Days <= 49_710
   is
      Y : Year_T := 2000 + (4 * Days) / 1461;
   begin
      if Y > 2000 and then Days_Before_Year (Y) > Days then
         Y := Y - 1;
      end if;
      if Y < Year_T'Last and then Days_Before_Year (Y + 1) <= Days then
         Y := Y + 1;
      end if;
      return Y;
   end Year_Of;

   function EU_Summer_Time (UTC : Unsigned_32) return Boolean is
      Days   : constant Natural := Natural (UTC / 86_400);
      Y      : constant Year_T := Year_Of (Days);
      --  the 31st of March and of October, days since 2000-01-01
      Mar_31 : constant Natural :=
        Days_Before_Year (Y) + 89 + (if Leap (Y) then 1 else 0);
      Oct_31 : constant Natural := Mar_31 + 214;
      --  the last Sunday on or before them: 2000-01-01 was a Saturday,
      --  so the day N is (N + 6) mod 7 days after a Sunday
      Start  : constant Unsigned_64 :=
        Unsigned_64 (Mar_31 - (Mar_31 + 6) mod 7) * 86_400 + 3_600;
      Stop   : constant Unsigned_64 :=
        Unsigned_64 (Oct_31 - (Oct_31 + 6) mod 7) * 86_400 + 3_600;
   begin
      return Unsigned_64 (UTC) >= Start and then Unsigned_64 (UTC) < Stop;
   end EU_Summer_Time;

   function Zone_Offset (Z     : Zone_Table_T;
                         NID_C : NID_C_T;
                         UTC   : Unsigned_32) return Zone_Offset_T
   is
   begin
      for I in 1 .. Z.Count loop
         pragma Loop_Invariant (True);
         if NID_C in Z.Zones (I).First .. Z.Zones (I).Last then
            return (Found   => True,
                    Minutes => Z.Zones (I).Offset_Min
                      + (if Z.Zones (I).Summer = EU_Summer
                           and then EU_Summer_Time (UTC)
                         then 60 else 0));
         end if;
      end loop;
      return (Found => False, Minutes => 0);
   end Zone_Offset;

   --  The configuration in use

   procedure Count_Refusal
     with Global => (In_Out => Refused)
   is
   begin
      if Refused < Natural'Last then
         Refused := Refused + 1;
      end if;
   end Count_Refusal;

   --  The gamma train of an accepted image (a gamma train of version 2),
   --  else none
   procedure Load_Gamma (Bytes : Byte_Array; Model : Brake_Model_T)
     with Global => (Output => Gam)
   is
      L : Natural;
      S : Field_Status_T;
   begin
      Gam := No_Gamma;
      if Model /= Gamma or else Bytes'Length < Min_Image_V2_Length then
         return;
      end if;
      L := Natural (Get_U16 (Bytes, Bytes'First + 6));
      --  the zones of version 3 between the train and the CRC
      if Get_U16 (Bytes, Bytes'First + 4) = 3
        and then L >= Min_Image_V3_Length
      then
         L := L - Zone_Image_Length;
      end if;
      if L in Min_Image_V2_Length .. Bytes'Length then
         Get_Gamma (Bytes, L - 4, Gam, S);
         if S /= Accepted then
            Gam := No_Gamma;
         end if;
      end if;
   end Load_Gamma;

   procedure Gamma_Models (D : in out Train_Data_T) is
   begin
      D.A_Brake_Emergency := Gam.A_Brake_Emergency;
      D.A_Brake_Service := Gam.A_Brake_Service;
      D.A_Brake_Normal := Gam.A_Brake_Normal;
      D.T_Brake_Emergency := Gam.T_Brake_Emergency;
      D.T_Brake_Service := Gam.T_Brake_Service;
   end Gamma_Models;

   procedure Gamma_Extra (X : out Train_Data_Extra_T) is
   begin
      X := Gam.Extra;
   end Gamma_Extra;

   procedure Load (Bytes : Byte_Array) is
      R : constant Decoded_T := Decoded (Bytes);
   begin
      if R.Status = Accepted then
         Cfg := R.Config;
         Is_Loaded := True;
         Load_Gamma (Bytes, R.Config.Train.Model);
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

   procedure Set_Voltages_For_Test (V : Natural) is
   begin
      Cfg.Train.Voltages := V;
   end Set_Voltages_For_Test;

   procedure Report_Taken is
   begin
      Pending := False;
   end Report_Taken;

end EVC_Config;
