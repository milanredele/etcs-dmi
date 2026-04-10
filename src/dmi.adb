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
                                         Visl => 140,
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
         -- Wait for 14 bytes: Speed (2), Vperm (2), Vtarget (2), Vrelease (2), Range (2), Distance (4)
         Buffer  : Stream_Element_Array (1 .. 14);
         Last    : Stream_Element_Offset;
         Request : Request_Type (N_Bytes_To_Read);
      begin
         -- 1. Respond quickly to input by polling for many updates if they are queued
         loop
            Control_Socket (Client, Request);
            exit when Request.Size < 14;

            Receive_Socket (Client, Buffer, Last);
            if Last = 14 then
               declare
                  function To_U16 (Low, High : Stream_Element) return Natural is
                  begin
                     return Natural (Low) + Natural (High) * 256;
                  end To_U16;

                  function To_U32 (B0, B1, B2, B3 : Stream_Element) return Natural is
                  begin
                     return Natural (B0) + Natural (B1) * 256 + Natural (B2) * 65536 + Natural (B3) * 16777216;
                  end To_U32;

                  V_Cur   : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (To_U16 (Buffer (1), Buffer (2)));
                  V_Perm  : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (To_U16 (Buffer (3), Buffer (4)));
                  V_Targ  : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (To_U16 (Buffer (5), Buffer (6)));
                  V_Rel   : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (To_U16 (Buffer (7), Buffer (8)));
                  R_Enum  : constant Natural := To_U16 (Buffer (9), Buffer (10));
                  D_Targ  : constant Natural := To_U32 (Buffer (11), Buffer (12), Buffer (13), Buffer (14));
                  
                  V_Wsl   : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (Natural (V_Perm) + 5);
                  V_Isl   : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (Natural (V_Perm) + 10);
                  V_Sbi   : constant Speed_And_Distance.Speed_T := Speed_And_Distance.Speed_T (Natural (V_Perm) + 15);
               begin
                  Speed_And_Distance.Set_Speed (V_Cur);
                  Speed_And_Distance.Set_Speed_Params ((Vperm   => V_Perm,
                                                        Vtarget => V_Targ,
                                                        Vwsl    => V_Wsl,
                                                        Visl    => V_Isl,
                                                        Vsbi    => V_Sbi,
                                                        Vrelease => V_Rel,
                                                        Vrelease_Exists => True));
                  
                  -- Distance range check 0..90000
                  Speed_And_Distance.Set_Distance_To_Target (Speed_And_Distance.Distance_T (D_Targ));

                  case R_Enum is
                     when 0 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_140);
                     when 1 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_180);
                     when 2 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_250);
                     when 3 => Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_400);
                     when others => null;
                  end case;

               end;
            end if;
         end loop;
         -- Update flashing state every 250ms
         if Clock - Last_Flash >= Flash_Interval then
            General_Parameters.Flash_On := not General_Parameters.Flash_On;
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
