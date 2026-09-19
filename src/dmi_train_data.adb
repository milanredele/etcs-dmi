--  ETCS DMI
--  Train data window(s) implementation (DMI 11.3.9, 11.4.1).

pragma Ada_2012;

package body DMI_Train_Data is

   use DMI_Data_Entry;

   ---------------------------------------------------------------------
   --  Keyboards (Tables 40, 41, 42)
   ---------------------------------------------------------------------

   Max_Cat   : constant := 18;  -- Table 41
   Max_Axle  : constant := 13;  -- SUBSET-026 7.5.1.62
   Max_Gauge : constant := 5;   -- Table 42

   --  Table 41: the ERTMS/ETCS operational train category, its cant
   --  deficiency train category value (NC_CDTRAIN, SUBSET-026 7.5.1.82.2)
   --  and its other international train category value (NC_TRAIN,
   --  7.5.1.84, one bit per category: bit 0 freight braked in 'P',
   --  bit 1 freight braked in 'G', bit 2 passenger)
   type Category_Row_T is record
      Label : Wide_String (1 .. 6);
      CD    : Natural;
      Other : Natural;
   end record;

   Categories : constant array (1 .. Max_Cat) of Category_Row_T :=
     (("PASS 1", 0, 4), ("PASS 2", 2, 4), ("PASS 3", 3, 4),
      ("TILT 1", 4, 4), ("TILT 2", 5, 4), ("TILT 3", 6, 4),
      ("TILT 4", 7, 4), ("TILT 5", 8, 4), ("TILT 6", 9, 4),
      ("TILT 7", 10, 4),
      ("FP 1  ", 0, 1), ("FP 2  ", 1, 1), ("FP 3  ", 2, 1),
      ("FP 4  ", 3, 1),
      ("FG 1  ", 0, 2), ("FG 2  ", 1, 2), ("FG 3  ", 2, 2),
      ("FG 4  ", 3, 2));

   --  11.3.9.9.5 with SUBSET-026 7.5.1.62: the labels of the axle load
   --  category input field are the axle load category values themselves
   type Axle_Row_T is record
      Label : Wide_String (1 .. 4);
      Value : Natural;
   end record;

   Axle_Loads : constant array (1 .. Max_Axle) of Axle_Row_T :=
     (("A   ", 0), ("HS17", 1), ("B1  ", 2), ("B2  ", 3),
      ("C2  ", 4), ("C3  ", 5), ("C4  ", 6),
      ("D2  ", 7), ("D3  ", 8), ("D4  ", 9), ("D4XL", 10),
      ("E4  ", 11), ("E5  ", 12));

   --  Table 42 with SUBSET-026 7.5.1.68
   type Gauge_Row_T is record
      Label : Wide_String (1 .. 9);
      Value : Natural;
   end record;

   Gauges : constant array (1 .. Max_Gauge) of Gauge_Row_T :=
     (("G1       ", 1), ("GA       ", 2), ("GB       ", 3),
      ("GC       ", 4), ("Out of GC", 0));

   --  Trailing blanks pad the constant labels above
   function Trim (S : Wide_String) return Wide_String is
      Last : Natural := S'Last;
   begin
      while Last >= S'First and then S (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      return S (S'First .. Last);
   end Trim;

   --  11.3.9.9.2: the keyboards shall display keys only for the
   --  categories, axle load categories and loading gauges relevant for
   --  the train formation(s). What is relevant is a property of the
   --  rolling stock; neither the DMI specification nor the protocol
   --  carries it, so the DMI offers every value the ERTMS/ETCS language
   --  defines (implementation choice, see the report). Tables 41 and the
   --  axle load categories then need two groups of predefined choices
   --  and use the [More] button of 10.3.5.19.
   function Category_Choices return Choice_Set_T is
      Result : Choice_Set_T := No_Choices;
   begin
      for Row of Categories loop
         Add_Choice (Result, Trim (Row.Label));
      end loop;
      return Result;
   end Category_Choices;

   function Axle_Choices return Choice_Set_T is
      Result : Choice_Set_T := No_Choices;
   begin
      for Row of Axle_Loads loop
         Add_Choice (Result, Trim (Row.Label));
      end loop;
      return Result;
   end Axle_Choices;

   function Gauge_Choices return Choice_Set_T is
      Result : Choice_Set_T := No_Choices;
   begin
      for Row of Gauges loop
         Add_Choice (Result, Trim (Row.Label));
      end loop;
      return Result;
   end Gauge_Choices;

   ---------------------------------------------------------------------
   --  The running data entry / validation process
   ---------------------------------------------------------------------

   type Working_T is record
      Value    : DMI_Driver_Data.Text_Value_T;
      Choice   : Natural := 0;       -- items of a dedicated keyboard
      Has      : Boolean := False;   -- 10.3.5.9: displays a data value
      Accepted : Boolean := False;   -- 10.3.3.5: echoed in white
   end record;

   Work    : array (Item_T) of Working_T;
   Running : Boolean := False;
   Window  : Window_Index_T := 1;

   --  Figures 120 and 121: which window carries which item, and as
   --  which of its input fields
   type Slot_T is record
      On_Window : Window_Index_T;
      Field     : Field_Index_T;
   end record;

   Slot : constant array (Item_T) of Slot_T :=
     (I_Category  => (1, 1),
      I_Length    => (1, 2),
      I_Brake     => (1, 3),
      I_Max_Speed => (1, 4),
      I_Axle_Load => (2, 1),
      I_Airtight  => (2, 2),
      I_Gauge     => (2, 3));

   --  10.3.3.1: the echo line of the item, the same on every window of
   --  the topic and on the validation window (Figures 120, 121, 130)
   function Echo_Line_Of (Item : Item_T) return Natural is
     (Item_T'Pos (Item) + 1);

   function Label_Of (Item : Item_T) return Wide_String is
     (case Item is
         when I_Category  => "Train category",
         when I_Length    => "Length (m)",
         when I_Brake     => "Brake percentage",
         when I_Max_Speed => "Max speed (km/h)",
         when I_Axle_Load => "Axle load category",
         when I_Airtight  => "Airtight",
         when I_Gauge     => "Loading gauge");

   function In_Progress return Boolean is (Running);
   function Current_Window return Window_Index_T is (Window);

   ---------------------------------------------------------------------
   --  Values
   ---------------------------------------------------------------------

   function Text_Of (S : Wide_String) return DMI_Driver_Data.Text_Value_T is
      Result : DMI_Driver_Data.Text_Value_T;
      Last   : constant Natural :=
        Natural'Min (S'Length, DMI_Driver_Data.Max_Field_Len);
   begin
      Result.Length := Last;
      Result.Text (1 .. Last) := S (S'First .. S'First + Last - 1);
      return Result;
   end Text_Of;

   --  5.1.4.1: no leading zeros. Zero stands for "no value" here: none
   --  of the train data has zero as a nominal value (see Not_Zero).
   function Number_Text (N : Natural) return DMI_Driver_Data.Text_Value_T is
      Img : constant Wide_String := Natural'Wide_Image (N);
   begin
      if N = 0 then
         return (others => <>);
      end if;
      return Text_Of (Img (2 .. Img'Last));
   end Number_Text;

   --  Total: a value that is not a number gives 0, a value beyond five
   --  digits is clamped (no train data of chapter 11 needs more)
   function To_Number (V : DMI_Driver_Data.Text_Value_T) return Natural is
      Result : Natural := 0;
   begin
      for I in 1 .. V.Length loop
         if V.Text (I) in '0' .. '9' then
            Result := Result * 10
              + (Wide_Character'Pos (V.Text (I)) - Wide_Character'Pos ('0'));
            if Result > 99_999 then
               return 99_999;
            end if;
         end if;
      end loop;
      return Result;
   end To_Number;

   --  The label a stored choice stands for; an index outside the list
   --  gives an empty value (total)
   function Category_Text (Index : Natural)
                           return DMI_Driver_Data.Text_Value_T is
     (if Index in 1 .. Max_Cat then Text_Of (Trim (Categories (Index).Label))
      else (others => <>));

   function Axle_Text (Index : Natural)
                       return DMI_Driver_Data.Text_Value_T is
     (if Index in 1 .. Max_Axle then Text_Of (Trim (Axle_Loads (Index).Label))
      else (others => <>));

   function Gauge_Text (Index : Natural)
                        return DMI_Driver_Data.Text_Value_T is
     (if Index in 1 .. Max_Gauge then Text_Of (Trim (Gauges (Index).Label))
      else (others => <>));

   --  Table 40 with 10.3.5.18: the airtight keyboard is the 'No' / 'Yes'
   --  choice on the keys 7 and 8; choice 1 is 'No', choice 2 is 'Yes'
   function Airtight_Text (Index : Natural)
                           return DMI_Driver_Data.Text_Value_T is
     (case Index is
         when 1      => Text_Of ("No"),
         when 2      => Text_Of ("Yes"),
         when others => (others => <>));

   function Stored_Text (Item : Item_T) return DMI_Driver_Data.Text_Value_T is
   begin
      if not DMI_Driver_Data.Train_Data_Entered then
         return (others => <>);
      end if;
      case Item is
         when I_Category =>
            return Category_Text (DMI_Driver_Data.Train_Category);
         when I_Length =>
            return Number_Text (DMI_Driver_Data.Train_Length);
         when I_Brake =>
            return Number_Text (DMI_Driver_Data.Brake_Pct);
         when I_Max_Speed =>
            return Number_Text (DMI_Driver_Data.Max_Speed);
         when I_Axle_Load =>
            return Axle_Text (DMI_Driver_Data.Axle_Load);
         when I_Airtight =>
            return Airtight_Text (DMI_Driver_Data.Airtight);
         when I_Gauge =>
            return Gauge_Text (DMI_Driver_Data.Loading_Gauge);
      end case;
   end Stored_Text;

   function Category_CD return Natural is
     (if DMI_Driver_Data.Train_Category in 1 .. Max_Cat
      then Categories (DMI_Driver_Data.Train_Category).CD
      else Unknown_Value);

   function Category_Other return Natural is
     (if DMI_Driver_Data.Train_Category in 1 .. Max_Cat
      then Categories (DMI_Driver_Data.Train_Category).Other
      else 0);

   function Axle_Load_Value return Natural is
     (if DMI_Driver_Data.Axle_Load in 1 .. Max_Axle
      then Axle_Loads (DMI_Driver_Data.Axle_Load).Value
      else Unknown_Value);

   --  M_AIRTIGHT: 0 not fitted, 1 fitted (SUBSET-026 7.5.1.61)
   function Airtight_Value return Natural is
     (case DMI_Driver_Data.Airtight is
         when 1      => 0,
         when 2      => 1,
         when others => Unknown_Value);

   function Gauge_Value return Natural is
     (if DMI_Driver_Data.Loading_Gauge in 1 .. Max_Gauge
      then Gauges (DMI_Driver_Data.Loading_Gauge).Value
      else Unknown_Value);

   ---------------------------------------------------------------------
   --  Process
   ---------------------------------------------------------------------

   function Stored_Choice (Item : Item_T) return Natural is
     (if not DMI_Driver_Data.Train_Data_Entered then 0
      else (case Item is
               when I_Category  => DMI_Driver_Data.Train_Category,
               when I_Axle_Load => DMI_Driver_Data.Axle_Load,
               when I_Airtight  => DMI_Driver_Data.Airtight,
               when I_Gauge     => DMI_Driver_Data.Loading_Gauge,
               when others      => 0));

   procedure Start_Process is
   begin
      Running := True;
      Window := 1;
      --  Table 50 S3-1 entered from S1, status of the train data
      --  "valid": the proposed value of each input field is the value
      --  stored on board. The DMI has neither values pre-configured
      --  on board nor an ERTMS/ETCS external source, so with any other
      --  status nothing is proposed (S3-1, 11.7.1.4.1).
      for I in Item_T loop
         Work (I) := (Value    => Stored_Text (I),
                      Choice   => Stored_Choice (I),
                      --  a proposed value is a data value the driver has
                      --  not accepted yet (Figure 97)
                      Has      => Stored_Text (I).Length > 0,
                      Accepted => False);
      end loop;
   end Start_Process;

   procedure End_Process is
   begin
      Running := False;
      Window := 1;
      for I in Item_T loop
         Work (I) := (others => <>);
      end loop;
   end End_Process;

   procedure Restart_At_First is
   begin
      Window := 1;
   end Restart_At_First;

   procedure Go_To (Index : Positive) is
   begin
      if Index in Window_Index_T then
         Window := Index;
      end if;
   end Go_To;

   procedure Capture (Index : Window_Index_T) is
   begin
      for I in Item_T loop
         if Slot (I).On_Window = Index then
            declare
               F : constant Field_Index_T := Slot (I).Field;
            begin
               if DMI_Data_Entry.Has_Value (F) then
                  Work (I) := (Value    => DMI_Data_Entry.Value (F),
                               Choice   => DMI_Data_Entry.Choice_Number (F),
                               Has      => True,
                               Accepted => DMI_Data_Entry.Accepted (F));
               else
                  --  10.3.1.20 read for a window change: an input field
                  --  left while a value was entered without accepting it
                  --  loses that entry and its data value, as it does when
                  --  another input field of the window is selected
                  --  (implementation choice; the clause names the input
                  --  field, not the window)
                  Work (I) := (others => <>);
               end if;
            end;
         end if;
      end loop;
   end Capture;

   procedure Store is
   begin
      DMI_Driver_Data.Train_Length := To_Number (Work (I_Length).Value);
      DMI_Driver_Data.Brake_Pct := To_Number (Work (I_Brake).Value);
      DMI_Driver_Data.Max_Speed := To_Number (Work (I_Max_Speed).Value);
      DMI_Driver_Data.Train_Category := Work (I_Category).Choice;
      DMI_Driver_Data.Axle_Load := Work (I_Axle_Load).Choice;
      DMI_Driver_Data.Airtight := Work (I_Airtight).Choice;
      DMI_Driver_Data.Loading_Gauge := Work (I_Gauge).Choice;
      DMI_Driver_Data.Train_Data_Entered := True;
   end Store;

   ---------------------------------------------------------------------
   --  Window definitions
   ---------------------------------------------------------------------

   --  10.3.4.1.2: the permitted ranges and resolutions are configured in
   --  the on-board and the protocol does not carry them, so the DMI
   --  holds what the specifications state for the data themselves
   Train_Length_Rule : constant Check_Rule_T :=   -- L_TRAIN, 7.5.1.56
     (Defined => True, Min => 0, Max => 4095, Resolution => 1);
   Max_Speed_Rule : constant Check_Rule_T :=      -- V_MAXTRAIN, 7.5.1.160
     (Defined => True, Min => 0, Max => 600, Resolution => 5);

   --  The only operational range the DMI can state by itself: zero is
   --  not a nominal value for a train length, a brake percentage or a
   --  maximum speed (implementation choice)
   function Not_Zero (Rule : Check_Rule_T; Top : Natural)
                      return Check_Rule_T is
     ((Defined    => True,
       Min        => Natural'Max (Rule.Resolution, 1),
       Max        => (if Rule.Defined then Rule.Max else Top),
       Resolution => 1));

   --  10.3.5.9 with Table 50 S3-1: every input field for train data in
   --  the other 'train data' windows already contains a data value
   function Others_Complete (Index : Window_Index_T) return Boolean is
   begin
      for I in Item_T loop
         if Slot (I).On_Window /= Index and then not Work (I).Has then
            return False;
         end if;
      end loop;
      return True;
   end Others_Complete;

   --  10.4.1.5 / 11.4.1.3: the echo texts of the whole topic
   procedure Fill_Echo (Def : in out Window_Def_T) is
   begin
      Def.Echo_Count := Item_T'Pos (Item_T'Last) + 1;
      for I in Item_T loop
         Def.Echo (Echo_Line_Of (I)) :=
           Echo (Label_Of (I), Work (I).Value, Work (I).Accepted,
                 --  5.1.5.2.2: only the three numbers are grouped
                 Group => I in I_Length | I_Brake | I_Max_Speed);
      end loop;
   end Fill_Echo;

   function Field_Of (Item : Item_T) return Field_Def_T is
   begin
      case Item is
         when I_Category =>
            --  Table 40: a dedicated keyboard; Table 41 gives the labels
            return Field (Label_Of (Item), Max_Choice_Label,
                          Keyboard => Dedicated,
                          Proposed => Work (Item).Value,
                          Choices  => Category_Choices,
                          Proposed_Choice => Work (Item).Choice,
                          Echo_Line => Echo_Line_Of (Item));
         when I_Length =>
            return Field (Label_Of (Item), 4,
                          Proposed => Work (Item).Value,
                          Technical => Train_Length_Rule,
                          Operational => Not_Zero (Train_Length_Rule, 9999),
                          Echo_Line => Echo_Line_Of (Item));
         when I_Brake =>
            --  the brake percentage is not an ERTMS/ETCS variable of
            --  SUBSET-026 chapter 7; its range would come from section
            --  A.3.11 or from the on-board configuration
            return Field (Label_Of (Item), 3,
                          Proposed => Work (Item).Value,
                          Operational => Not_Zero (No_Rule, 999),
                          Echo_Line => Echo_Line_Of (Item));
         when I_Max_Speed =>
            return Field (Label_Of (Item), 3,
                          Proposed => Work (Item).Value,
                          Technical => Max_Speed_Rule,
                          Operational => Not_Zero (Max_Speed_Rule, 999),
                          Echo_Line => Echo_Line_Of (Item));
         when I_Axle_Load =>
            return Field (Label_Of (Item), Max_Choice_Label,
                          Keyboard => Dedicated,
                          Proposed => Work (Item).Value,
                          Choices  => Axle_Choices,
                          Proposed_Choice => Work (Item).Choice,
                          Echo_Line => Echo_Line_Of (Item));
         when I_Airtight =>
            --  Table 40: key 7 is 'No' and key 8 is 'Yes' (10.3.5.18)
            return Field (Label_Of (Item), 3,
                          Keyboard => Yes_No,
                          Proposed => Work (Item).Value,
                          Proposed_Choice => Work (Item).Choice,
                          Echo_Line => Echo_Line_Of (Item));
         when I_Gauge =>
            return Field (Label_Of (Item), Max_Choice_Label,
                          Keyboard => Dedicated,
                          Proposed => Work (Item).Value,
                          Choices  => Gauge_Choices,
                          Proposed_Choice => Work (Item).Choice,
                          Echo_Line => Echo_Line_Of (Item));
      end case;
   end Field_Of;

   function Window_Def (Index : Window_Index_T)
                        return DMI_Data_Entry.Window_Def_T is
      Result : Window_Def_T;
   begin
      --  11.3.9.1: a window on the total grid array with echo texts and
      --  the question 'Train data entry complete?'; 11.3.9.2 / 11.3.9.3:
      --  the title with the sequence number of the window
      Result.Layout := Total_Grid;
      Result.Title := Window_Title ("Train data");
      Result.Page := Index;
      Result.Page_Count := Window_Count;
      Result.Field_Count := 0;
      for I in Item_T loop
         if Slot (I).On_Window = Index then
            if Slot (I).Field > Result.Field_Count then
               Result.Field_Count := Slot (I).Field;
            end if;
            Result.Fields (Slot (I).Field) := Field_Of (I);
         end if;
      end loop;
      Result.Topic_Complete := Others_Complete (Index);
      Fill_Echo (Result);
      return Result;
   end Window_Def;

   function Validation_Def return DMI_Data_Entry.Window_Def_T is
      Result : Window_Def_T;
   begin
      --  11.4.1: a single input field with only a data part and a
      --  dedicated 'No'/'Yes' keyboard (10.4.1.2), the value 'Yes'
      --  proposed (Table 50 S3-2, Figure 130)
      Result.Layout := DMI_Data_Entry.Validation;
      Result.Title := Window_Title ("Validate train data");
      Result.Field_Count := 1;
      Result.Fields (1) :=
        Field ("Validate", 3, Keyboard => Yes_No,
               Proposed => Text_Of ("Yes"), Proposed_Choice => 2);
      Fill_Echo (Result);
      return Result;
   end Validation_Def;

end DMI_Train_Data;
