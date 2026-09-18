--  ETCS DMI
--  Planning information (DMI 8.3): state received from the EVC and the
--  rendering of the whole planning area in D.

package DMI_Planning is

   Max_Gradients : constant := 8;
   Max_Speeds    : constant := 10;
   Max_Orders    : constant := 12;

   type Gradient_T is record
      Start_M : Natural := 0;
      Value   : Integer := 0; -- permille, negative downhill
   end record;
   type Gradient_List_T is array (1 .. Max_Gradients) of Gradient_T;

   type Speed_Disc_T is record
      Dist_M        : Natural := 0;
      Speed         : Natural := 0; -- km/h
      Is_Ind_Target : Boolean := False; -- target of the indication marker
   end record;
   type Speed_List_T is array (1 .. Max_Speeds) of Speed_Disc_T;

   type Order_T is record
      Symbol_Kind : Natural range 1 .. 37 := 1; -- PL symbol number
      Dist_M      : Natural := 0;
   end record;
   type Order_List_T is array (1 .. Max_Orders) of Order_T;

   Valid : Boolean := False;

   MA_Dist_M         : Natural := 0;
   Indication_Valid  : Boolean := False;
   Indication_Dist_M : Natural := 0;
   Advice_Valid      : Boolean := False;
   Advice_Dist_M     : Natural := 0;
   Ceiling_Speed     : Natural := 0;

   Gradients      : Gradient_List_T;
   Gradient_Count : Natural := 0;
   Speeds         : Speed_List_T;
   Speed_Count    : Natural := 0;
   Orders         : Order_List_T;
   Order_Count    : Natural := 0;

   -- DMI 8.3.3.4: six ranges; the SRS defines no default, 0-4000 is used
   type Range_Index_T is range 1 .. 6;
   Range_Max : constant array (Range_Index_T) of Natural :=
     (1_000, 2_000, 4_000, 8_000, 16_000, 32_000);
   Current_Range : Range_Index_T := 3;

   -- DMI 8.3.10.8/.9 with 5.3.2.7.5 disabling at the ends
   function Can_Zoom_In return Boolean;   -- [Scale Up], shorter range
   function Can_Zoom_Out return Boolean;  -- [Scale Down], longer range
   procedure Zoom_In;
   procedure Zoom_Out;

   -- DMI 8.3.1.1: FS/SM/AD, or OS with the toggle on and no TAF
   function Displayed return Boolean;

   -- Draw the complete planning information into area D
   procedure Render;

   procedure Reset;

end DMI_Planning;
