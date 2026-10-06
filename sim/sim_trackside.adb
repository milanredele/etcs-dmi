--  ETCS DMI test simulator
--  The trackside of the ETCS on-board: implementation.

with DMI_Protocol; use DMI_Protocol;

package body Sim_Trackside is

   use EVC_Track;
   use Sim_Telegrams;
   use type Interfaces.Integer_64;
   use type Ada.Streams.Stream_Element_Offset;

   Built        : Boolean := False;
   Good         : Boolean := False;
   Built_Preset : EVC_Track.Preset_T := EVC_Track.Default;

   --  The active preset's group table (the default is unchanged: same
   --  object, same bytes, the native golden depends on it)
   Active_Groups : Group_Table_T := Balise_Groups;

   Telegrams : array (Balise_Index) of Telegram_T;

   function Group_Of (B : Balise_Index) return Positive is
     ((B - 1) / Balises_Per_Group + 1);

   function Pig_Of (B : Balise_Index) return Natural is
     ((B - 1) mod Balises_Per_Group);

   function Balise_At_Cm (B : Balise_Index) return Interfaces.Integer_64 is
     (Interfaces.Integer_64 (Active_Groups (Group_Of (B)).At_M) * 100
      + Interfaces.Integer_64 (Pig_Of (B) * Balise_Spacing_M) * 100);

   function Telegram (B : Balise_Index) return Telegram_T is (Telegrams (B));

   function Built_OK return Boolean is (Built and then Good);
   function Current_Preset return EVC_Track.Preset_T is (Built_Preset);

   --  The linking of group G: every group after it
   Last_Group : constant Positive := Balise_Groups'Last;

   procedure Put_Linking (W : in out Writer_T; G : Positive;
                          OK : in out Boolean)
   is
   begin
      if G < Last_Group then
         declare
            Count   : constant Positive := Last_Group - G;
            D_Links : Nat_List (1 .. Count);
            NIDs    : Nat_List (1 .. Count);
         begin
            for I in 1 .. Count loop
               D_Links (I) := Natural'Max
                 (0, Active_Groups (G + I).At_M
                     - Active_Groups (G + I - 1).At_M);
               NIDs (I) := Active_Groups (G + I).NID_BG;
            end loop;
            Put (W, Linking (D_Links, NIDs), OK);
         end;
      end if;
   end Put_Linking;

   --  A profile of segments (their start, m from the mission start, and
   --  value) from a location reference From m in rear of the mission
   --  start: the segment in force at the reference at distance 0 (the
   --  first one when the reference is in rear of them all), the later
   --  ones by their distance to the one before, then the end mark at
   --  Profiles_End_M; a segment behind the reference is left out
   type Segment_T is record
      Start_M, Value : Integer;
   end record;
   type Segment_List is array (Positive range <>) of Segment_T;

   function Profile (Segments : Segment_List; From : Integer)
     return Profile_List
   is
      Ref : constant Integer := -From;
      K   : Positive := Segments'First;
   begin
      for J in Segments'Range loop
         if J > Segments'First and then Segments (J).Start_M <= Ref then
            K := J;
         end if;
      end loop;
      declare
         Res  : Profile_List (1 .. Segments'Last - K + 2);
         Prev : Integer := Ref;
      begin
         Res (1) := (D_M => 0, Value => Segments (K).Value);
         for J in K + 1 .. Segments'Last loop
            Res (J - K + 1) :=
              (D_M   => Natural'Max (0, Segments (J).Start_M - Prev),
               Value => Segments (J).Value);
            Prev := Segments (J).Start_M;
         end loop;
         Res (Res'Last) :=
           (D_M => Natural'Max (0, Profiles_End_M - Prev), Value => End_Mark);
         return Res;
      end;
   end Profile;

   procedure Put_SSP (W : in out Writer_T; From : Integer;
                      OK : in out Boolean)
   is
      L : Segment_List (MRSP'Range);
   begin
      for I in MRSP'Range loop
         L (I) := (MRSP (I).Start_M, MRSP (I).Speed);
      end loop;
      Put (W, SSP (Profile (L, From)), OK);
   end Put_SSP;

   procedure Put_Gradients (W : in out Writer_T; From : Integer;
                            OK : in out Boolean)
   is
      L : Segment_List (EVC_Track.Gradients'Range);
   begin
      for I in L'Range loop
         L (I) := (EVC_Track.Gradients (I).Start_M,
                   EVC_Track.Gradients (I).Value);
      end loop;
      Put (W, Sim_Telegrams.Gradients (Profile (L, From)), OK);
   end Put_Gradients;

   --  The packets of the first group: from its location reference (its
   --  balise 0, From m in rear of the mission start)
   procedure Put_Mission (W : in out Writer_T; Pig : Natural; From : Integer;
                          OK : in out Boolean)
   is
   begin
      if Pig = 0 then
         Put (W, National_Values (NID_C), OK);
         Put_SSP (W, From, OK);
      else
         Put_Gradients (W, From, OK);
         Put (W, MA ((1 => EOA_M + From), V_Main_Kmh => MRSP (1).Speed,
                     Release_Kmh => Release_Speed), OK);
      end if;
   end Put_Mission;

   procedure Build (Preset : EVC_Track.Preset_T := EVC_Track.Default) is
      W : Writer_T;
   begin
      if Built and then Built_Preset = Preset then
         return;
      end if;
      Active_Groups :=
        (if Preset = EVC_Track.Features
         then Balise_Groups_Features else Balise_Groups);
      Good := True;
      for B in Balise_Index loop
         declare
            G   : constant Positive := Group_Of (B);
            Pig : constant Natural := Pig_Of (B);
            At_M : constant Integer := Active_Groups (G).At_M;
         begin
            Start (W, NID_C, Active_Groups (G).NID_BG, Pig,
                   Balises_Per_Group, Linked => True, OK => Good);
            Put_Linking (W, G, Good);
            case Active_Groups (G).Content is
               when Mission =>
                  Put_Mission (W, Pig, -At_M, Good);
               when Neutral_Section =>
                  if Pig = 0 then
                     Put (W, Track_Condition
                            (Conditions (1).Start_M - At_M,
                             Conditions (1).End_M - Conditions (1).Start_M,
                             Kind => 9), Good);
                  end if;
               when Pantograph_Level =>
                  if Pig = 0 then
                     Put (W, Track_Condition
                            (Conditions (2).Start_M - At_M,
                             Conditions (2).End_M - Conditions (2).Start_M,
                             Kind => 3), Good);
                     Put (W, Level_2_Order
                            (Level_Transition_M - At_M,
                             Level_Transition_M - Level_Ann_M), Good);
                  end if;
               when TSR_Text =>
                  if Pig = 0 then
                     Put (W, TSR (TSR_ID, TSR_From_M - At_M,
                                  TSR_To_M - TSR_From_M, TSR_Speed), Good);
                     Put (W, Plain_Text (Text_Message, Text_From_M - At_M,
                                         Text_To_M - Text_From_M, NID_C),
                          Good);
                  end if;
               when Tunnel =>
                  if Pig = 0 then
                     Put (W, Track_Condition
                            (Tunnel_Start_M - At_M,
                             Tunnel_End_M - Tunnel_Start_M,
                             Kind => 1), Good);
                  end if;
               when Linking_Only =>
                  null;
               --  the "features" preset (bench page only)
               when On_Sight_To_Level0 =>
                  if Pig = 0 then
                     Put (W, Mode_Profile (D_M => OS_D_M, M_MAMODE => 0,
                                           L_M => OS_L_M, Ack_M => OS_Ack_M),
                          Good);
                     Put (W, Level_Order (0, D_M => Level0_D_M,
                                          Ack_M => Level0_Ack_M), Good);
                  end if;
               when Level_Back =>
                  if Pig = 0 then
                     Put (W, Level_Order (2, D_M => Level1_D_M,
                                          Ack_M => Level1_Ack_M), Good);
                  end if;
               when SR_Stop =>
                  if Pig = 0 then
                     Put (W, Stop_If_In_SR (Stop => True), Good);
                  end if;
               when Shunting_Demo =>
                  if Pig = 0 then
                     Put (W, Mode_Profile (D_M => Shunting_D_M,
                                           M_MAMODE => 1, L_M => 0,
                                           Ack_M => Shunting_Ack_M), Good);
                     Put (W, Shunting_Area_List ((1 => 6)), Good);
                  end if;
               when Text_Ack =>
                  if Pig = 0 then
                     declare
                        C : Text_Conditions_T;
                     begin
                        C.Confirm := 1;
                        Put (W, Plain_Text
                               ("Features demo: acknowledge to go on", C),
                             Good);
                     end;
                  end if;
            end case;
            Finish (W, Telegrams (B), Good);
         end;
      end loop;
      Built := True;
      Built_Preset := Preset;
   end Build;

   procedure Layout_Payload (Buffer : out Ada.Streams.Stream_Element_Array;
                             Last   : out Ada.Streams.Stream_Element_Offset)
   is
      Offset : Ada.Streams.Stream_Element_Offset := Buffer'First;
   begin
      Buffer := (others => 0);
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (EOA_M));
      Put_U8 (Buffer, Offset, Interfaces.Unsigned_8 (Release_Speed));

      Put_U8 (Buffer, Offset, MRSP'Length);
      for Seg of MRSP loop
         Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (Seg.Start_M));
         Put_U16 (Buffer, Offset, Interfaces.Unsigned_16 (Seg.Speed));
      end loop;

      Put_U8 (Buffer, Offset, EVC_Track.Gradients'Length);
      for Seg of EVC_Track.Gradients loop
         Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (Seg.Start_M));
         Put_U8 (Buffer, Offset,
                 (if Seg.Value < 0
                  then Interfaces.Unsigned_8 (256 + Seg.Value)
                  else Interfaces.Unsigned_8 (Seg.Value)));
      end loop;

      Put_U8 (Buffer, Offset, Conditions'Length);
      for C of Conditions loop
         Put_U8 (Buffer, Offset, Interfaces.Unsigned_8 (C.Announce_Symbol));
         Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (C.Announce_M));
         Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (C.Start_M));
         Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (C.End_M));
      end loop;

      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (LX_From_M));
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (LX_At_M));
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (Tunnel_Announce_M));
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (Tunnel_Start_M));
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (Tunnel_End_M));
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (Level_Ann_M));
      Put_U32 (Buffer, Offset,
               Interfaces.Unsigned_32 (Level_Transition_M));
      Put_U32 (Buffer, Offset, Interfaces.Unsigned_32 (TAF_M));
      Last := Offset - 1;
   end Layout_Payload;

end Sim_Trackside;
