--  ETCS DMI
--  The operated system version (SUBSET-026 3.17.2) as the EVC reports it
--  (MSG_SYSTEM_VERSION), for the System version window (DMI 11.5.2,
--  Table 46).

package DMI_System_Version is

   --  M_VERSION (SUBSET-026 7.5.1.79): X in the three MSBs, Y in the
   --  four LSBs
   subtype X_T is Natural range 0 .. 7;
   subtype Y_T is Natural range 0 .. 15;

   --  False until a message with a version in range arrives, and after
   --  one that says "not known": the window then shows no value
   Known : Boolean := False;
   X     : X_T := 0;
   Y     : Y_T := 0;

   --  Any pair is accepted; one out of range is "not known"
   procedure Set (New_X, New_Y : Natural);

   --  "X.Y", e.g. "3.0" (Figure 135); empty when not known
   function Image return Wide_String;

   procedure Reset;

end DMI_System_Version;
