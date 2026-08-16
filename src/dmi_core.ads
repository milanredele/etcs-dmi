--  ETCS DMI
--  Core of the DMI: protocol message handling, state application and
--  rendering, independent of any transport. The live main (dmi.adb) feeds
--  it from a socket; the regression runner feeds it directly in process.

with Ada.Streams; use Ada.Streams;
with DMI_Protocol; use DMI_Protocol;

package DMI_Core is

   -- Reset the DMI to its power-up state
   procedure Initialise;

   -- Apply one received protocol message
   procedure Handle_Message (The_Type : Msg_Type_T;
                             Payload  : Stream_Element_Array);

   -- Draw the complete screen for the current state
   procedure Render;

   -- Write queued outbound messages (driver actions, sounds) to the
   -- stream and clear the queue
   procedure Flush_Outbox
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class);

   -- Queue an outbound message; used by input handling and sound logic
   procedure Queue_Message (The_Type : Msg_Type_T;
                            Payload  : Stream_Element_Array);

end DMI_Core;
