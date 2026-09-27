--  ETCS DMI
--  Driver-controlled display settings.

package User_Settings is

   -- DMI 8.2.2.4 Table 15: one toggle per mode controls all concerned
   -- speed/planning information objects (OS: hooks, release speed digital,
   -- distance to target digital, planning info, TTI; SR: hooks, distance,
   -- TTI; SH: hooks). Automatically off when entering one of these modes
   -- (8.2.2.4.5).
   Speed_Info_Visible : Boolean := False;

end User_Settings;
