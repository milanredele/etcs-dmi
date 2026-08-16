--  ETCS DMI
--  Copyright (C) 2019  Milan Redele
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

with Display.A_Area;
with Display.B_Area;
with Display.C_Area;
with Display.D_Area;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with Track_Ahead_Free;
with User_Settings;
with General_Parameters;

with GNAT.Sockets;            use GNAT.Sockets;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with Ada.Real_Time;           use Ada.Real_Time;

with DMI_Protocol; use DMI_Protocol;
with Ada.Unchecked_Conversion;
with Interfaces; use Interfaces;

procedure Dmi is
   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

   Terminated : Boolean := False;
   Char       : Character;
   Avail      : Boolean;

   Next_Frame : Time := Clock;
   Frame_Interval : constant Time_Span := Milliseconds (50);

   Last_Flash : Time := Clock;
   Flash_Interval : constant Time_Span := Milliseconds (250);

   Flash_Enabled_State : Boolean := False;

   -- Helper to convert steam to record
   function To_Telegram is new Ada.Unchecked_Conversion 
     (Source => Ada.Streams.Stream_Element_Array,
      Target => DMI_Telegram_T);

   -- Basic CRC-16 CCITT
   function Get_CRC (Data : Ada.Streams.Stream_Element_Array) return Unsigned_16 is
      CRC : Unsigned_16 := 16#FFFF#;
   begin
      for I in Data'Range loop
         CRC := CRC xor Shift_Left (Unsigned_16 (Data (I)), 8);
         for J in 1 .. 8 loop
            if (CRC and 16#8000#) /= 0 then
               CRC := Shift_Left (CRC, 1) xor 16#1021#;
            else
               CRC := Shift_Left (CRC, 1);
            end if;
         end loop;
      end loop;
      return CRC;
   end Get_CRC;

begin
   General_Parameters.Flash_On := True;
   Supplementary_Driving_Info.Mode := Supplementary_Driving_Info.M_FS;
   Supplementary_Driving_Info.Acknowledgment_Mode := (Valid => False);
   Supplementary_Driving_Info.Override := False;
   Supplementary_Driving_Info.Level := Supplementary_Driving_Info.L1;
   Supplementary_Driving_Info.Level_Announcement := (True, Supplementary_Driving_Info.L2, True);
   User_Settings.Toggle (User_Settings.Basic_Speed_Hook) := True;
   User_Settings.Toggle (User_Settings.Release_Speed_Digital) := True;
   User_Settings.Toggle (User_Settings.LSSMA) := True;
   Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.TSM);
   Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_180);
   Speed_And_Distance.Set_Distance_To_Target (684);
   Speed_And_Distance.Set_LSSMA (120);
   Speed_And_Distance.Set_Speed_Params ((Vperm => 120,
                                         Vtarget => 80,
                                         Vwsl => 130,
                                         Vsbi => 150,
                                         Vrelease => 35,
                                         Vrelease_Exists => True));
   Speed_And_Distance.Set_Speed (136);

   Track_Ahead_Free.Show := True;

   Display.B_Area.Draw;
   Display.A_Area.Draw;
   Display.C_Area.Draw;
   Display.D_Area.Draw;

   Create_Socket (Client);
   Address.Addr := Inet_Addr("127.0.0.1");
   Address.Port := 1337;

   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   while not Terminated loop
      declare
         use Ada.Streams;
         use Ada.Text_IO;
         -- Telegram is now 16 bytes
         Buffer  : Stream_Element_Array (1 .. 16);
         Last    : Stream_Element_Offset;
         Request : Request_Type (N_Bytes_To_Read);
      begin
         -- 1. Respond quickly to input by polling for many updates if they are queued
         loop
            Control_Socket (Client, Request);
            exit when Request.Size < 16;

            Receive_Socket (Client, Buffer, Last);
            if Last = 16 then
               declare
                  Tel : constant DMI_Telegram_T := To_Telegram (Buffer);
               begin
                  -- Checksum validation
                  if Tel.Checksum = Get_CRC (Buffer (1 .. 14)) then
                     case Tel.Status.Monitoring is
                        when 0 => Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.CSM);
                        when 1 => Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.TSM);
                        when others => Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.RSM);
                     end case;
                     Speed_And_Distance.Set_CSM_Target_Info (Tel.Status.CSM_TI = 1);

                     Speed_And_Distance.Set_Speed_Params
                        ((Vperm    => Speed_And_Distance.Speed_T (Tel.V_Perm),
                          Vtarget  => Speed_And_Distance.Speed_T (Tel.V_Targ),
                          Vwsl     => Speed_And_Distance.Speed_T (Natural (Tel.V_Perm) + 5),
                          Vsbi     => Speed_And_Distance.Speed_T (Natural (Tel.V_Perm) + 15),
                          Vrelease => Speed_And_Distance.Speed_T (Tel.V_Rel),
                          Vrelease_Exists => (Tel.Status.Vrelease_Exists = 1)));
                     Speed_And_Distance.Set_Speed (Speed_And_Distance.Speed_T (Tel.V_Cur));

                     Speed_And_Distance.Set_Distance_To_Target (Speed_And_Distance.Distance_T (if Tel.D_Targ > 90000 then 90000 else Tel.D_Targ));

                     case Tel.Status.Speed_Range is
                        when 0 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_140);
                        when 1 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_180);
                        when 2 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_250);
                        when 3 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_400);
                     end case;

                     -- Apply Other Statuses
                     Track_Ahead_Free.Show := (Tel.Status.Show_TAF = 1);
                     Flash_Enabled_State := (Tel.Status.Flash_Enable = 1);

                     -- Mode index follows Mode_T declaration order
                     if Natural (Tel.Status.Mode) <=
                        Supplementary_Driving_Info.Mode_T'Pos (Supplementary_Driving_Info.Mode_T'Last)
                     then
                        Supplementary_Driving_Info.Mode :=
                          Supplementary_Driving_Info.Mode_T'Val (Tel.Status.Mode);
                     end if;

                  else
                     Ada.Text_IO.Put_Line ("CRC Error!");
                  end if;
               end;
            end if;
         end loop;

         -- Update flashing state independently of network input
         if Flash_Enabled_State then
            if Clock - Last_Flash >= Flash_Interval then
               General_Parameters.Flash_On := not General_Parameters.Flash_On;
               Last_Flash := Clock;
            end if;
         else
            General_Parameters.Flash_On := True;
            Last_Flash := Clock;
         end if;

         -- 2. Draw only once per loop iteration
         Display.B_Area.Draw;
         Display.A_Area.Draw;
         Display.C_Area.Draw;
         Display.D_Area.Draw;

         -- 3. Transmit the complete frame back to the client
         Display.A_Area.A_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));
         Display.B_Area.B_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));
         Display.C_Area.C_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));
         Display.D_Area.D_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));

         -- 4. Check for exit
         Get_Immediate (Char, Avail);
         if Avail then
            if Char = 'q' or Char = 'Q' or Character'Pos (Char) = 27 then -- 'q' or ESC
               Terminated := True;
            end if;
         end if;

         -- 5. Precise frame timing using 'delay until'
         Next_Frame := Next_Frame + Frame_Interval;
         delay until Next_Frame;
      end;
   end loop;

   Shutdown_Socket (Client);
   Close_Socket (Client);
end Dmi;
