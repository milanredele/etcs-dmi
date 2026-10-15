--  ETCS on-board (EVC)
--  The operated system version (see the specification)

package body EVC_System_Version
  with SPARK_Mode => On,
       Refined_State => (State => (Current, RBC_Governs))
is

   --  3.17.2.9.1: the highest supported one when nothing is known
   Current     : Major_T := Highest_X;
   RBC_Governs : Boolean := False;

   function Operated return Major_T is (Current)
     with Refined_Global => Current;

   function By_RBC return Boolean is (RBC_Governs)
     with Refined_Global => RBC_Governs;

   --  3.17.2.9, 3.17.2.9.1
   procedure Restore (Known : Boolean; X : Natural)
     with Refined_Global => (Output => (Current, RBC_Governs))
   is
   begin
      Current := (if Known and then X in Major_T then X else Highest_X);
      RBC_Governs := False;
   end Restore;

   --  3.17.2.3, 3.17.2.5, 3.17.2.6, 3.17.2.7
   procedure Take_Balise_Group (Group_X  : Natural;
                                Ordered  : Boolean;
                                Order    : M_VERSION_T;
                                Mismatch : Boolean)
     with Refined_Global => (In_Out => Current, Input => RBC_Governs)
   is
   begin
      if RBC_Governs then
         return;
      elsif Ordered then
         if Major (Order) in Major_T then
            Current := Major (Order);
         end if;
      elsif Group_X in Major_T
        and then (Mismatch or else Group_X > Current)
      then
         Current := Group_X;
      end if;
   end Take_Balise_Group;

   --  3.17.2.8 a), b), d), e)
   procedure Follow (Level_2 : Boolean; Session : Boolean; V : M_VERSION_T)
     with Refined_Global => (In_Out => Current, Output => RBC_Governs)
   is
   begin
      RBC_Governs := Level_2 and then Session and then Compatible (V);
      if RBC_Governs then
         Current := Major (V);
      end if;
   end Follow;

end EVC_System_Version;
