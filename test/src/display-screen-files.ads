--  ETCS DMI
--  Host side helpers over the screen buffer for the regression runner:
--  raw dumps and SHA-256 digests. Kept out of the DMI proper so that the
--  embedded and WebAssembly builds do not depend on file I/O.

package Display.Screen.Files is

   -- Raw dump of the colour index buffer, row major; used to inspect
   -- failing regression frames
   procedure Dump (File_Name : String);

   -- Compare the screen against a previously dumped file; True on match
   function Matches_Dump (File_Name : String) return Boolean;

   -- SHA-256 of the colour index buffer as a lower case hex string;
   -- golden frames are stored as digests
   function Digest return String;

end Display.Screen.Files;
