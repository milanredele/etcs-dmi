--  ETCS on-board (EVC)
--  The inputs of the train interface of a cycle, implementation.

package body EVC_Train_Inputs
  with SPARK_Mode => On,
       Refined_State => (State => (A, B, Sleeping_In, PS_In, NL_In))
is

   A, B        : Boolean := False;
   Sleeping_In : Boolean := False;
   PS_In       : Boolean := False;
   NL_In       : Boolean := False;

   function Cab_A_Active return Boolean is (A)
     with Refined_Global => A;
   function Cab_B_Active return Boolean is (B)
     with Refined_Global => B;
   function Sleeping_Requested return Boolean is (Sleeping_In)
     with Refined_Global => Sleeping_In;
   function Passive_Shunting_Permitted return Boolean is (PS_In)
     with Refined_Global => PS_In;
   function Non_Leading_Permitted return Boolean is (NL_In)
     with Refined_Global => NL_In;

   procedure Clear is
   begin
      A := False;
      B := False;
      Sleeping_In := False;
      PS_In := False;
      NL_In := False;
   end Clear;

   procedure Set (Cab_A, Cab_B, Sleeping, Passive_Shunting,
                  Non_Leading : Boolean)
   is
   begin
      A := Cab_A;
      B := Cab_B;
      Sleeping_In := Sleeping;
      PS_In := Passive_Shunting;
      NL_In := Non_Leading;
   end Set;

end EVC_Train_Inputs;
