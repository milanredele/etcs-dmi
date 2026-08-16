--  ETCS DMI test simulator
--  Static track description for the EVC simulator. Distances in metres
--  from the mission start, speeds in km/h, gradients in permille.

package EVC_Track is

   -- Most restrictive speed profile
   type MRSP_Segment_T is record
      Start_M : Natural;
      Speed   : Natural;
   end record;
   MRSP : constant array (1 .. 3) of MRSP_Segment_T :=
     ((0, 140), (4_000, 100), (7_000, 120));

   -- End of authority
   EOA_M         : constant Natural := 10_000;
   Release_Speed : constant Natural := 25;

   -- Gradient profile
   type Gradient_Segment_T is record
      Start_M : Natural;
      Value   : Integer;
   end record;
   Gradients : constant array (1 .. 4) of Gradient_Segment_T :=
     ((0, 5), (2_000, -8), (5_000, 0), (8_000, 12));

   -- Track conditions: announced ahead, active while inside
   type Condition_T is record
      Announce_Symbol : Natural; -- TC symbol (yellow variant)
      Active_Symbol   : Natural; -- TC symbol (grey variant)
      PL_Symbol       : Natural; -- planning symbol
      Announce_M      : Natural; -- announcement location
      Start_M         : Natural;
      End_M           : Natural;
   end record;
   Conditions : constant array (1 .. 2) of Condition_T :=
     -- neutral section (TC07 announce / TC06 active, PL05)
     ((7, 6, 5, 2_000, 3_000, 3_300),
      -- lower pantograph (TC03 announce / TC01 lowered, PL01)
      (3, 1, 1, 4_400, 5_200, 5_800));

   -- Level crossing not protected (LX01 in B3/4/5 while approaching)
   LX_From_M : constant Natural := 5_500;
   LX_At_M   : constant Natural := 6_000;

   -- Tunnel stopping area
   Tunnel_Announce_M : constant Natural := 8_000;
   Tunnel_Start_M    : constant Natural := 8_500;
   Tunnel_End_M      : constant Natural := 9_000;

   -- Level transition L1 -> L2, announced with acknowledgement
   Level_Ann_M        : constant Natural := 4_500;
   Level_Transition_M : constant Natural := 5_000;

   -- Track ahead free request location
   TAF_M : constant Natural := 9_400;

   function MRSP_At (Position_M : Natural) return Natural;
   function Gradient_At (Position_M : Natural) return Integer;

end EVC_Track;
