--  ETCS on-board (EVC)
--  The inputs of the train interface that the modes read in a cycle
--  (SUBSET-034 2.5.1 the cab status, 2.2.2 the sleeping, passive
--  shunting and non leading inputs; SUBSET-026 4.6.3 [2], [3], [14],
--  [26] to [30], [46], [47]). EVC_Core latches the TIU port and hands
--  the values of the cycle over at its first step (Set); the conditions
--  of 4.6.3 and the start of mission read them here.
--
--  SUBSET-034 2.5.1: one cab status input per cab; "cab active" is
--  "desk open" in SUBSET-026. A desk is open when a cab is active;
--  every desk is closed when none is.

package EVC_Train_Inputs
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   function Cab_A_Active return Boolean
     with Global => State;
   function Cab_B_Active return Boolean
     with Global => State;

   --  4.6.3 [2], [22], [23]: a desk is open; [14], [26] to [30]: the
   --  desks are closed
   function Desk_Open return Boolean is (Cab_A_Active or else Cab_B_Active)
     with Global => State;

   --  4.6.3 [3], [14]: "Sleeping requested"
   function Sleeping_Requested return Boolean
     with Global => State;
   --  4.6.3 [26], [30]: "Passive shunting permitted"
   function Passive_Shunting_Permitted return Boolean
     with Global => State;
   --  4.6.3 [46], [47]: "Non-leading permitted"
   function Non_Leading_Permitted return Boolean
     with Global => State;

   --  Power-up: no cab active, nothing requested or permitted
   procedure Clear
     with Global => (Output => State),
          Post => not Desk_Open and then not Sleeping_Requested
                  and then not Passive_Shunting_Permitted
                  and then not Non_Leading_Permitted;

   --  The inputs of the cycle
   procedure Set (Cab_A, Cab_B, Sleeping, Passive_Shunting,
                  Non_Leading : Boolean)
     with Global => (Output => State),
          Post => Cab_A_Active = Cab_A and then Cab_B_Active = Cab_B
                  and then Sleeping_Requested = Sleeping
                  and then Passive_Shunting_Permitted = Passive_Shunting
                  and then Non_Leading_Permitted = Non_Leading;

end EVC_Train_Inputs;
