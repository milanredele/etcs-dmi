--  ETCS DMI
--  Train data of the flexible train data entry (DMI 11.3.9.6 b, Table
--  40) and the data entry / validation process that spans the windows
--  the seven items need (11.3.9.3, 10.6).
--
--  DMI_Windows owns the window stack and opens the windows; this package
--  owns the keyboards of Tables 41 and 42, the values entered so far and
--  the values stored on board, and builds the window definitions the
--  generic engine of DMI_Data_Entry works on. 11.7.1.6.1: the values
--  entered become the values stored on board only when the validation
--  window is left with its input field set to 'Yes', which is why the
--  running process needs a store of its own.

with DMI_Data_Entry;
with DMI_Driver_Data;

package DMI_Train_Data is

   --  Table 40 in the order of Figures 120, 121 and 130
   type Item_T is (I_Category,
                   I_Length,
                   I_Brake,
                   I_Max_Speed,
                   I_Axle_Load,
                   I_Airtight,
                   I_Gauge);

   --  11.3.9.5: how many windows the topic needs follows from the
   --  number of input fields; with all seven items modifiable by the
   --  driver and at most 4 input fields per window (10.3.5.1) they are
   --  the two windows of Figures 120 and 121
   Window_Count : constant := 2;
   subtype Window_Index_T is Positive range 1 .. Window_Count;

   --  10.6.1.1: a data entry / validation process about the train data
   --  is running
   function In_Progress return Boolean;
   function Current_Window return Window_Index_T;

   --  10.6.1.1 with Table 50 S3-1 entered from S1: the process starts on
   --  the first window with the stored values proposed (11.7.1.4)
   procedure Start_Process;

   --  10.6.1.3: the process stopped; nothing is carried over
   procedure End_Process;

   --  Table 50 S3-2 -> S3-1: the first window is presented again and the
   --  proposed values are the data values of the previous S3-1
   procedure Restart_At_First;

   --  The window the driver asked for with [Previous] / [Next]; a value
   --  outside the range is ignored (total)
   procedure Go_To (Index : Positive);

   --  Read the data values of the window Index back from the engine.
   --  Called before every window change, so that the process keeps them.
   procedure Capture (Index : Window_Index_T);

   function Window_Def (Index : Window_Index_T)
                        return DMI_Data_Entry.Window_Def_T;

   --  11.4.1 with 11.4.1.3: the validation window echoes all items
   function Validation_Def return DMI_Data_Entry.Window_Def_T;

   --  11.7.1.6.1: the entered values replace the values stored on board
   procedure Store;

   --  The stored value of an item as text, for the data view window
   --  (Table 45 items 4 to 10); Length 0 when nothing is stored
   function Stored_Text (Item : Item_T) return DMI_Driver_Data.Text_Value_T;

   --  The stored choices as the ERTMS/ETCS variables of SUBSET-026
   --  chapter 7, for MSG_DRIVER_DATA; Unknown_Value when nothing is
   --  stored
   Unknown_Value : constant := 16#FF#;

   function Category_CD return Natural;     -- NC_CDTRAIN, 7.5.1.82.2
   function Category_Other return Natural;  -- NC_TRAIN, 7.5.1.84 (bit set)
   function Axle_Load_Value return Natural; -- M_AXLELOADCAT, 7.5.1.62
   function Airtight_Value return Natural;  -- M_AIRTIGHT, 7.5.1.61
   function Gauge_Value return Natural;     -- M_LOADINGGAUGE, 7.5.1.68

end DMI_Train_Data;
