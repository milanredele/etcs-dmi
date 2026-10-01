--  ETCS DMI test simulator
--  Eurobalise telegrams for the ETCS on-board, built with the on-board's
--  own encoder (evc/language): the telegram of SUBSET-026 8.4.2 (header,
--  packets, packet 255, padded to 830 bits) and builders of the packets
--  a trackside of level 1 sends, the way test/src/evc_test.adb builds
--  them for its scenarios (Telegram_X, SSP, Grad, MA_Of, Link_To). Used
--  by Sim_Trackside; the tests may use it as well.
--
--  Everything here is integer and bounded: it builds for the wasm32
--  light runtime like the rest of sim/. An encode that fails (a value
--  out of its range, a telegram too long) clears OK and never raises.

with EVC_Bytes;
with ETCS_Bits;
with ETCS_Telegram;
with ETCS_Track_Packets.P3;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P68;
with ETCS_Track_Packets.P73;
with ETCS_Track_Packets.P49;
with ETCS_Track_Packets.P74;
with ETCS_Track_Packets.P80;
with ETCS_Track_Packets.P88;
with ETCS_Track_Packets.P132;
with ETCS_Track_Packets.P135;
with ETCS_Track_Packets.P137;
with ETCS_Track_Packets.P138;
with ETCS_Track_Packets.P139;
with Interfaces;

