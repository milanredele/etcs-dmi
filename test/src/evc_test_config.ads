--  ETCS on-board (EVC)
--  the installation configuration (EVC_Config): data, not code --
--  the byte image and its checks, EVC_Core.Configure, and every
--  field the supervision or the position reads.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Config is

      procedure Scenario_Config_Image;
      procedure Scenario_Config_Core;
      procedure Scenario_Config_Behaviour;
      --  3.18.5.1: the zones of the image of format version 3, the
      --  calendar of the EU summer time
      procedure Scenario_Config_Zones;
      --  3.18.3.2 c) 1st bullet, 3.13.2.2.2.1: the image of format version
      --  4 carries the traction cut-off time; version 3 keeps the default
      procedure Scenario_Config_Traction;

end EVC_Test_Config;
