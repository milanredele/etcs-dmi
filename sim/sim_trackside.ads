--  ETCS DMI test simulator
--  The trackside of the ETCS on-board on the bench: the balise groups of
--  EVC_Track.Balise_Groups with their telegrams (Sim_Telegrams), the
--  places of their balises, and the picture of the line for the page
--  (MSG_TRACK_LAYOUT, as EVC_Mock sends it).
--
--  The first group, 12 m in rear of the mission start, carries what
--  evc_test's mission gives the on-board: the national values (packet
--  3), the SSP (27: 140, 100 from 4 km, 120 from 7 km, to 10.5 km),
--  the gradients (21) and the level 1 MA (12: V_MAIN 140 km/h, the EOA
--  at 10 km with a danger point there and the release speed of 25
--  km/h), balise 0 the first two and balise 1 the others. Every group
--  links the groups after it (packet 5, in both balises; reaction:
--  service brake, 2 m location accuracy) and carries, in balise 0, what
--  lies ahead of it on the line: the neutral section (68, M_TRACKCOND
--  9), the lowering of the pantograph (68, 3) with the order to switch
--  to level 2 (41, stored until the level transitions of E4), the TSR
--  (65) with a plain text (73, the plain text packet of SUBSET-026
--  v4.0.0; E4 shows it), the tunnel stopping area (68, 1).
--
--  Positions are in cm of the track (0: the mission start), rising in
--  the nominal direction of every group.

with Ada.Streams;
with EVC_Track;
with Interfaces;
with Sim_Telegrams;

package Sim_Trackside is

   Balise_Count : constant :=
     EVC_Track.Balise_Groups'Length * EVC_Track.Balises_Per_Group;

   subtype Balise_Index is Positive range 1 .. Balise_Count;

   --  Build the telegrams of Preset (once per preset; a call with the
   --  preset already built does nothing). False when one did not
   --  encode, which a check of the tests catches. The default Preset
   --  keeps every existing caller's behaviour (and the native golden)
   --  unchanged; Features is the bench page's alternate "features"
   --  track (EVC_Track.Preset_T).
   procedure Build (Preset : EVC_Track.Preset_T := EVC_Track.Default);

   --  The SSP (packet 27) and the gradient profile (packet 21) of the
   --  track of the last Build, from a location reference From m in rear of
   --  the mission start: the first group's, and the track description
   --  Sim_RBC gives with its MA (3.7.3.1)
   procedure Put_SSP (W : in out Sim_Telegrams.Writer_T; From : Integer;
                      OK : in out Boolean);
   procedure Put_Gradients (W : in out Sim_Telegrams.Writer_T;
                            From : Integer; OK : in out Boolean);
   function Built_OK return Boolean;
   function Current_Preset return EVC_Track.Preset_T;

   --  The balises in the order of the track: position of the centre
   --  (cm), group (index in EVC_Track.Balise_Groups) and N_PIG
   function Balise_At_Cm (B : Balise_Index) return Interfaces.Integer_64;
   function Group_Of (B : Balise_Index) return Positive;
   function Telegram (B : Balise_Index) return Sim_Telegrams.Telegram_T;

   --  The end of the SSP and of the gradient profile of the first group
   Profiles_End_M : constant := 10_500;

   --  MSG_TRACK_LAYOUT (dmi_protocol.ads): the payload EVC_Mock sends,
   --  from the same EVC_Track
   procedure Layout_Payload (Buffer : out Ada.Streams.Stream_Element_Array;
                             Last   : out Ada.Streams.Stream_Element_Offset)
     with Pre => Buffer'Length >= 256;

end Sim_Trackside;
