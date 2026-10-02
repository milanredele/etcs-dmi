--  ETCS on-board (EVC)
--  The mapping tables of the SUBSET-076 runner, body.

pragma Ada_2012;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Strings.Fixed;
with EVC_DMI_Port;

package body S076_Tables is

   function Up (S : String) return String renames To_Upper;

   function Starts (S, Prefix : String) return Boolean is
     (S'Length >= Prefix'Length
      and then Up (S (S'First .. S'First + Prefix'Length - 1)) = Up (Prefix));

   function Has (S, Part : String) return Boolean is
     (Ada.Strings.Fixed.Index (Up (S), Up (Part)) > 0);

   function Same (A, B : String) return Boolean is (Up (A) = Up (B));

   ---------------------------------------------------------------------
   --  Modes and levels
   ---------------------------------------------------------------------

   function Mode_Of (Abbreviation : String) return Mode_Set_T is
      S : constant String := Up (Abbreviation);
      R : Mode_Set_T := No_Modes;
   begin
      if    S = "FS" then R (M_FS) := True;
      elsif S = "AD" then R (M_AD) := True;
      elsif S = "LS" then R (M_LS) := True;
      elsif S = "OS" then R (M_OS) := True;
      elsif S = "SR" then R (M_SR) := True;
      elsif S = "SM" then R (M_SM) := True;
      elsif S = "SH" then R (M_SH) := True;
      elsif S = "UN" then R (M_UN) := True;
      elsif S = "PS" then R (M_PS) := True;
      elsif S = "SL" then R (M_SL) := True;
      elsif S = "SB" then R (M_SB) := True;
      elsif S = "TR" then R (M_TR) := True;
      elsif S = "PT" then R (M_PT) := True;
      elsif S = "SF" then R (M_SF) := True;
      elsif S = "IS" then R (M_IS) := True;
      elsif S = "NP" then R (M_NP) := True;
      elsif S = "NL" then R (M_NL) := True;
      elsif S = "SN" then R (M_SN) := True;
      elsif S = "RV" then R (M_RV) := True;
      end if;
      return R;
   end Mode_Of;

   function Mode_Of_Symbol (Name : String) return Mode_Set_T is
      R : Mode_Set_T := No_Modes;
   begin
      if Same (Name, "Stand-By") then R (M_SB) := True;
      elsif Same (Name, "Staff-Responsible") then R (M_SR) := True;
      elsif Same (Name, "Full-Supervision") then R (M_FS) := True;
      elsif Same (Name, "Trip") then R (M_TR) := True;
      elsif Same (Name, "Shunting") then R (M_SH) := True;
      elsif Same (Name, "On-Sight") then R (M_OS) := True;
      elsif Same (Name, "Post-trip") then R (M_PT) := True;
      elsif Same (Name, "Unfitted") then R (M_UN) := True;
      elsif Same (Name, "Limited-Supervision") then R (M_LS) := True;
      elsif Same (Name, "National-System") then R (M_SN) := True;
      elsif Same (Name, "Reversing") then R (M_RV) := True;
      elsif Same (Name, "Automatic-Driving") then R (M_AD) := True;
      elsif Same (Name, "Non--leading") or else Same (Name, "Non-leading")
      then R (M_NL) := True;
      elsif Same (Name, "System-Failure") then R (M_SF) := True;
      elsif Same (Name, "Supervised-Manoeuvre") then R (M_SM) := True;
      elsif Same (Name, "Sleeping") then R (M_SL) := True;
      elsif Same (Name, "Isolation") then R (M_IS) := True;
      elsif Starts (Name, "Mode-") then
         --  "Mode-OS/LS", "Mode-SH-/-LS-/-OS", "Mode-FS-/-AD"
         declare
            Rest : constant String := Name (Name'First + 5 .. Name'Last);
            F    : Natural := Rest'First;
         begin
            for I in Rest'First .. Rest'Last + 1 loop
               if I > Rest'Last or else Rest (I) = '/' then
                  declare
                     Part : constant String := Rest (F .. I - 1);
                     A, B : Natural;
                  begin
                     --  strip the "-" around "-/-"
                     A := Part'First;
                     B := Part'Last;
                     while A <= B and then Part (A) = '-' loop
                        A := A + 1;
                     end loop;
                     while B >= A and then Part (B) = '-' loop
                        B := B - 1;
                     end loop;
                     declare
                        M : constant Mode_Set_T := Mode_Of (Part (A .. B));
                     begin
                        for X in Mode_T loop
                           R (X) := R (X) or else M (X);
                        end loop;
                     end;
                  end;
                  F := I + 1;
               end if;
            end loop;
         end;
      end if;
      return R;
   end Mode_Of_Symbol;

   function Level_Of (Name : String) return Level_Kind_T is
      S : constant String := Up (Name);
   begin
      if S = "L0" or else S = "LEVEL-0" or else S = "LEVEL-L0" then
         return K_L0;
      elsif S = "L1" or else S = "LEVEL-1" or else S = "LEVEL-L1" then
         return K_L1;
      elsif S = "L2" or else S = "LEVEL-2" or else S = "LEVEL-L2" then
         return K_L2;
      elsif S = "L3" or else S = "LEVEL-3" then
         return K_L3;
      elsif S = "LNTC" or else S = "NTC" or else S = "LEVEL-NTC"
        or else S = "LEVEL-LNTC"
      then
         return K_NTC;
      end if;
      return K_None;
   end Level_Of;

   function Mode_Of_M_MODE (Value : Natural; Mode : out Mode_T)
     return Boolean is
   begin
      Mode := M_NP;
      case Value is
         when 0  => Mode := M_FS;
         when 1  => Mode := M_OS;
         when 2  => Mode := M_SR;
         when 3  => Mode := M_SH;
         when 4  => Mode := M_UN;
         when 5  => Mode := M_SL;
         when 6  => Mode := M_SB;
         when 7  => Mode := M_TR;
         when 8  => Mode := M_PT;
         when 9  => Mode := M_SF;
         when 10 => Mode := M_IS;
         when 11 => Mode := M_NL;
         when 12 => Mode := M_LS;
         when 13 => Mode := M_SN;
         when 14 => Mode := M_RV;
         when 15 => Mode := M_PS;
         when 16 => Mode := M_AD;
         when 17 => Mode := M_SM;
         when others => return False;
      end case;
      return True;
   end Mode_Of_M_MODE;

   function DMI_Code (Mode : Mode_T) return Natural is
     (if EVC_DMI_Port.Has_Mode_Code (Mode)
      then Natural (EVC_DMI_Port.Mode_Code (Mode)) else 16#FF#);

   ---------------------------------------------------------------------
   --  DMI objects
   ---------------------------------------------------------------------

   function L (Items : Number_List_T; Count : Natural) return Numbers_T is
     ((Count => Count, List => Items));

   function N1 (A : Natural) return Numbers_T is
     (L ((1 => A, others => 0), 1));
   function N2 (A, B : Natural) return Numbers_T is
     (L ((1 => A, 2 => B, others => 0), 2));
   function N3 (A, B, C : Natural) return Numbers_T is
     (L ((1 => A, 2 => B, 3 => C, others => 0), 3));
   function N4 (A, B, C, D : Natural) return Numbers_T is
     (L ((1 => A, 2 => B, 3 => C, 4 => D, others => 0), 4));

   function SS_Entries (Name : String) return Numbers_T is
   begin
      if Same (Name, "Trip-reason") then
         --  the entries of a trip reason (dmi_protocol.ads)
         return L ((2, 5, 13, 16, 21, 22, 23, 24, 25, 26, 29, others => 0),
                   11);
      elsif Same (Name, "Balise-read-error") then return N2 (1, 2);
      elsif Same (Name, "Trackside-malfunction") then return N1 (3);
      elsif Same (Name, "Communication-error") then return N2 (4, 5);
      elsif Same (Name, "Entering-FS") then return N1 (6);
      elsif Same (Name, "Entering-OS") then return N1 (7);
      elsif Same (Name, "Entering-SM") then return N1 (8);
      elsif Same (Name, "Runaway-movement") then return N1 (9);
      elsif Same (Name, "SM-refused") then return N1 (10);
      elsif Same (Name, "SM-request-failed") then return N1 (11);
      elsif Same (Name, "SH-refused") then return N2 (12, 13);
      elsif Same (Name, "SH-request-failed") then return N1 (14);
      elsif Same (Name, "Trackside-not-compatible") then return N2 (15, 16);
      elsif Same (Name, "Train-data-changed") then return N2 (17, 18);
      elsif Same (Name, "Safe-consist-length-no-longer-available") then
         return N1 (19);
      elsif Same (Name, "Train-is-rejected") then return N1 (20);
      elsif Same (Name, "Emergency-stop") then return N1 (26);
      elsif Same (Name, "RV-distance-exceeded") then return N1 (27);
      elsif Same (Name, "PT-distance-exceeded") then return N1 (28);
      elsif Has (Name, "Route-unsuitable") then
         if Has (Name, "loading-gauge") then return N1 (30);
         elsif Has (Name, "traction") then return N1 (31);
         elsif Has (Name, "axle-load") then return N1 (32);
         else return N3 (30, 31, 32);
         end if;
      elsif Same (Name, "FRMCS-network-registration-failed") then
         return N1 (33);
      elsif Same (Name, "GSM-R-network-registration-failed") then
         return N1 (34);
      elsif Same (Name, "Radio-network-registration-failed") then
         return N2 (33, 34);
      elsif Has (Name, "NL-no-longer") or else Has (Name, "Non-leading")
      then return N1 (35);
      elsif Same (Name, "Odometer-impaired") then return N1 (36);
      elsif Same (Name, "ATO-needs-data") then return N1 (37);
      end if;
      return (others => <>);
   end SS_Entries;

   function TC_Kinds (Name : String) return Numbers_T is
      Ann : constant Boolean := Has (Name, "announcement");
   begin
      if Same (Name, "LX-not-protected") then return N1 (38);
      elsif Same (Name, "Pantograph-lowered") then return N1 (1);
      elsif Same (Name, "Lower-Pantograph") then return N2 (2, 3);
      elsif Same (Name, "Raise-Pantograph") then return N2 (4, 5);
      elsif Starts (Name, "Neutral-Section") then
         return (if Ann then N2 (6, 7) else N1 (6));
      elsif Same (Name, "End-of-Neutral-Section") then return N2 (8, 9);
      elsif Starts (Name, "Non-stopping-area") then
         return (if Ann then N2 (10, 11) else N1 (10));
      elsif Same (Name, "Radio-hole") then return N1 (12);
      elsif Starts (Name, "Inhibition-of-magnetic-shoe-brake") then
         return (if Ann then N2 (13, 14) else N1 (13));
      elsif Starts (Name, "Inhibition-of-eddy-current-brake") then
         return (if Ann then N2 (15, 16) else N1 (15));
      elsif Starts (Name, "Inhibition-of-regenerative-brake") then
         return (if Ann then N2 (17, 18) else N1 (17));
      elsif Same (Name, "Air-conditioning-intake-closed") then
         return N1 (19);
      elsif Same (Name, "Close-air-conditioning-intake-announcement") then
         return N2 (19, 21);
      elsif Same (Name, "Open-air-conditioning-intake") then
         return N2 (20, 22);
      elsif Starts (Name, "Change-of-traction-system:-not-fitted-line") then
         return (if Ann then N2 (23, 24) else N1 (23));
      elsif Starts (Name, "Change-of-traction-system:-AC-25-kV-50-Hz") then
         return (if Ann then N2 (25, 26) else N1 (25));
      elsif Starts (Name, "Change-of-traction-system:-AC-15-kV-16.7-Hz")
      then
         return (if Ann then N2 (27, 28) else N1 (27));
      elsif Same (Name, "Sound-horn") then return N1 (35);
      elsif Starts (Name, "Tunnel-stopping-area") then
         return (if Ann then N1 (37) else N1 (36));
      end if;
      return (others => <>);
   end TC_Kinds;

   function TIU_TC_Kinds (Name : String) return Numbers_T is
   begin
      if Same (Name, "Station-Platforms") then return N1 (10);
      elsif Same (Name, "Change-of-allowed-current-consumption") then
         return N1 (9);
      elsif Same (Name, "Brakes-Inhibition-with-distance") then
         return N4 (4, 5, 6, 7);
      end if;
      return (others => <>);
   end TIU_TC_Kinds;

   ---------------------------------------------------------------------
   --  JRU
   ---------------------------------------------------------------------

   function Proposed (M : Mode_T) return Fact_T is
     ((Kind => Mode_Proposed, Mode => M, others => <>));
   function Acked (M : Mode_T) return Fact_T is
     ((Kind => Mode_Acked, Mode => M, others => <>));
   function Event (E : Natural; Sub : Integer := -1; B3 : Integer := -1)
     return Fact_T is
     ((Kind => Event_Seen, Event => E, Sub => Sub, B3 => B3, others => <>));
   None : constant Fact_T := (others => <>);

   function Driver_Action_Fact (Code : Natural) return Fact_T is
   begin
      case Code is
         when 0  => return Acked (M_OS);
         when 1  => return Acked (M_SH);
         when 2  => return Acked (M_TR);
         when 3  => return Acked (M_SR);
         when 4  => return Acked (M_UN);
         when 5  => return Acked (M_RV);
         when 6  => return Event (40, 5, Level_T'Pos (L0));
         when 10 => return Event (40, 5, Level_T'Pos (NTC));
         when 13 => return Acked (M_LS);
         when 14 => return Event (23, 2);
         when 15 => return Event (41, 12, 1);
         when 18 => return (Kind => Mode_Is, Mode => M_IS, others => <>);
         when 19 => return Event (41, 5);
         when 21 => return Event (41, 3);
         when 28 => return Acked (M_SN);
         when 34 => return Event (40, 1, Level_T'Pos (L0));
         when 35 => return Event (40, 1, Level_T'Pos (L1));
         when 36 => return Event (40, 1, Level_T'Pos (L2));
         when 38 => return Event (40, 1, Level_T'Pos (NTC));
         when 49 => return Event (23, 9, 1);
         when 50 => return Event (23, 9, 0);
         when others => return None;
      end case;
   end Driver_Action_Fact;

   function Symbol_Fact (Bit : Natural; On : Boolean) return Fact_T is
      function Is_Mode (M : Mode_T) return Fact_T is
        ((Kind => (if On then Mode_Is else Mode_Is_Not), Mode => M,
          others => <>));
      function Ack_Of (M : Mode_T) return Fact_T is
        (if On then Proposed (M) else Acked (M));
      function Level (V : Level_T) return Fact_T is
        (if On then (Kind => Level_Is, Level => V, others => <>) else None);
   begin
      case Bit is
         when 1  => return Level (L0);
         when 2  => return Level (NTC);
         when 3  => return Level (L1);
         when 4  => return Level (L2);
         --  LE06 / LE07: level 0 announced / its acknowledgement asked;
         --  LE08 / LE09 NTC; LE10 level 1, LE12 level 2 announced
         when 6  => return (if On then Event (40, 2, Level_T'Pos (L0))
                            else None);
         when 7  => return (if On then Event (40, 4, Level_T'Pos (L0))
                            else Event (40, 5, Level_T'Pos (L0)));
         when 8  => return (if On then Event (40, 2, Level_T'Pos (NTC))
                            else None);
         when 9  => return (if On then Event (40, 4, Level_T'Pos (NTC))
                            else Event (40, 5, Level_T'Pos (NTC)));
         when 10 => return (if On then Event (40, 2, Level_T'Pos (L1))
                            else None);
         when 12 => return (if On then Event (40, 2, Level_T'Pos (L2))
                            else None);
         when 14 => return Is_Mode (M_AD);
         when 15 => return Is_Mode (M_SM);
         when 16 => return Is_Mode (M_SH);
         when 17 => return Ack_Of (M_SH);
         when 18 => return Event (23, (if On then 2 else 3));
         when 19 => return Is_Mode (M_TR);
         when 20 => return Ack_Of (M_TR);
         when 21 => return Is_Mode (M_PT);
         when 22 => return Is_Mode (M_OS);
         when 23 => return Ack_Of (M_OS);
         when 24 => return Is_Mode (M_SR);
         when 25 => return Ack_Of (M_SR);
         when 26 => return Is_Mode (M_FS);
         when 27 => return Is_Mode (M_NL);
         when 28 => return Is_Mode (M_SB);
         when 29 => return Is_Mode (M_RV);
         when 30 => return Ack_Of (M_RV);
         when 31 => return Is_Mode (M_UN);
         when 32 => return Ack_Of (M_UN);
         when 33 => return Is_Mode (M_SF);
         when 34 => return Is_Mode (M_SN);
         when 35 => return Ack_Of (M_SN);
         when 36 => return Is_Mode (M_LS);
         when 37 => return Ack_Of (M_LS);
         --  ST01: a brake commanded by the on-board, or none
         when 38 => return (Kind => Brakes_Shown,
                            Value => (if On then 1 else 0), others => <>);
         --  ST07: BMM reaction inhibition
         when 88 => return Event (23, 9, (if On then 1 else 0));
         when others => return None;
      end case;
   end Symbol_Fact;

   function Trips (A : Natural; B : Natural := 99; C : Natural := 99)
     return Fact_T
   is
      F : Fact_T := (Kind => Trip_Reason, others => <>);
   begin
      F.B3_List.Count := 1;
      F.B3_List.List (1) := A;
      if B /= 99 then
         F.B3_List.Count := 2;
         F.B3_List.List (2) := B;
      end if;
      if C /= 99 then
         F.B3_List.Count := 3;
         F.B3_List.List (3) := C;
      end if;
      return F;
   end Trips;

   function System_Status_Fact (Bit : Natural; On : Boolean) return Fact_T is
   begin
      if not On then
         return None;
      end if;
      --  the trip reasons (EVC_Procedures.Trip_Reason_T'Pos)
      case Bit is
         when 1  => return Trips (4, 5);        -- Balise read error
         when 9  => return Trips (9);           -- Trackside not compatible
         when 10 => return Event (23, 11);      -- Train data changed
         when 12 => return Trips (1, 2, 3);     -- Unauthorized passing
         when 13 => return Trips (12);          -- No MA at level transition
         when 14 => return Trips (11);          -- SR distance exceeded
         when 15 => return Trips (6, 7);        -- SH stop order
         when 16 => return Trips (8);           -- SR stop order
         when 18 => return Event (23, 8, 4);    -- RV distance exceeded
         when 19 => return Trips (10);          -- No track description
         when 25 => return Event (23, 10);      -- PT distance exceeded
         when 26 => return Event (41, 13);      -- NL no longer permitted
         when 27 => return Event (7, 1);        -- Odometer impaired
         when others => return None;
      end case;
   end System_Status_Fact;

   function Message_Event (NID_Message_JRU : Natural) return JRU_Map_T is
   begin
      case NID_Message_JRU is
         when 2  => return (Event => 41, Sub => 3, B4 => -1, Known => True);
         when 6  => return (Event => 2, Sub => -1, B4 => -1, Known => True);
         when 9  => return (Event => 3, Sub => -1, B4 => -1, Known => True);
         when 15 => return (Event => 9, Sub => -1, B4 => -1, Known => True);
         when 16 => return (Event => 24, Sub => 1, B4 => 0, Known => True);
         when 17 => return (Event => 24, Sub => 2, B4 => 0, Known => True);
         when 18 => return (Event => 24, Sub => 1, B4 => 1, Known => True);
         when 19 => return (Event => 24, Sub => 2, B4 => 1, Known => True);
         when 20 => return (Event => 21, Sub => -1, B4 => -1, Known => True);
         when 25 => return (Event => 41, Sub => 11, B4 => -1, Known => True);
         when 49 => return (Event => 41, Sub => 2, B4 => -1, Known => True);
         when 52 => return (Event => 7, Sub => -1, B4 => -1, Known => True);
         when others => return (others => <>);
      end case;
   end Message_Event;

   function Table_Sizes return String is
      Actions, Symbols, Statuses, Messages : Natural := 0;
   begin
      for C in 0 .. 255 loop
         if Driver_Action_Fact (C).Kind /= No_Fact then
            Actions := Actions + 1;
         end if;
         if Message_Event (C).Known then
            Messages := Messages + 1;
         end if;
      end loop;
      for B in 1 .. 110 loop
         if Symbol_Fact (B, True).Kind /= No_Fact then
            Symbols := Symbols + 1;
         end if;
         if B <= 31 and then System_Status_Fact (B, True).Kind /= No_Fact then
            Statuses := Statuses + 1;
         end if;
      end loop;
      return "JRU: M_DRIVERACTIONS" & Actions'Image & " of 56,"
        & " DMI_SYMB_STATUS bits" & Symbols'Image & " of 110,"
        & " SYSTEM_STATUS_MESSAGE bits" & Statuses'Image & " of 31,"
        & " whole messages" & Messages'Image
        & " (plus 3, 4, 11, 12, 20, 21, 23, 43 and ALL by their fields)";
   end Table_Sizes;

end S076_Tables;
