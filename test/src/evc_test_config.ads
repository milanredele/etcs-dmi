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

end EVC_Test_Config;
