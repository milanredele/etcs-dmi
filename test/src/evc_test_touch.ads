--  ETCS on-board (EVC) / DMI
--  A native, touch-only start of mission: DMI_Core and EVC_Core
--  connected by their frames as the bench page connects them (the
--  on-board in the default bench environment, Sim_Onboard_Env,
--  EVC_Track.Default), the driver acting only through touch
--  coordinates taken from the DMI's own layout queries
--  (DMI_Windows.Button_Area, Display.C_Area), never a copied pixel
--  number. Driver ID, level, Train Data entry and validation (both
--  windows), train running number, 'Start', the acknowledgement of SR
--  (DMI specification chapter 11, SUBSET-026 5.4.3.2 S-states), then
--  driving until FS at the first balise group.
--
--  Run by evc_test with its Check (test/src/evc_test.adb).

generic
   with procedure Check (Condition : Boolean; What : String);
package Evc_Test_Touch is

   procedure Run;

end Evc_Test_Touch;
