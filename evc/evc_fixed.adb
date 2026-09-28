--  ETCS on-board (EVC)
--  The integer arithmetic of the speed and distance monitoring,
--  implementation.

package body EVC_Fixed
  with SPARK_Mode => On
is

   ----------------
   -- Sqrt_Floor --
   ----------------

   --  Bisection on [Lo, Hi) with Lo² <= X < Hi²: 32 halvings at most
   function Sqrt_Floor (X : Num) return Num is
      Lo  : Num := 0;
      Hi  : Num := 2**31 + 1;
      Mid : Num;
   begin
      while Hi - Lo > 1 loop
         pragma Loop_Invariant (Lo in 0 .. 2**31);
         pragma Loop_Invariant (Hi in Lo + 2 .. 2**31 + 1);
         pragma Loop_Invariant (Lo * Lo <= X);
         pragma Loop_Invariant (Hi * Hi > X);
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         if Mid * Mid <= X then
            Lo := Mid;
         else
            Hi := Mid;
         end if;
      end loop;
      return Lo;
   end Sqrt_Floor;

end EVC_Fixed;
