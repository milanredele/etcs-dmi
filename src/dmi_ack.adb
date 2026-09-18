--  ETCS DMI
--  Acknowledgement service implementation.

pragma Ada_2012;
with DMI_Sounds;

package body DMI_Ack is

   package SDI renames Supplementary_Driving_Info;

   -- One reserved slot per object kind (level, mode, brake release)
   Object_Slots : constant := 3;
   Capacity     : constant := Text_Capacity + Object_Slots;

   type Request_T is record
      Kind    : Ack_Kind_T := Ack_Kind_T'First;
      Mode    : SDI.Acknowledgment_Mode_T := SDI.Acknowledgment_Mode_T'First;
      Level   : SDI.Level_T := SDI.Unknown;
      Text_ID : Natural := 0;
      -- Arrived since the last Tick: "triggered simultaneously" with
      -- the other fresh requests (5.4.1.9.1)
      Fresh   : Boolean := False;
   end record;

   -- Queue (1) is the head of the FIFO, Queue (Count) its tail. The
   -- fresh requests always form the tail end of the queue.
   Queue : array (1 .. Capacity) of Request_T;
   Count : Natural range 0 .. Capacity := 0;

   -- The head of the queue is presented to the driver (5.4.1.7)
   Displayed : Boolean := False;

   -- DMI 5.4.1.9: 1 s between two consecutively displayed requests
   Gap_Ms      : constant := 1000;
   Gap_Left_Ms : Natural := 0;

   function Is_Text (Kind : Ack_Kind_T) return Boolean is
     (Kind in Text_Kind_T);

   function Text_Count return Natural is
      Result : Natural := 0;
   begin
      for I in 1 .. Count loop
         if Is_Text (Queue (I).Kind) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Text_Count;

   -- Index of the request of an object kind, 0 if there is none
   function Find_Kind (Kind : Ack_Kind_T) return Natural is
   begin
      for I in 1 .. Count loop
         if Queue (I).Kind = Kind then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Kind;

   function Find_Text (ID : Natural) return Natural is
   begin
      for I in 1 .. Count loop
         if Is_Text (Queue (I).Kind) and then Queue (I).Text_ID = ID then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Text;

   procedure Remove_At (Index : Positive) is
   begin
      if Index > Count then
         return;
      end if;
      if Index = 1 and then Displayed then
         Displayed := False;
         -- DMI 5.4.1.9: the next request is displayed 1 s after the
         -- current one has been acknowledged or revoked
         Gap_Left_Ms := Gap_Ms;
      end if;
      for I in Index .. Count - 1 loop
         Queue (I) := Queue (I + 1);
      end loop;
      Count := Count - 1;
   end Remove_At;

   -- FIFO insertion. Requests of earlier cycles keep their place; among
   -- the requests of the current cycle the sequence of 5.4.1.9.1 applies.
   -- The caller made sure there is room.
   procedure Insert (Request : Request_T) is
      Position : Positive := Count + 1;
   begin
      if Count >= Capacity then
         return;
      end if;
      for I in 1 .. Count loop
         if Queue (I).Fresh and then Queue (I).Kind > Request.Kind then
            Position := I;
            exit;
         end if;
      end loop;
      for I in reverse Position .. Count loop
         Queue (I + 1) := Queue (I);
      end loop;
      Queue (Position) := Request;
      Queue (Position).Fresh := True;
      Count := Count + 1;
   end Insert;

   procedure Select_Next is
   begin
      if Displayed or else Gap_Left_Ms > 0 or else Count = 0 then
         return;
      end if;
      Displayed := True;
      -- DMI 5.4.1.5: flashing frame comes with Sinfo
      DMI_Sounds.Play (DMI_Sounds.Sinfo);
   end Select_Next;

   procedure Request_Mode_Ack
     (Mode : Supplementary_Driving_Info.Acknowledgment_Mode_T)
   is
      use type SDI.Mode_T;
      Index : constant Natural := Find_Kind (Mode_Change);
   begin
      if Index /= 0 then
         if Queue (Index).Mode = Mode then
            return;
         end if;
         Remove_At (Index);
      end if;
      Insert ((Kind => Mode_Change, Mode => Mode, others => <>));
   end Request_Mode_Ack;

   procedure Request_Level_Ack
     (Level : Supplementary_Driving_Info.Level_T)
   is
      use type SDI.Level_T;
      Index : constant Natural := Find_Kind (Level_Transition);
   begin
      if Index /= 0 then
         if Queue (Index).Level = Level then
            return;
         end if;
         Remove_At (Index);
      end if;
      Insert ((Kind => Level_Transition, Level => Level, others => <>));
   end Request_Level_Ack;

   procedure Request_Brake_Release_Ack is
   begin
      if Find_Kind (Brake_Release) = 0 then
         Insert ((Kind => Brake_Release, others => <>));
      end if;
   end Request_Brake_Release_Ack;

   procedure Request_Text_Ack (Kind     : Text_Kind_T;
                               ID       : Natural;
                               Accepted : out Boolean) is
   begin
      if Find_Text (ID) /= 0 then
         Accepted := True;
      elsif Text_Count >= Text_Capacity then
         Accepted := False;
      else
         Insert ((Kind => Kind, Text_ID => ID, others => <>));
         Accepted := True;
      end if;
   end Request_Text_Ack;

   procedure Cancel (Kind : Object_Kind_T) is
      Index : constant Natural := Find_Kind (Kind);
   begin
      if Index /= 0 then
         Remove_At (Index);
      end if;
   end Cancel;

   procedure Cancel_Text (ID : Natural) is
      Index : constant Natural := Find_Text (ID);
   begin
      if Index /= 0 then
         Remove_At (Index);
      end if;
   end Cancel_Text;

   procedure Acknowledge_Current is
   begin
      if Displayed then
         Remove_At (1);
      end if;
   end Acknowledge_Current;

   procedure Tick (Dt_Ms : Natural) is
   begin
      -- what arrived during the last cycle is now in FIFO order
      for I in 1 .. Count loop
         Queue (I).Fresh := False;
      end loop;
      if Gap_Left_Ms > 0 then
         Gap_Left_Ms := (if Dt_Ms >= Gap_Left_Ms then 0 else Gap_Left_Ms - Dt_Ms);
      end if;
      Select_Next;
   end Tick;

   function Current_Valid return Boolean is (Displayed and then Count > 0);

   function Current_Kind return Ack_Kind_T is (Queue (1).Kind);

   function Current_Mode return Supplementary_Driving_Info.Acknowledgment_Mode_T is
     (Queue (1).Mode);

   function Current_Level return Supplementary_Driving_Info.Level_T is
     (Queue (1).Level);

   function Current_Text_ID return Natural is (Queue (1).Text_ID);

   function Text_Queued (ID : Natural) return Boolean is
     (Find_Text (ID) /= 0);

   function Pending_Count return Natural is (Count);

   procedure Reset is
   begin
      Queue := (others => <>);
      Count := 0;
      Displayed := False;
      Gap_Left_Ms := 0;
   end Reset;

end DMI_Ack;
