with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Streams;
with EVC_Brake_Commands;
with EVC_Braking;
with EVC_Bytes;
with EVC_Config;
with EVC_Core;
with EVC_Curves;
with EVC_DMI_Port;
with EVC_Distances;
with EVC_Fixed;
with EVC_Modes;
with EVC_PBD;
with EVC_Ports;
with EVC_Position;
with EVC_Profile;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Test_Modes;
with EVC_Train_Data;
with Interfaces;

package body EVC_Test_Config is

   package Pos renames EVC_Position;
   package SI renames EVC_Stored_Information;
   package SIn renames EVC_Supervision_Input;
   package SDM renames EVC_SDM;
   package BC renames EVC_Brake_Commands;
   package CFG renames EVC_Config;

   use type EVC_Distances.Cm_T;
   use type EVC_Distances.Sense_T;
   use type EVC_Bytes.Byte_Array;
   use type SIn.Release_Speed_Kind_T;
   use type SIn.Brake_Inhibition_T;
   use type SIn.Onboard_Config_T;
   use type SIn.Brake_Model_T;
   use type SIn.Decel_Curve_T;
   use type SIn.Train_Data_Extra_T;
   use type SDM.Monitoring_T;
   use type CFG.Config_T;
   use type CFG.Status_T;
   use Ada.Streams;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

   ---------------------------------------------------------------------


   function Status_Of (Image : Byte_Array) return CFG.Status_T is
     (CFG.Decoded (Image).Status);

   --  Image with its CRC made right again after a change of its bytes
   function Resealed (Image : Byte_Array) return Byte_Array is
      R : Byte_Array := Image;
      C : constant Unsigned_32 :=
        CFG.CRC_32 (R (R'First .. R'First + CFG.CRC_Offset - 1));
   begin
      for N in 0 .. 3 loop
         R (R'First + CFG.CRC_Offset + N) :=
           EVC_Bytes.Byte_Of (Unsigned_64 (C), N);
      end loop;
      return R;
   end Resealed;

   --  The bytes of a file (empty when it cannot be read)
   function File_Bytes (Path : String) return Byte_Array is
      package SIO renames Ada.Streams.Stream_IO;
      F : SIO.File_Type;
   begin
      if not Ada.Directories.Exists (Path) then
         return (1 .. 0 => 0);
      end if;
      SIO.Open (F, SIO.In_File, Path);
      declare
         Data : Stream_Element_Array
           (1 .. Stream_Element_Offset (SIO.Size (F)));
         Last : Stream_Element_Offset;
         R    : Byte_Array (1 .. Data'Length);
      begin
         SIO.Read (F, Data, Last);
         SIO.Close (F);
         for I in R'Range loop
            R (I) := Byte (Data (Stream_Element_Offset (I)));
         end loop;
         return R (1 .. Natural (Last));
      end;
   end File_Bytes;

   --  An image of version 2 of length L with its CRC made right again
   function Resealed_V2 (Image : Byte_Array; L : Natural) return Byte_Array
   is
      R : Byte_Array := Image;
      C : constant Unsigned_32 := CFG.CRC_32 (R (R'First .. R'First + L - 5));
   begin
      for N in 0 .. 3 loop
         R (R'First + L - 4 + N) := EVC_Bytes.Byte_Of (Unsigned_64 (C), N);
      end loop;
      return R;
   end Resealed_V2;

   --  A curve of N steps from Speed by 20 km/h (cm/s), the deceleration
   --  falling from Decel by 50 mm/s² a step
   function Curve (N : Natural; Speed, Decel : Natural)
     return SIn.Decel_Curve_T
   is
      R : SIn.Decel_Curve_T := (Count => N, Steps => (others => (0, 0)));
   begin
      for K in 1 .. N loop
         R.Steps (K) := (Speed => Speed + (K - 1) * 556,
                         Decel => Decel - (K - 1) * 50);
      end loop;
      return R;
   end Curve;

   --  A gamma train: two steps of emergency and service, Kdry 0.9, Kwet
   --  0.8, Kn, a rotating mass of 5 %; with the normal service sets and
   --  the models by combination if asked, at Steps steps each
   function Gamma_Sample (Sets, By_Combination : Boolean;
                          Steps : Positive := 2) return CFG.Gamma_T
   is
      G : CFG.Gamma_T := CFG.No_Gamma;
   begin
      G.A_Brake_Emergency := Curve (Steps, 2_778, 900);
      G.A_Brake_Service := Curve (Steps, 2_778, 700);
      G.A_Brake_Normal := Curve ((if Steps > 2 then Steps else 1), 0, 500);
      G.T_Brake_Emergency := 2_000;
      G.T_Brake_Service := 3_000;
      G.Extra.T_Brake_Emergency_React := 500;
      G.Extra.T_Brake_Service_React := 700;
      G.Extra.Kdry_Rst := (others => (others => 900));
      G.Extra.Kwet_Rst := (others => 800);
      G.Extra.Kn_Plus := Curve ((if Steps > 2 then Steps else 1), 0, 400);
      G.Extra.Kn_Minus := Curve ((if Steps > 2 then Steps else 1), 0, 410);
      G.Extra.M_Rotating_Nom := 5;
      if Sets then
         G.Extra.A_SB01 := 600;
         G.Extra.A_SB12 := 800;
         for N in 0 .. 2 loop
            G.Extra.Normal_Service_G (N) := Curve (Steps, 1_000, 700 + N);
            G.Extra.Normal_Service_P (N) := Curve (Steps, 1_000, 800 + N);
         end loop;
      end if;
      if By_Combination then
         G.Extra.By_Combination := True;
         for C in SIn.Brake_Combination_T loop
            G.Extra.A_Emergency_Combination (C) :=
              Curve (Steps, 2_778, 900 + C * 10);
            G.Extra.A_Service_Combination (C) :=
              Curve (Steps, 2_778, 700 + C * 10);
         end loop;
         for C in SIn.Combination_T loop
            G.Extra.T_Emergency_Combination (C) := (400 + C, 2_000 + C);
            G.Extra.T_Service_Combination (C) := (600 + C, 3_000 + C);
         end loop;
      end if;
      return G;
   end Gamma_Sample;

   --  The image of format version 2: the lambda train, the gamma train
   --  (the round trip of Encode_V2 through a load), the length, the
   --  ranges of the new fields; a version 1 image stays accepted
   --  (Scenario_Config_Image)
   procedure Scenario_Config_Image_V2 is
      C    : CFG.Config_T := CFG.Default;
      G    : constant CFG.Gamma_T := Gamma_Sample (False, False);
      Img  : CFG.Max_Image_T;
      L    : Natural;
      D    : CFG.Decoded_T;
      X    : SIn.Train_Data_Extra_T;
      T    : SIn.Train_Data_T;
      All_OK : Boolean := True;

      --  the gamma image with Value at Offset (resealed) has status Want
      procedure Field (Offset : Natural; Value : Byte_Array;
                       Want   : CFG.Status_T; What : String)
      is
         I : Byte_Array := Img;
      begin
         I (Offset + 1 .. Offset + Value'Length) := Value;
         Check (Status_Of (Resealed_V2 (I, L)) = Want,
                "config image v2: " & What & " "
                & CFG.Status_T'Image (Status_Of (Resealed_V2 (I, L))));
      end Field;
   begin
      --  a lambda train with a regenerative and an Ep brake
      C.Train.Has_Regenerative := True;
      C.Train.Has_Electro_Pneumatic := True;
      CFG.Encode_V2 (C, CFG.No_Gamma, Img, L);
      D := CFG.Decoded (Img (1 .. L));
      Check (L = 38 and then Img (1 .. 8) = (16#45#, 16#56#, 16#43#, 16#46#,
                                             2, 0, 38, 0)
             and then Img (33 .. 34) = (0, 9)
             and then D.Status = CFG.Accepted and then D.Config = C,
             "config image v2: a lambda train, 38 bytes, the model and the "
             & "special brakes back");

      --  a gamma train
      C.Train.Model := SIn.Gamma;
      CFG.Encode_V2 (C, G, Img, L);
      D := CFG.Decoded (Img (1 .. L));
      Check (L = 34 + 8 + 9 + 9 + 5 + 160 + 16 + 5 + 5 + 3 + 4
             and then D.Status = CFG.Accepted and then D.Config = C,
             "config image v2: a gamma train of two steps, 258 bytes, "
             & "accepted" & Natural'Image (L) & " "
             & CFG.Status_T'Image (D.Status));
      EVC_Core.Initialise;
      EVC_Core.Configure (Img (1 .. L));
      CFG.Gamma_Extra (X);
      CFG.Gamma_Models (T);
      Check (EVC_Core.Configuration = C and then X = G.Extra
             and then T.A_Brake_Emergency = G.A_Brake_Emergency
             and then T.A_Brake_Service = G.A_Brake_Service
             and then T.A_Brake_Normal = G.A_Brake_Normal
             and then T.T_Brake_Emergency = G.T_Brake_Emergency
             and then T.T_Brake_Service = G.T_Brake_Service,
             "config image v2: the gamma train loaded is the one encoded "
             & "(3.18.3.2 c), 3.18.3.2.1)");

      --  the ranges of the new fields
      Field (32, (1 => 2), CFG.Bad_Field, "braking model 2");
      Field (33, (1 => 16), CFG.Bad_Field, "special brakes 16");
      Field (34, (16#61#, 16#EA#), CFG.Bad_Field, "T_brake_react 60.001 s");
      Field (34, (16#60#, 16#EA#), CFG.Accepted, "T_brake_react 60 s");
      Field (42, (1 => 0), CFG.Bad_Field, "no step of A_brake_emergency");
      Field (42, (1 => 9), CFG.Bad_Field, "9 steps of A_brake_emergency");
      Field (47, (16#AD#, 16#0A#), CFG.Bad_Field,
             "speeds of A_brake_emergency not rising");
      Field (45, (16#31#, 16#75#), CFG.Bad_Field, "a deceleration 30.001");
      Field (69, (16#D1#, 16#07#), CFG.Bad_Field, "Kdry_rst 2.001");
      Field (L - 7, (1 => 101), CFG.Bad_Field, "M_rotating_nom 101 %");
      Field (L - 6, (1 => 2), CFG.Bad_Field, "normal service sets 2");
      Field (L - 5, (1 => 2), CFG.Bad_Field, "by combination 2");
      Field (L - 5, (1 => 1), CFG.Bad_Length,
             "by combination without the models");

      --  the length
      for Bad in Natural range L - 1 .. L + 1 loop
         if Bad /= L then
            declare
               I : Byte_Array := Img;
            begin
               I (7) := Byte (Bad mod 256);
               I (8) := Byte (Bad / 256);
               I := Resealed_V2 (I, Bad);
               if Status_Of (I) /= CFG.Bad_Length then
                  All_OK := False;
               end if;
            end;
         end if;
      end loop;
      Check (All_OK, "config image v2: a length one short or one long of "
             & "the fields refused, bad length");
      Field (6, (37, 0), CFG.Bad_Length, "length 37");
      Field (6, (16#E1#, 16#04#), CFG.Bad_Length, "length 1249");
      Field (4, (4, 0), CFG.Bad_Version, "format version 4");
      All_OK := True;
      for K in 0 .. L - 1 loop
         if Status_Of (Img (1 .. K)) /= CFG.Truncated then
            All_OK := False;
         end if;
      end loop;
      Check (All_OK, "config image v2: every truncated image refused");
      Img (100) := Img (100) xor 1;
      Check (Status_Of (Img (1 .. L)) = CFG.Bad_CRC,
             "config image v2: a bit of Kdry flipped, bad CRC");

      --  the longest: every curve at 8 steps, the sets, the combinations
      CFG.Encode_V2 (C, Gamma_Sample (True, True, 8), Img, L);
      D := CFG.Decoded (Img);
      Check (L = CFG.Max_Image_V2_Length and then D.Status = CFG.Accepted
             and then D.Config = C,
             "config image v2: the longest image, 1248 bytes, accepted");
      EVC_Core.Configure (Img);
      CFG.Gamma_Extra (X);
      Check (X = Gamma_Sample (True, True, 8).Extra,
             "config image v2: the sets and the models by combination "
             & "loaded (3.13.2.2.3.1.7, 3.13.2.2.3.1.9, 3.13.2.2.3.2.8)");

      --  back to the default
      EVC_Core.Initialise;
      EVC_Core.Configure (CFG.Encode (CFG.Default));
      CFG.Gamma_Extra (X);
      Check (EVC_Core.Configuration = CFG.Default
             and then X = SIn.Train_Data_Extra_T'(others => <>),
             "config image v2: a version 1 image loaded, no gamma train");
   end Scenario_Config_Image_V2;

   --  The image: its layout, the CRC, the header, truncation, the ranges
   --  of the fields and Table 3 of 3.13.2.2.6.1
   procedure Scenario_Config_Image is
      use type SIn.Special_Brake_Interface_T;
      D        : constant CFG.Image_T := CFG.Encode (CFG.Default);
      Img      : Byte_Array (1 .. CFG.Image_Length);
      C        : CFG.Config_T;
      OK       : Boolean;
      All_OK   : Boolean := True;
      Legal    : Natural := 0;
      Illegal  : Natural := 0;
      Seed     : Unsigned_32 := 7;

      function Next (Modulus : Natural) return Natural is
      begin
         Seed := Seed * 1_103_515_245 + 12_345;
         return Natural (Shift_Right (Seed, 8) mod Unsigned_32 (Modulus));
      end Next;

      --  the image with Value at Offset (resealed) has the status Want
      procedure Field (Offset : Natural; Value : Byte_Array;
                       Want   : CFG.Status_T; What : String)
      is
         I : Byte_Array := D;
      begin
         I (Offset + 1 .. Offset + Value'Length) := Value;
         Check (Status_Of (Resealed (I)) = Want,
                "config image: " & What & " "
                & CFG.Status_T'Image (Status_Of (Resealed (I))));
      end Field;
   begin
      Check (CFG.CRC_32 ((16#31#, 16#32#, 16#33#, 16#34#, 16#35#, 16#36#,
                          16#37#, 16#38#, 16#39#)) = 16#CBF4_3926#,
             "config image: the CRC-32 of IEEE 802.3 (the check value of "
             & """123456789"")");
      Check (CFG.Valid (CFG.Default)
             and then CFG.Default.Supervision.Special_Brakes
                        (SIn.Magnetic_Shoe) = SIn.Emergency_Only,
             "config: the default is valid, its magnetic shoe brake "
             & "interface the emergency brake model only (Table 3)");
      CFG.Decode (D, C, OK);
      Check (OK and then C = CFG.Default,
             "config image: encoded and decoded, the default comes back");
      Check (D (1 .. 8) = (16#45#, 16#56#, 16#43#, 16#46#, 1, 0, 36, 0),
             "config image: magic EVCF, version 1, length 36");
      Check (File_Bytes ("test/wasm/onboard.cfg") = Byte_Array (D),
             "config image: test/wasm/onboard.cfg (test/tools/evc_config.py"
             & " of ports/hosted/evc.cfg) is the kernel's image of the "
             & "default");

      --  a block of flash: the image, then erased flash, at any index
      declare
         Block : Byte_Array (1_001 .. 1_256) := (others => 16#FF#);
      begin
         Block (1_001 .. 1_036) := D;
         Check (Status_Of (Block) = CFG.Accepted
                and then CFG.Decoded (Block).Config = CFG.Default,
                "config image: at the start of a larger block (a flash "
                & "section), at any index");
      end;

      --  the CRC
      Img := D;
      Img (21) := Img (21) xor 1;
      Check (Status_Of (Img) = CFG.Bad_CRC,
             "config image: a bit of the antenna flipped, bad CRC");
      Img := D;
      Img (36) := Img (36) xor 16#80#;
      Check (Status_Of (Img) = CFG.Bad_CRC,
             "config image: a bit of the CRC flipped, bad CRC");

      --  the header
      Field (4, (2, 0), CFG.Bad_Length, "format version 2 of 36 bytes refused");
      Field (4, (1, 1), CFG.Bad_Version, "format version 257 refused");
      Field (0, (1 => 16#46#), CFG.Bad_Magic, "magic FVCF refused");
      Field (6, (35, 0), CFG.Bad_Length, "length 35 refused");
      Field (6, (37, 0), CFG.Bad_Length, "length 37 refused");

      --  truncated: every shorter image
      for L in 0 .. CFG.Image_Length - 1 loop
         if Status_Of (D (1 .. L)) /= CFG.Truncated then
            All_OK := False;
         end if;
      end loop;
      Check (All_OK, "config image: every truncated image (0 to 35 bytes)"
             & " refused as truncated");

      --  the ranges of the fields, and their limits
      for Offset in 8 .. 11 loop
         Field (Offset, (1 => 2), CFG.Bad_Field,
                "flag at" & Natural'Image (Offset) & " = 2");
      end loop;
      Field (18, (1 => 2), CFG.Bad_Field, "additional brake flag = 2");
      Field (19, (1 => 16#FF#), CFG.Bad_Field, "catenary flag = 255");
      Field (12, (16#E7#, 16#03#), CFG.Bad_Field, "k1 0.999");
      Field (12, (16#89#, 16#13#), CFG.Bad_Field, "k1 5.001");
      Field (12, (16#E8#, 16#03#), CFG.Accepted, "k1 1.000");
      Field (12, (16#88#, 16#13#), CFG.Accepted, "k1 5.000");
      for Offset in 14 .. 17 loop
         Field (Offset, (1 => 4), CFG.Bad_Field,
                "special brake interface 4 at" & Natural'Image (Offset));
      end loop;
      Field (20, (16#A1#, 16#86#, 16#01#, 0), CFG.Bad_Field,
             "antenna to cab A 1000.01 m");
      Field (24, (16#A0#, 16#86#, 16#01#, 0), CFG.Accepted,
             "antenna to cab B 1000 m");
      Field (24, (0, 0, 0, 1), CFG.Bad_Field, "antenna to cab B 2**24 cm");
      Field (20, (0, 0, 0, 0), CFG.Accepted, "antenna to cab A 0");
      Field (28, (16#61#, 16#EA#), CFG.Bad_Field, "SB failure 60.001 s");
      Field (28, (16#60#, 16#EA#), CFG.Accepted, "SB failure 60 s");
      Field (30, (16#B9#, 16#0B#), CFG.Bad_Field, "SB failure 3.001 m/s²");
      Field (30, (16#B8#, 16#0B#), CFG.Accepted, "SB failure 3 m/s²");

      --  3.13.2.2.6.1 Table 3, stated here again from the PDF (page 122
      --  of SUBSET-026-3): every combination of a brake and an interface
      All_OK := True;
      for B in SIn.Special_Brake_T loop
         for I in SIn.Special_Brake_Interface_T loop
            declare
               use type SIn.Special_Brake_T;
               Allowed : constant Boolean :=
                 (if B = SIn.Magnetic_Shoe
                  then I = SIn.No_Interface or else I = SIn.Emergency_Only
                  elsif B = SIn.Electro_Pneumatic
                  then I /= SIn.Emergency_Only
                  else True);
               X : CFG.Config_T := CFG.Default;
               R : CFG.Decoded_T;
            begin
               X.Supervision.Special_Brakes (B) := I;
               R := CFG.Decoded (CFG.Encode (X));
               if Allowed then
                  Legal := Legal + 1;
                  All_OK := All_OK and then CFG.Valid (X)
                            and then R.Status = CFG.Accepted
                            and then R.Config = X;
               else
                  Illegal := Illegal + 1;
                  All_OK := All_OK and then not CFG.Valid (X)
                            and then R.Status = CFG.Table_3_Violated
                            and then R.Config = CFG.Default;
               end if;
            end;
         end loop;
      end loop;
      Check (All_OK and then Legal = 13 and then Illegal = 3,
             "config: Table 3 (3.13.2.2.6.1), the 13 possibilities marked "
             & "accepted, the 3 others (magnetic shoe brake: service brake"
             & " model only, both models; Ep brake: emergency brake model "
             & "only) refused");

      --  random valid configurations: encoded and decoded
      All_OK := True;
      for K in 1 .. 500 loop
         declare
            X : CFG.Config_T;
            S : SIn.Onboard_Config_T renames X.Supervision;
         begin
            S.Service_Brake_Command := Next (2) = 1;
            S.Service_Brake_Feedback := Next (2) = 1;
            S.Feedback_From_Cylinder := Next (2) = 1;
            S.K1_Milli := 1_000 + Next (4_001);
            S.Traction_Cut_Off := Next (2) = 1;
            for B in SIn.Special_Brake_T loop
               loop
                  S.Special_Brakes (B) :=
                    SIn.Special_Brake_Interface_T'Val (Next (4));
                  exit when CFG.Table_3 (B, S.Special_Brakes (B));
               end loop;
            end loop;
            S.Additional_Brake_Allowed := Next (2) = 1;
            S.Regenerative_Needs_Catenary := Next (2) = 1;
            S.SB_Failure_Time_Ms := Next (60_001);
            S.SB_Failure_Decel_Mms2 := Next (3_001);
            X.Antenna_To_Cab_A := CFG.Antenna_Offset_T (Next (100_001));
            X.Antenna_To_Cab_B := CFG.Antenna_Offset_T (Next (100_001));
            CFG.Decode (CFG.Encode (X), C, OK);
            All_OK := All_OK and then OK and then C = X;
         end;
      end loop;
      Check (All_OK, "config image: 500 random valid configurations "
             & "encoded and decoded");
      Scenario_Config_Image_V2;
   end Scenario_Config_Image;

   --  The B2, B3, B4 of the last JRU record of Event in the last Take,
   --  as B2 * 65536 + B3 * 256 + B4; -1 when there is none
   function JRU_Last_Of (Event : Natural) return Integer is
      R : Integer := -1;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = JRU and then Byte_At (I, 1) = Event then
            R := Byte_At (I, 2) * 65_536 + Byte_At (I, 3) * 256
                 + Byte_At (I, 4);
         end if;
      end loop;
      return R;
   end JRU_Last_Of;

   --  A gamma image loaded in No Power, then the driver's Train Data in
   --  Stand By (DMI Table 40: 200 m, 135 %, 160 km/h): the Train Data of
   --  a gamma train with the installation's models, the brake percentage
   --  kept but no model from it, the snapshot's Extra.Train the
   --  installation's (3.18.3.2 c) and its 4th and 5th bullets)
   procedure Config_Gamma_Train is
      C : CFG.Config_T := CFG.Default;
      G : constant CFG.Gamma_T := Gamma_Sample (True, False);
      Img : CFG.Max_Image_T;
      L : Natural;
   begin
      C.Train.Model := SIn.Gamma;
      CFG.Encode_V2 (C, G, Img, L);
      EVC_Core.Initialise;
      EVC_Core.Configure (Img (1 .. L));
      EVC_Test_Modes.Start_E4;
      Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
                         (0, 4, 49, 50, 51, 52)));
      Stand_X (100);
      Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
                         Byte_Array'(1 => 2) & U16 (200) & U16 (135)
                         & U16 (160) & Byte_Array'(1 => 2) & U16 (4)
                         & Byte_Array'(0, 0, 1)));
      Stand_X (200);
      declare
         D : constant SIn.Train_Data_T := EVC_Train_Data.Data;
      begin
         Check (EVC_Train_Data.Valid and then D.Model = SIn.Gamma
                and then D.Brake_Percentage = 135
                and then D.A_Brake_Emergency = G.A_Brake_Emergency
                and then D.A_Brake_Service = G.A_Brake_Service
                and then D.T_Brake_Emergency = G.T_Brake_Emergency
                and then not EVC_Braking.Conversion_Applicable (D),
                "configure: a gamma train's Train Data, the models of the "
                & "installation, 135 % kept but no conversion model "
                & "(3.18.3.2 c), 3.13.2.2.5.1)");
      end;
      Check (SI.Current.Train_Data.Model = SIn.Gamma
             and then SI.Current.Extra.Train = G.Extra,
             "configure: the snapshot's Extra.Train is the installation's: "
             & "Kdry, Kwet, Kn, the normal service sets, M_rotating_nom "
             & "(3.18.3.2 c) 4th and 5th bullets)");
      --  3.18.3.9: the default Train Data of Supervised Manoeuvre of a
      --  gamma installation carry its models
      EVC_Train_Data.Start_Manoeuvre_Set (CFG.Current.Train);
      declare
         D : constant SIn.Train_Data_T := EVC_Train_Data.Data;
      begin
         Check (EVC_Train_Data.Manoeuvre_Set and then not EVC_Train_Data.Valid
                and then D.Model = SIn.Gamma
                and then D.A_Brake_Emergency = G.A_Brake_Emergency
                and then D.A_Brake_Service = G.A_Brake_Service
                and then D.T_Brake_Emergency = G.T_Brake_Emergency
                and then D.T_Brake_Service = G.T_Brake_Service,
                "configure: the Supervised Manoeuvre default train of a "
                & "gamma installation with its models (3.18.3.9, "
                & "3.18.3.2 c))");
      end;
      EVC_Train_Data.End_Manoeuvre_Set;
   end Config_Gamma_Train;

   --  EVC_Core.Configure: accepted in No Power, kept over a power-up,
   --  refused in service or when invalid (the previous one stays), the
   --  JRU records
   procedure Scenario_Config_Core is
      C   : CFG.Config_T := CFG.Default;
      Bad : CFG.Config_T := CFG.Default;
      Rej : Natural;
      Event : constant := EVC_Ports.JRU_Configuration;
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Rej := CFG.Rejections;
      C.Antenna_To_Cab_A := 1_000;
      C.Antenna_To_Cab_B := 2_000;
      C.Supervision.Traction_Cut_Off := False;
      C.Supervision.K1_Milli := 2_700;
      EVC_Core.Configure (CFG.Encode (C));
      Check (EVC_Core.Configured and then EVC_Core.Configuration = C
             and then Pos.Front_Offset (EVC_Distances.Plus) = 1_000
             and then Pos.Front_Offset (EVC_Distances.Minus) = 2_000,
             "configure: an image given in No Power is the configuration,"
             & " the position takes its antenna");
      EVC_Core.Tick (100);
      Take;
      Check (JRU_Count (Event) = 1
             and then JRU_Last_Of (Event)
                        = 1 * 65_536 + 0 * 256 + Natural'Min (Rej, 255),
             "configure: JRU event 33, loaded");
      Check (SI.Current.Extra.Config = C.Supervision,
             "configure: the snapshot of the stored information carries "
             & "it (3.13.2.2.6 to 3.13.2.2.8)");
      EVC_Core.Tick (100);
      Take;
      Check (JRU_Count (Event) = 0, "configure: recorded once");

      --  in Stand By: refused
      EVC_Core.Configure (CFG.Encode (CFG.Default));
      Check (EVC_Core.Configuration = C and then CFG.Rejections = Rej + 1
             and then CFG.Last_Status = CFG.Refused_In_Service,
             "configure: refused in Stand By, the installation does not "
             & "change under a running on-board");
      EVC_Core.Tick (100);
      Take;
      Check (JRU_Last_Of (Event)
               = 2 * 65_536 + 8 * 256 + Natural'Min (Rej + 1, 255),
             "configure: JRU event 33, refused in service");

      --  a power-up keeps it
      EVC_Core.Initialise;
      Check (EVC_Core.Configured and then EVC_Core.Configuration = C
             and then Pos.Front_Offset (EVC_Distances.Plus) = 1_000,
             "configure: the configuration stays over a power-up");

      --  invalid images in No Power: refused, the previous one stays
      Bad.Supervision.Special_Brakes (SIn.Magnetic_Shoe) :=
        SIn.Emergency_And_Service;
      EVC_Core.Configure (CFG.Encode (Bad));
      Check (EVC_Core.Configuration = C
             and then CFG.Last_Status = CFG.Table_3_Violated
             and then CFG.Rejections = Rej + 2,
             "configure: an image against Table 3 is refused, the "
             & "previous configuration stays");
      EVC_Core.Configure (CFG.Encode (CFG.Default) (1 .. 20));
      Check (EVC_Core.Configuration = C
             and then CFG.Last_Status = CFG.Truncated,
             "configure: a truncated image is refused");
      Reset_Capture;
      EVC_Core.Tick (100);
      Take;
      Check (JRU_Count (Event) = 1
             and then JRU_Last_Of (Event)
                        = 2 * 65_536 + 1 * 256 + Natural'Min (Rej + 3, 255),
             "configure: JRU event 33, the last outcome (truncated) and "
             & "the refusals");

      Config_Gamma_Train;

      --  back to the default, for what follows
      EVC_Core.Initialise;
      EVC_Core.Configure (CFG.Encode (CFG.Default));
      Check (EVC_Core.Configuration = CFG.Default
             and then Pos.Front_Offset (EVC_Distances.Plus) = 300,
             "configure: the default again");
   end Scenario_Config_Core;

   --  A power-up with the configuration C and one cycle: the stored
   --  information puts it into its snapshot
   procedure Load_Config (C : CFG.Config_T) is
   begin
      EVC_Core.Initialise;
      EVC_Core.Configure (CFG.Encode (C));
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Core.Configuration = C
             and then SI.Current.Extra.Config = C.Supervision,
             "configuration loaded and in the snapshot");
   end Load_Config;

   --  S with the configuration of the snapshot of the stored information
   function Configured (S : SIn.Snapshot_T) return SIn.Snapshot_T is
      R : SIn.Snapshot_T := S;
   begin
      R.Extra.Config := SI.Current.Extra.Config;
      return R;
   end Configured;

   --  One check per field of the configuration the supervision or the
   --  position reads: the field loaded by Configure changes what they do
   procedure Scenario_Config_Behaviour is
      use EVC_Fixed;
      Far : constant EVC_Distances.Dist_T := -EVC_Distances.Max_Cm + 1;
      SvL : constant EVC_Curves.Curve_T :=
        (EVC_Curves.EBD, 500_000, 0, 0, False);

      --  where the service brake is commanded approaching an EOA at
      --  120 km/h: the brake pressure Start_P kPa (TIU input 12) before
      --  target speed monitoring, TSM_P in it; the traction cut-off seen
      function SB_At (C      : CFG.Config_T;
                      Start_P, TSM_P : Natural;
                      TCO    : out Boolean) return Integer_64
      is
         S : SIn.Snapshot_T;
         X : Integer_64 := 0;
         V : constant SIn.Speed_Cms_T := Cms (120.0);
      begin
         TCO := False;
         Load_Config (C);
         S := Configured (Base_Snapshot);
         S.National.Q_NVSBFBPERM := True;
         Give_MA (S, 5_000, 200);
         Place (S, X, V);
         Sup_Start (S);
         Input (TIU, (12, Byte (Start_P / 4)));
         for Step in 1 .. 4_000 loop
            if Res.Monitoring = SDM.TSM then
               Input (TIU, (12, Byte (TSM_P / 4)));
            end if;
            X := X + Integer_64 (V) / 10;
            Move (X, V);
            Sup_Cycle;
            if Cmd.TCO
              or else (TIU_Out /= 16#FFFF# and then TIU_Out mod 8 >= 4)
            then
               TCO := True;
            end if;
            if Cmd.SB then
               return X;
            end if;
         end loop;
         return -1;
      end SB_At;

      --  the EBD 1 km before an SvL at 5000 m for a Gamma train whose
      --  special brakes add 0.3 m/s² to the emergency brake (every
      --  combination with one of them), with the brakes Active on the
      --  train interface and the inhibition areas of Areas
      function EBD_Speed (C          : CFG.Config_T;
                          Active     : EVC_Braking.Brakes_T;
                          Additional : Boolean := False;
                          Areas      : SIn.Inhibition_Areas_T :=
                            (others => <>);
                          Model      : out EVC_Braking.Model_T)
        return Speed_T
      is
         S : SIn.Snapshot_T;
         P : EVC_Profile.Profile_T;
      begin
         Load_Config (C);
         S := Configured (Case_Snapshot (Gamma_Train, Flat));
         S.Train_Data.Has_Regenerative := True;
         S.Train_Data.Has_Magnetic_Shoe := True;
         S.Extra.Train.By_Combination := True;
         for K in SIn.Brake_Combination_T loop
            S.Extra.Train.A_Emergency_Combination (K) :=
              S.Train_Data.A_Brake_Emergency;
            S.Extra.Train.A_Service_Combination (K) :=
              S.Train_Data.A_Brake_Service;
            if K /= 0 then
               for J in 1 .. 3 loop
                  S.Extra.Train.A_Emergency_Combination (K).Steps (J).Decel
                    := S.Train_Data.A_Brake_Emergency.Steps (J).Decel + 300;
               end loop;
            end if;
         end loop;
         S.Inhibitions := Areas;
         EVC_Braking.Build (S, Active, Additional, Model);
         EVC_Profile.Build (S, Model, Far, P);
         return EVC_Curves.Speed_At (Model, P, SvL, 400_000);
      end EBD_Speed;

      C     : CFG.Config_T;
      M     : EVC_Braking.Model_T;
      TCO   : array (1 .. 5) of Boolean;
      Plain, Pipe, Cyl_2, Cyl_4, No_TCO_At : Integer_64;
      None  : constant EVC_Braking.Brakes_T := (others => False);
      Shoe  : constant EVC_Braking.Brakes_T :=
        (SIn.Magnetic_Shoe => True, others => False);
      Regen : constant EVC_Braking.Brakes_T :=
        (SIn.Regenerative => True, others => False);
      Plain_V, V1, V2, V3 : Speed_T;
      Powerless : constant SIn.Inhibition_Areas_T :=
        (Count => 1,
         Areas => (1 => (SIn.Powerless_Section, 450_000, 470_000),
                   others => (SIn.Regenerative_Inhibited, 0, 0)));
   begin
      --  3.13.2.2.7.1: no service brake command, the emergency brake in
      --  its place (3.13.10.2.3)
      C := CFG.Default;
      C.Supervision.Service_Brake_Command := False;
      Load_Config (C);
      declare
         S : SIn.Snapshot_T := Configured (Base_Snapshot);
      begin
         Place (S, 100_000, Cms (148.0));
         Sup_Start (S);
         Check (Cmd.EB and then not Cmd.SB,
                "config behaviour: service brake command not implemented,"
                & " the emergency brake at 148 km/h in CSM (3.13.10.2.3)");
      end;
      Load_Config (CFG.Default);
      declare
         S : SIn.Snapshot_T := Configured (Base_Snapshot);
      begin
         Place (S, 100_000, Cms (148.0));
         Sup_Start (S);
         Check (Cmd.SB and then not Cmd.EB,
                "config behaviour: with the command, the service brake");
      end;

      --  3.13.2.2.7.2, 3.13.2.2.7.3, A.3.10.3: the feedback, from the
      --  brake pipe or from the cylinder with k1: the fictive pipe
      --  pressure 500 - p_cylinder / k1
      C := CFG.Default;
      C.Supervision.Service_Brake_Feedback := False;
      Plain := SB_At (C, 500, 400, TCO (1));
      C.Supervision.Service_Brake_Feedback := True;
      Pipe := SB_At (C, 500, 400, TCO (2));
      C.Supervision.Feedback_From_Cylinder := True;
      C.Supervision.K1_Milli := 2_000;
      Cyl_2 := SB_At (C, 0, 200, TCO (3));
      C.Supervision.K1_Milli := 4_000;
      Cyl_4 := SB_At (C, 0, 200, TCO (4));
      Check (TCO (1 .. 4) = (1 .. 4 => True),
             "config behaviour: the traction cut-off commanded at W "
             & "(3.13.2.2.8.1 implemented)");
      Check (Plain > 0 and then Pipe > Plain,
             "config behaviour: the service brake feedback (400 kPa) moves"
             & " the service brake from" & Integer_64'Image (Plain / 100)
             & " m to" & Integer_64'Image (Pipe / 100) & " m");
      Check (Cyl_2 = Pipe and then Cyl_4 > Plain and then Cyl_4 /= Cyl_2,
             "config behaviour: from the cylinder, 200 kPa with k1 2.0 is "
             & "the pipe at 400 kPa (" & Integer_64'Image (Cyl_2 / 100)
             & " m), with k1 4.0 at 450 kPa (" & Integer_64'Image
               (Cyl_4 / 100) & " m)");

      --  3.13.2.2.8.1: no traction cut-off command, no TCO on the TIU
      C := CFG.Default;
      C.Supervision.Traction_Cut_Off := False;
      No_TCO_At := SB_At (C, 500, 500, TCO (5));
      Check (No_TCO_At > 0 and then not TCO (5),
             "config behaviour: traction cut-off not implemented, no TCO "
             & "bit on the TIU output up to the service brake");

      --  3.13.2.2.6.1, Table 4: the magnetic shoe brake, emergency brake
      --  model only, counts when the train interface says it is active;
      --  without an interface it always counts; its status never counts
      --  for the service brake model
      Plain_V := EBD_Speed (CFG.Default, None, Model => M);
      Check (not M.Emergency_Brakes (SIn.Magnetic_Shoe)
             and then M.Service_Brakes (SIn.Magnetic_Shoe),
             "config behaviour: magnetic shoe brake, emergency brake model"
             & " only, not active: out of the emergency brake model only");
      V1 := EBD_Speed (CFG.Default, Shoe, Model => M);
      C := CFG.Default;
      C.Supervision.Special_Brakes (SIn.Magnetic_Shoe) := SIn.No_Interface;
      V2 := EBD_Speed (C, None, Model => M);
      Check (V1 > Plain_V and then V2 = V1
             and then M.Emergency_Brakes (SIn.Magnetic_Shoe),
             "config behaviour: the magnetic shoe brake raises the EBD 1 km"
             & " before the SvL from" & Img (Natural (Plain_V)) & " to"
             & Img (Natural (V1)) & " cm/s when the TIU reports it active "
             & "(Emergency_Only), always without an interface");
      --  the regenerative brake, service brake model only: its status
      --  does not count for the emergency brake model
      C := CFG.Default;
      C.Supervision.Special_Brakes (SIn.Regenerative) := SIn.Service_Only;
      V3 := EBD_Speed (C, None, Model => M);
      Check (V3 = V1 and then M.Emergency_Brakes (SIn.Regenerative)
             and then not M.Service_Brakes (SIn.Regenerative),
             "config behaviour: regenerative brake, service brake model "
             & "only: always in the emergency brake model");

      --  3.12.1.3.3: a powerless section inhibits the regenerative brake
      --  when it needs the catenary
      V1 := EBD_Speed (CFG.Default, Regen, Areas => Powerless, Model => M);
      C := CFG.Default;
      C.Supervision.Regenerative_Needs_Catenary := False;
      V2 := EBD_Speed (C, Regen, Areas => Powerless, Model => M);
      V3 := EBD_Speed (C, Regen, Model => M);
      Check (V1 < V2 and then V2 = V3,
             "config behaviour: the regenerative brake needs the catenary:"
             & " a powerless section 30 m before the SvL lowers the EBD "
             & "from" & Img (Natural (V2)) & " to" & Img (Natural (V1))
             & " cm/s; not needed, nothing changes");

      --  3.13.2.2.6.4, 3.13.6.2.1.6: the additional brake allowed selects
      --  A_NVMAXREDADH1 when it is active
      C := CFG.Default;
      C.Supervision.Additional_Brake_Allowed := True;
      V1 := EBD_Speed (C, None, Additional => True, Model => M);
      Check (M.Redadh = 100 * 1_000,
             "config behaviour: additional brake allowed and active: "
             & "A_NVMAXREDADH1 (1 m/s²)");
      V1 := EBD_Speed (CFG.Default, None, Additional => True, Model => M);
      Check (M.Redadh = 100 * 700 and then V1 > 0,
             "config behaviour: not allowed: A_NVMAXREDADH2 (0.7 m/s²)");

      --  3.14.1.2: the service brake failure, after T_bs + the time
      --  without the deceleration of the configuration
      declare
         function Failed_After (C : CFG.Config_T; A_Est : Accel_T)
           return Natural
         is
            S     : SIn.Snapshot_T;
            R     : SDM.Result_T;
            State : BC.State_T;
            Out_C : BC.Commands_T;
         begin
            Load_Config (C);
            S := Configured (Base_Snapshot);
            Place (S, 100_000, Cms (100.0));
            R.SB := True;
            for Ms in 1 .. 300 loop
               BC.Step (S, R,
                        (Mode       => M_FS,
                         Controller => BC.Forwards,
                         Ack        => False,
                         Dt_Ms      => 100,
                         A_Est      => A_Est,
                         T_Bs       => 3_000,
                         Modifying_Data => False),
                        State, Out_C);
               if State.SB_Failed then
                  return Ms * 100;
               end if;
            end loop;
            return 0;
         end Failed_After;

         T_Default, T_Longer, Decel_Default, Decel_Higher : Natural;
      begin
         T_Default := Failed_After (CFG.Default, 0);
         C := CFG.Default;
         C.Supervision.SB_Failure_Time_Ms := 5_000;
         T_Longer := Failed_After (C, 0);
         Decel_Default := Failed_After (CFG.Default, -150);
         C := CFG.Default;
         C.Supervision.SB_Failure_Decel_Mms2 := 200;
         Decel_Higher := Failed_After (C, -150);
         Check (T_Default = 5_100 and then T_Longer = 8_100,
                "config behaviour: service brake failure 2 s after T_bs "
                & "(3 s) without deceleration," & Img (T_Default)
                & " ms; with 5 s," & Img (T_Longer) & " ms (3.14.1.2)");
         Check (Decel_Default = 0 and then Decel_Higher = 5_100,
                "config behaviour: 0.15 m/s² of deceleration is braking "
                & "against 0.1 m/s², a failure against 0.2 m/s²");
      end;

      --  3.6.1.3.4: the antenna, the front end of the engine against
      --  the LRBG of a passage, and the PBD's antenna (3.11.11)
      for A in 1 .. 2 loop
         C := CFG.Default;
         C.Antenna_To_Cab_A := (if A = 1 then 300 else 1_000);
         C.Antenna_To_Cab_B := 2_500;
         EVC_Core.Initialise;
         EVC_Core.Configure (CFG.Encode (C));
         Start_Track;
         Add_Group (Group (10, 100));
         Run_To (20_000);
         Check (Pos.LRBG.Valid and then Pos.LRBG.X = 10_000
                and then Pos.Estimated_Front = 10_000 + C.Antenna_To_Cab_A
                and then SI.PBD_Inputs.Antenna
                           = EVC_PBD.Antenna_T (C.Antenna_To_Cab_A)
                and then Pos.Front_Offset (EVC_Distances.Minus) = 2_500,
                "config behaviour: the LRBG at 100 m, the front end at"
                & EVC_Distances.Cm_T'Image (Pos.Estimated_Front)
                & " cm with the antenna" & EVC_Distances.Cm_T'Image
                  (C.Antenna_To_Cab_A) & " cm from cab A");
      end loop;

      --  back to the default, for what follows
      EVC_Core.Initialise;
      EVC_Core.Configure (CFG.Encode (CFG.Default));
   end Scenario_Config_Behaviour;

   procedure Scenario_Config_Zones is
      C   : CFG.Config_T := CFG.Default;
      G   : constant CFG.Gamma_T := Gamma_Sample (False, False);
      Img : CFG.Max_Image_T;
      L   : Natural;
      D   : CFG.Decoded_T;
      X   : SIn.Train_Data_Extra_T;
      Z   : CFG.Zone_Offset_T;
      --  the offset of the zones' count byte
      Z0  : Natural;
      use type CFG.Zone_Table_T;
      use type CFG.Fixed_Train_T;

      --  the image of version 3 with Value at Offset (resealed) has
      --  status Want
      procedure Field (Offset : Natural; Value : Byte_Array;
                       Want   : CFG.Status_T; What : String)
      is
         I : Byte_Array := Img (1 .. L);
      begin
         I (Offset + 1 .. Offset + Value'Length) := Value;
         Check (Status_Of (Resealed_V2 (I, L)) = Want,
                "config zones: " & What & " "
                & CFG.Status_T'Image (Status_Of (Resealed_V2 (I, L))));
      end Field;
   begin
      C.Zones.Count := 2;
      C.Zones.Zones (1) := (First => 200, Last => 210, Offset_Min => 60,
                            Summer => CFG.EU_Summer);
      C.Zones.Zones (2) := (First => 300, Last => 300, Offset_Min => -300,
                            Summer => CFG.No_Summer);
      CFG.Encode_V3 (C, CFG.No_Gamma, Img, L);
      D := CFG.Decoded (Img (1 .. L));
      Check (L = 38 + CFG.Zone_Image_Length
             and then Img (1 .. 8) = (16#45#, 16#56#, 16#43#, 16#46#,
                                      3, 0, Byte (L), 0)
             and then D.Status = CFG.Accepted and then D.Config = C,
             "config zones: an image of version 3 of a lambda train, the "
             & "zones between the train and the CRC, gives the "
             & "configuration back");
      Z0 := L - 4 - CFG.Zone_Image_Length;
      Check (Img (Z0 + 1 .. Z0 + 15)
               = (2, 200, 0, 210, 0, 12, 3, 1, 44, 1, 44, 1, 164, 1, 0),
             "config zones: the count, then NID_C first and last, the "
             & "offset + 720 min and the rule of each zone");
      Check (File_Bytes ("test/config/zones_v3.img")
               = Byte_Array (Img (1 .. L)),
             "config zones: test/config/zones_v3.img (test/tools/"
             & "evc_config.py of test/config/zones_v3.toml) is the "
             & "kernel's image of version 3 of these zones");
      Field (Z0, (1 => 9), CFG.Bad_Field, "more than 8 zones refused");
      Field (Z0 + 3, (100, 0), CFG.Bad_Field,
             "a zone ending before its start refused");
      Field (Z0 + 3, (0, 4), CFG.Bad_Field, "NID_C 1024 refused");
      Field (Z0 + 5, (25, 6), CFG.Bad_Field,
             "an offset beyond UTC+14:00 refused");
      Field (Z0 + 7, (1 => 2), CFG.Bad_Field, "an unknown rule refused");
      Field (Z0, (1 => 0), CFG.Accepted, "no zone accepted");

      CFG.Encode_V2 (C, CFG.No_Gamma, Img, L);
      D := CFG.Decoded (Img (1 .. L));
      Check (L = 38 and then D.Status = CFG.Accepted
             and then D.Config.Zones = CFG.No_Zones
             and then D.Config.Train = C.Train,
             "config zones: an image of version 2 has no zone");

      C.Train.Model := SIn.Gamma;
      CFG.Encode_V3 (C, G, Img, L);
      D := CFG.Decoded (Img (1 .. L));
      CFG.Load (Img (1 .. L));
      CFG.Gamma_Extra (X);
      Check (D.Status = CFG.Accepted and then D.Config = C
             and then CFG.Current = C and then X = G.Extra,
             "config zones: a gamma train of version 3 loads its train "
             & "and its zones");
      CFG.Load (CFG.Encode (CFG.Default));

      --  the EU summer time of 2026 (29 March, 25 October) and of the
      --  leap year 2024 (31 March), at 01:00 UTC, seconds since 2000
      Check (not CFG.EU_Summer_Time (828_061_199)
             and then CFG.EU_Summer_Time (828_061_200)
             and then CFG.EU_Summer_Time (846_205_199)
             and then not CFG.EU_Summer_Time (846_205_200)
             and then not CFG.EU_Summer_Time (765_161_999)
             and then CFG.EU_Summer_Time (765_162_000)
             and then not CFG.EU_Summer_Time (0)
             and then not CFG.EU_Summer_Time (Unsigned_32'Last),
             "config zones: the EU summer time from the last Sunday of "
             & "March to the last Sunday of October at 01:00 UTC");
      Z := CFG.Zone_Offset (C.Zones, 210, 836_179_200);
      Check (Z.Found and then Z.Minutes = 120
             and then CFG.Zone_Offset (C.Zones, 300, 836_179_200).Minutes
                      = -300
             and then not CFG.Zone_Offset (C.Zones, 211, 836_179_200).Found,
             "config zones: the offset of the zone of a NID_C on 1 July "
             & "2026, the summer time added by the EU rule only");
   end Scenario_Config_Zones;

end EVC_Test_Config;
