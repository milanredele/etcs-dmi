--  ETCS on-board (EVC)
--  The stored information kept over No Power (see the specification)

package body EVC_Retained
  with SPARK_Mode => On,
       Refined_State => (State => Store)
is

   Store : Kept_T;

   procedure Erase is
   begin
      Store := (others => <>);
   end Erase;

   function Saved return Boolean is (Store.Saved)
     with Refined_Global => Store;

   procedure Save (K : Kept_T) is
   begin
      Store := K;
   end Save;

   procedure Load (K : out Kept_T) is
   begin
      K := Store;
   end Load;

end EVC_Retained;
