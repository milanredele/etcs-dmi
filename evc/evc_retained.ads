--  ETCS on-board (EVC)
--  The stored information kept over No Power: SUBSET-026 4.10 (the
--  column NP of its table: "to be revalidated", the data become
--  invalid; "unchanged") and 4.11 (their status when No Power is left).
--
--  What is kept (4.10, column NP):
--    - the train position, "to be revalidated" (EVC_Position.Keep: the
--      LRBG, the distance of the train from it, the confidence interval,
--      the train orientation);
--    - the ERTMS/ETCS level and the table of priority of the trackside
--      supported levels, "to be revalidated";
--    - the RBC contact information, "to be revalidated" (RBC_Contact_T:
--      written by the radio of phase E5; this on-board has none yet);
--  not kept: what 4.10 deletes in NP (Train Data, driver ID, train
--  running number, the MA and the track description, the RBC/RIU system
--  version, ...). Not yet kept, with the phase that brings it: EOLM
--  information (Euroloop, E7), the radio network and the radio system
--  used ("unchanged", E5), the not yet applicable table of priority,
--  the order kept in SH, PS or SM (4.11.1.4).
--
--  The store is written at the end of every cycle (Save, EVC_Core), so
--  that it holds the data of the last cycle before the power was lost,
--  and read at the power-up (Load, EVC_Core.Power_Up). Here it is a
--  memory that survives EVC_Core.Initialise, as the installation
--  configuration (EVC_Config) does: the state of the on-board within
--  one run of its host. On the target (phase E8) the same record goes
--  to non-volatile memory with a CRC behind this interface; Erase is
--  the empty store of a new on-board (EVC_Core.Initialise).

with EVC_Levels;
with EVC_Modes;    use EVC_Modes;
with EVC_Position;

package EVC_Retained
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The RBC contact information (3.5.3.7: NID_C, NID_RBC, NID_RADIO),
   --  stored by the radio of phase E5
   type RBC_Contact_T is record
      Known     : Boolean := False;
      NID_C     : Natural range 0 .. 1023 := 0;
      NID_RBC   : Natural range 0 .. 16383 := 0;
      --  NID_RADIO, the 16 digits of the number as 64 bits
      Radio_Hi  : Natural range 0 .. 2**31 - 1 := 0;
      Radio_Lo  : Natural range 0 .. 2**31 - 1 := 0;
   end record;

   type Kept_T is record
      --  something was saved since the store was erased
      Saved       : Boolean := False;
      Level_Known : Boolean := False;
      Level       : Level_T := L0;
      Table       : EVC_Levels.Priority_Table_T;
      Position    : EVC_Position.Kept_Position_T;
      RBC         : RBC_Contact_T;
   end record;

   --  The empty store
   procedure Erase
     with Global => (Output => State),
          Post => not Saved;

   function Saved return Boolean
     with Global => State;

   procedure Save (K : Kept_T)
     with Global => (Output => State),
          Post => Saved = K.Saved;

   procedure Load (K : out Kept_T)
     with Global => (Input => State),
          Post => K.Saved = Saved;

end EVC_Retained;
