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
with Speed_And_Distance;
with Supplementary_Driving_Info;
with User_Settings;

with GNAT.Sockets;            use GNAT.Sockets;
with Ada.Streams.Stream_IO;

procedure Dmi is
   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

begin
   Supplementary_Driving_Info.Mode := Supplementary_Driving_Info.M_LS;
   Supplementary_Driving_Info.Acknowledgment_Mode := (True, Supplementary_Driving_Info.M_SH);
   Supplementary_Driving_Info.Override := False;
   User_Settings.Toggle (User_Settings.Basic_Speed_Hook) := True;
   User_Settings.Toggle (User_Settings.Release_Speed_Digital) := True;
   User_Settings.Toggle (User_Settings.LSSMA) := True;
   Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.TSM);
   Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_400);
   Speed_And_Distance.Set_Distance_To_Target (684);
   Speed_And_Distance.Set_LSSMA (120);
   Speed_And_Distance.Set_Speed_Params ((Vperm => 120,
                                         Vtarget => 80,
                                         Vwsl => 130,
                                         Visl => 140,
                                         Vsbi => 150,
                                         Vrelease => 35,
                                         Vrelease_Exists => False));
   Speed_And_Distance.Set_Speed (88);

   Display.B_Area.Draw;
   --Display.B_Area.B_Buffer.Dump ("b_frame.dmp");

   Display.A_Area.Draw;

   Display.C_Area.Draw;

   Create_Socket (Client);
   Address.Addr := Inet_Addr("127.0.0.1");
   Address.Port := 1337;

   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   Display.A_Area.A_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));
   Display.B_Area.B_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));
   Display.C_Area.C_Buffer.Write (Ada.Streams.Stream_IO.Stream_Access (Channel));

   Shutdown_Socket (Client);
   Close_Socket (Client);
end Dmi;
