--  ETCS DMI
--  Planning information (DMI 8.3): state received from the EVC and the
--  rendering of the whole planning area in D.

package DMI_Planning is

   ---------------------------------------------------------------------
   -- Limits
   --
   -- The SRS sets no upper limit to the number of elements; 8.3.5.2 and
   -- 8.3.6.2 ask for the profiles within the movement authority, 8.3.6.3
   -- for all MRSP discontinuities. Storage is static, so there are
   -- capacities. They are chosen for the longest range, 0-32000 m
   -- (8.3.3.4): a gradient change every 500 m, a speed discontinuity and
   -- an order every 1000 m on average over the whole range. 32 orders is
   -- also about what three columns of 20 cell symbols can show without
   -- overlap (8.3.4.23).
   --
   -- Memory: an element is packed into 4 bytes (gradient, order) or
   -- 6 bytes (speed), so the lists take 64 * 4 + 32 * 6 + 32 * 4 = 576
   -- bytes of static data, plus 128 bytes of stack while the orders are
   -- sorted for drawing. (The former 8/10/12 elements with 32 bit
   -- fields took 280 bytes.)
   --
   -- Overflow: see Add_Gradient, Add_Speed and Add_Order. The rule is
   -- that what is not known is not drawn as if it were known.
   ---------------------------------------------------------------------

   Max_Gradients : constant := 64;
   Max_Speeds    : constant := 32;
   Max_Orders    : constant := 32;

   -- 8.2.1.1.3: the largest speed dial ends at 400 km/h; a higher speed
   -- in the planning information is not valid
   Max_Speed_Kmh : constant := 400;

   -- A distance as the protocol carries it (u16, metres)
   subtype Distance_T is Natural range 0 .. 65_535;
   -- 8.3.3.4: the end of the longest range. Nothing beyond it can be
   -- displayed in any range, so nothing beyond it is stored.
   Max_Range_M : constant Distance_T := 32_000;

   subtype Gradient_Value_T is Integer range -128 .. 127; -- i8, permille
   subtype Speed_T is Natural range 0 .. Max_Speed_Kmh;

   type Gradient_T is record
      Start_M : Distance_T := 0;
      Value   : Gradient_Value_T := 0; -- permille, negative downhill
   end record;
   for Gradient_T use record
      Start_M at 0 range 0 .. 15;
      Value   at 2 range 0 .. 7;
   end record;
   for Gradient_T'Size use 32;
   type Gradient_List_T is array (1 .. Max_Gradients) of Gradient_T;

   type Speed_Disc_T is record
      Dist_M        : Distance_T := 0;
      Speed         : Speed_T := 0; -- km/h
      Is_Ind_Target : Boolean := False; -- target of the indication marker
   end record;
   for Speed_Disc_T use record
      Dist_M        at 0 range 0 .. 15;
      Speed         at 2 range 0 .. 15;
      Is_Ind_Target at 4 range 0 .. 7;
   end record;
   for Speed_Disc_T'Size use 48;
   type Speed_List_T is array (1 .. Max_Speeds) of Speed_Disc_T;

   type Order_T is record
      Symbol_Kind : Natural range 1 .. 37 := 1; -- PL symbol number
      Dist_M      : Distance_T := 0;
   end record;
   for Order_T use record
      Dist_M      at 0 range 0 .. 15;
      Symbol_Kind at 2 range 0 .. 7;
   end record;
   for Order_T'Size use 32;
   type Order_List_T is array (1 .. Max_Orders) of Order_T;

   pragma Compile_Time_Error
     (Gradient_List_T'Size + Speed_List_T'Size + Order_List_T'Size
        > 576 * 8,
      "the planning lists take more memory than documented above");

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

   -- The distance up to which each profile is known. It is the end of
   -- the scale while the profile is complete, and the place where the
   -- profile was cut otherwise (see Add_Gradient and Add_Speed). The
   -- last gradient rectangle (8.3.5.5) and the PASP (8.3.7) end there
   -- or at the end of the movement authority, whichever is nearer.
   Gradient_End_M : Distance_T := Distance_T'Last;
   Speed_End_M    : Distance_T := Distance_T'Last;
   -- Valid orders that found no room, for diagnosis
   Orders_Left_Out : Natural := 0;

   -- Update interface for the message decoder. Every value is checked
   -- here, so any content coming from the EVC can be passed in; what is
   -- not valid is left out, never stored as something else.
   --
   -- Begin_Update empties the three lists; the Add procedures append
   -- one element each.
   procedure Begin_Update;

   -- Gradient elements and speed discontinuities come in the order of
   -- their distance (equal distances are accepted). The length of an
   -- element is only known from the start of the next one (8.3.5.5), so
   -- a profile is cut at the first element that cannot be stored, and
   -- everything after the cut is left out:
   --  * an element nearer than the one before it: the order is broken
   --    and the end of the element before it is unknown, so the profile
   --    ends where that element starts;
   --  * no room left (Max_Gradients, Max_Speeds), a start beyond
   --    Max_Range_M, a gradient outside Gradient_Value_T or a speed
   --    above Max_Speed_Kmh: the profile ends at the start of this
   --    element, which still bounds the element before it.
   -- Nothing is drawn beyond the cut: no stretched gradient rectangle,
   -- no PASP, no discontinuity symbol.
   procedure Add_Gradient (Start_M : Natural; Value : Integer);
   procedure Add_Speed (Dist_M, Speed : Natural; Is_Ind_Target : Boolean);

   -- 8.3.4.3 to 8.3.4.20: the orders and announcements are PL01-PL20 and
   -- PL24-PL36. PL21-PL23 and PL37 belong to the speed profile
   -- discontinuities (8.3.6.4, 8.3.6.4.2) and are no orders. An element
   -- with any other symbol number is left out.
   function Is_Order_Symbol (Symbol_Kind : Natural) return Boolean is
     (Symbol_Kind in 1 .. 20 | 24 .. 36);
   -- Orders may come in any order. One beyond Max_Range_M is left out.
   -- When Max_Orders are stored, the nearest ones are kept (8.3.4.24
   -- gives them precedence on the display as well): a nearer one
   -- replaces the farthest one, a farther one is left out. Both are
   -- counted in Orders_Left_Out.
   procedure Add_Order (Symbol_Kind, Dist_M : Natural);

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
