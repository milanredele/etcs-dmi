--  ETCS DMI
--  Automatic Train Operation information (DMI 8.5): the state the EVC
--  relays from the ERTMS/ATO on-board (MSG_ATO, see dmi_protocol.ads)
--  and the position of the ATO selector (11.3.14). The stopping points
--  are planning objects and live in DMI_Planning (8.5.3, 8.3.4.25).
--
--  Nothing here is derived: every value is the on-board's. Until a
--  first MSG_ATO arrives nothing is known and nothing of 8.5 is shown.

package DMI_ATO is

   -- SUBSET-026 3.15.11.2: "On" or "Stand-by"; Unknown until the EVC
   -- reports it (read as Stand-by)
   type Selector_T is (Unknown, Stand_By, On);

   -- 8.5.2.4: ATO01 .. ATO05
   type Status_T is (No_Status,
                     Selected,      -- ATO01
                     Ready,         -- ATO02, ready for engagement
                     Engaged,       -- ATO03
                     Disengaging,   -- ATO04
                     Failure);      -- ATO05

   -- 8.5.4.3 .. 8.5.4.5: ATO06 .. ATO08
   type Accuracy_T is (No_Accuracy, Overshoot, Undershoot, Accurate);

   -- 8.5.6.3: ATO10 .. ATO16
   type Doors_T is (No_Doors,
                    Open_Both,       -- ATO10
                    Open_Left,       -- ATO11
                    Open_Right,      -- ATO12
                    Doors_Open,      -- ATO13
                    Close_Request,   -- ATO14
                    Closing,         -- ATO15
                    Doors_Closed);   -- ATO16

   -- 8.5.8.4: ATO17 .. ATO19
   type Skip_T is (No_Skip, Inactive, By_Trackside, By_Driver);

   -- 8.5.5.4 / 8.5.5.5: '[s]s' up to 59 s, '[m]m:ss' up to 99:59
   Max_Dwell_S : constant := 5_999;
   subtype Dwell_T is Natural range 0 .. Max_Dwell_S;

   -- dmi_protocol.ads, ATO_Max_Name
   Max_Name : constant := 32;
   subtype Name_Length_T is Natural range 0 .. Max_Name;

   Selector          : Selector_T := Unknown;
   Status            : Status_T := No_Status;
   Warning           : Boolean := False;
   At_Stopping_Point : Boolean := False;
   Accuracy          : Accuracy_T := No_Accuracy;
   Dwell_Valid       : Boolean := False;
   Dwell_S           : Dwell_T := 0;
   Train_Hold        : Boolean := False;
   Doors             : Doors_T := No_Doors;
   Skip              : Skip_T := No_Skip;
   Advice_Valid      : Boolean := False;
   Advice_Speed      : Natural range 0 .. 400 := 0;
   Coasting          : Boolean := False;
   ETA_Valid         : Boolean := False;
   ETA_H             : Natural range 0 .. 23 := 0;
   ETA_M, ETA_S      : Natural range 0 .. 59 := 0;
   Name_Length       : Name_Length_T := 0;
   Name              : Wide_String (1 .. Max_Name) := (others => ' ');

   -- 8.5.1.1: the ATO information is shown if the ATO selector is set
   -- to "On"
   function Displayed return Boolean is (Selector = On);

   -- 8.5.1.2 d: the objects shown outside stopping points (next
   -- stopping point name and estimated arrival time, skip stopping point
   -- status, target advice speed, coasting advice, next advice change
   -- marker)
   function Outside_Shown return Boolean is
     (Displayed and then not At_Stopping_Point);

   -- 8.5.2.5 / 8.5.2.6: G1 is an enabled up-type button while ATO02
   -- (engage) or ATO03 / ATO04 (disengage) is displayed
   function Engage_Button return Boolean is
     (Displayed and then Status in Ready | Engaged | Disengaging);

   -- The request G1 stands for: True the start of automatic driving
   -- (ATO02), False its stop (ATO03, ATO04)
   function Engage_Requested return Boolean is (Status = Ready);

   -- 8.5.8.5: G5 is an enabled delay-type button while ATO17 or ATO19
   -- is displayed
   function Skip_Button return Boolean is
     (Outside_Shown and then Skip in Inactive | By_Driver);

   -- The request G5 stands for: True request the skip (ATO17), False
   -- revoke it (ATO19)
   function Skip_Requested return Boolean is (Skip = Inactive);

   procedure Reset;

end DMI_ATO;
