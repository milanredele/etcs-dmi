--  ETCS on-board (EVC)
--  The track description the on-board stores, implementation.

with EVC_Location; use EVC_Location;

package body EVC_Track_Description
  with SPARK_Mode => On,
       Refined_State => (State => (SSP_S, Grad_S, ASP_S, TSR_S, Adh_S,
                                   PBD_S, Grad_Default_Known, Grad_Default,
                                   LX_S, LX_Sense_S, Suit_S, Lost_N))
is

   SSP_S              : Store_T := Empty_Store;
   Grad_S             : Store_T := Empty_Store;
   ASP_S              : Store_T := Empty_Store;
   TSR_S              : Store_T := Empty_Store;
   Adh_S              : Store_T := Empty_Store;
   PBD_S              : Store_T := Empty_Store;
   Grad_Default_Known : Boolean := False;
   Grad_Default       : Gradient_T := 0;
   LX_S               : LX_Array_T;
   LX_Sense_S         : Sense_T := Plus;
   Suit_S             : Suitability_Array_T;
   Lost_N             : Natural := 0;

   function SSP return Store_T is (SSP_S)
     with Refined_Global => SSP_S;
   function Gradients return Store_T is (Grad_S)
     with Refined_Global => Grad_S;
   function ASP return Store_T is (ASP_S)
     with Refined_Global => ASP_S;
   function TSR return Store_T is (TSR_S)
     with Refined_Global => TSR_S;
   function Adhesion_Store return Store_T is (Adh_S)
     with Refined_Global => Adh_S;
   function PBD return Store_T is (PBD_S)
     with Refined_Global => PBD_S;
   function SSP_Count return Natural is (SSP_S.Count)
     with Refined_Global => SSP_S;
   function Gradients_Count return Natural is (Grad_S.Count)
     with Refined_Global => Grad_S;
   function TSR_Count return Natural is (TSR_S.Count)
     with Refined_Global => TSR_S;
   function Default_Gradient_Known return Boolean is (Grad_Default_Known)
     with Refined_Global => Grad_Default_Known;
   function Default_Gradient return Gradient_T is (Grad_Default)
     with Refined_Global => Grad_Default;
   function LX return LX_Array_T is (LX_S)
     with Refined_Global => LX_S;
   function LX_Item (I : Positive) return LX_T is (LX_S (I))
     with Refined_Global => LX_S;
   function LX_Sense return Sense_T is (LX_Sense_S)
     with Refined_Global => LX_Sense_S;
   function Suitability return Suitability_Array_T is (Suit_S)
     with Refined_Global => Suit_S;

   function Lost return Natural
     with Refined_Global => (SSP_S, Grad_S, ASP_S, TSR_S, Adh_S, PBD_S,
                             Lost_N)
   is
      N : Natural := Lost_N;

      procedure Plus (X : Natural) is
      begin
         N := (if Natural'Last - N < X then Natural'Last else N + X);
      end Plus;
   begin
      Plus (SSP_S.Lost);
      Plus (Grad_S.Lost);
      Plus (ASP_S.Lost);
      Plus (TSR_S.Lost);
      Plus (Adh_S.Lost);
      Plus (PBD_S.Lost);
      return N;
   end Lost;

   procedure Count_Lost is
   begin
      if Lost_N < Natural'Last then
         Lost_N := Lost_N + 1;
      end if;
   end Count_Lost;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      SSP_S := Empty_Store;
      Grad_S := Empty_Store;
      ASP_S := Empty_Store;
      TSR_S := Empty_Store;
      Adh_S := Empty_Store;
      PBD_S := Empty_Store;
      Grad_Default_Known := False;
      Grad_Default := 0;
      LX_S := (others => No_LX);
      LX_Sense_S := Plus;
      Suit_S := (others => No_Suitability);
      Lost_N := 0;
   end Clear;

   --  A store receives information of the sense S: a store of the other
   --  sense (the orientation changed) is emptied first
   procedure Orient (St : in out Store_T; S : Sense_T)
     with Post => St.Sense = S
   is
   begin
      if St.Sense /= S then
         St := Empty_Store;
         St.Sense := S;
      end if;
   end Orient;

   --  A distance of the packet, cm
   function D (Code : Natural; Scale : Natural) return Dist_T is
     (Scaled (Code, Scale))
     with Pre => Code <= 32_767 and then Scale <= 2;

   -----------------
   -- Train_Speed --
   -----------------

   function Train_Speed (V_STATIC : V_STATIC_T;
                         N        : Natural;
                         Diffs    : Diff_Array;
                         C        : EVC_Train_Data.Categories_T)
     return Speed_Cms_T
   is
      Basic      : constant Speed_Cms_T := V5_To_Cms (Natural (V_STATIC));
      --  3.11.3.2.3: the "Cant Deficiency" SSP
      Exact      : Boolean := False;
      Exact_V    : Speed_Cms_T := 0;
      Below      : Boolean := False;
      Below_NC   : Natural := 0;
      Below_V    : Speed_Cms_T := 0;
      CD         : Speed_Cms_T;
      --  3.11.3.2.6: the "other specific" SSPs of the train's categories
      Other      : Boolean := False;
      Other_V    : Speed_Cms_T := No_Speed_Limit;
      Replaced   : Boolean := False;
      Train_CD   : constant Natural := Natural (C.Cant_Deficiency);
   begin
      for I in 1 .. N loop
         declare
            X : constant Diff_T := Diffs (I);
            V : constant Speed_Cms_T := V5_To_Cms (Natural (X.V_DIFF));
         begin
            if X.Q_DIFF = 0 then
               if X.NC = Train_CD then
                  Exact := True;
                  Exact_V := V;
               elsif X.NC < Train_CD
                 and then (not Below or else X.NC > Below_NC)
               then
                  Below := True;
                  Below_NC := X.NC;
                  Below_V := V;
               end if;
            elsif X.Q_DIFF in 1 | 2
              and then X.NC <= 14
              and then (Natural (C.Other) / 2**X.NC) mod 2 = 1
            then
               Other := True;
               Other_V := Speed_Cms_T'Min (Other_V, V);
               if X.Q_DIFF = 1 then
                  Replaced := True;
               end if;
            end if;
         end;
      end loop;
      CD := (if Exact then Exact_V elsif Below then Below_V else Basic);
      if not Other then
         return CD;
      elsif Replaced then
         return Other_V;
      else
         return Speed_Cms_T'Min (CD, Other_V);
      end if;
   end Train_Speed;

   --------------
   -- Take_SSP --
   --------------

   procedure Take_SSP (P : ETCS_Track_Packets.P27.Packet_T;
                       M : Message_T;
                       T : Origin_Table_T;
                       C : EVC_Train_Data.Categories_T)
   is
      Scale   : constant Natural := Natural (P.Q_SCALE);
      Start   : Dist_T;
      Next    : Dist_T;
      Speed   : Speed_Cms_T;
      Delay_L : Boolean;
      Diffs   : Diff_Array;
      Ended   : Boolean := False;

      procedure Load (N : N_ITER_T; L : ETCS_Track_Packets.P27.Q_DIFF_Array)
      is
      begin
         for I in 1 .. Natural (N) loop
            Diffs (I) :=
              (Q_DIFF => L (I).Q_DIFF,
               NC     => (if L (I).Q_DIFF = 0 then Natural (L (I).NC_CDDIFF)
                          else Natural (L (I).NC_DIFF)),
               V_DIFF => L (I).V_DIFF);
         end loop;
      end Load;

      procedure Load_2 (N : N_ITER_T;
                        L : ETCS_Track_Packets.P27.Q_DIFF_Array_2)
      is
      begin
         for I in 1 .. Natural (N) loop
            Diffs (I) :=
              (Q_DIFF => L (I).Q_DIFF,
               NC     => (if L (I).Q_DIFF = 0 then Natural (L (I).NC_CDDIFF)
                          else Natural (L (I).NC_DIFF)),
               V_DIFF => L (I).V_DIFF);
         end loop;
      end Load_2;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (SSP_S, M.Sense);
      Start := D (Natural (P.D_STATIC), Scale);
      --  3.7.3.1 a)
      Cut_Beyond (SSP_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      if P.V_STATIC = 127 then
         return;
      end if;
      Diffs := (others => (others => <>));
      Load (P.N_ITER, P.Q_DIFF_List);
      Speed := Train_Speed (P.V_STATIC, Natural (P.N_ITER), Diffs, C);
      Delay_L := P.Q_FRONT = 0;
      for K in 1 .. Natural (P.N_ITER_2) loop
         Next := Sum (Start, D (Natural (P.D_STATIC_List (K).D_STATIC),
                                Scale));
         Append (SSP_S, (Start        => At_Offset (M, Start),
                         Finish       => At_Offset (M, Next),
                         Open         => False,
                         Value        => Speed,
                         Delay_Length => Delay_L,
                         Id           => 0,
                         Msg          => M.Msg,
                         others       => <>));
         if P.D_STATIC_List (K).V_STATIC = 127 then
            Ended := True;
            exit;
         end if;
         Start := Next;
         Diffs := (others => (others => <>));
         Load_2 (P.D_STATIC_List (K).N_ITER, P.D_STATIC_List (K).Q_DIFF_List);
         Speed := Train_Speed (P.D_STATIC_List (K).V_STATIC,
                               Natural (P.D_STATIC_List (K).N_ITER), Diffs, C);
         Delay_L := P.D_STATIC_List (K).Q_FRONT = 0;
      end loop;
      if not Ended then
         Append (SSP_S, (Start        => At_Offset (M, Start),
                         Finish       => At_Offset (M, Start),
                         Open         => True,
                         Value        => Speed,
                         Delay_Length => Delay_L,
                         Id           => 0,
                         Msg          => M.Msg,
                         others       => <>));
      end if;
   end Take_SSP;

   --------------------
   -- Take_Gradients --
   --------------------

   procedure Take_Gradients (P : ETCS_Track_Packets.P21.Packet_T;
                             M : Message_T;
                             T : Origin_Table_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;
      Next  : Dist_T;
      Value : Gradient_T;
      Ended : Boolean := False;

      function Signed (Q_GDIR : Q_GDIR_T; G : G_A_T) return Gradient_T is
        (if Q_GDIR = 1 then Gradient_T (Natural'Min (Natural (G), 255))
         else -Gradient_T (Natural'Min (Natural (G), 255)));
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (Grad_S, M.Sense);
      Start := D (Natural (P.D_GRADIENT), Scale);
      --  3.7.3.1 b)
      Cut_Beyond (Grad_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      if P.G_A = 255 then
         return;
      end if;
      Value := Signed (P.Q_GDIR, P.G_A);
      for K in 1 .. Natural (P.N_ITER) loop
         Next := Sum (Start, D (Natural (P.D_GRADIENT_List (K).D_GRADIENT),
                                Scale));
         Append (Grad_S, (Start        => At_Offset (M, Start),
                          Finish       => At_Offset (M, Next),
                          Open         => False,
                          Value        => Value,
                          Delay_Length => False,
                          Id           => 0,
                          Msg          => M.Msg,
                          others       => <>));
         if P.D_GRADIENT_List (K).G_A = 255 then
            Ended := True;
            exit;
         end if;
         Start := Next;
         Value := Signed (P.D_GRADIENT_List (K).Q_GDIR,
                          P.D_GRADIENT_List (K).G_A);
      end loop;
      if not Ended then
         Append (Grad_S, (Start        => At_Offset (M, Start),
                          Finish       => At_Offset (M, Start),
                          Open         => True,
                          Value        => Value,
                          Delay_Length => False,
                          Id           => 0,
                          Msg          => M.Msg,
                          others       => <>));
      end if;
   end Take_Gradients;

   --------------
   -- Take_ASP --
   --------------

   procedure Take_ASP (P    : ETCS_Track_Packets.P51.Packet_T;
                       M    : Message_T;
                       T    : Origin_Table_T;
                       Axle : M_AXLELOADCAT_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;

      --  3.11.4.3: the speed of the train's category, if listed
      procedure Add_Element (From    : Dist_T;
                             Length  : Dist_T;
                             Q_FRONT : Q_FRONT_T;
                             Found   : Boolean;
                             V       : V_AXLELOAD_T)
      is
      begin
         if Found then
            Append (ASP_S, (Start        => At_Offset (M, From),
                            Finish       => At_Offset (M, Sum (From, Length)),
                            Open         => False,
                            Value        => V5_To_Cms (Natural (V)),
                            Delay_Length => Q_FRONT = 0,
                            Id           => 0,
                            Msg          => M.Msg,
                            others       => <>));
         end if;
      end Add_Element;

      Found : Boolean;
      V     : V_AXLELOAD_T;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (ASP_S, M.Sense);
      if P.Q_TRACKINIT = 1 then
         --  3.7.3.2 b): no restriction due to axle load from D_TRACKINIT
         Start := D (Natural (P.D_TRACKINIT), Scale);
         Cut_Beyond (ASP_S, T,
                     Frame (T, At_Offset (M, Start), Estimated_Item),
                     At_Offset (M, Start), M.Msg);
         return;
      end if;
      Start := D (Natural (P.D_AXLELOAD), Scale);
      --  3.7.3.1 c): from the start of the first element
      Cut_Beyond (ASP_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      Found := False;
      V := 0;
      for I in 1 .. Natural (P.N_ITER) loop
         if P.M_AXLELOADCAT_List (I).M_AXLELOADCAT = Axle then
            Found := True;
            V := P.M_AXLELOADCAT_List (I).V_AXLELOAD;
         end if;
      end loop;
      Add_Element (Start, D (Natural (P.L_AXLELOAD), Scale), P.Q_FRONT,
                   Found, V);
      for K in 1 .. Natural (P.N_ITER_2) loop
         declare
            X : ETCS_Track_Packets.P51.D_AXLELOAD_Item renames
              P.D_AXLELOAD_List (K);
         begin
            --  3.6.3.2.4 a): increments between the starts
            Start := Sum (Start, D (Natural (X.D_AXLELOAD), Scale));
            Found := False;
            V := 0;
            for I in 1 .. Natural (X.N_ITER) loop
               if X.M_AXLELOADCAT_List (I).M_AXLELOADCAT = Axle then
                  Found := True;
                  V := X.M_AXLELOADCAT_List (I).V_AXLELOAD;
               end if;
            end loop;
            Add_Element (Start, D (Natural (X.L_AXLELOAD), Scale), X.Q_FRONT,
                         Found, V);
         end;
      end loop;
   end Take_ASP;

   --------------
   -- Take_PBD --
   --------------

   procedure Take_PBD (P : ETCS_Track_Packets.P52.Packet_T;
                       M : Message_T;
                       T : Origin_Table_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;

      --  A section from From, of the length Length: its order (3.11.11.2),
      --  its speed computed in the cycle (Compute_PBD)
      procedure Add_Section (From    : Dist_T;
                             Length  : Dist_T;
                             D_PBD   : D_PBD_T;
                             Q_GDIR  : Q_GDIR_T;
                             G       : G_PBDSR_T;
                             Q_PBDSR : Q_PBDSR_T)
      is
         G_Signed : constant Gradient_T :=
           (if Q_GDIR = 1 then Gradient_T (Natural'Min (Natural (G), 255))
            else -Gradient_T (Natural'Min (Natural (G), 255)));
      begin
         Append (PBD_S, (Start        => At_Offset (M, From),
                         Finish       => At_Offset (M, Sum (From, Length)),
                         Open         => False,
                         Value        => 0,
                         Delay_Length => False,
                         Id           => Natural (D (Natural (D_PBD), Scale)),
                         Msg          => M.Msg,
                         Noted        => False,
                         Gradient     => G_Signed,
                         Service      => Q_PBDSR = 1,
                         others       => <>));
      end Add_Section;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (PBD_S, M.Sense);
      if P.Q_TRACKINIT = 1 then
         --  3.7.3.2 a): no speed restriction to ensure a permitted
         --  braking distance from D_TRACKINIT (3.11.11.11)
         Start := D (Natural (P.D_TRACKINIT), Scale);
         Cut_Beyond (PBD_S, T,
                     Frame (T, At_Offset (M, Start), Estimated_Item),
                     At_Offset (M, Start), M.Msg);
         return;
      end if;
      Start := D (Natural (P.D_PBDSR), Scale);
      --  3.7.3.1 d): from the start of the first element
      Cut_Beyond (PBD_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      Add_Section (Start, D (Natural (P.L_PBDSR), Scale), P.D_PBD,
                   P.Q_GDIR, P.G_PBDSR, P.Q_PBDSR);
      for K in 1 .. Natural (P.N_ITER) loop
         declare
            X : ETCS_Track_Packets.P52.D_PBD_Item renames P.D_PBD_List (K);
         begin
            --  3.6.3.2.4 a): increments between the starts
            Start := Sum (Start, D (Natural (X.D_PBDSR), Scale));
            Add_Section (Start, D (Natural (X.L_PBDSR), Scale), X.D_PBD,
                         X.Q_GDIR, X.G_PBDSR, X.Q_PBDSR);
         end;
      end loop;
   end Take_PBD;

   -----------------
   -- Compute_PBD --
   -----------------

   procedure Compute_PBD (I            : EVC_PBD.Inputs_T;
                          All_Sections : Boolean;
                          Work         : in out EVC_Profile.Profile_T;
                          Computed     : out Natural)
   is
   begin
      Computed := 0;
      for K in 1 .. PBD_S.Count loop
         pragma Loop_Invariant
           (Computed < K
            and then (for all J in 1 .. K - 1 => PBD_S.List (J).Noted));
         if All_Sections or else not PBD_S.List (K).Noted then
            EVC_PBD.Restrict
              (I,
               D_PBD    => Cm_T'Min (EVC_PBD.PBD_Distance_T'Last,
                                       Cm_T (PBD_S.List (K).Id)),
               Gradient => Gradient_T'Max
                             (Gradient_T'First,
                              Gradient_T'Min (Gradient_T'Last,
                                              PBD_S.List (K).Gradient)),
               Service  => PBD_S.List (K).Service,
               Work     => Work,
               V        => PBD_S.List (K).Value);
            PBD_S.List (K).Noted := True;
            Computed := Computed + 1;
         end if;
      end loop;
   end Compute_PBD;

   --------------
   -- Take_TSR --
   --------------

   procedure Take_TSR (P : ETCS_Track_Packets.P65.Packet_T;
                       M : Message_T;
                       T : Origin_Table_T)
   is
      pragma Unreferenced (T);
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;
      I     : Natural := 1;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (TSR_S, M.Sense);
      --  3.11.5.9: the one of the same identity is replaced, unless not
      --  revocable (NID_TSR 255: an additional one); 3.11.5.7
      if P.NID_TSR /= 255 then
         while I <= TSR_S.Count loop
            pragma Loop_Invariant (I >= 1 and then TSR_S.Sense = M.Sense);
            pragma Loop_Variant (Decreases => TSR_S.Count - I);
            if TSR_S.List (I).Id = Natural (P.NID_TSR) then
               Remove (TSR_S, I);
            else
               I := I + 1;
            end if;
         end loop;
      end if;
      Start := D (Natural (P.D_TSR), Scale);
      Append (TSR_S,
              (Start        => At_Offset (M, Start),
               Finish       => At_Offset (M, Sum (Start,
                                                  D (Natural (P.L_TSR),
                                                     Scale))),
               Open         => False,
               Value        => V5_To_Cms (Natural (P.V_TSR)),
               Delay_Length => P.Q_FRONT = 0,
               Id           => Natural (P.NID_TSR),
               Msg          => M.Msg,
               others       => <>));
   end Take_TSR;

   ----------------
   -- Revoke_TSR --
   ----------------

   procedure Revoke_TSR (P       : ETCS_Track_Packets.P66.Packet_T;
                         Revoked : out Natural)
   is
      I : Natural := 1;
   begin
      Revoked := 0;
      if P.NID_TSR = 255 then
         return;
      end if;
      while I <= TSR_S.Count loop
         pragma Loop_Invariant
           (I >= 1
            and then Revoked <= TSR_S.Count'Loop_Entry
            and then TSR_S.Count = TSR_S.Count'Loop_Entry - Revoked);
         pragma Loop_Variant (Decreases => TSR_S.Count - I);
         if TSR_S.List (I).Id = Natural (P.NID_TSR) then
            Remove (TSR_S, I);
            Revoked := Revoked + 1;
         else
            I := I + 1;
         end if;
      end loop;
   end Revoke_TSR;

   ---------------------------
   -- Take_Default_Gradient --
   ---------------------------

   procedure Take_Default_Gradient (P : ETCS_Track_Packets.P141.Packet_T)
   is
   begin
      Grad_Default :=
        (if P.Q_GDIR = 1 then Gradient_T (P.G_TSR)
         else -Gradient_T (P.G_TSR));
      Grad_Default_Known := True;
   end Take_Default_Gradient;

   -------------
   -- Take_LX --
   -------------

   procedure Take_LX (P : ETCS_Track_Packets.P88.Packet_T;
                      M : Message_T;
                      T : Origin_Table_T)
   is
      pragma Unreferenced (T);
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;
      Slot  : Natural := 0;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      if LX_Sense_S /= M.Sense then
         LX_S := (others => No_LX);
         LX_Sense_S := M.Sense;
      end if;
      --  3.12.5.3: the one of the same identity is replaced
      for I in LX_S'Range loop
         if LX_S (I).Used and then LX_S (I).Id = P.NID_LX then
            Slot := I;
         end if;
      end loop;
      if Slot = 0 then
         for I in LX_S'Range loop
            if not LX_S (I).Used then
               Slot := I;
               exit;
            end if;
         end loop;
      end if;
      if Slot = 0 then
         Count_Lost;
         return;
      end if;
      Start := D (Natural (P.D_LX), Scale);
      LX_S (Slot) :=
        (Used          => True,
         Id            => P.NID_LX,
         Start         => At_Offset (M, Start),
         Finish        => At_Offset (M, Sum (Start, D (Natural (P.L_LX),
                                                        Scale))),
         Protected_LX  => P.Q_LXSTATUS = 0,
         Speed         => V5_To_Cms (Natural (P.V_LX)),
         Stop_Required => P.Q_STOPLX = 1,
         Stop_Length   => D (Natural (P.L_STOPLX), Scale),
         Msg           => M.Msg,
         --  phase E4, 5.16: a new information starts the procedure
         --  again
         Released      => False,
         Released_From => 0,
         Indicated     => False);
   end Take_LX;

   -------------------
   -- Take_Adhesion --
   -------------------

   procedure Take_Adhesion (P : ETCS_Track_Packets.P71.Packet_T;
                            M : Message_T;
                            T : Origin_Table_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (Adh_S, M.Sense);
      Start := D (Natural (P.D_ADHESION), Scale);
      --  3.7.3.1 l)
      Cut_Beyond (Adh_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      if P.M_ADHESION = 0 then
         Append (Adh_S,
                 (Start        => At_Offset (M, Start),
                  Finish       => At_Offset (M, Sum (Start,
                                                     D (Natural (P.L_ADHESION),
                                                        Scale))),
                  Open         => False,
                  Value        => 0,
                  Delay_Length => False,
                  Id           => 0,
                  Msg          => M.Msg,
                  others       => <>));
      end if;
   end Take_Adhesion;

   ----------------------
   -- Take_Suitability --
   ----------------------

   procedure Take_Suitability (P : ETCS_Track_Packets.P70.Packet_T;
                               M : Message_T;
                               T : Origin_Table_T)
   is
      Scale    : constant Natural := Natural (P.Q_SCALE);
      Start    : Dist_T;
      Replaced : array (0 .. 2) of Boolean := (others => False);

      procedure Put (Kind : Natural; Value : Natural;
                     Traction : NID_CTRACTION_T)
        with Pre => Kind <= 2 and then Value <= 65_535
      is
         Slot : Natural := 0;
      begin
         --  3.7.3.1 h), i), j): all the stored data of the type
         if not Replaced (Kind) then
            for I in Suit_S'Range loop
               if Suit_S (I).Used and then Suit_S (I).Kind = Kind
                 and then Suit_S (I).Msg < M.Msg
               then
                  Suit_S (I) := (others => <>);
               end if;
            end loop;
            Replaced (Kind) := True;
         end if;
         for I in Suit_S'Range loop
            if not Suit_S (I).Used then
               Slot := I;
               exit;
            end if;
         end loop;
         if Slot = 0 then
            Count_Lost;
            return;
         end if;
         Suit_S (Slot) := (Used     => True,
                           At_Loc   => At_Offset (M, Start),
                           Kind     => Kind,
                           Value    => Value,
                           Traction => Traction,
                           Msg      => M.Msg);
      end Put;

      function Value_Of (Q : Q_SUITABILITY_T;
                         G : M_LINEGAUGE_T;
                         L : M_LINEAXLELOADCAT_T;
                         V : M_VOLTAGE_T) return Natural
      is (case Q is
             when 0 => Natural (G),
             when 1 => Natural (L),
             when others => Natural (V))
        with Post => Value_Of'Result <= 65_535;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      if P.Q_TRACKINIT = 1 then
         --  3.7.3.2 d): no restriction from D_TRACKINIT on
         Start := D (Natural (P.D_TRACKINIT), Scale);
         for I in Suit_S'Range loop
            if Suit_S (I).Used
              and then A (M.Sense, Frame (T, Suit_S (I).At_Loc,
                                          Estimated_Item))
                       >= A (M.Sense, Frame (T, At_Offset (M, Start),
                                             Estimated_Item))
            then
               Suit_S (I) := (others => <>);
            end if;
         end loop;
         return;
      end if;
      Start := D (Natural (P.D_SUITABILITY), Scale);
      if P.Q_SUITABILITY <= 2 then
         Put (Natural (P.Q_SUITABILITY),
              Value_Of (P.Q_SUITABILITY, P.M_LINEGAUGE, P.M_LINEAXLELOADCAT,
                        P.M_VOLTAGE),
              P.NID_CTRACTION);
      end if;
      for K in 1 .. Natural (P.N_ITER) loop
         declare
            X : ETCS_Track_Packets.P70.D_SUITABILITY_Item renames
              P.D_SUITABILITY_List (K);
         begin
            Start := Sum (Start, D (Natural (X.D_SUITABILITY), Scale));
            if X.Q_SUITABILITY <= 2 then
               Put (Natural (X.Q_SUITABILITY),
                    Value_Of (X.Q_SUITABILITY, X.M_LINEGAUGE,
                              X.M_LINEAXLELOADCAT, X.M_VOLTAGE),
                    X.NID_CTRACTION);
            end if;
         end;
      end loop;
   end Take_Suitability;

   -------------------
   -- Delete_Beyond --
   -------------------

   procedure Delete_Beyond (T          : Origin_Table_T;
                            X          : Dist_T;
                            To         : Location_T;
                            Before_Msg : Natural)
   is
   begin
      Cut_Beyond (Grad_S, T, X, To, Before_Msg);
      Cut_Beyond (SSP_S, T, X, To, Before_Msg);
      Cut_Beyond (ASP_S, T, X, To, Before_Msg);
      Cut_Beyond (PBD_S, T, X, To, Before_Msg);
      for I in Suit_S'Range loop
         if Suit_S (I).Used and then Suit_S (I).Msg < Before_Msg
           and then A (SSP_S.Sense, Frame (T, Suit_S (I).At_Loc,
                                           Estimated_Item))
                    >= A (SSP_S.Sense, X)
         then
            Suit_S (I) := (others => <>);
         end if;
      end loop;
   end Delete_Beyond;

   -------------------
   -- Delete_Behind --
   -------------------

   procedure Delete_Behind (T : Origin_Table_T; Rear : Dist_T) is
   begin
      Cut_Behind (SSP_S, T, Rear, Keep_In_Rear);
      Cut_Behind (Grad_S, T, Rear, Keep_In_Rear);
      Cut_Behind (ASP_S, T, Rear, Keep_In_Rear);
      Cut_Behind (TSR_S, T, Rear, Keep_In_Rear);
      Cut_Behind (Adh_S, T, Rear, Keep_In_Rear);
      Cut_Behind (PBD_S, T, Rear, Keep_In_Rear);
      for I in LX_S'Range loop
         if LX_S (I).Used
           and then A (LX_Sense_S, Frame (T, LX_S (I).Finish, Min_Item))
                    < Diff (A (LX_Sense_S, Rear), Keep_In_Rear)
         then
            LX_S (I) := (others => <>);
         end if;
      end loop;
      for I in Suit_S'Range loop
         if Suit_S (I).Used
           and then A (SSP_S.Sense, Frame (T, Suit_S (I).At_Loc, Min_Item))
                    < Diff (A (SSP_S.Sense, Rear), Keep_In_Rear)
         then
            Suit_S (I) := (others => <>);
         end if;
      end loop;
   end Delete_Behind;

   -----------------
   -- Delete_TSRs --
   -----------------

   procedure Delete_TSRs is
   begin
      TSR_S.Count := 0;
   end Delete_TSRs;

   ------------
   -- Delete --
   ------------

   procedure Delete (What : Deletion_T) is
   begin
      if What.Track then
         SSP_S := Empty_Store;
         Grad_S := Empty_Store;
         ASP_S := Empty_Store;
         LX_S := (others => No_LX);
      end if;
      if What.PBD then
         PBD_S := Empty_Store;
      end if;
      if What.Suitability then
         Suit_S := (others => No_Suitability);
      end if;
      if What.TSR then
         TSR_S := Empty_Store;
         Grad_Default_Known := False;
         Grad_Default := 0;
      end if;
      if What.Adhesion then
         Adh_S := Empty_Store;
      end if;
   end Delete;

   ----------
   -- Mark --
   ----------

   procedure Mark (Marks : in out Origin_Marks_T) is
   begin
      Mark (SSP_S, Marks);
      Mark (Grad_S, Marks);
      Mark (ASP_S, Marks);
      Mark (TSR_S, Marks);
      Mark (Adh_S, Marks);
      Mark (PBD_S, Marks);
      for I in LX_S'Range loop
         if LX_S (I).Used then
            Mark (LX_S (I).Start, Marks);
            Mark (LX_S (I).Finish, Marks);
         end if;
      end loop;
      for I in Suit_S'Range loop
         if Suit_S (I).Used then
            Mark (Suit_S (I).At_Loc, Marks);
         end if;
      end loop;
   end Mark;

   ---------------------------------------------------------------------
   --  For the snapshot
   ---------------------------------------------------------------------

   --  Element X of a store of the sense Ahead as an element along Ahead:
   --  from its "max" start to its "min" end, plus the train length when
   --  the rear end counts
   function Element_Of (T      : Origin_Table_T;
                        Ahead  : Sense_T;
                        X      : Stored_T;
                        Length : Length_T) return Element_T
   is (Start  => A (Ahead, Frame (T, X.Start, Max_Item)),
       Finish => (if X.Open then Max_Cm
                  elsif X.Delay_Length
                  then Sum (A (Ahead, Frame (T, X.Finish, Min_Item)), Length)
                  else A (Ahead, Frame (T, X.Finish, Min_Item))),
       Value  => X.Value);

   procedure Add_Stored (E      : in out Elements_T;
                         T      : Origin_Table_T;
                         Ahead  : Sense_T;
                         X      : Stored_T;
                         Length : Length_T)
     with Post => E.Count >= E.Count'Old
   is
      El : constant Element_T := Element_Of (T, Ahead, X, Length);
   begin
      Add (E, El.Start, El.Finish, El.Value);
   end Add_Stored;

   --  The gaps a relocation by 3.6.4.2.5 c) leaves inside a continuous
   --  profile (the SSP, the gradients: 3.6.3.2.2, 3.6.4.2.6), between an
   --  element of St and the one that starts where it ends: from the end
   --  of the element before the change (its "min" item, plus the train
   --  length where the rear end counts) to the start of the one after it
   --  (its "max" item), the lower of the two (see the header). Where the
   --  two elements meet or overlap there is no gap: the envelope takes
   --  the lower one over the overlap already
   procedure Add_Gaps (E      : in out Elements_T;
                       T      : Origin_Table_T;
                       Ahead  : Sense_T;
                       St     : Store_T;
                       Length : Length_T)
     with Post => E.Count >= E.Count'Old
   is
   begin
      for I in 1 .. St.Count loop
         pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
         for J in 1 .. St.Count loop
            pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
            if J /= I and then not St.List (J).Open
              and then St.List (J).Finish = St.List (I).Start
            then
               declare
                  Before : constant Element_T :=
                    Element_Of (T, Ahead, St.List (J), Length);
                  After  : constant Element_T :=
                    Element_Of (T, Ahead, St.List (I), Length);
               begin
                  if Before.Finish < After.Start then
                     Add (E, Before.Finish, After.Start,
                          Value_T'Min (Before.Value, After.Value));
                  end if;
               end;
            end if;
         end loop;
      end loop;
   end Add_Gaps;

   procedure Speed_Elements (T        : Origin_Table_T;
                             Ahead    : Sense_T;
                             Length   : Length_T;
                             E        : in out Elements_T;
                             Only_TSR : Boolean := False)
   is
   begin
      if Only_TSR then
         if TSR_S.Sense = Ahead then
            for I in 1 .. TSR_S.Count loop
               pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
               Add_Stored (E, T, Ahead, TSR_S.List (I), Length);
            end loop;
         end if;
         return;
      end if;
      if SSP_S.Sense = Ahead then
         for I in 1 .. SSP_S.Count loop
            pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
            Add_Stored (E, T, Ahead, SSP_S.List (I), Length);
         end loop;
         --  the SSP is continuous over the track it covers: the gaps a
         --  relocation leaves take the lower neighbour (see the header)
         Add_Gaps (E, T, Ahead, SSP_S, Length);
      end if;
      if ASP_S.Sense = Ahead then
         for I in 1 .. ASP_S.Count loop
            pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
            Add_Stored (E, T, Ahead, ASP_S.List (I), Length);
         end loop;
      end if;
      if TSR_S.Sense = Ahead then
         for I in 1 .. TSR_S.Count loop
            pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
            Add_Stored (E, T, Ahead, TSR_S.List (I), Length);
         end loop;
      end if;
      --  3.11.11: the sections computed (Compute_PBD runs before)
      if PBD_S.Sense = Ahead then
         for I in 1 .. PBD_S.Count loop
            pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
            Add_Stored (E, T, Ahead, PBD_S.List (I), Length);
         end loop;
      end if;
      --  3.11.9: the LX speed restriction of a level crossing not
      --  protected, over its area; once it substitutes the supervision
      --  of its start as temporary EOA and SvL (5.16.2.1, 5.16.3.2),
      --  from the location of the substitution
      if LX_Sense_S = Ahead then
         for I in LX_S'Range loop
            pragma Loop_Invariant (E.Count >= E.Count'Loop_Entry);
            if LX_S (I).Used and then not LX_S (I).Protected_LX then
               Add (E,
                    (if LX_S (I).Released
                     then Dist_T'Min
                            (A (Ahead, LX_S (I).Released_From),
                             A (Ahead, Frame (T, LX_S (I).Start, Max_Item)))
                     else A (Ahead, Frame (T, LX_S (I).Start, Max_Item))),
                    A (Ahead, Frame (T, LX_S (I).Finish, Min_Item)),
                    LX_S (I).Speed);
            end if;
         end loop;
      end if;
   end Speed_Elements;

   function TSR_Limits (T      : Origin_Table_T;
                        Ahead  : Sense_T;
                        Length : Length_T;
                        From   : Cm_T;
                        To     : Cm_T;
                        V      : Value_T) return Boolean
     with Refined_Global => TSR_S
   is
   begin
      if TSR_S.Sense /= Ahead then
         return False;
      end if;
      for I in 1 .. TSR_S.Count loop
         declare
            El : constant Element_T :=
              Element_Of (T, Ahead, TSR_S.List (I), Length);
         begin
            if El.Start < El.Finish and then El.Start < To
              and then From < El.Finish and then El.Value <= V
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end TSR_Limits;

   procedure Gradient_Elements (T     : Origin_Table_T;
                                Ahead : Sense_T;
                                E     : in out Elements_T)
   is
   begin
      if Grad_S.Sense /= Ahead then
         return;
      end if;
      for I in 1 .. Grad_S.Count loop
         Add_Stored (E, T, Ahead, Grad_S.List (I), 0);
      end loop;
      --  3.11.12.2: the gaps a relocation leaves take the lower
      --  neighbour (see the header)
      Add_Gaps (E, T, Ahead, Grad_S, 0);
   end Gradient_Elements;

   procedure Adhesion_Areas (T     : Origin_Table_T;
                             Ahead : Sense_T;
                             Areas : in out Adhesion_T)
   is
   begin
      if Adh_S.Sense /= Ahead then
         return;
      end if;
      for I in 1 .. Adh_S.Count loop
         exit when Areas.Count = Max_Adhesion_Areas;
         Areas.Count := Areas.Count + 1;
         Areas.Areas (Areas.Count) :=
           (Start  => Frame (T, Adh_S.List (I).Start, Max_Item),
            Finish => Frame (T, Adh_S.List (I).Finish, Min_Item));
      end loop;
   end Adhesion_Areas;

   --  The estimated front end in rear of the start of the profile St
   --  (moved here from EVC_Procedures with Before_Profiles: the store is
   --  read in place, not copied)
   function Before_Profile (St : Store_T; T : Origin_Table_T;
                            Est : Dist_T) return Boolean
   is
      First : Dist_T := Max_Cm;
   begin
      if St.Count = 0 then
         return False;
      end if;
      for I in 1 .. St.Count loop
         pragma Loop_Invariant (First <= Max_Cm);
         First := Dist_T'Min
           (First, A (St.Sense, Frame (T, St.List (I).Start,
                                       Estimated_Item)));
      end loop;
      return A (St.Sense, Est) < First;
   end Before_Profile;

   function Before_Profiles (T : Origin_Table_T; Est : Dist_T)
     return Boolean
   is (Before_Profile (SSP_S, T, Est) or else Before_Profile (Grad_S, T, Est))
     with Refined_Global => (SSP_S, Grad_S);

   function Covered (T : Origin_Table_T; Ahead : Sense_T; From, To : Dist_T)
     return Boolean
   is (SSP_S.Sense = Ahead and then Grad_S.Sense = Ahead
       and then Covers (SSP_S, T, From, To)
       and then Covers (Grad_S, T, From, To))
     with Refined_Global => (SSP_S, Grad_S);

   procedure LX_Target (T     : Origin_Table_T;
                        Ahead : Sense_T;
                        Front : Dist_T;
                        Found : out Boolean;
                        EOA   : out Dist_T;
                        SvL   : out Dist_T;
                        Index : out Natural)
   is
      Best : Dist_T := Max_Cm;
   begin
      Found := False;
      EOA := 0;
      SvL := 0;
      Index := 0;
      if LX_Sense_S /= Ahead then
         return;
      end if;
      for I in LX_S'Range loop
         pragma Loop_Invariant (Index <= Max_LX
                                and then (if Found then Index >= 1));
         if LX_S (I).Used and then not LX_S (I).Protected_LX
           and then not LX_S (I).Released
         then
            declare
               E : constant Dist_T :=
                 Frame (T, LX_S (I).Start, Estimated_Item);
            begin
               --  phase E4: kept until the min safe front end passed
               --  its end (a start passed without the substitution of
               --  5.16 is an EOA passed: the trip of 4.6.3 [12], {9})
               if A (Ahead, Frame (T, LX_S (I).Finish, Max_Item))
                    >= A (Ahead, Front)
                 and then A (Ahead, E) < Best
               then
                  Best := A (Ahead, E);
                  Found := True;
                  Index := I;
                  EOA := E;
                  SvL := Frame (T, LX_S (I).Start, Max_Item);
               end if;
            end;
         end if;
      end loop;
      --  the SvL never before the EOA
      if Found and then A (Ahead, SvL) < A (Ahead, EOA) then
         EOA := SvL;
      end if;
   end LX_Target;

   ----------------
   -- Release_LX --
   ----------------

   procedure Release_LX (I : Positive; From : Dist_T) is
   begin
      if LX_S (I).Used and then not LX_S (I).Protected_LX then
         LX_S (I).Released := True;
         LX_S (I).Released_From := From;
         LX_S (I).Indicated := True;
      end if;
   end Release_LX;

   -----------------
   -- Indicate_LX --
   -----------------

   procedure Indicate_LX (I : Positive) is
   begin
      if LX_S (I).Used and then not LX_S (I).Protected_LX then
         LX_S (I).Indicated := True;
      end if;
   end Indicate_LX;

end EVC_Track_Description;
