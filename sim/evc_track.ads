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

   -- Operational stopping points of the ATO journey profile (DMI 8.5.3,
   -- 8.5.7): name, location, train hold at the start of the stop and
   -- dwell time after it, and the side of the doors. Knebworth holds
   -- the train and has a dwell time above a minute, so that the bench
   -- shows ATO09 and the '[m]m:ss' format of 8.5.5.5.
   type Door_Side_T is (Left, Right, Both);
   type Stopping_Point_T is record
      Name    : String (1 .. 12); -- padded with spaces
      At_M    : Natural;
      Hold_S  : Natural;
      Dwell_S : Natural;
      Doors   : Door_Side_T;
   end record;
   Stopping_Points : constant array (1 .. 3) of Stopping_Point_T :=
     (("Welwyn North", 2_500, 0, 25, Left),
      ("Knebworth   ", 6_300, 10, 65, Right),
      ("Stevenage   ", 9_900, 0, 30, Both));

   ---------------------------------------------------------------------
   -- The balise groups of the line, for the ETCS on-board of the bench
   -- (Sim_Trackside builds their telegrams; EVC_Mock does not read
   -- them). Every group has two balises Balise_Spacing_M apart, the
   -- first (N_PIG 0) at At_M, nominal direction towards rising
   -- positions, all in the country NID_C and linked (Q_LINK 1). The
   -- first group is 12 m in rear of the mission start and carries the
   -- national values, the SSP, the gradients and the level 1 MA of the
   -- description above; the others repeat the linking and carry what
   -- lies ahead of them.
   ---------------------------------------------------------------------

   NID_C            : constant := 123;
   Balise_Spacing_M : constant := 3;
   Balises_Per_Group : constant := 2;

   -- What a group carries besides the linking to the groups after it
   type Group_Content_T is
     (Mission,           -- 3, 27, 21, 12
      Neutral_Section,   -- 68: Conditions (1)
      Pantograph_Level,  -- 68: Conditions (2); 41: the transition to L2
      TSR_Text,          -- 65: the TSR below; 73: the text below
      Tunnel,            -- 68: the tunnel stopping area
      Linking_Only);

   type Balise_Group_T is record
      NID_BG  : Natural;
      At_M    : Integer;
      Content : Group_Content_T;
   end record;

   Balise_Groups : constant array (1 .. 6) of Balise_Group_T :=
     ((1, -12, Mission),
      (2, 1_500, Neutral_Section),
      (3, 4_000, Pantograph_Level),
      (4, 6_500, TSR_Text),
      (5, 8_000, Tunnel),
      (6, 9_600, Linking_Only));

   -- A temporary speed restriction and a plain text message for the
   -- on-board only (the mock has neither): 80 km/h from 7 400 m to
   -- 7 900 m, the text shown from 6 600 m to 7 400 m
   TSR_ID       : constant := 5;
   TSR_From_M   : constant Natural := 7_400;
   TSR_To_M     : constant Natural := 7_900;
   TSR_Speed    : constant Natural := 80;
   Text_From_M  : constant Natural := 6_600;
   Text_To_M    : constant Natural := 7_400;
   Text_Message : constant String := "Works on the line";

   function MRSP_At (Position_M : Natural) return Natural;
   function Gradient_At (Position_M : Natural) return Integer;

end EVC_Track;
