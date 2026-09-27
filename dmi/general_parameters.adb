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

pragma Ada_2012;
with Interfaces; use Interfaces;

package body General_Parameters is


   procedure Write_Color
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  Color)
   is
   begin
      RGB'Write (Stream, RGB_Colors (Item));
   end Write_Color;

   ---------------
   -- Write_RGB --
   ---------------

   procedure Write_RGB
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  RGB) is
   begin
        Unsigned_8'Write (Stream, Unsigned_8 (Item.R));
        Unsigned_8'Write (Stream, Unsigned_8 (Item.G));
        Unsigned_8'Write (Stream, Unsigned_8 (Item.B));
   end Write_RGB;

end General_Parameters;
