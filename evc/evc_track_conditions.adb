--  ETCS on-board (EVC)
--  Track conditions and their indication, implementation.

with ETCS_Variables; use ETCS_Variables;
with EVC_Location;   use EVC_Location;

package body EVC_Track_Conditions
  with SPARK_Mode => On,
       Refined_State => (State => (Cond_S, Traction_S, BMM_S, Serial,
                                   Platform_S, Current_S))
is

   Cond_S     : Store_T := Empty_Store;
   Traction_S : Store_T := Empty_Store;
   BMM_S      : Store_T := Empty_Store;
   --  the number of the next condition on the DMI (1 .. 127; the
   --  changes of traction system take 128 .. 255)
   Serial     : Natural range 1 .. 127 := 1;
   --  phase E4: packets 69 and 40
   Platform_S : Store_T := Empty_Store;
   Current_S  : Store_T := Empty_Store;

   function Conditions return Store_T is (Cond_S)
     with Refined_Global => Cond_S;
   function Traction_Changes return Store_T is (Traction_S)
     with Refined_Global => Traction_S;
   function Big_Metal_Masses return Store_T is (BMM_S)
     with Refined_Global => BMM_S;
   function Platforms return Store_T is (Platform_S)
     with Refined_Global => Platform_S;
   function Current_Changes return Store_T is (Current_S)
     with Refined_Global => Current_S;

   procedure Clear is
   begin
      Cond_S := Empty_Store;
      Traction_S := Empty_Store;
      BMM_S := Empty_Store;
      Serial := 1;
      Platform_S := Empty_Store;
      Current_S := Empty_Store;
   end Clear;

   procedure Orient (St : in out Store_T; S : Sense_T)
     with Post => St.Sense = S
   is
   begin
      if St.Sense /= S then
         St := Empty_Store;
         St.Sense := S;
      end if;
   end Orient;

   function Next_Serial return Natural is (Serial)
     with Global => Serial;

   procedure Step_Serial
     with Global => (In_Out => Serial)
   is
   begin
      Serial := (if Serial = 127 then 1 else Serial + 1);
   end Step_Serial;

   ---------------------
   -- Take_Conditions --
   ---------------------

   procedure Take_Conditions (P : ETCS_Track_Packets.P68.Packet_T;
                              M : Message_T;
                              T : Origin_Table_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;

      procedure Put (L : Natural; Kind : Natural)
        with Pre => L <= 32_767 and then Scale <= 2 and then Kind <= 15,
             Global => (In_Out => (Cond_S, Serial),
                        Input  => (Start, M, Scale))
      is
      begin
         Append (Cond_S,
                 (Start    => At_Offset (M, Start),
                  Finish   => At_Offset (M, Sum (Start, Scaled (L, Scale))),
                  Open     => False,
                  Value    => Kind,
                  Id       => Next_Serial,
                  Msg      => M.Msg,
                  others   => <>));
         Step_Serial;
      end Put;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (Cond_S, M.Sense);
      if P.Q_TRACKINIT = 1 then
         --  3.7.3.2 c): the initial states from D_TRACKINIT
         Start := Scaled (Natural (P.D_TRACKINIT), Scale);
         Cut_Beyond (Cond_S, T,
                     Frame (T, At_Offset (M, Start), Estimated_Item),
                     At_Offset (M, Start), M.Msg);
         return;
      end if;
      Start := Scaled (Natural (P.D_TRACKCOND), Scale);
      --  3.7.3.1 g)
      Cut_Beyond (Cond_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      Put (Natural (P.L_TRACKCOND), Natural (P.M_TRACKCOND));
      for K in 1 .. Natural (P.N_ITER) loop
         --  3.6.3.2.4 a): increments between the starts
         Start := Sum (Start, Scaled (Natural (P.D_TRACKCOND_List (K)
                                                .D_TRACKCOND), Scale));
         Put (Natural (P.D_TRACKCOND_List (K).L_TRACKCOND),
              Natural (P.D_TRACKCOND_List (K).M_TRACKCOND));
      end loop;
   end Take_Conditions;

   -------------------
   -- Take_Traction --
   -------------------

   procedure Take_Traction (P : ETCS_Track_Packets.P39.Packet_T;
                            M : Message_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      At_D  : Dist_T;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      --  3.7.3.1 e): all the stored ones
      Traction_S := Empty_Store;
      Traction_S.Sense := M.Sense;
      At_D := Scaled (Natural (P.D_TRACTION), Scale);
      Append (Traction_S,
              (Start    => At_Offset (M, At_D),
               Finish   => At_Offset (M, At_D),
               Open     => False,
               Value    => Natural (P.M_VOLTAGE) * 1_024
                             + (if P.M_VOLTAGE /= 0
                                then Natural (P.NID_CTRACTION) else 0),
               Id       => 128,
               Msg      => M.Msg,
               others   => <>));
   end Take_Traction;

   ---------------------------
   -- Take_Big_Metal_Masses --
   ---------------------------

   procedure Take_Big_Metal_Masses (P : ETCS_Track_Packets.P67.Packet_T;
                                    M : Message_T;
                                    T : Origin_Table_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;

      procedure Put (L : Natural)
        with Pre => L <= 32_767 and then Scale <= 2,
             Global => (In_Out => BMM_S, Input => (Start, M, Scale))
      is
      begin
         Append (BMM_S,
                 (Start    => At_Offset (M, Start),
                  Finish   => At_Offset (M, Sum (Start, Scaled (L, Scale))),
                  Msg      => M.Msg,
                  others   => <>));
      end Put;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (BMM_S, M.Sense);
      Start := Scaled (Natural (P.D_TRACKCOND), Scale);
      --  3.7.3.1 f)
      Cut_Beyond (BMM_S, T, Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      Put (Natural (P.L_TRACKCOND));
      for K in 1 .. Natural (P.N_ITER) loop
         Start := Sum (Start, Scaled (Natural (P.D_TRACKCOND_List (K)
                                                .D_TRACKCOND), Scale));
         Put (Natural (P.D_TRACKCOND_List (K).L_TRACKCOND));
      end loop;
   end Take_Big_Metal_Masses;

   --------------------
   -- Take_Platforms --
   --------------------

   procedure Take_Platforms (P : ETCS_Track_Packets.P69.Packet_T;
                             M : Message_T;
                             T : Origin_Table_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;

      procedure Put (L : Natural; Height, Side : Natural)
        with Pre => L <= 32_767 and then Scale <= 2 and then Height <= 15
                    and then Side <= 3,
             Global => (In_Out => Platform_S, Input => (Start, M, Scale))
      is
      begin
         Append (Platform_S,
                 (Start    => At_Offset (M, Start),
                  Finish   => At_Offset (M, Sum (Start, Scaled (L, Scale))),
                  Open     => False,
                  Value    => Height * 4 + Side,
                  Id       => 0,
                  Msg      => M.Msg,
                  others   => <>));
      end Put;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Orient (Platform_S, M.Sense);
      if P.Q_TRACKINIT = 1 then
         --  3.7.3.2 e): the initial state (no platform, 3.12.1.3) from
         --  D_TRACKINIT
         Start := Scaled (Natural (P.D_TRACKINIT), Scale);
         Cut_Beyond (Platform_S, T,
                     Frame (T, At_Offset (M, Start), Estimated_Item),
                     At_Offset (M, Start), M.Msg);
         return;
      end if;
      Start := Scaled (Natural (P.D_TRACKCOND), Scale);
      --  3.7.3.1 o)
      Cut_Beyond (Platform_S, T,
                  Frame (T, At_Offset (M, Start), Estimated_Item),
                  At_Offset (M, Start), M.Msg);
      Put (Natural (P.L_TRACKCOND), Natural (P.M_PLATFORM),
           Natural (P.Q_PLATFORM));
      for K in 1 .. Natural (P.N_ITER) loop
         Start := Sum (Start, Scaled (Natural (P.D_TRACKCOND_List (K)
                                                .D_TRACKCOND), Scale));
         Put (Natural (P.D_TRACKCOND_List (K).L_TRACKCOND),
              Natural (P.D_TRACKCOND_List (K).M_PLATFORM),
              Natural (P.D_TRACKCOND_List (K).Q_PLATFORM));
      end loop;
   end Take_Platforms;

   ------------------
   -- Take_Current --
   ------------------

   procedure Take_Current (P : ETCS_Track_Packets.P40.Packet_T;
                           M : Message_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      At_D  : Dist_T;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      --  3.7.3.1 p): all the stored ones
      Current_S := Empty_Store;
      Current_S.Sense := M.Sense;
      At_D := Scaled (Natural (P.D_CURRENT), Scale);
      Append (Current_S,
              (Start    => At_Offset (M, At_D),
               Finish   => At_Offset (M, At_D),
               Open     => False,
               Value    => Natural (P.M_CURRENT),
               Id       => 160,
               Msg      => M.Msg,
               others   => <>));
   end Take_Current;

   -------------------
   -- Delete_Beyond --
   -------------------

   procedure Delete_Beyond (T          : Origin_Table_T;
                            X          : Dist_T;
                            To         : Location_T;
                            Before_Msg : Natural)
   is
   begin
      Cut_Beyond (Cond_S, T, X, To, Before_Msg);
      Cut_Beyond (Traction_S, T, X, To, Before_Msg);
      Cut_Beyond (BMM_S, T, X, To, Before_Msg);
      Cut_Beyond (Platform_S, T, X, To, Before_Msg);
      Cut_Beyond (Current_S, T, X, To, Before_Msg);
   end Delete_Beyond;

   procedure Delete_Behind (T : Origin_Table_T; Rear : Dist_T;
                            Keep : Length_T)
   is
   begin
      Cut_Behind (Cond_S, T, Rear, Keep);
      Cut_Behind (Traction_S, T, Rear, Keep);
      Cut_Behind (BMM_S, T, Rear, Keep);
      Cut_Behind (Platform_S, T, Rear, Keep);
      Cut_Behind (Current_S, T, Rear, Keep);
   end Delete_Behind;

   procedure Mark (Marks : in out Origin_Marks_T) is
   begin
      Mark (Cond_S, Marks);
      Mark (Traction_S, Marks);
      Mark (BMM_S, Marks);
      Mark (Platform_S, Marks);
      Mark (Current_S, Marks);
   end Mark;

   ---------------------------------------------------------------------
   --  Indication
   ---------------------------------------------------------------------

   --  The symbols: announcement, active, after the end (0: none), and
   --  the planning orders at the start and at the end (0: none), for a
   --  type of track condition (DMI 8.2.3.5, 8.3.4)
   type Symbols_T is record
      Announce, Active, After, PL_Start, PL_End : Natural range 0 .. 38;
   end record;

   function Symbols (Kind : Natural) return Symbols_T is
     (case Kind is
         when 0 => (11, 10, 0, 9, 0),                     -- non stopping
         when 2 => (0, 35, 0, 24, 0),                     -- sound horn
         when 3 => ((if Automatic then 2 else 3), 1,      -- lower panto
                    (if Automatic then 4 else 5),
                    (if Automatic then 1 else 2),
                    (if Automatic then 3 else 4)),
         when 4 => (0, 12, 0, 10, 0),                     -- radio hole
         when 5 => ((if Automatic then 19 else 21), 19,   -- air tightness
                    (if Automatic then 20 else 22),
                    (if Automatic then 17 else 19),
                    (if Automatic then 18 else 20)),
         when 6 => ((if Automatic then 17 else 18), 17, 0, -- regenerative
                    (if Automatic then 15 else 16), 0),
         when 7 | 10 => ((if Automatic then 15 else 16), 15, 0,  -- eddy
                         (if Automatic then 13 else 14), 0),
         when 8 => ((if Automatic then 13 else 14), 13, 0, -- magnetic shoe
                    (if Automatic then 11 else 12), 0),
         when 9 => ((if Automatic then 6 else 7), 6,      -- main switch
                    (if Automatic then 8 else 9),
                    (if Automatic then 5 else 6),
                    (if Automatic then 7 else 8)),
         when others => (0, 0, 0, 0, 0));                 -- tunnel (1)

   --  The change of traction system to M_VOLTAGE V (DMI 8.2.3.5.21 ff,
   --  8.3.4.15 ff): the "new traction system" symbol is TC23 + 2 V, its
   --  announcement the next one when the driver acts; PL25 + 2 V
   function Traction_Symbols (V : Natural) return Symbols_T is
     ((Announce => 23 + 2 * V + (if Automatic then 0 else 1),
       Active   => 23 + 2 * V,
       After    => 23 + 2 * V,
       PL_Start => 25 + 2 * V + (if Automatic then 0 else 1),
       PL_End   => 0))
     with Pre => V <= 5;

   --  Phase E4: the virtual limit found last cycle for the foot X of
   --  the condition Id (5.18.4.2, 5.18.8.3)
   procedure Find_Virtual (Last  : Virtual_Limits_T;
                           Id    : Natural;
                           X     : Dist_T;
                           Found : out Boolean;
                           L     : out Virtual_Limit_T)
   is
   begin
      Found := False;
      L := (others => <>);
      for K in Last'Range loop
         if Last (K).Valid and then Last (K).Id = Id
           and then Last (K).Foot = X
         then
            Found := True;
            L := Last (K);
         end if;
      end loop;
   end Find_Virtual;

   --  5.18.4.2: G, the train length in advance of the end of a non
   --  stopping area (the "min" item, as for its end)
   function G_Of (T : Origin_Table_T; E : Stored_T; S : Sense_T;
                  Length : Length_T) return Dist_T
   is (Advance (Frame (T, E.Finish, Min_Item), S, Length));

   procedure Evaluate (T      : Origin_Table_T;
                       Train  : Train_Frame_T;
                       Now_Ms : Unsigned_64;
                       Ind    : out Indications_T;
                       Orders : out Orders_T;
                       Last   : Virtual_Limits_T := (others => <>))
   is
      Announce : constant Length_T :=
        Length_T'Max (Announce_Min_Cm,
                      Cm_T (Natural'Min (Train.Speed, 100_000))
                        * Announce_Time_Ms / 1_000);
      Horn     : constant Length_T :=
        Cm_T (Natural'Min (Train.Speed, 100_000)) * Horn_Time_Ms / 1_000;

      procedure Show (Id : Natural; Kind : Natural)
        with Pre => Id <= 255 and then Kind <= 38
      is
      begin
         if Kind /= 0 and then Ind.Count < Max_Indications then
            Ind.Count := Ind.Count + 1;
            Ind.List (Ind.Count) := (Id => Id, Kind => Kind);
         end if;
      end Show;

      procedure Order (Symbol : Natural; X : Dist_T)
        with Pre => Symbol <= 40
      is
      begin
         if Symbol /= 0 and then Orders.Count < Max_Orders then
            Orders.Count := Orders.Count + 1;
            Orders.List (Orders.Count) := (Symbol => Symbol, At_X => X);
         end if;
      end Order;

      --  the rear end passed the end E: noted once, and the 5 s since
      procedure Note (St : in out Store_T; I : Positive; Passed : Boolean)
        with Pre => I <= St.Count,
             Post => St.Count = St.Count'Old
      is
      begin
         if Passed and then not St.List (I).Noted then
            St.List (I).Noted := True;
            St.List (I).Noted_Ms := Now_Ms;
         end if;
      end Note;

      function Within_After (E : Stored_T) return Boolean is
        (not E.Noted
         or else Now_Ms < E.Noted_Ms
         or else Now_Ms - E.Noted_Ms <= After_End_Ms);
   begin
      Ind := (Count => 0, List => (others => (others => <>)));
      Orders := (Count => 0, List => (others => (others => <>)));
      if not Train.Valid then
         return;
      end if;

      if Cond_S.Sense = Train.Sense then
         for I in 1 .. Cond_S.Count loop
            pragma Loop_Invariant (Cond_S.Count = Cond_S.Count'Loop_Entry);
            declare
               S   : constant Sense_T := Cond_S.Sense;
               E   : constant Stored_T := Cond_S.List (I);
               Sym : constant Symbols_T :=
                 Symbols (Natural'Min (Natural'Max (E.Value, 0), 15));
               Id  : constant Natural := Natural'Min (E.Id, 255);
               D   : constant Dist_T := A (S, Frame (T, E.Start, Max_Item));
               Fin : constant Dist_T :=
                 A (S, Frame (T, E.Finish, Min_Item));
               C   : constant Dist_T := Diff (D, Announce);
               Max_F  : constant Dist_T := A (S, Train.Max_Front);
               Min_F  : constant Dist_T := A (S, Train.Min_Front);
               Min_R  : constant Dist_T := A (S, Train.Min_Rear);
               Est_F  : constant Dist_T := A (S, Train.Est_Front);
               DE  : constant Dist_T :=
                 A (S, Frame (T, E.Start, Estimated_Item));
               FE  : constant Dist_T :=
                 A (S, Frame (T, E.Finish, Estimated_Item));
            begin
               Note (Cond_S, I, Min_R >= Fin);
               case E.Value is
                  when 2 =>
                     --  5.18.9: sound horn, the estimated front end
                     if Est_F >= Diff (DE, Horn) and then Est_F < FE then
                        Show (Id, Sym.Active);
                     end if;
                  when 4 =>
                     --  5.18.5: radio hole
                     if Est_F >= DE and then Est_F < FE then
                        Show (Id, Sym.Active);
                     end if;
                  when 3 | 9 =>
                     --  5.18.2, 5.18.3: powerless section, its end
                     --  against the min safe front end
                     if Max_F >= C and then Max_F < D then
                        Show (Id, Sym.Announce);
                     elsif Max_F >= D and then Min_F < Fin then
                        Show (Id, Sym.Active);
                     elsif Min_F >= Fin and then Within_After (Cond_S.List (I))
                     then
                        Show (Id, Sym.After);
                     end if;
                  when 5 =>
                     --  5.18.6: air tightness
                     if Max_F >= C and then Max_F < D then
                        Show (Id, Sym.Announce);
                     elsif Max_F >= D and then Min_R < Fin then
                        Show (Id, Sym.Active);
                     elsif Min_R >= Fin and then Within_After (Cond_S.List (I))
                     then
                        Show (Id, Sym.After);
                     end if;
                  when 0 =>
                     --  5.18.4.2 to 5.18.4.4: between the virtual SBI
                     --  limits SBID (max safe front end) and SBIG (min
                     --  safe front end) that the supervision found last
                     --  cycle; without them from point C to the rear end
                     --  leaving it (E3)
                     declare
                        F_D, F_G : Boolean;
                        L_D, L_G : Virtual_Limit_T;
                        Shown    : Boolean;
                     begin
                        Find_Virtual (Last, E.Id,
                                      Frame (T, E.Start, Max_Item), F_D, L_D);
                        Find_Virtual (Last, E.Id,
                                      G_Of (T, E, S, Train.Length), F_G, L_G);
                        if F_D and then F_G then
                           Shown := Max_F >= A (S, L_D.SBI)
                                    and then Min_F < A (S, L_G.SBI);
                        else
                           Shown := Max_F >= C and then Min_R < Fin;
                        end if;
                        if Shown and then Max_F < D then
                           Show (Id, Sym.Announce);
                        elsif Shown then
                           Show (Id, Sym.Active);
                        end if;
                     end;
                  when 6 | 7 | 8 | 10 =>
                     --  5.18.7
                     if Max_F >= C and then Max_F < D then
                        Show (Id, Sym.Announce);
                     elsif Max_F >= D and then Min_R < Fin then
                        Show (Id, Sym.Active);
                     end if;
                  when others =>
                     null;
               end case;
               --  8.3.4: the orders ahead of the estimated front end
               if DE > Est_F then
                  Order (Sym.PL_Start, Frame (T, E.Start, Estimated_Item));
               end if;
               if FE > Est_F then
                  Order (Sym.PL_End, Frame (T, E.Finish, Estimated_Item));
               end if;
            end;
         end loop;
      end if;

      if Traction_S.Sense = Train.Sense then
         for I in 1 .. Traction_S.Count loop
            pragma Loop_Invariant
              (Traction_S.Count = Traction_S.Count'Loop_Entry);
            declare
               S   : constant Sense_T := Traction_S.Sense;
               E   : constant Stored_T := Traction_S.List (I);
               V   : constant Natural :=
                 Natural'Min (Natural'Max (E.Value, 0) / 1_024, 5);
               Sym : constant Symbols_T := Traction_Symbols (V);
               F   : constant Dist_T := A (S, Frame (T, E.Start, Max_Item));
               FM  : constant Dist_T := A (S, Frame (T, E.Start, Min_Item));
               FE  : constant Dist_T :=
                 A (S, Frame (T, E.Start, Estimated_Item));
               C   : constant Dist_T := Diff (F, Announce);
               Max_F  : constant Dist_T := A (S, Train.Max_Front);
               Min_R  : constant Dist_T := A (S, Train.Min_Rear);
               Est_F  : constant Dist_T := A (S, Train.Est_Front);
               Id  : constant Natural := 128 + Natural'Min (I, 127);
            begin
               Note (Traction_S, I, Min_R >= FM);
               --  5.18.10
               if Max_F >= C and then Max_F < F then
                  Show (Id, Sym.Announce);
               elsif Max_F >= F
                 and then Within_After (Traction_S.List (I))
               then
                  Show (Id, Sym.Active);
               end if;
               if FE > Est_F then
                  Order (Sym.PL_Start, Frame (T, E.Start, Estimated_Item));
               end if;
            end;
         end loop;
      end if;
   end Evaluate;

   ------------------
   -- Virtual_Feet --
   ------------------

   procedure Virtual_Feet (T     : Origin_Table_T;
                           Train : Train_Frame_T;
                           Feet  : out Virtual_Feet_T)
   is
      N        : Natural range 0 .. Max_Virtual := 0;
      Areas    : Natural := 0;
      Tunnels  : Natural := 0;

      procedure Put (Id : Natural; X : Dist_T)
        with Global => (In_Out => (Feet, N))
      is
      begin
         if N < Max_Virtual then
            N := N + 1;
            Feet (N) := (Used => True, Id => Natural'Min (Id, 255),
                         Foot => X);
         end if;
      end Put;
   begin
      Feet := (others => (others => <>));
      if not Train.Valid or else Cond_S.Sense /= Train.Sense then
         return;
      end if;
      for I in 1 .. Cond_S.Count loop
         declare
            S : constant Sense_T := Cond_S.Sense;
            E : constant Stored_T := Cond_S.List (I);
         begin
            --  5.18.4.2: the two nearest non stopping areas whose G the
            --  min safe front end has not passed
            if E.Value = 0 and then Areas < 2
              and then A (S, Train.Min_Front)
                         < A (S, G_Of (T, E, S, Train.Length))
            then
               Areas := Areas + 1;
               Put (E.Id, Frame (T, E.Start, Max_Item));
               Put (E.Id, G_Of (T, E, S, Train.Length));
            --  5.18.8.3: the two nearest tunnel stopping areas whose end
            --  the estimated front end has not reached
            elsif E.Value = 1 and then Tunnels < 2
              and then A (S, Train.Est_Front)
                         < A (S, Frame (T, E.Finish, Min_Item))
            then
               Tunnels := Tunnels + 1;
               Put (E.Id, Frame (T, E.Finish, Min_Item));
            end if;
         end;
      end loop;
   end Virtual_Feet;

   -----------------------
   -- Tunnel_Indication --
   -----------------------

   procedure Tunnel_Indication (T      : Origin_Table_T;
                                Train  : Train_Frame_T;
                                Last   : Virtual_Limits_T;
                                Tunnel : out Tunnel_T)
   is
   begin
      Tunnel := (others => <>);
      if not Train.Valid or else Cond_S.Sense /= Train.Sense then
         return;
      end if;
      for I in 1 .. Cond_S.Count loop
         declare
            S     : constant Sense_T := Cond_S.Sense;
            E     : constant Stored_T := Cond_S.List (I);
            Found : Boolean;
            L     : Virtual_Limit_T;
         begin
            if E.Value = 1 then
               Find_Virtual (Last, E.Id, Frame (T, E.Finish, Min_Item),
                             Found, L);
               --  5.18.8.3 a): the front end in rear of the Permitted
               --  limit of the SBD to its end; b) else the next one
               if Found
                 and then A (S, Train.Est_Front) < A (S, L.P)
               then
                  declare
                     D_M : constant Cm_T :=
                       (A (S, Frame (T, E.Start, Estimated_Item))
                        - A (S, Train.Est_Front)) / 100;
                  begin
                     if D_M > 0 then
                        --  5.18.8.4
                        Tunnel := (State      => 2,
                                   Distance_M =>
                                     Natural (Cm_T'Min (D_M, 99_999)));
                     else
                        --  5.18.8.5
                        Tunnel := (State => 1, Distance_M => 0);
                     end if;
                  end;
                  return;
               end if;
            end if;
         end;
      end loop;
   end Tunnel_Indication;

   --------------
   -- External --
   --------------

   procedure External (T     : Origin_Table_T;
                       Train : Train_Frame_T;
                       Info  : out External_T)
   is
      --  point C, as for the indication (5.18.2.2.1, 5.18.3.2.1,
      --  5.18.6.2.1, 5.18.7.3.2, 5.18.10.3)
      Announce : constant Length_T :=
        Length_T'Max (Announce_Min_Cm,
                      Cm_T (Natural'Min (Train.Speed, 100_000))
                        * Announce_Time_Ms / 1_000);

      procedure Put (Item : External_Item_T) is
      begin
         if Info.Count < Max_External then
            Info.Count := Info.Count + 1;
            Info.List (Info.Count) := Item;
         end if;
      end Put;
   begin
      Info := (Count => 0, List => (others => (others => <>)));
      if not Train.Valid then
         return;
      end if;

      if Cond_S.Sense = Train.Sense then
         for I in 1 .. Cond_S.Count loop
            declare
               S      : constant Sense_T := Cond_S.Sense;
               E      : constant Stored_T := Cond_S.List (I);
               D      : constant Dist_T := A (S, Frame (T, E.Start, Max_Item));
               Fin    : constant Dist_T :=
                 A (S, Frame (T, E.Finish, Min_Item));
               C      : constant Dist_T := Diff (D, Announce);
               Max_F  : constant Dist_T := A (S, Train.Max_Front);
               Min_F  : constant Dist_T := A (S, Train.Min_Front);
               Min_R  : constant Dist_T := A (S, Train.Min_Rear);
               Kind   : constant Natural :=
                 (case E.Value is
                     when 3      => Ext_Pantograph,
                     when 9      => Ext_Main_Switch,
                     when 5      => Ext_Air_Tight,
                     when 6      => Ext_Regenerative,
                     when 7      => Ext_Eddy_Service,
                     when 10     => Ext_Eddy_Emergency,
                     when 8      => Ext_Magnetic_Shoe,
                     when others => 0);
               Id     : constant Natural := Natural'Min (E.Id, 255);
            begin
               if Kind /= 0 and then Max_F >= C and then Min_R < Fin then
                  if Kind in Ext_Pantograph | Ext_Main_Switch then
                     --  5.20.2.3 to .5, 5.20.3.3 to .5: to D from the max
                     --  safe front end while the min safe rear end is in
                     --  rear of D; to E from the min safe front end
                     Put ((Kind      => Kind,
                           Id        => Id,
                           Has_Start => Min_R < D,
                           To_Start  => Diff (D, Max_F),
                           Has_End   => True,
                           To_End    => Diff (Fin, Min_F),
                           Value     => 0));
                  else
                     --  5.20.4.3 to .5, 5.20.5.4 to .6: to D from the max
                     --  safe front end until it reaches D; to E from the
                     --  min safe rear end
                     Put ((Kind      => Kind,
                           Id        => Id,
                           Has_Start => Max_F < D,
                           To_Start  => Diff (D, Max_F),
                           Has_End   => True,
                           To_End    => Diff (Fin, Min_R),
                           Value     => 0));
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Traction_S.Sense = Train.Sense then
         for I in 1 .. Traction_S.Count loop
            declare
               S     : constant Sense_T := Traction_S.Sense;
               E     : constant Stored_T := Traction_S.List (I);
               F     : constant Dist_T := A (S, Frame (T, E.Start, Max_Item));
               C     : constant Dist_T := Diff (F, Announce);
               Max_F : constant Dist_T := A (S, Train.Max_Front);
               Min_R : constant Dist_T := A (S, Train.Min_Rear);
            begin
               --  5.20.6.2 to .4: to F from the max safe front end, and
               --  the new traction system, until the min safe rear end
               --  reaches F
               if Max_F >= C and then Min_R < F then
                  Put ((Kind      => Ext_Traction,
                        Id        => 128 + Natural'Min (I, 127),
                        Has_Start => True,
                        To_Start  => Diff (F, Max_F),
                        Has_End   => False,
                        To_End    => 0,
                        Value     => Natural'Min (Natural'Max (E.Value, 0),
                                                  65_535)));
               end if;
            end;
         end loop;
      end if;

      --  5.20.7.2 to .5: the change of allowed current consumption
      if Current_S.Sense = Train.Sense then
         for I in 1 .. Current_S.Count loop
            declare
               S     : constant Sense_T := Current_S.Sense;
               E     : constant Stored_T := Current_S.List (I);
               F     : constant Dist_T := A (S, Frame (T, E.Start, Max_Item));
               C     : constant Dist_T := Diff (F, Announce);
               Max_F : constant Dist_T := A (S, Train.Max_Front);
               Min_R : constant Dist_T := A (S, Train.Min_Rear);
            begin
               if Max_F >= C and then Min_R < F then
                  Put ((Kind      => Ext_Current,
                        Id        => 160,
                        Has_Start => True,
                        To_Start  => Diff (F, Max_F),
                        Has_End   => False,
                        To_End    => 0,
                        Value     => Natural'Min (Natural'Max (E.Value, 0),
                                                  65_535)));
               end if;
            end;
         end loop;
      end if;

      --  5.20.8.2 to .6: the station platforms, to D from the max safe
      --  front end while the min safe rear end is in rear of D, to E from
      --  the min safe front end, with the height and the side, until the
      --  min safe rear end reaches E
      if Platform_S.Sense = Train.Sense then
         for I in 1 .. Platform_S.Count loop
            declare
               S     : constant Sense_T := Platform_S.Sense;
               E     : constant Stored_T := Platform_S.List (I);
               D     : constant Dist_T := A (S, Frame (T, E.Start, Max_Item));
               Fin   : constant Dist_T := A (S, Frame (T, E.Finish, Min_Item));
               C     : constant Dist_T := Diff (D, Announce);
               Max_F : constant Dist_T := A (S, Train.Max_Front);
               Min_F : constant Dist_T := A (S, Train.Min_Front);
               Min_R : constant Dist_T := A (S, Train.Min_Rear);
            begin
               if Max_F >= C and then Min_R < Fin then
                  Put ((Kind      => Ext_Platform,
                        Id        => 192 + Natural'Min (I, 63),
                        Has_Start => Min_R < D,
                        To_Start  => Diff (D, Max_F),
                        Has_End   => True,
                        To_End    => Diff (Fin, Min_F),
                        Value     => Natural'Min (Natural'Max (E.Value, 0),
                                                  65_535)));
               end if;
            end;
         end loop;
      end if;
   end External;

   -----------------
   -- Inhibitions --
   -----------------

   procedure Inhibitions (T      : Origin_Table_T;
                          Ahead  : Sense_T;
                          Length : Length_T;
                          Areas  : out Inhibition_Areas_T)
   is
   begin
      Areas := (Count => 0, Areas => (others => (Regenerative_Inhibited,
                                                 0, 0)));
      if Cond_S.Sense /= Ahead then
         return;
      end if;
      for I in 1 .. Cond_S.Count loop
         exit when Areas.Count = Max_Inhibition_Areas;
         declare
            E : constant Stored_T := Cond_S.List (I);
         begin
            if E.Value in 3 | 6 | 7 | 8 | 9 | 10 then
               Areas.Count := Areas.Count + 1;
               Areas.Areas (Areas.Count) :=
                 (Kind   => (case E.Value is
                               when 7      => Eddy_Current_Service_Inhibited,
                               when 10     =>
                                 Eddy_Current_Emergency_Inhibited,
                               when 8      => Magnetic_Shoe_Inhibited,
                               when 3 | 9  => Powerless_Section,
                               when others => Regenerative_Inhibited),
                  Start  => Frame (T, E.Start, Max_Item),
                  Finish => Advance (Frame (T, E.Finish, Min_Item), Ahead,
                                     Length));
            end if;
         end;
      end loop;
   end Inhibitions;

end EVC_Track_Conditions;
