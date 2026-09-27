--  ETCS DMI test tooling
--  The supervision status as the on-board speed and distance monitoring
--  determines it (SUBSET-026 3.13.10), reduced to what the simulator
--  models: speeds in km/h against the supervision limits and one brake
--  command. The DMI is told the result (MSG_SPEED_STATE), it does not
--  derive it.

package EVC_Supervision is

   -- wire codes of MSG_SPEED_STATE
   subtype Monitoring_T is Natural range 0 .. 2; -- CSM / TSM / RSM
   subtype Status_T is Natural range 0 .. 4;     -- NoS IndS OvS WaS IntS
   NoS  : constant Status_T := 0;
   IndS : constant Status_T := 1;
   OvS  : constant Status_T := 2;
   WaS  : constant Status_T := 3;
   IntS : constant Status_T := 4;

   -- Previous: the status before this evaluation (WaS is revoked at the
   -- Permitted limit only, IntS with the brake command only; Tables 6,
   -- 10, 11 and 14). In_AD: Automatic Driving, where exceeding the SBI
   -- limit in TSM triggers nothing (SUBSET-026 4.4.16.1.4).
   function Status (Monitoring      : Monitoring_T;
                    Speed           : Natural;
                    V_Perm          : Natural;
                    V_Warning       : Natural;
                    V_SBI           : Natural;
                    V_Release       : Natural;
                    Brake_Commanded : Boolean;
                    In_AD           : Boolean;
                    Previous        : Status_T) return Status_T;

end EVC_Supervision;
