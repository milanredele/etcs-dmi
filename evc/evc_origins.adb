--  ETCS on-board (EVC)
--  The origins of the stored location based information, implementation.

package body EVC_Origins
  with SPARK_Mode => On,
       Refined_State => (State => (Table, Refused_N))
is

   type Table_T is array (Index_T) of Origin_T;

   Table     : Table_T;
   Refused_N : Natural := 0;

   function Get (I : Index_T) return Origin_T is (Table (I))
     with Refined_Global => Table;

   function Used_Count return Count_T
     with Refined_Global => Table
   is
      N : Count_T := 0;
   begin
      for I in Index_T loop
         pragma Loop_Invariant (N < I);
         if Table (I).Used then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Used_Count;

   function Refused return Natural is (Refused_N)
     with Refined_Global => Refused_N;

   procedure Clear is
   begin
      Table := (others => (others => <>));
      Refused_N := 0;
   end Clear;

   procedure Allocate (Ref : Anchor_T; S : Sense_T; I : out Count_T) is
   begin
      I := 0;
      for J in Index_T loop
         if not Table (J).Used then
            I := J;
            exit;
         end if;
      end loop;
      if I = 0 then
         if Refused_N < Natural'Last then
            Refused_N := Refused_N + 1;
         end if;
         return;
      end if;
      Table (I) :=
        (Used => True,
         Est  => (Valid => True, Kind => Estimated_Item, Ref => Ref,
                  Sense => S, D => 0, Last_C => False,
                  Last_C_Later => False),
         Min  => (Valid => True, Kind => Min_Item, Ref => Ref,
                  Sense => S, D => 0, Last_C => False,
                  Last_C_Later => False),
         Max  => (Valid => True, Kind => Max_Item, Ref => Ref,
                  Sense => S, D => 0, Last_C => False,
                  Last_C_Later => False));
   end Allocate;

   procedure Put (I : Index_T; O : Origin_T) is
   begin
      Table (I) := O;
   end Put;

   procedure Release (I : Index_T) is
   begin
      Table (I) := (others => <>);
   end Release;

end EVC_Origins;
