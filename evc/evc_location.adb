--  ETCS on-board (EVC)
--  Reference balise groups and location items, implementation.

package body EVC_Location
  with SPARK_Mode => On
is

   --------------
   -- Relocate --
   --------------

   procedure Relocate (Item   : in out Item_T;
                       To     : Anchor_T;
                       Linked : Boolean;
                       Link   : Dist_T;
                       Low    : Length_T;
                       High   : Length_T)
   is
      S    : constant Sense_T := Item.Sense;
      F    : constant Anchor_T := Item.Ref;
      Step : Dist_T;
   begin
      if Item.Ref = To then
         return;
      end if;
      if Linked and then not Item.Last_C then
         --  a) the linking distance as such
         Step := Link;
         Item.Last_C := False;
      elsif Linked and then Item.Last_C_Later then
         --  b) the linking distance, widened by twice the accuracy of
         --  the former reference on the side of the kind of the item
         Step := (case Item.Kind is
                     when Estimated_Item => Link,
                     when Min_Item => Diff (Link, Add (F.Locacc, F.Locacc)),
                     when Max_Item => Sum (Link, Add (F.Locacc, F.Locacc)));
         Item.Last_C := False;
      else
         --  c) the travelled distance between the two groups, from the
         --  estimated, min or max front end positions against each: the
         --  difference of the estimated ones is the distance between the
         --  location references, and the confidence intervals differ by
         --  their accuracies and the deviations since each detection
         declare
            Est : constant Dist_T := Estimated (F, S, To.X);
         begin
            Step :=
              (case Item.Kind is
                  when Estimated_Item => Est,
                  when Min_Item =>
                     Diff (Est, Diff (Doubt_Over (F, S, Low, High),
                                      Doubt_Over (To, S, Low, High))),
                  when Max_Item =>
                     Sum (Est, Diff (Doubt_Under (F, S, Low, High),
                                     Doubt_Under (To, S, Low, High))));
         end;
         Item.Last_C := True;
         Item.Last_C_Later := To.Seq >= F.Seq;
      end if;
      Item.D := Diff (Item.D, Step);
      Item.Ref := To;
   end Relocate;

end EVC_Location;
