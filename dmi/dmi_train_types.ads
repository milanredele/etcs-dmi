--  ETCS DMI
--  The pre-configured train types of the fixed Train Data entry (DMI
--  11.3.9.6 a, 11.3.9.8, Table 39), as the on-board sends them in
--  MSG_TRAIN_TYPES: the names, the keys of the dedicated keyboard of the
--  'Train type' input field, and the Train Data each stands for, in the
--  codes of MSG_DRIVER_DATA kind 2. Set_List replaces the list as a
--  whole; nothing is known before the first message.
with DMI_Protocol;

package DMI_Train_Types is

   Max_Types : constant := DMI_Protocol.Train_Types_Max;
   Max_Name  : constant := DMI_Protocol.Train_Type_Name_Max;

   subtype Type_Count_T is Natural range 0 .. Max_Types;
   subtype Type_Index_T is Positive range 1 .. Max_Types;

   type Train_Type_T is record
      Name_Length : Natural range 0 .. Max_Name := 0;
      Name        : Wide_String (1 .. Max_Name) := (others => ' ');
      Length_M    : Natural := 0;     -- L_TRAIN, m
      Brake_Pct   : Natural := 0;     -- %
      Max_Speed   : Natural := 0;     -- V_MAXTRAIN, km/h
      CD          : Natural := 0;     -- NC_CDTRAIN
      Other       : Natural := 0;     -- NC_TRAIN (bit set)
      Axle        : Natural := 0;     -- M_AXLELOADCAT
      Airtight    : Natural := 0;     -- M_AIRTIGHT
      Gauge       : Natural := 0;     -- M_LOADINGGAUGE
   end record;

   type Type_List_T is array (Type_Index_T) of Train_Type_T;

   procedure Set_List (Count : Type_Count_T; List : Type_List_T);
   procedure Reset;

   function Count return Type_Count_T;
   --  The type at Index; an empty one (Name_Length 0) above Count
   function Get (Index : Positive) return Train_Type_T;

end DMI_Train_Types;
