--  ETCS DMI test simulator
--  Eurobalise telegrams for the ETCS on-board: implementation.

with ETCS_Variables; use ETCS_Variables;

package body Sim_Telegrams is

   --  The values below come from the constant track description; they
   --  are clamped into the ranges of their variables all the same, so
   --  that a description out of range makes a wrong packet, never a
   --  raise
   function Clamp (V : Integer; Low, High : Integer) return Integer is
     (Integer'Max (Low, Integer'Min (High, V)));

   function D15 (M : Natural) return Natural is (Clamp (M, 0, 32_767));

   -----------
   -- Start --
   -----------

   procedure Start (W       : in out Writer_T;
                    NID_C   : Natural;
                    NID_BG  : Natural;
                    N_PIG   : Natural;
                    Balises : Positive;
                    Linked  : Boolean;
                    OK      : in out Boolean)
   is
      H : constant ETCS_Telegram.Header_T :=
        (Q_UPDOWN  => 1,
         M_VERSION => 48,
         Q_MEDIA   => 0,
         N_PIG     => N_PIG_T (Clamp (N_PIG, 0, 7)),
         N_TOTAL   => N_TOTAL_T (Clamp (Balises - 1, 0, 7)),
         M_DUP     => 0,
         M_MCOUNT  => 7,
         NID_C     => NID_C_T (Clamp (NID_C, 0, 1023)),
         NID_BG    => NID_BG_T (Clamp (NID_BG, 0, 16_383)),
         Q_LINK    => (if Linked then 1 else 0));
   begin
      ETCS_Bits.Clear (W);
      ETCS_Telegram.Write_Header (W, H);
      OK := OK and then not ETCS_Bits.Failed (W)
            and then N_PIG <= 7 and then Balises <= 8
            and then NID_C <= 1023 and then NID_BG <= 16_383;
   end Start;

   ---------
   -- Put --
   ---------

   procedure Put (W : in out Writer_T; P : T3.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T3.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T5.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T5.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T12.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T12.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T21.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T21.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T27.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T27.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T41.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T41.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T65.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T65.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T68.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T68.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   procedure Put (W : in out Writer_T; P : T73.Packet_T; OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T73.Encode (P, W, Done);
      OK := OK and then Done;
   end Put;

   ------------
   -- Finish --
   ------------

   procedure Finish (W  : in out Writer_T;
                     T  : out Telegram_T;
                     OK : in out Boolean)
   is
      Done : Boolean;
   begin
      T := (Bits => 0, Data => (others => 0));
      ETCS_Telegram.Finish (W, ETCS_Telegram.Long_Bits, Done);
      if Done and then ETCS_Bits.Position (W) = ETCS_Telegram.Long_Bits then
         declare
            D : constant Byte_Array := ETCS_Bits.Data (W);
         begin
            if D'Length = T.Data'Length then
               T.Data := D;
               T.Bits := ETCS_Telegram.Long_Bits;
            else
               Done := False;
            end if;
         end;
      end if;
      OK := OK and then Done;
   end Finish;

   -----------------
   -- BTM_Payload --
   -----------------

   function BTM_Payload (T     : Telegram_T;
                         Stamp : Interfaces.Unsigned_32) return Byte_Array
   is
      N      : constant Natural := (T.Bits + 7) / 8;
      Result : Byte_Array (1 .. 6 + N);
      S      : constant Interfaces.Unsigned_64 :=
        Interfaces.Unsigned_64 (Stamp);
   begin
      for I in 0 .. 3 loop
         Result (1 + I) := EVC_Bytes.Byte_Of (S, I);
      end loop;
      Result (5) := EVC_Bytes.Byte (T.Bits mod 256);
      Result (6) := EVC_Bytes.Byte (T.Bits / 256);
      Result (7 .. 6 + N) := T.Data (1 .. N);
      return Result;
   end BTM_Payload;

   ---------------------------------------------------------------------
   --  Packets
   ---------------------------------------------------------------------

   function V_Static (Kmh : Integer) return V_STATIC_T is
     (if Kmh = End_Mark then 127
      else V_STATIC_T (Clamp (Kmh / 5, 0, 120)));

   function SSP (L : Profile_List) return T27.Packet_T is
      P : T27.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_STATIC := D_STATIC_T (D15 (L (L'First).D_M));
      P.V_STATIC := V_Static (L (L'First).Value);
      P.Q_FRONT := 1;
      P.N_ITER := 0;
      P.N_ITER_2 := N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.D_STATIC_List (I).D_STATIC :=
           D_STATIC_T (D15 (L (L'First + I).D_M));
         P.D_STATIC_List (I).V_STATIC := V_Static (L (L'First + I).Value);
         P.D_STATIC_List (I).Q_FRONT := 1;
      end loop;
      return P;
   end SSP;

   function Gradients (L : Profile_List) return T21.Packet_T is
      P : T21.Packet_T;

      procedure Set (V : Integer; Q : out Q_GDIR_T; G : out G_A_T) is
      begin
         if V = End_Mark then
            Q := 1;
            G := 255;
         else
            Q := (if V >= 0 then 1 else 0);
            G := G_A_T (Clamp (abs V, 0, 254));
         end if;
      end Set;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_GRADIENT := D_GRADIENT_T (D15 (L (L'First).D_M));
      Set (L (L'First).Value, P.Q_GDIR, P.G_A);
      P.N_ITER := N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.D_GRADIENT_List (I).D_GRADIENT :=
           D_GRADIENT_T (D15 (L (L'First + I).D_M));
         Set (L (L'First + I).Value, P.D_GRADIENT_List (I).Q_GDIR,
              P.D_GRADIENT_List (I).G_A);
      end loop;
      return P;
   end Gradients;

   function MA (Lengths     : Nat_List;
                V_Main_Kmh  : Natural;
                Release_Kmh : Natural := 0) return T12.Packet_T
   is
      P : T12.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.V_MAIN := V_MAIN_T (Clamp (V_Main_Kmh / 5, 0, 120));
      P.V_EMA := 0;
      P.T_EMA := 1023;
      P.N_ITER := N_ITER_T (Lengths'Length - 1);
      for I in 1 .. Lengths'Length - 1 loop
         P.L_SECTION_List (I).L_SECTION :=
           L_SECTION_T (D15 (Lengths (Lengths'First + I - 1)));
      end loop;
      P.L_ENDSECTION := L_ENDSECTION_T (D15 (Lengths (Lengths'Last)));
      if Release_Kmh > 0 then
         P.Q_DANGERPOINT := 1;
         P.Has_D_DP := True;
         P.D_DP := 0;
         P.V_RELEASEDP := V_RELEASEDP_T (Clamp (Release_Kmh / 5, 0, 120));
      end if;
      return P;
   end MA;

   function Linking (D_Links  : Nat_List;
                     NIDs     : Nat_List;
                     Reaction : Natural := 1;
                     Locacc   : Natural := 2) return T5.Packet_T
   is
      L : T5.Packet_T;
      function Id (I : Positive) return NID_BG_T is
        (NID_BG_T (Clamp (NIDs (I), 0, 16_383)));
   begin
      L.Q_DIR := 1;
      L.Q_SCALE := 1;
      L.D_LINK := D_LINK_T (D15 (D_Links (D_Links'First)));
      L.NID_BG := Id (NIDs'First);
      L.Q_LINKORIENTATION := 1;
      L.Q_LINKREACTION := Q_LINKREACTION_T (Clamp (Reaction, 0, 2));
      L.Q_LOCACC := Q_LOCACC_T (Clamp (Locacc, 0, 63));
      L.N_ITER := N_ITER_T (D_Links'Length - 1);
      for I in 1 .. D_Links'Length - 1 loop
         L.D_LINK_List (I).D_LINK :=
           D_LINK_T (D15 (D_Links (D_Links'First + I)));
         L.D_LINK_List (I).NID_BG := Id (NIDs'First + I);
         L.D_LINK_List (I).Q_LINKORIENTATION := 1;
         L.D_LINK_List (I).Q_LINKREACTION := L.Q_LINKREACTION;
         L.D_LINK_List (I).Q_LOCACC := L.Q_LOCACC;
      end loop;
      return L;
   end Linking;

   function National_Values (NID_C      : Natural;
                             Q_NVEMRRLS : Natural := 0) return T3.Packet_T
   is
      NV : T3.Packet_T;
   begin
      NV.Q_DIR := 2;
      NV.Q_SCALE := 1;
      NV.D_VALIDNV := 0;
      NV.NID_C := NID_C_T (Clamp (NID_C, 0, 1023));
      NV.N_ITER := 0;
      NV.V_NVSHUNT := 6;
      NV.V_NVSTFF := 8;
      NV.V_NVONSIGHT := 6;
      NV.V_NVLIMSUPERV := 20;
      NV.V_NVUNFIT := 20;
      NV.V_NVREL := 8;
      NV.D_NVROLL := 2;
      NV.Q_NVSBTSMPERM := 1;
      NV.Q_NVEMRRLS := Q_NVEMRRLS_T (Clamp (Q_NVEMRRLS, 0, 1));
      NV.Q_NVGUIPERM := 0;
      NV.Q_NVSBFBPERM := 0;
      NV.Q_NVINHSMICPERM := 0;
      NV.V_NVALLOWOVTRP := 0;
      NV.V_NVSUPOVTRP := 6;
      NV.D_NVOVTRP := 200;
      NV.T_NVOVTRP := 60;
      NV.D_NVPOTRP := 200;
      NV.M_NVCONTACT := 2;
      NV.T_NVCONTACT := 255;
      NV.M_NVDERUN := 1;
      NV.D_NVSTFF := 32_767;
      NV.Q_NVDRIVER_ADHES := 0;
      NV.A_NVMAXREDADH1 := 20;
      NV.A_NVMAXREDADH2 := 14;
      NV.A_NVMAXREDADH3 := 14;
      NV.Q_NVLOCACC := 12;
      NV.M_NVAVADH := 0;
      NV.M_NVEBCL := 9;
      NV.Q_NVKINT := 0;
      return NV;
   end National_Values;

   function Track_Condition (D_M, L_M : Natural;
                             Kind     : Natural) return T68.Packet_T
   is
      P : T68.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.Q_TRACKINIT := 0;
      P.Has_D_TRACKCOND := True;
      P.D_TRACKCOND := D_TRACKCOND_T (D15 (D_M));
      P.L_TRACKCOND := L_TRACKCOND_T (D15 (L_M));
      P.M_TRACKCOND := M_TRACKCOND_T (Clamp (Kind, 0, 10));
      P.N_ITER := 0;
      return P;
   end Track_Condition;

   function TSR (Id : Natural; D_M, L_M, Kmh : Natural) return T65.Packet_T
   is
      T : T65.Packet_T;
   begin
      T.Q_DIR := 1;
      T.Q_SCALE := 1;
      T.NID_TSR := NID_TSR_T (Clamp (Id, 0, 254));
      T.D_TSR := D_TSR_T (D15 (D_M));
      T.L_TSR := L_TSR_T (D15 (L_M));
      T.Q_FRONT := 0;
      T.V_TSR := V_TSR_T (Clamp (Kmh / 5, 0, 120));
      return T;
   end TSR;

   function Level_2_Order (D_M, Ack_M : Natural) return T41.Packet_T is
      P : T41.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR := D_LEVELTR_T (Clamp (D_M, 0, 32_766));
      P.M_LEVELTR := M_LEVELTR_Level_2;
      P.Has_NID_NTC := False;
      P.L_ACKLEVELTR := L_ACKLEVELTR_T (D15 (Ack_M));
      --  phase E4: level 1 too, with a lower priority (5.10.2.2, 5.10.2.4:
      --  an on-board without a radio for level 2 stays in level 1)
      P.N_ITER := 1;
      P.M_LEVELTR_List (1) :=
        (M_LEVELTR    => M_LEVELTR_Level_1,
         Has_NID_NTC  => False,
         NID_NTC      => 0,
         L_ACKLEVELTR => L_ACKLEVELTR_T (D15 (Ack_M)));
      return P;
   end Level_2_Order;

   function Plain_Text (Text : String; D_M, L_M, NID_C : Natural)
     return T73.Packet_T
   is
      P : T73.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.Q_TEXTCLASS := Q_TEXTCLASS_Auxiliary_Information;
      P.Q_TEXTDISPLAY := Q_TEXTDISPLAY_No_Display_As_Soon;
      P.D_TEXTDISPLAY := D_TEXTDISPLAY_T (Clamp (D_M, 0, 32_766));
      P.M_MODETEXTDISPLAY := M_MODETEXTDISPLAY_No_Mode_Sub_Condition;
      P.M_LEVELTEXTDISPLAY := M_LEVELTEXTDISPLAY_No_Level_Sub_Condition;
      P.L_TEXTDISPLAY := L_TEXTDISPLAY_T (Clamp (L_M, 0, 32_766));
      P.T_TEXTDISPLAY := T_TEXTDISPLAY_No_Time_Sub_Condition;
      P.M_MODETEXTDISPLAY_2 := M_MODETEXTDISPLAY_No_Mode_Sub_Condition;
      P.M_LEVELTEXTDISPLAY_2 := M_LEVELTEXTDISPLAY_No_Level_Sub_Condition;
      P.Q_TEXTCONFIRM := Q_TEXTCONFIRM_No_Confirmation_Required;
      P.Q_TEXTREPORT := Q_TEXTREPORT_No_Driver_Acknowledgement_Report;
      P.NID_C := NID_C_T (Clamp (NID_C, 0, 1023));
      P.NID_RBC := 0;
      P.L_TEXT := L_TEXT_T (Text'Length);
      for I in 1 .. Text'Length loop
         P.X_TEXT_List (I) :=
           X_TEXT_T (Character'Pos (Text (Text'First + I - 1)));
      end loop;
      return P;
   end Plain_Text;

end Sim_Telegrams;
