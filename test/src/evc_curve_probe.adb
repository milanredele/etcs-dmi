--  evc_curve_probe: the locations of the on-board's supervision limits
--  before a target, measured on the whole on-board (EVC_Core through
--  EVC_Test_Support): a train is placed at a constant speed at a
--  distance before the target, the core runs four cycles, and the
--  distance where the supervision status of MSG_SPEED_STATE reaches
--  Indication, Overspeed (the Permitted limit), Warning, Intervention
--  (the SBI) and where the emergency brake is commanded (the EBI) is
--  bisected to the metre. Host only (B174).
--
--  Arguments, key=value, every one optional:
--    lambda=109 length=750 pos=pp|fp|fg vmax=200 tco=0.5 (s)
--    target=2300 (m from the origin of the gradient profile)
--    loa=30 (km/h: a target speed at the target; else an EOA)
--    svl=450 (m beyond the EOA) release=30 (km/h, EOA only; a release
--      speed calculated on-board is given here as its value)
--    grad=0:0,1000:-5 (start m : gradient per mille, positive uphill)
--    kv=0:0.96,100:0.9 (km/h : factor, freight / all trains)
--    kvp=... (passenger set, same form) kr=0:1.0,250:0.9 (m : factor)
--    kt=1.0 ebcl=9 inhsmic=0|1 gui=0|1 sbtsm=0|1
--    adhesion=1400:2350 (m: one reduced adhesion area) redadh=0.7
--      (m/s2: A_NVMAXREDADH1 .. 3 alike)
--    ci=0 (m: the confidence interval, max safe front end = estimated
--      front end + ci, min safe front end = estimated front end - ci)
--    vura=0|f41|<km/h> (V_max - V_est the odometer reports: f41 the
--      speed accuracy of SUBSET-041, 2 km/h up to 30 km/h, then up to
--      12 km/h at 500 km/h)
--    ceiling=<km/h> (the MRSP, default the highest speed + 20)
--    speeds=50,55,60
--    drive=<m> (B195: instead of the bisection, a continuous run at the
--      highest speed from <m> before the target, the state carried
--      from cycle to cycle; one line per change: distance, status,
--      V_Perm, V_SBI, target speed @ distance / 10, monitoring, SB, EB)
--    dip=<m>:<km/h> (with drive: the speed of the one cycle where the
--      train passes <m>, as the SUBSET-076 runner's last cycle before a
--      location reports it)
--  Output: one line per speed: the distances (m) from the max safe
--  front end to the target of I, P, W, SBI, EBI, the same from the
--  estimated front end, and V_Perm / V_SBI displayed (km/h) with the
--  train on the Permitted limit (3.13.9.3.5.7). -1: above the limit
--  everywhere up to 6000 m; -2: not even at the target.
with Ada.Text_IO;      use Ada.Text_IO;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Strings.Fixed;
with Interfaces;       use Interfaces;
with EVC_Test_Support; use EVC_Test_Support;
with EVC_Supervision_Input;
with EVC_Distances;
with EVC_Limits;
with EVC_Fixed;

