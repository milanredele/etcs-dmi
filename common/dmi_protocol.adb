--  ETCS DMI
--  Protocol v2 little endian codec primitives.

package body DMI_Protocol is

   procedure Put_U8 (Buffer : in out Stream_Element_Array;
                     Offset : in out Stream_Element_Offset;
                     Value  : Unsigned_8) is
   begin
      Buffer (Offset) := Stream_Element (Value);
      Offset := Offset + 1;
   end Put_U8;

   procedure Put_U16 (Buffer : in out Stream_Element_Array;
                      Offset : in out Stream_Element_Offset;
                      Value  : Unsigned_16) is
   begin
      Put_U8 (Buffer, Offset, Unsigned_8 (Value and 16#FF#));
      Put_U8 (Buffer, Offset, Unsigned_8 (Shift_Right (Value, 8)));
   end Put_U16;

   procedure Put_U32 (Buffer : in out Stream_Element_Array;
                      Offset : in out Stream_Element_Offset;
                      Value  : Unsigned_32) is
   begin
      Put_U16 (Buffer, Offset, Unsigned_16 (Value and 16#FFFF#));
      Put_U16 (Buffer, Offset, Unsigned_16 (Shift_Right (Value, 16)));
   end Put_U32;

   function Get_U8 (Buffer : Stream_Element_Array;
                    Offset : in out Stream_Element_Offset) return Unsigned_8 is
      Result : constant Unsigned_8 := Unsigned_8 (Buffer (Offset));
   begin
      Offset := Offset + 1;
      return Result;
   end Get_U8;

   function Get_U16 (Buffer : Stream_Element_Array;
                     Offset : in out Stream_Element_Offset) return Unsigned_16 is
      Low  : constant Unsigned_16 := Unsigned_16 (Get_U8 (Buffer, Offset));
      High : constant Unsigned_16 := Unsigned_16 (Get_U8 (Buffer, Offset));
   begin
      return Low or Shift_Left (High, 8);
   end Get_U16;

   function Get_U32 (Buffer : Stream_Element_Array;
                     Offset : in out Stream_Element_Offset) return Unsigned_32 is
      Low  : constant Unsigned_32 := Unsigned_32 (Get_U16 (Buffer, Offset));
      High : constant Unsigned_32 := Unsigned_32 (Get_U16 (Buffer, Offset));
   begin
      return Low or Shift_Left (High, 16);
   end Get_U32;

   procedure Put_Header (Buffer   : in out Stream_Element_Array;
                         Offset   : in out Stream_Element_Offset;
                         The_Type : Msg_Type_T;
                         Length   : Natural) is
   begin
      Put_U8 (Buffer, Offset, Unsigned_8 (The_Type));
      Put_U32 (Buffer, Offset, Unsigned_32 (Length));
   end Put_Header;

end DMI_Protocol;