package Sim_Telegrams is

   package T3 renames ETCS_Track_Packets.P3;
   package T5 renames ETCS_Track_Packets.P5;
   package T12 renames ETCS_Track_Packets.P12;
   package T21 renames ETCS_Track_Packets.P21;
   package T27 renames ETCS_Track_Packets.P27;
   package T41 renames ETCS_Track_Packets.P41;
   package T65 renames ETCS_Track_Packets.P65;
   package T68 renames ETCS_Track_Packets.P68;
   package T73 renames ETCS_Track_Packets.P73;
   --  added with the procedures of phase E4 (e4/procedures)
   package T49 renames ETCS_Track_Packets.P49;
   package T74 renames ETCS_Track_Packets.P74;
   package T80 renames ETCS_Track_Packets.P80;
   package T88 renames ETCS_Track_Packets.P88;
   package T132 renames ETCS_Track_Packets.P132;
   package T135 renames ETCS_Track_Packets.P135;
   package T137 renames ETCS_Track_Packets.P137;
   package T138 renames ETCS_Track_Packets.P138;
   package T139 renames ETCS_Track_Packets.P139;

   subtype Byte_Array is EVC_Bytes.Byte_Array;
   subtype Writer_T is ETCS_Bits.Writer (ETCS_Bits.Max_Bytes);

   --  One telegram: its user bits, most significant bit first
   type Telegram_T is record
      Bits : Natural range 0 .. ETCS_Telegram.Long_Bits := 0;
      Data : Byte_Array (1 .. ETCS_Telegram.Max_Bytes) := (others => 0);
   end record;

   --  A telegram of balise N_PIG (0 first) of a group of Balises balises,
   --  version 2.0 (M_VERSION 48, as the tests), not duplicated,
   --  M_MCOUNT 7 (the telegram fits any message), Q_UPDOWN 1: W is
   --  cleared and gets the header
   procedure Start (W       : in out Writer_T;
                    NID_C   : Natural;
                    NID_BG  : Natural;
                    N_PIG   : Natural;
                    Balises : Positive;
                    Linked  : Boolean;
                    OK      : in out Boolean);

   --  Append a packet
   procedure Put (W : in out Writer_T; P : T3.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T5.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T12.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T21.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T27.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T41.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T65.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T68.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T73.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T49.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T74.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T80.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T88.Packet_T; OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T132.Packet_T;
                  OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T135.Packet_T;
                  OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T137.Packet_T;
                  OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T138.Packet_T;
                  OK : in out Boolean);
   procedure Put (W : in out Writer_T; P : T139.Packet_T;
                  OK : in out Boolean);

   --  Packet 255 and the padding to a long telegram (830 bits)
   procedure Finish (W  : in out Writer_T;
                     T  : out Telegram_T;
                     OK : in out Boolean);

   --  The BTM input of EVC_Ports: the detection stamp (the odometer's
   --  d_est when the antenna passed the balise), n_bits, the bits
   BTM_Length : constant := 4 + 2 + ETCS_Telegram.Max_Bytes;
   function BTM_Payload (T     : Telegram_T;
                         Stamp : Interfaces.Unsigned_32) return Byte_Array
     with Post => BTM_Payload'Result'Length
                    = 6 + (T.Bits + 7) / 8;

   ---------------------------------------------------------------------
   --  Packets. Distances in metres (Q_SCALE 1), from the location
   --  reference of the group, nominal direction (Q_DIR 1) unless said
   ---------------------------------------------------------------------

   type Nat_List is array (Positive range <>) of Natural;

   --  An SSP or a gradient profile element: the distance from the
   --  previous one (m), the value (km/h, or signed per mille for a
   --  gradient; End_Mark: the profile ends there)
   End_Mark : constant := 999;
   type Profile_Item is record
      D_M   : Natural;
      Value : Integer;
   end record;
   type Profile_List is array (Positive range <>) of Profile_Item;

   --  Packet 27, the basic SSP (no category specific speeds, no train
   --  length delay: Q_FRONT 1)
   function SSP (L : Profile_List) return T27.Packet_T
     with Pre => L'Length in 1 .. 32;

   --  Packet 21
   function Gradients (L : Profile_List) return T21.Packet_T
     with Pre => L'Length in 1 .. 32;

   --  Packet 12: sections of these lengths (m), the last one the End
   --  Section, no timer, no overlap; with a danger point at the EOA and
   --  its release speed when Release_Kmh is given
   function MA (Lengths     : Nat_List;
                V_Main_Kmh  : Natural;
                Release_Kmh : Natural := 0) return T12.Packet_T
     with Pre => Lengths'Length in 1 .. 32;

   --  Packet 5: to the groups NIDs at the incremental distances D_Links
   --  (m), all in the same country, nominal orientation, with the
   --  reaction and the location accuracy (m) given
   function Linking (D_Links  : Nat_List;
                     NIDs     : Nat_List;
                     Reaction : Natural := 1;
                     Locacc   : Natural := 2) return T5.Packet_T
     with Pre => D_Links'Length = NIDs'Length
                 and then D_Links'Length in 1 .. 32;

   --  Packet 3: the national values of SUBSET-026 A.3.2 for the country
   --  NID_C, valid at once, both directions (the values evc_test's
   --  mission sends, with Q_NVEMRRLS as given: 0 as A.3.2 has it, the
   --  emergency brake is revoked at standstill only)
   function National_Values (NID_C      : Natural;
                             Q_NVEMRRLS : Natural := 0) return T3.Packet_T;

   --  Packet 68: one track condition M_TRACKCOND from D_M, L_M long
   function Track_Condition (D_M, L_M : Natural;
                             Kind     : Natural) return T68.Packet_T;

   --  Packet 65: a TSR from D_M, L_M long, of Kmh, revoked with the train
   --  length delay (Q_FRONT 0)
   function TSR (Id : Natural; D_M, L_M, Kmh : Natural) return T65.Packet_T;

   --  Packet 41: the order to switch to level 2 (M_LEVELTR 3) at D_M,
   --  with an acknowledgement area Ack_M long
   function Level_2_Order (D_M, Ack_M : Natural) return T41.Packet_T;

   --  Packet 73: an auxiliary plain text shown from D_M on for L_M, in
   --  any mode and level, no confirmation, no report
   function Plain_Text (Text : String; D_M, L_M, NID_C : Natural)
     return T73.Packet_T
     with Pre => Text'Length in 1 .. 255;

   ---------------------------------------------------------------------
   --  Added with the procedures of phase E4 (e4/procedures): the
   --  packets of the mode profile, shunting, reversing, level crossings
   --  and text messages, for the scenarios of test/src/evc_test.adb
   ---------------------------------------------------------------------

   --  Packet 80, one area: M_MAMODE 0 On Sight, 1 Shunting, 2 Limited
   --  Supervision, from D_M, L_M long, its speed (km/h; 127 * 5: the
   --  national value), the acknowledgement area Ack_M in rear of it,
   --  Q_MAMODE (1: the beginning is a temporary SvL)
   National_Speed : constant := 635;
   function Mode_Profile (D_M      : Natural;
                          M_MAMODE : Natural;
                          L_M      : Natural;
                          Ack_M    : Natural;
                          Kmh      : Natural := National_Speed;
                          Q_MAMODE : Natural := 0) return T80.Packet_T;

   --  Packet 132: "stop if in shunting" (Stop) or "go if in shunting"
   function Danger_For_Shunting (Stop : Boolean) return T132.Packet_T;

   --  Packet 135: stop shunting on desk opening
   function Stop_Shunting_On_Desk_Opening return T135.Packet_T;

   --  Packet 49: the balise groups (of the country of the group) that
   --  may be passed in the shunting area
   function Shunting_Area_List (NIDs : Nat_List) return T49.Packet_T
     with Pre => NIDs'Length <= 31;

   --  Packet 137: "stop if in SR" (Stop) or "go if in SR"
   function Stop_If_In_SR (Stop : Boolean) return T137.Packet_T;

   --  Packet 138: the reversing area from D_M, L_M long
   function Reversing_Area (D_M, L_M : Natural) return T138.Packet_T;

   --  Packet 139: the distance to run in reverse (m; 32_767 infinite) and
   --  the reversing speed (km/h)
   function Reversing_Supervision (D_M, Kmh : Natural)
     return T139.Packet_T;

   --  Packet 88: a level crossing, from D_M, L_M long, protected or
   --  not (Guarded False: then with its speed, and the stopping area
   --  of L_Stop_M when stopping is required)
   function Level_Crossing (Id        : Natural;
                            D_M, L_M  : Natural;
                            Guarded   : Boolean;
                            Kmh       : Natural := 0;
                            Stop      : Boolean := False;
                            L_Stop_M  : Natural := 0) return T88.Packet_T;

   --  The conditions of a text message (packets 73 and 74, 7.5.1):
   --  start at D_M (No_Location: none), in mode Start_Mode
   --  (M_MODETEXTDISPLAY, 15 none), level Start_Level
   --  (M_LEVELTEXTDISPLAY, 4 none); end after L_M (No_Location: none),
   --  T_S seconds (1023 none), a transition from End_Mode (15 none);
   --  All_Of: Q_TEXTDISPLAY 1; Confirm: Q_TEXTCONFIRM;
   --  Ack_Ends: Q_CONFTEXTDISPLAY 0; Important: Q_TEXTCLASS 1
   No_Location : constant := 32_767;
   type Text_Conditions_T is record
      D_M         : Natural := No_Location;
      Start_Mode  : Natural := 15;
      Start_Level : Natural := 4;
      L_M         : Natural := No_Location;
      T_S         : Natural := 1023;
      End_Mode    : Natural := 15;
      All_Of      : Boolean := False;
      Confirm     : Natural := 0;
      Ack_Ends    : Boolean := True;
      Important   : Boolean := False;
   end record;

   function Plain_Text (Text : String; C : Text_Conditions_T)
     return T73.Packet_T
     with Pre => Text'Length in 1 .. 255;

   --  Packet 74: fixed text Q_TEXT (0 "Level crossing not protected", 1
   --  "Acknowledgement")
   function Fixed_Text (Q_TEXT : Natural; C : Text_Conditions_T)
     return T74.Packet_T;

end Sim_Telegrams;
