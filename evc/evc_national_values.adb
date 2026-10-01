--  ETCS on-board (EVC)
--  The National Values, implementation.

package body EVC_National_Values
  with SPARK_Mode => On,
       Refined_State => (State => (In_Use, Waiting, Has_Waiting, Waiting_At))
is

   In_Use      : Set_T := Default_Set;
   Waiting     : Set_T := Default_Set;
   Has_Waiting : Boolean := False;
   Waiting_At  : Location_T;

   function Current return Set_T is (In_Use)
     with Refined_Global => In_Use;

   function Pending return Boolean is (Has_Waiting)
     with Refined_Global => Has_Waiting;

   function Pending_At return Location_T is (Waiting_At)
     with Refined_Global => Waiting_At;

   ---------------------------------------------------------------------
   --  Conversions
   ---------------------------------------------------------------------

   --  A speed of 5 km/h steps (the spare codes above 120 as 120)
   function Speed (Code : Natural) return Speed_Cms_T is
     (Kmh_To_Cms (5 * Natural'Min (Code, 120)))
     with Pre => Code <= 127;

   --  A 15 bit distance at the resolution Q_SCALE, the largest value
   --  when it is the "infinite" code 32767
   function Distance (Code : Natural; Q_SCALE : Natural;
                      Infinite : Boolean := False) return Length_T
   is (if Infinite and then Code = 32_767 then Max_Cm
       else Scaled (Code, Natural'Min (Q_SCALE, 2)))
     with Pre => Code <= 32_767;

   --  A factor of the given resolution in thousandths
   function Factor (Code : Natural; Step : Natural) return Factor_Milli_T is
     (Factor_Milli_T (Natural'Min (Code * Step, Factor_Milli_T'Last)))
     with Pre => Code <= 127 and then Step <= 50;

   --  A deceleration of 0.05 m/s² steps; "no maximum" as the largest
   function Decel (Code : Natural) return Decel_Mms2_T is
     (if Code >= 61 then Decel_Mms2_T'Last else Decel_Mms2_T (Code * 50))
     with Pre => Code <= 63;

   --  7.5.0.1 to 7.5.0.3: the special values of A_NVMAXREDADHn
   function Use_Of (Code : Natural) return Redadh_Use_T is
     (case Code is
         when 61     => Target_Information,
         when 62     => Time_To_Indication,
         when 63     => No_Limit,
         when others => Limit);

   --  L_NVKRINT (7.5.1.48.1): 0, 25, 50, 75, 100, 150, 200, then 100 m
   --  steps up to 2700 m
   function Kr_Length (Code : L_NVKRINT_T) return Length_T is
     (case Code is
         when 0 .. 4 => Metres (25 * Natural (Code)),
         when 5      => Metres (150),
         when others => Metres (100 * (Natural (Code) - 4)));

   -----------------
   -- From_Packet --
   -----------------

   function From_Packet (P : ETCS_Track_Packets.P3.Packet_T) return Set_T
   is
      S     : Set_T := Default_Set;
      Scale : constant Natural := Natural'Min (Natural (P.Q_SCALE), 2);

      --  A Kv set from the first step and the list of the others; Two
      --  takes the second factor of each step (subset "b")
      procedure Kv (V0 : V_NVKVINT_T; M0 : M_NVKVINT_T;
                    N  : N_ITER_T;
                    L  : ETCS_Track_Packets.P3.V_NVKVINT_Array;
                    Two : Boolean;
                    M0_2 : M_NVKVINT_T;
                    Set : out Kv_Set_T)
        with Global => null,
             Post => Set.Count >= 1
      is
      begin
         Set := (Count => 1, Steps => (others => (0, 1_000)));
         Set.Steps (1) := (Speed (Natural (V0)),
                           Factor (Natural (if Two then M0_2 else M0), 20));
         for I in 1 .. Natural (N) loop
            pragma Loop_Invariant (Set.Count <= I);
            exit when Set.Count = Max_Kv_Steps;
            Set.Count := Set.Count + 1;
            Set.Steps (Set.Count) :=
              (Speed (Natural (L (I).V_NVKVINT)),
               Factor (Natural (if Two then L (I).M_NVKVINT_2
                                else L (I).M_NVKVINT), 20));
         end loop;
      end Kv;

      procedure Kv_2 (V0 : V_NVKVINT_T; M0 : M_NVKVINT_T;
                      N  : N_ITER_T;
                      L  : ETCS_Track_Packets.P3.V_NVKVINT_Array_2;
                      Two : Boolean;
                      M0_2 : M_NVKVINT_T;
                      Set : out Kv_Set_T)
        with Global => null,
             Post => Set.Count >= 1
      is
      begin
         Set := (Count => 1, Steps => (others => (0, 1_000)));
         Set.Steps (1) := (Speed (Natural (V0)),
                           Factor (Natural (if Two then M0_2 else M0), 20));
         for I in 1 .. Natural (N) loop
            pragma Loop_Invariant (Set.Count <= I);
            exit when Set.Count = Max_Kv_Steps;
            Set.Count := Set.Count + 1;
            Set.Steps (Set.Count) :=
              (Speed (Natural (L (I).V_NVKVINT)),
               Factor (Natural (if Two then L (I).M_NVKVINT_2
                                else L (I).M_NVKVINT), 20));
         end loop;
      end Kv_2;

      V : National_Values_T renames S.Values;
   begin
      V.V_NVSHUNT := Speed (Natural (P.V_NVSHUNT));
      V.V_NVSTFF := Speed (Natural (P.V_NVSTFF));
      V.V_NVONSIGHT := Speed (Natural (P.V_NVONSIGHT));
      V.V_NVLIMSUPERV := Speed (Natural (P.V_NVLIMSUPERV));
      V.V_NVUNFIT := Speed (Natural (P.V_NVUNFIT));
      V.V_NVREL := Speed (Natural (P.V_NVREL));
      V.D_NVROLL := Distance (Natural (P.D_NVROLL), Scale, Infinite => True);
      V.Q_NVSBTSMPERM := P.Q_NVSBTSMPERM = 1;
      V.Q_NVEMRRLS := P.Q_NVEMRRLS = 1;
      V.Q_NVGUIPERM := P.Q_NVGUIPERM = 1;
      V.Q_NVSBFBPERM := P.Q_NVSBFBPERM = 1;
      V.Q_NVINHSMICPERM := P.Q_NVINHSMICPERM = 1;
      V.V_NVALLOWOVTRP := Speed (Natural (P.V_NVALLOWOVTRP));
      V.V_NVSUPOVTRP := Speed (Natural (P.V_NVSUPOVTRP));
      V.D_NVOVTRP := Distance (Natural (P.D_NVOVTRP), Scale);
      V.T_NVOVTRP := Time_Ms_T (Natural (P.T_NVOVTRP) * 1_000);
      V.D_NVPOTRP := Distance (Natural (P.D_NVPOTRP), Scale);
      S.M_NVCONTACT := Natural'Min (Natural (P.M_NVCONTACT), 2);
      S.T_NVCONTACT := (if P.T_NVCONTACT = 255 then Time_Ms_T'Last
                        else Time_Ms_T (Natural (P.T_NVCONTACT) * 1_000));
      S.M_NVDERUN := P.M_NVDERUN = 1;
      V.D_NVSTFF := Distance (Natural (P.D_NVSTFF), Scale, Infinite => True);
      V.Q_NVDRIVER_ADHES := P.Q_NVDRIVER_ADHES = 1;
      V.A_NVMAXREDADH1 := Decel (Natural (P.A_NVMAXREDADH1));
      V.A_NVMAXREDADH2 := Decel (Natural (P.A_NVMAXREDADH2));
      V.A_NVMAXREDADH3 := Decel (Natural (P.A_NVMAXREDADH3));
      S.Redadh_Use := (Use_Of (Natural (P.A_NVMAXREDADH1)),
                       Use_Of (Natural (P.A_NVMAXREDADH2)),
                       Use_Of (Natural (P.A_NVMAXREDADH3)));
      S.Q_NVLOCACC := Metres (Natural (P.Q_NVLOCACC));
      V.M_NVAVADH := Factor (Natural (P.M_NVAVADH), 50);
      V.M_NVEBCL := Natural'Min (Natural (P.M_NVEBCL), 9);

      --  the integrated correction factors (Q_NVKINT 1), else defaults
      if P.Q_NVKINT = 1 then
         --  the first set, then the others (N_ITER_3)
         if P.Q_NVKVINTSET = 1 then
            Kv (P.V_NVKVINT, P.M_NVKVINT, P.N_ITER_2, P.V_NVKVINT_List,
                False, P.M_NVKVINT_2, V.Kv_Int_Passenger);
            Kv (P.V_NVKVINT, P.M_NVKVINT, P.N_ITER_2, P.V_NVKVINT_List,
                True, P.M_NVKVINT_2, V.Kv_Int_Passenger_B);
            V.A_NVP12 := Decel_Mms2_T (Natural (P.A_NVP12) * 50);
            V.A_NVP23 := Decel_Mms2_T (Natural (P.A_NVP23) * 50);
         else
            Kv (P.V_NVKVINT, P.M_NVKVINT, P.N_ITER_2, P.V_NVKVINT_List,
                False, P.M_NVKVINT_2, V.Kv_Int_Fresh);
         end if;
         for K in 1 .. Natural (P.N_ITER_3) loop
            declare
               Q : ETCS_Track_Packets.P3.Q_NVKVINTSET_Item renames
                 P.Q_NVKVINTSET_List (K);
            begin
               if Q.Q_NVKVINTSET = 1 then
                  Kv_2 (Q.V_NVKVINT, Q.M_NVKVINT, Q.N_ITER, Q.V_NVKVINT_List,
                        False, Q.M_NVKVINT_2, V.Kv_Int_Passenger);
                  Kv_2 (Q.V_NVKVINT, Q.M_NVKVINT, Q.N_ITER, Q.V_NVKVINT_List,
                        True, Q.M_NVKVINT_2, V.Kv_Int_Passenger_B);
                  V.A_NVP12 := Decel_Mms2_T (Natural (Q.A_NVP12) * 50);
                  V.A_NVP23 := Decel_Mms2_T (Natural (Q.A_NVP23) * 50);
               elsif Q.Q_NVKVINTSET = 0 then
                  Kv_2 (Q.V_NVKVINT, Q.M_NVKVINT, Q.N_ITER, Q.V_NVKVINT_List,
                        False, Q.M_NVKVINT_2, V.Kv_Int_Fresh);
               end if;
            end;
         end loop;
         V.Kr_Int := (Count => 1, Steps => (others => (0, 1_000)));
         V.Kr_Int.Steps (1) :=
           (Kr_Length (P.L_NVKRINT), Factor (Natural (P.M_NVKRINT), 50));
         for I in 1 .. Natural (P.N_ITER_4) loop
            pragma Loop_Invariant (V.Kr_Int.Count <= I);
            exit when V.Kr_Int.Count = Max_Kv_Steps;
            V.Kr_Int.Count := V.Kr_Int.Count + 1;
            V.Kr_Int.Steps (V.Kr_Int.Count) :=
              (Kr_Length (P.L_NVKRINT_List (I).L_NVKRINT),
               Factor (Natural (P.L_NVKRINT_List (I).M_NVKRINT), 50));
         end loop;
         V.Kt_Int := Factor (Natural (P.M_NVKTINT), 50);
      end if;

      --  the countries: NID_C and the N_ITER others
      S.From_Trackside := True;
      S.Country_Count := 1;
      S.Countries (1) := P.NID_C;
      for I in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (S.Country_Count = I);
         S.Country_Count := S.Country_Count + 1;
         S.Countries (S.Country_Count) := P.NID_C_List (I);
      end loop;
      return S;
   end From_Packet;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      In_Use := Default_Set;
      Waiting := Default_Set;
      Has_Waiting := False;
      Waiting_At := (others => <>);
   end Clear;

   -------------
   -- Receive --
   -------------

   procedure Receive (P           : ETCS_Track_Packets.P3.Packet_T;
                      Immediate   : Boolean;
                      At_Location : Location_T)
   is
      S : constant Set_T := From_Packet (P);
   begin
      --  3.18.2.9: the one not yet applicable is deleted
      if Immediate then
         In_Use := S;
         Has_Waiting := False;
      else
         Waiting := S;
         Waiting_At := At_Location;
         Has_Waiting := True;
      end if;
   end Receive;

   -------------------
   -- Apply_Pending --
   -------------------

   procedure Apply_Pending is
   begin
      if Has_Waiting then
         In_Use := Waiting;
      end if;
      Has_Waiting := False;
   end Apply_Pending;

   --------------------
   -- Delete_Pending --
   --------------------

   procedure Delete_Pending is
   begin
      Has_Waiting := False;
   end Delete_Pending;

   -------------------
   -- Check_Country --
   -------------------

   procedure Check_Country (NID_C : NID_C_T; Reverted : out Boolean) is
   begin
      Reverted := False;
      if not In_Use.From_Trackside then
         return;
      end if;
      for I in 1 .. In_Use.Country_Count loop
         if In_Use.Countries (I) = NID_C then
            return;
         end if;
      end loop;
      In_Use := Default_Set;
      Reverted := True;
   end Check_Country;

end EVC_National_Values;
