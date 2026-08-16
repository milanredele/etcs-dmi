--  ETCS DMI
--  Button engine implementation (DMI 5.3.2.6).

pragma Ada_2012;
with DMI_Sounds;

package body DMI_Buttons is

   type Button_T is record
      Active   : Boolean := False;
      The_Area : Display.Area_T := ((0, 0), 0, 0);
      Kind     : Kind_T := Up_Type;
   end record;

   Buttons : array (Button_ID_T) of Button_T;

   -- Only one button can be pressed at a time (DMI 5.3.2.5)
   Tracking     : Boolean := False;
   Tracked      : Button_ID_T := Button_ID_T'First;
   Inside       : Boolean := False;
   Held_Ms      : Natural := 0;
   Repeat_Ms    : Natural := 0;

   Down_Type_Repeat_Delay    : constant := 1500; -- DMI 5.3.2.6.5
   Down_Type_Repeat_Interval : constant := 300;
   Delay_Type_Hold           : constant := 2000; -- DMI 5.3.2.6.6
   Delay_Type_Toggle         : constant := 250;

   Activations : array (1 .. 8) of Button_ID_T;
   Activation_Count : Natural := 0;

   procedure Queue_Activation (ID : Button_ID_T) is
   begin
      if Activation_Count < Activations'Last then
         Activation_Count := Activation_Count + 1;
         Activations (Activation_Count) := ID;
      end if;
   end Queue_Activation;

   function Contains (The_Area : Display.Area_T; X, Y : Natural) return Boolean is
     (X >= The_Area.Position.X
      and then X < The_Area.Position.X + The_Area.Width
      and then Y >= The_Area.Position.Y
      and then Y < The_Area.Position.Y + The_Area.Height);

   procedure Set_Active (ID       : Button_ID_T;
                         The_Area : Display.Area_T;
                         Kind     : Kind_T) is
   begin
      Buttons (ID) := (Active => True, The_Area => The_Area, Kind => Kind);
   end Set_Active;

   procedure Set_Inactive (ID : Button_ID_T) is
   begin
      Buttons (ID).Active := False;
      if Tracking and then Tracked = ID then
         Tracking := False;
      end if;
   end Set_Inactive;

   procedure Pointer_Event (Event : Pointer_Event_T;
                            X, Y  : Natural) is
   begin
      case Event is
         when Down =>
            if Tracking then
               return; -- one press at a time
            end if;
            for ID in Button_ID_T loop
               if Buttons (ID).Active
                 and then Contains (Buttons (ID).The_Area, X, Y)
               then
                  Tracking := True;
                  Tracked := ID;
                  Inside := True;
                  Held_Ms := 0;
                  Repeat_Ms := 0;
                  -- DMI 5.3.2.6.2/.4/.6: 'click' on the initial press
                  DMI_Sounds.Play (DMI_Sounds.Click);
                  if Buttons (ID).Kind = Down_Type then
                     -- activation together with the press
                     Queue_Activation (ID);
                  end if;
                  exit;
               end if;
            end loop;

         when Move =>
            if Tracking then
               declare
                  Was_Inside : constant Boolean := Inside;
               begin
                  Inside := Contains (Buttons (Tracked).The_Area, X, Y);
                  -- DMI 5.3.2.6.7: leaving a delay-type button resets its
                  -- 2 second timer; re-entering restarts it without click
                  if Buttons (Tracked).Kind = Delay_Type
                    and then Was_Inside and then not Inside
                  then
                     Held_Ms := 0;
                  end if;
               end;
            end if;

         when Up =>
            if Tracking then
               case Buttons (Tracked).Kind is
                  when Up_Type =>
                     -- DMI 5.3.2.6.3: activation counted on release
                     if Inside then
                        Queue_Activation (Tracked);
                     end if;
                  when Delay_Type =>
                     -- DMI 5.3.2.6.6: only valid after 2 s of pressing
                     if Inside and then Held_Ms >= Delay_Type_Hold then
                        Queue_Activation (Tracked);
                     end if;
                  when Down_Type =>
                     null; -- already activated on press
               end case;
               Tracking := False;
            end if;
      end case;
   end Pointer_Event;

   procedure Tick (Dt_Ms : Natural) is
   begin
      if not Tracking then
         return;
      end if;
      if Inside then
         Held_Ms := Held_Ms + Dt_Ms;
      end if;
      -- DMI 5.3.2.6.5: optional repeat function of down-type buttons
      if Buttons (Tracked).Kind = Down_Type and then Inside then
         if Held_Ms >= Down_Type_Repeat_Delay then
            Repeat_Ms := Repeat_Ms + Dt_Ms;
            if Repeat_Ms >= Down_Type_Repeat_Interval then
               Repeat_Ms := Repeat_Ms - Down_Type_Repeat_Interval;
               Queue_Activation (Tracked);
            end if;
         end if;
      end if;
   end Tick;

   function Is_Pressed (ID : Button_ID_T) return Boolean is
   begin
      if not Tracking or else Tracked /= ID or else not Inside then
         return False;
      end if;
      case Buttons (ID).Kind is
         when Up_Type =>
            return True;
         when Down_Type =>
            return True;
         when Delay_Type =>
            -- toggle the pressed rendering every 0.25 s; after 2 s the
            -- button behaves as up-type (steady pressed)
            return Held_Ms >= Delay_Type_Hold
              or else (Held_Ms / Delay_Type_Toggle) mod 2 = 0;
      end case;
   end Is_Pressed;

   function Pop_Activation (ID : out Button_ID_T) return Boolean is
   begin
      if Activation_Count = 0 then
         return False;
      end if;
      ID := Activations (1);
      Activations (1 .. Activation_Count - 1) :=
        Activations (2 .. Activation_Count);
      Activation_Count := Activation_Count - 1;
      return True;
   end Pop_Activation;

end DMI_Buttons;
