--  ETCS DMI
--  Generic data entry engine (DMI 10.3) and data validation window
--  (10.4), touch screen technology.
--
--  DMI_Windows owns the window stack and the dialogue sequences; it
--  opens a window definition here, asks for the buttons of the current
--  state, forwards the presses, renders, and reads the entered values
--  back when the engine reports the entry complete. Nothing in this
--  package knows the windows of chapter 11.

with Display;
with DMI_Buttons;
with DMI_Driver_Data;

package DMI_Data_Entry is

   --  10.3.5.1: at most 4 input fields on the total grid array, one on
   --  the half grid array
   Max_Fields : constant := 4;
   subtype Field_Count_T is Natural range 0 .. Max_Fields;
   subtype Field_Index_T is Positive range 1 .. Max_Fields;

   --  30 characters take the longest title of chapter 11, 'Mission
   --  with one radio system' (11.3.16.2)
   Max_Label : constant := 30;
   subtype Label_T is Wide_String (1 .. Max_Label);

   --  10.3.5.12: the keyboard presented for the selected input field.
   --  The enhanced numeric keyboard (10.3.5.16) and a dedicated keyboard
   --  with predefined choices (10.3.5.19) are further values of this
   --  type; each only adds its key labels and what a key press appends.
   type Keyboard_T is
     (Numeric,     -- 10.3.5.15
      Yes_No,      -- 10.3.5.18, dedicated keyboard limited to 'No'/'Yes'
      Dedicated,   -- 10.3.5.19, predefined choices with [More] on key 12
      Alphanumeric);  -- 10.3.5.17, multi-tap keys (10.3.2.5)

   --  10.3.5.19: the predefined choices of a dedicated keyboard. One
   --  choice is one key label and, once chosen, the whole data value of
   --  the input field. 18 characters take the longest label of chapter
   --  11 ('Non slippery rail', Table 43); 20 choices take the longest
   --  list (Table 41, 18 train categories).
   Max_Choice_Label : constant := 18;
   subtype Choice_Label_T is Wide_String (1 .. Max_Choice_Label);

   Max_Choices : constant := 20;
   subtype Choice_Count_T is Natural range 0 .. Max_Choices;
   subtype Choice_Index_T is Positive range 1 .. Max_Choices;

   type Choice_T is record
      Label   : Choice_Label_T := (others => ' ');
      --  11.3.2.7 / 11.3.2.8: a choice the on-board does not offer is a
      --  disabled key; an empty label is a key that is not there at all
      --  (Table 38 leaves the key 3 empty)
      Enabled : Boolean := True;
   end record;

   type Choice_Array_T is array (Choice_Index_T) of Choice_T;

   type Choice_Set_T is record
      Count : Choice_Count_T := 0;
      List  : Choice_Array_T;
   end record;

   No_Choices : constant Choice_Set_T := (Count => 0, List => (others => <>));

   --  Append one predefined choice; an empty label leaves the key empty.
   --  A set that is already full is left alone (total, never raises).
   procedure Add_Choice (Set     : in out Choice_Set_T;
                         Label   : Wide_String;
                         Enabled : Boolean := True);

   --  10.3.4.1.2: the permitted range and the resolution of an input
   --  field are configured in the on-board and their definition is
   --  outside the scope of the specification. Defined = False: no rule,
   --  the check is satisfied. A resolution of 0 or 1 accepts any value.
   type Check_Rule_T is record
      Defined    : Boolean := False;
      Min        : Natural := 0;
      Max        : Natural := 0;
      Resolution : Natural := 1;
   end record;

   No_Rule : constant Check_Rule_T := (others => <>);

   type Field_Def_T is record
      Label    : Label_T := (others => ' ');
      Keyboard : Keyboard_T := Numeric;
      Max_Len  : Natural := 5;
      --  11.7.1.4: the stored value is proposed in the input field
      Proposed : DMI_Driver_Data.Text_Value_T;
      --  10.3.4.2, 10.3.4.3: technical range and resolution check
      Technical : Check_Rule_T := No_Rule;
      --  10.3.4.5: operational range check
      Operational : Check_Rule_T := No_Rule;
      --  10.3.5.19: the predefined choices of a dedicated keyboard and
      --  the one the proposed value stands for (0: none)
      Choices : Choice_Set_T := No_Choices;
      Proposed_Choice : Natural := 0;
      --  10.3.3.1: the echo line this input field feeds when the topic
      --  spans several windows (11.3.9.3); 0: the input fields of this
      --  window are echoed in their own order
      Echo_Line : Natural := 0;
   end record;

   type Field_Def_List_T is array (Field_Index_T) of Field_Def_T;

   --  10.3.5.2 / 10.3.5.3 / 10.4.1.1
   type Layout_T is
     (Half_Grid,    -- Table 22: D/F/G, a single input field
      Total_Grid,   -- Tables 23, 24, 25: A/B/C/D/E/F/G, echo texts
      Validation);  -- Table 29: A/B/C/D/E/F/G, 'No'/'Yes' choice

   --  10.4.1.5: the validation window echoes the input fields of the
   --  topic it validates, which are not its own input field
   type Echo_Item_T is record
      Label    : Label_T := (others => ' ');
      Value    : DMI_Driver_Data.Text_Value_T;
      Accepted : Boolean := False;  -- 10.3.3.5: white when accepted
      --  5.1.5.2.2: data limited to dedicated values is not grouped
      Group    : Boolean := True;
   end record;

   --  11.3.9 with 11.4.1.3: a topic can have more input fields than one
   --  window holds, and every window of the topic echoes all of them
   --  (Figures 120, 121, 130: the 7 items of the flexible train data
   --  entry)
   Max_Echo : constant := 8;
   subtype Echo_Count_T is Natural range 0 .. Max_Echo;
   subtype Echo_Index_T is Positive range 1 .. Max_Echo;

   type Echo_List_T is array (Echo_Index_T) of Echo_Item_T;

   type Window_Def_T is record
      Layout      : Layout_T := Half_Grid;
      Title       : Label_T := (others => ' ');
      Field_Count : Field_Count_T := 0;
      Fields      : Field_Def_List_T;
      --  0: the echo texts are those of the window's own input fields
      Echo_Count  : Echo_Count_T := 0;
      Echo        : Echo_List_T;
      --  5.3.1.2.1 g with Tables 22 and 23: the windows of a topic are
      --  numbered in the title and carry [Previous] and [Next]
      Page        : Positive := 1;
      Page_Count  : Positive := 1;
      --  10.3.5.9: every input field of the topic that is not on this
      --  window already displays a data value (Table 50 S3-1)
      Topic_Complete : Boolean := True;
      --  10.3.5.6: a window on the total grid array echoes its input
      --  fields; 11.3.5.1: the RBC data window has "no echo texts"
      Echo_Texts : Boolean := True;
      --  10.3.1.7 lets a single input field consist of its data area
      --  only; True keeps the label area all the same (11.3.5.3: the
      --  input field 'RBC ID' of an RBC data window without the phone
      --  number field)
      Labelled : Boolean := False;
   end record;

   --  Build a window title / one field definition; the text is padded,
   --  a longer text is cut
   function Window_Title (Text : Wide_String) return Label_T;

   function Field
     (Label    : Wide_String;
      Max_Len  : Natural;
      Keyboard : Keyboard_T := Numeric;
      Proposed : DMI_Driver_Data.Text_Value_T := (0, (others => ' '));
      Technical   : Check_Rule_T := No_Rule;
      Operational : Check_Rule_T := No_Rule;
      Choices     : Choice_Set_T := No_Choices;
      Proposed_Choice : Natural := 0;
      Echo_Line   : Natural := 0)
      return Field_Def_T;

   function Echo
     (Label    : Wide_String;
      Value    : DMI_Driver_Data.Text_Value_T;
      Accepted : Boolean := True;
      Group    : Boolean := True) return Echo_Item_T;

   --  10.3.4.4 / 10.3.4.6: cross-check rules between input fields. They
   --  are a configuration of the on-board too (10.3.4.1.2) and neither
   --  the DMI specification nor the protocol carries one, so no rule is
   --  configured here; the mechanism and the '????' presentation exist
   --  and an integration fills this list. Rules are executed in the
   --  order of the list, technical ones first (Figure 98).
   type Cross_Kind_T is (No_Cross, Technical_Cross, Operational_Cross);
   type Cross_Relation_T is (Not_Greater, Not_Less);

   type Cross_Rule_T is record
      Kind     : Cross_Kind_T := No_Cross;
      A        : Field_Index_T := 1;
      B        : Field_Index_T := 1;
      Relation : Cross_Relation_T := Not_Greater; -- value (A) rel value (B)
   end record;

   Max_Cross_Rules : constant := 4;
   type Cross_Rule_List_T is array (1 .. Max_Cross_Rules) of Cross_Rule_T;

   Cross_Rules : Cross_Rule_List_T := (others => (others => <>));

   --  10.6.1.1: a data entry / validation process starts with the first
   --  window of the topic
   procedure Open (Definition : Window_Def_T);

   --  The area the window covers (the background to fill): D/F/G for the
   --  half grid array, the whole grid for the total grid array
   function Covered_Area return Display.Area_T;

   --  Window-internal buttons for the registry of DMI_Core; a button not
   --  enabled is not registered (5.3.2.7.5)
   function Button_Count return Natural;
   function Button_Area (Index : Positive) return Display.Area_T;
   function Button_Enabled (Index : Positive) return Boolean;
   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T;

   procedure Press (Index : Positive);

   --  10.3.2.5 a: the multi-tap keyboards need time. Dt_Ms is the
   --  elapsed time since the last call; any value is accepted. Called by
   --  DMI_Core.Tick, like every other timed part of the DMI.
   procedure Tick (Dt_Ms : Natural);

   --  True once, when the driver completed the entry (the values are
   --  then read with Value / Number)
   function Take_Completion return Boolean;

   --  Tables 22 and 23: the window of the topic the driver asked for by
   --  pressing [Previous] or [Next]; 0 when none was asked. Taken once,
   --  like Take_Completion.
   function Take_Page_Request return Natural;

   function Value (Index : Field_Index_T) return DMI_Driver_Data.Text_Value_T;

   --  10.3.5.19: the predefined choice the value of a dedicated keyboard
   --  input field stands for (its position in the choice set); 0 when
   --  the field holds no choice
   function Choice_Number (Index : Field_Index_T) return Natural;

   --  10.3.1.15 / 10.3.3.5: the driver accepted the value of this input
   --  field during the running data entry process (its echo text is
   --  white), needed by the caller to carry the state over to the next
   --  window of the same topic
   function Accepted (Index : Field_Index_T) return Boolean;

   --  10.3.5.9 / Figure 97: the input field displays a data value (what
   --  the pressed keys show is not one yet)
   function Has_Value (Index : Field_Index_T) return Boolean;

   --  The value as a number; a value that is not a number gives 0, a
   --  value above 99 999 999 (8 digits, the longest numeric data of
   --  chapter 11) is clamped (total, never raises)
   function Number (Index : Field_Index_T) return Natural;

   procedure Render;

end DMI_Data_Entry;
