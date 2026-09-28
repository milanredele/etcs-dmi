--  ETCS on-board (EVC)
--  Linking information stored on-board, implementation.

package body EVC_Linking
  with SPARK_Mode => On
is

   ----------
   -- Find --
   ----------

   function Find (L : Linking_T; Id : Identity_T; From : Positive)
     return Link_Count_T
   is
   begin
      for I in From .. L.Count loop
         if L.Links (I).Known_Id and then L.Links (I).Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   -----------------
   -- From_Packet --
   -----------------

   procedure From_Packet (P      : ETCS_Track_Packets.P5.Packet_T;
                          Sender : Identity_T;
                          Sense  : Sense_T;
                          L      : out Linking_T;
                          OK     : out Boolean)
   is
      Scale   : constant Natural := Natural (P.Q_SCALE);
      Country : NID_C_T := Sender.NID_C;
      D       : Length_T := 0;

      --  One announced group; Q_NEWCOUNTRY 0: the country of the one
      --  before (7.5.1.121)
      procedure Put (I            : Link_Index_T;
                     D_LINK       : D_LINK_T;
                     New_Country  : Boolean;
                     NID_C        : NID_C_T;
                     NID_BG       : NID_BG_T;
                     Orientation  : Q_LINKORIENTATION_T;
                     Reaction     : Q_LINKREACTION_T;
                     Locacc       : Q_LOCACC_T)
        with Pre => Valid_Scale (Scale)
                    and then D <= Cm_T (I - 1) * 32_767 * 1000,
             Post => D <= Cm_T (I) * 32_767 * 1000
                     and then L.Solr = L.Solr'Old
                     and then L.Expected = L.Expected'Old
                     and then L.Ref_Id = L.Ref_Id'Old
      is
      begin
         if New_Country then
            Country := NID_C;
         end if;
         D := D + Scaled (Natural (D_LINK), Scale);
         L.Links (I) :=
           (Known_Id => NID_BG /= 16383,
            Id       => (NID_C => Country, NID_BG => NID_BG),
            D        => D,
            Nominal  => Orientation = 1,
            Reaction => Reaction,
            Locacc   => Metres (Natural (Locacc)));
      end Put;
   begin
      L := (Stored   => False,
            Ref_Id   => Sender,
            Sense    => Sense,
            Count    => 0,
            Links    => (others => <>),
            Expected => 1,
            Solr     => 0);
      OK := Valid_Scale (Scale)
        and then P.Q_LINKREACTION <= 2
        and then (for all I in 1 .. Natural (P.N_ITER) =>
                    P.D_LINK_List (I).Q_LINKREACTION <= 2);
      if not OK then
         return;
      end if;
      Put (1, P.D_LINK, P.Q_NEWCOUNTRY = 1, P.NID_C, P.NID_BG,
           P.Q_LINKORIENTATION, P.Q_LINKREACTION, P.Q_LOCACC);
      for K in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (D <= Cm_T (K) * 32_767 * 1000);
         pragma Loop_Invariant
           (L.Solr = 0 and then L.Expected = 1 and then L.Ref_Id = Sender);
         declare
            Item : constant ETCS_Track_Packets.P5.D_LINK_Item :=
              P.D_LINK_List (K);
         begin
            Put (K + 1, Item.D_LINK, Item.Q_NEWCOUNTRY = 1, Item.NID_C,
                 Item.NID_BG, Item.Q_LINKORIENTATION, Item.Q_LINKREACTION,
                 Item.Q_LOCACC);
         end;
      end loop;
      L.Count := 1 + Natural (P.N_ITER);
      L.Stored := True;
   end From_Packet;

end EVC_Linking;