procedure EVC_Curve_Probe is
   package SIn renames EVC_Supervision_Input;

   --  the target sits Shift beyond its given distance, so that the
   --  train is never behind the origin of the coordinates
   Shift_M : constant := 10_000;
   Max_D_M : constant := 6_000;

   Base     : SIn.Snapshot_T := Base_Snapshot;
   Target_M : Integer := 2_000;
   LOA_Kmh  : Integer := -1;
   SvL_M    : Integer := 0;
   Rel_Kmh  : Long_Float := 0.0;
   CI_Cm    : Integer_64 := 0;
   Vura     : Integer := 0;        -- cm/s; -1: SUBSET-041
   Ceiling  : Integer := -1;
   Speeds   : String (1 .. 400) := (others => ' ');
   Speeds_L : Natural := 0;
   Drive_M  : Integer := -1;      -- drive=<m>: a continuous run from there
   Dip_M    : Integer := -1;      -- dip=<m>:<km/h>: one cycle's speed
   Dip_V    : Natural := 0;

   function To_LF (S : String) return Long_Float is
     (Long_Float'Value
        (if Ada.Strings.Fixed.Index (S, ".") = 0 then S & ".0" else S));
   function Milli (S : String) return Natural is
     (Natural (To_LF (S) * 1_000.0));
   function Img (N : Integer) return String is
     (Ada.Strings.Fixed.Trim (Integer'Image (N), Ada.Strings.Left));

   --  The pairs "a:b,c:d" of a list, one at a time
   procedure Next_Pair (S : String; From : in out Positive;
                        A, B : out Long_Float) is
      Comma : Natural := Ada.Strings.Fixed.Index (S, ",", From);
      Colon : Natural;
   begin
      if Comma = 0 then
         Comma := S'Last + 1;
      end if;
      Colon := Ada.Strings.Fixed.Index (S (From .. Comma - 1), ":");
      A := To_LF (S (From .. Colon - 1));
      B := To_LF (S (Colon + 1 .. Comma - 1));
      From := Comma + 1;
   end Next_Pair;

   function Kv_Of (S : String) return SIn.Kv_Set_T is
      R    : SIn.Kv_Set_T;
      From : Positive := S'First;
      A, B : Long_Float;
   begin
      while From <= S'Last and then R.Count < SIn.Max_Kv_Steps loop
         Next_Pair (S, From, A, B);
         R.Count := R.Count + 1;
         R.Steps (R.Count) := (Cms (A), Natural (B * 1_000.0));
      end loop;
      return R;
   end Kv_Of;

   function Kr_Of (S : String) return SIn.Kr_Set_T is
      R    : SIn.Kr_Set_T;
      From : Positive := S'First;
      A, B : Long_Float;
   begin
      while From <= S'Last and then R.Count < SIn.Max_Kv_Steps loop
         Next_Pair (S, From, A, B);
         R.Count := R.Count + 1;
         R.Steps (R.Count) :=
           (EVC_Distances.Length_T (A * 100.0), Natural (B * 1_000.0));
      end loop;
      return R;
   end Kr_Of;

   --  the gradient profile, shifted; its first segment reaches back to 0
   procedure Set_Gradient (S : String) is
      G    : SIn.Gradient_Profile_T renames Base.Gradients;
      From : Positive := S'First;
      A, B : Long_Float;
   begin
      G.Count := 0;
      while From <= S'Last and then G.Count < SIn.Max_Gradient_Segments
      loop
         Next_Pair (S, From, A, B);
         G.Count := G.Count + 1;
         G.Segments (G.Count) :=
           (Start    => (if G.Count = 1 then 0
                         else EVC_Distances.Cm_T ((A + Long_Float (Shift_M))
                                                  * 100.0)),
            Gradient => Integer (B));
      end loop;
   end Set_Gradient;

   procedure Set (Key, Value : String) is
      TD : SIn.Train_Data_T renames Base.Train_Data;
      NV : SIn.National_Values_T renames Base.National;
   begin
      if Key = "lambda" then
         TD.Brake_Percentage := Integer'Value (Value);
      elsif Key = "length" then
         TD.Length := EVC_Distances.Length_T (To_LF (Value) * 100.0);
      elsif Key = "pos" then
         TD.Brake_Position :=
           (if Value = "pp" then SIn.Passenger_P
            elsif Value = "fp" then SIn.Freight_P else SIn.Freight_G);
      elsif Key = "vmax" then
         TD.Max_Speed := Cms (To_LF (Value));
      elsif Key = "tco" then
         TD.T_Traction_Cut_Off := Milli (Value);
      elsif Key = "target" then
         Target_M := Integer'Value (Value);
      elsif Key = "drive" then
         Drive_M := Integer'Value (Value);
      elsif Key = "dip" then
         declare
            Colon : constant Natural := Ada.Strings.Fixed.Index (Value, ":");
         begin
            Dip_M := Integer'Value (Value (Value'First .. Colon - 1));
            Dip_V := Cms (To_LF (Value (Colon + 1 .. Value'Last)));
         end;
      elsif Key = "loa" then
         LOA_Kmh := Integer'Value (Value);
      elsif Key = "svl" then
         SvL_M := Integer'Value (Value);
      elsif Key = "release" then
         Rel_Kmh := To_LF (Value);
      elsif Key = "grad" then
         Set_Gradient (Value);
      elsif Key = "kv" then
         NV.Kv_Int_Fresh := Kv_Of (Value);
      elsif Key = "kvp" then
         NV.Kv_Int_Passenger := Kv_Of (Value);
      elsif Key = "kr" then
         NV.Kr_Int := Kr_Of (Value);
      elsif Key = "kt" then
         NV.Kt_Int := Milli (Value);
      elsif Key = "ebcl" then
         NV.M_NVEBCL := Integer'Value (Value);
      elsif Key = "inhsmic" then
         NV.Q_NVINHSMICPERM := Value = "1";
      elsif Key = "adhesion" then
         --  one reduced adhesion area from:to (m, B192)
         declare
            A, B : Long_Float;
            From : Positive := Value'First;
         begin
            Next_Pair (Value, From, A, B);
            Base.Adhesion.Count := 1;
            Base.Adhesion.Areas (1) :=
              (Start  => EVC_Distances.Cm_T ((A + Long_Float (Shift_M)) * 100.0),
               Finish => EVC_Distances.Cm_T ((B + Long_Float (Shift_M)) * 100.0));
         end;
      elsif Key = "redadh" then
         --  A_NVMAXREDADH1 .. 3 alike, m/s2
         NV.A_NVMAXREDADH1 := Milli (Value);
         NV.A_NVMAXREDADH2 := Milli (Value);
         NV.A_NVMAXREDADH3 := Milli (Value);
      elsif Key = "sbtsm" then
         NV.Q_NVSBTSMPERM := Value = "1";
      elsif Key = "gui" then
         NV.Q_NVGUIPERM := Value = "1";
      elsif Key = "ci" then
         CI_Cm := Integer_64 (To_LF (Value) * 100.0);
      elsif Key = "vura" then
         Vura := (if Value = "f41" then -1 else Cms (To_LF (Value)));
      elsif Key = "ceiling" then
         Ceiling := Integer'Value (Value);
      elsif Key = "speeds" then
         Speeds_L := Value'Length;
         Speeds (1 .. Speeds_L) := Value;
      else
         Put_Line (Standard_Error, "evc_curve_probe: unknown key " & Key);
         Set_Exit_Status (Failure);
      end if;
   end Set;

   Target_Cm : Integer_64;

   --  The supervision level with the max safe front end D_M metres
   --  before the target at V km/h: 0 none, 1 Indication, 2 Overspeed,
   --  3 Warning, 4 Intervention, 5 the emergency brake commanded
   function Level_At (D_M : Integer; V_Kmh : Integer) return Natural is
      S  : SIn.Snapshot_T := Base;
      V  : constant SIn.Speed_Cms_T := Cms (Long_Float (V_Kmh));
      Vu : constant Integer :=
        (if Vura < 0 then Integer (EVC_Limits.F41 (EVC_Fixed.Speed_T (V)))
         else Vura);
   begin
      Place (S, Target_Cm - Integer_64 (D_M) * 100 - CI_Cm, V, CI_Cm);
      S.Train.Speed_Max := Natural'Min (V + Vu, SIn.Speed_Cms_T'Last);
      Sup_Start (S);
      for K in 1 .. 3 loop
         Sup_Cycle;
      end loop;
      return (if Cmd.EB then 5 else Natural'Min (Speed_Frame.Status, 4));
   end Level_At;

   --  The largest D (m before the target) with the level reached: the
   --  level rises as D falls
   function Limit_Of (Level : Natural; V_Kmh : Integer) return Integer is
      Lo : Integer := 0;
      Hi : Integer := Max_D_M;
   begin
      if Level_At (Hi, V_Kmh) >= Level then
         return -1;
      elsif Level_At (Lo, V_Kmh) < Level then
         return -2;
      end if;
      while Hi - Lo > 1 loop
         declare
            Mid : constant Integer := (Lo + Hi) / 2;
         begin
            if Level_At (Mid, V_Kmh) >= Level then
               Lo := Mid;
            else
               Hi := Mid;
            end if;
         end;
      end loop;
      return Lo;
   end Limit_Of;

   procedure Probe (V_Kmh : Integer) is
      L      : array (1 .. 5) of Integer;
      Line   : String (1 .. 200) := (others => ' ');
      Last   : Natural := 0;
      CI_M   : constant Integer := Integer (CI_Cm / 100);
      procedure Add (S : String) is
      begin
         Line (Last + 1 .. Last + S'Length + 1) := ' ' & S;
         Last := Last + S'Length + 1;
      end Add;
   begin
      for K in L'Range loop
         L (K) := Limit_Of (K, V_Kmh);
      end loop;
      Add (Img (V_Kmh));
      for K in L'Range loop
         Add (Img (L (K)));
      end loop;
      Add ("|");
      for K in L'Range loop
         Add (Img (if L (K) < 0 then L (K) else L (K) + CI_M));
      end loop;
      Add ("|");
      if L (2) >= 0 and then Level_At (L (2), V_Kmh) >= 2 then
         Add (Img (Speed_Frame.V_Perm));
         Add (Img (Speed_Frame.V_SBI));
      else
         Add ("- -");
      end if;
      Put_Line (Line (2 .. Last));
   end Probe;

   --  drive=<m>: the train at the highest speed from D metres before the
   --  target, moved on every 100 ms cycle at that speed (the state
   --  carried from cycle to cycle, as in a run), one line per change
   --  of the status or the shown speeds: D (max safe front end to the
   --  target, m), the status, V_Perm, V_SBI, the target speed and
   --  distance shown, the SB and EB commands
   procedure Drive (V_Kmh : Integer) is
      S   : SIn.Snapshot_T := Base;
      V   : constant SIn.Speed_Cms_T := Cms (Long_Float (V_Kmh));
      Vu  : constant Integer :=
        (if Vura < 0 then Integer (EVC_Limits.F41 (EVC_Fixed.Speed_T (V)))
         else Vura);
      At_Cm : Integer_64 := Target_Cm - Integer_64 (Drive_M) * 100 - CI_Cm;
      Last  : String (1 .. 60) := (others => ' ');
   begin
      Place (S, At_Cm, V, CI_Cm);
      S.Train.Speed_Max := Natural'Min (V + Vu, SIn.Speed_Cms_T'Last);
      Sup_Start (S);
      while At_Cm < Target_Cm loop
         At_Cm := At_Cm + Integer_64 (V) / 10;
         Place (Sup, At_Cm, V, CI_Cm);
         Sup.Train.Speed_Max := S.Train.Speed_Max;
         if Dip_M >= 0 and then Target_Cm - At_Cm - CI_Cm <= Integer_64 (Dip_M) * 100
         then
            --  the speed of one cycle only, the position moving on (the
            --  runner's last cycle before a location, B195)
            Sup.Train.Speed := Dip_V;
            Sup.Train.Speed_Max := Dip_V;
            Dip_M := -1;
         end if;
         Sup_Cycle;
         declare
            Now : String (1 .. 60) := (others => ' ');
            T   : constant String :=
              Img (Natural'Min (Speed_Frame.Status, 9)) & " "
              & Img (Speed_Frame.V_Perm) & " " & Img (Speed_Frame.V_SBI)
              & " t" & Img (Speed_Frame.V_Target) & "@"
              & Img (Speed_Frame.D_Target / 10) & " m" & Img (Speed_Frame.Monitoring)
              & (if Cmd.SB then " SB" else "")
              & (if Cmd.EB then " EB" else "");
         begin
            Now (1 .. T'Length) := T;
            if Now /= Last then
               Put_Line (Img (Integer ((Target_Cm - At_Cm - CI_Cm) / 100))
                         & " " & T);
               Last := Now;
            end if;
         end;
         exit when Cmd.EB;
      end loop;
   end Drive;

   Top : Integer := 0;
begin
   Base.Train_Data.Max_Speed := Cms (200.0);
   Base.Train_Data.T_Traction_Cut_Off := 500;
   Base.National.Kt_Int := 1_000;
   for N in 1 .. Argument_Count loop
      declare
         A  : constant String := Argument (N);
         Eq : constant Natural := Ada.Strings.Fixed.Index (A, "=");
      begin
         if Eq = 0 then
            Put_Line (Standard_Error, "evc_curve_probe: key=value: " & A);
            Set_Exit_Status (Failure);
            return;
         end if;
         Set (A (A'First .. Eq - 1), A (Eq + 1 .. A'Last));
      end;
   end loop;
   Target_Cm := Integer_64 (Target_M + Shift_M) * 100;
   declare
      From : Positive := 1;
      Comma : Natural;
   begin
      while From <= Speeds_L loop
         Comma := Ada.Strings.Fixed.Index (Speeds (1 .. Speeds_L), ",", From);
         Comma := (if Comma = 0 then Speeds_L + 1 else Comma);
         Top := Integer'Max (Top, Integer'Value (Speeds (From .. Comma - 1)));
         From := Comma + 1;
      end loop;
   end;
   Base.MRSP.Count := 1;
   Base.MRSP.Segments (1) :=
     (Start => 0,
      Speed => Cms (Long_Float (if Ceiling > 0 then Ceiling else Top + 20)));
   Base.MA :=
     (Present       => True,
      EOA           => EVC_Distances.Cm_T (Target_Cm),
      SvL           => EVC_Distances.Cm_T (Target_Cm + Integer_64 (SvL_M) * 100),
      LOA_Speed     => (if LOA_Kmh >= 0 then Cms (Long_Float (LOA_Kmh)) else 0),
      Release_Speed =>
        (if LOA_Kmh < 0 and then Rel_Kmh > 0.0
         then (Kind => SIn.Fixed, Speed => Cms (Rel_Kmh))
         else (Kind => SIn.None, Speed => 0)));
   if Drive_M >= 0 then
      Drive (Top);
      return;
   end if;
   Put_Line ("# V_kmh  I P W SBI EBI (max safe front end to the target, m)"
             & " | the same from the estimated front end"
             & " | V_Perm V_SBI shown on P (km/h)");
   declare
      From : Positive := 1;
      Comma : Natural;
   begin
      while From <= Speeds_L loop
         Comma := Ada.Strings.Fixed.Index (Speeds (1 .. Speeds_L), ",", From);
         Comma := (if Comma = 0 then Speeds_L + 1 else Comma);
         Probe (Integer'Value (Speeds (From .. Comma - 1)));
         From := Comma + 1;
      end loop;
   end;
end EVC_Curve_Probe;
