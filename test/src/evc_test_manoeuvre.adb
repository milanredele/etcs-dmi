--  ETCS on-board (EVC) regression: Supervised Manoeuvre, implementation.

with EVC_Core;
with EVC_Ports;           use EVC_Ports;
with EVC_Train_Data;
with EVC_Test_Support;    use EVC_Test_Support;

package body EVC_Test_Manoeuvre is

   --  A TIU frame of the safe consist length (EVC_Ports signal 15):
   --  value V, the lengths in front of the engine (nominal, min, max),
   --  then in rear of it, in metres
   function SCL_Frame (V : Byte; F_Nom, F_Min, F_Max,
                       R_Nom, R_Min, R_Max : Natural := 0)
     return Byte_Array
   is
      L     : constant array (0 .. 5) of Natural :=
        (F_Nom, F_Min, F_Max, R_Nom, R_Min, R_Max);
      Frame : Byte_Array (1 .. TIU_SCL_Length) := (others => 0);
   begin
      Frame (1) := 15;
      Frame (2) := V;
      for K in L'Range loop
         Frame (3 + 2 * K) := Byte (L (K) mod 256);
         Frame (4 + 2 * K) := Byte (L (K) / 256);
      end loop;
      return Frame;
   end SCL_Frame;

   procedure Scenario_Safe_Consist is
      Valid_Before : Boolean;
   begin
      Start_X;
      Stand_X (300);
      Check (not EVC_Train_Data.Consist_Available
             and then not EVC_Train_Data.Consist_Known
             and then EVC_Train_Data.Entry_Possible,
             "SCL: no safe consist length before the first TIU input");
      Check (Valid_TIU (SCL_Frame (1, 0, 0, 0, 400, 398, 402))
             and then Valid_TIU (SCL_Frame (0))
             and then not Valid_TIU (SCL_Frame (1, 0, 0, 0, 400, 401, 402))
             and then not Valid_TIU (SCL_Frame (1, 0, 0, 0, 400, 398, 4096))
             and then not Valid_TIU (SCL_Frame (2))
             and then not Valid_TIU ((15, 1)),
             "SCL: the TIU frame of signal 15 (EVC_Ports): min <= nom <= "
             & "max in 0 .. 4095 m on each side, value 0 or 1, 14 bytes");

      --  3.18.3.2 b) 1st bullet: available, nothing in front
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 0, 0, 0, 400, 398, 402));
      Stand_X (300);
      Check (EVC_Train_Data.Consist_Available
             and then EVC_Train_Data.Consist.Rear_Max = 402
             and then EVC_Train_Data.Consist.Rear_Min = 398
             and then EVC_Train_Data.Entry_Possible
             and then Natural (EVC_Train_Data.Consist_Length) = 40_200,
             "SCL: available from the TIU, nothing in front of the engine, "
             & "the train length the sum of the max lengths (3.18.3.2 b), "
             & "3.18.3.2.4)");

      --  3.18.3.5 a) b): a length in front of the engine
      Valid_Before := EVC_Train_Data.Valid;
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 20, 19, 21, 400, 398, 402));
      Stand_X (300);
      Check (not EVC_Train_Data.Valid
             and then not EVC_Train_Data.Entry_Possible
             and then EVC_Train_Data.Consist_In_Front,
             "SCL: a length in front of the engine, no valid Train Data "
             & "(valid before:" & Boolean'Image (Valid_Before) & ") and no "
             & "driver entry (3.18.3.5 a), b))");

      --  3.18.3.2.5: unavailable, the values kept
      EVC_Core.Handle_Input (TIU, SCL_Frame (0));
      Stand_X (300);
      Check (not EVC_Train_Data.Consist_Available
             and then EVC_Train_Data.Consist_Known
             and then EVC_Train_Data.Consist.Front_Max = 21
             and then EVC_Train_Data.Entry_Possible,
             "SCL: unavailable, the safe consist length kept (3.18.3.2.5)");
   end Scenario_Safe_Consist;

end EVC_Test_Manoeuvre;
