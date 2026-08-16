--  ETCS DMI
--  Acknowledgement service implementation.

pragma Ada_2012;
with DMI_Sounds;

package body DMI_Ack is

   package SDI renames Supplementary_Driving_Info;

   type Slot_T is record
      Pending : Boolean := False;
      Mode    : SDI.Acknowledgment_Mode_T := SDI.Acknowledgment_Mode_T'First;
      Level   : SDI.Level_T := SDI.Unknown;
   end record;

   Slots : array (Ack_Kind_T) of Slot_T;

   Displayed      : Boolean := False;
   Displayed_Kind : Ack_Kind_T := Ack_Kind_T'First;

   -- DMI 5.4.1.9: 1 s between two consecutively displayed requests
   Gap_Ms      : constant := 1000;
   Gap_Left_Ms : Natural := 0;

   procedure Select_Next is
   begin
      if Displayed or else Gap_Left_Ms > 0 then
         return;
      end if;
      for Kind in Ack_Kind_T loop
         if Slots (Kind).Pending then
            Displayed := True;
            Displayed_Kind := Kind;
            -- DMI 5.4.1.5: flashing frame comes with Sinfo
            DMI_Sounds.Play (DMI_Sounds.Sinfo);
            return;
         end if;
      end loop;
   end Select_Next;

   procedure Request_Mode_Ack
     (Mode : Supplementary_Driving_Info.Acknowledgment_Mode_T) is
   begin
      Slots (Mode_Change) := (Pending => True,
                              Mode    => Mode,
                              Level   => SDI.Unknown);
      Select_Next;
   end Request_Mode_Ack;

   procedure Request_Level_Ack
     (Level : Supplementary_Driving_Info.Level_T) is
   begin
      Slots (Level_Transition) := (Pending => True,
                                   Mode    => SDI.Acknowledgment_Mode_T'First,
                                   Level   => Level);
      Select_Next;
   end Request_Level_Ack;

   procedure Cancel (Kind : Ack_Kind_T) is
   begin
      Slots (Kind).Pending := False;
      if Displayed and then Displayed_Kind = Kind then
         Displayed := False;
      end if;
   end Cancel;

   procedure Acknowledge_Current is
   begin
      if Displayed then
         Slots (Displayed_Kind).Pending := False;
         Displayed := False;
         -- DMI 5.4.1.9: keep 1 s of separation before the next request
         Gap_Left_Ms := Gap_Ms;
      end if;
   end Acknowledge_Current;

   procedure Tick (Dt_Ms : Natural) is
   begin
      if Gap_Left_Ms > 0 then
         Gap_Left_Ms := (if Dt_Ms >= Gap_Left_Ms then 0 else Gap_Left_Ms - Dt_Ms);
      end if;
      Select_Next;
   end Tick;

   function Current_Valid return Boolean is (Displayed);

   function Current_Kind return Ack_Kind_T is (Displayed_Kind);

   function Current_Mode return Supplementary_Driving_Info.Acknowledgment_Mode_T is
     (Slots (Mode_Change).Mode);

   function Current_Level return Supplementary_Driving_Info.Level_T is
     (Slots (Level_Transition).Level);

   procedure Reset is
   begin
      Slots := (others => <>);
      Displayed := False;
      Gap_Left_Ms := 0;
   end Reset;

end DMI_Ack;
