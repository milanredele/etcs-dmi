package body EVC_Supervision is

   function Status (Monitoring      : Monitoring_T;
                    Speed           : Natural;
                    V_Perm          : Natural;
                    V_Warning       : Natural;
                    V_SBI           : Natural;
                    V_Release       : Natural;
                    Brake_Commanded : Boolean;
                    In_AD           : Boolean;
                    Previous        : Status_T) return Status_T
   is
      Base : constant Status_T := (if Monitoring = 0 then NoS else IndS);
   begin
      if Monitoring = 2 then
         if Speed > V_Release or else (Previous = IntS and Brake_Commanded) then
            return IntS;
         end if;
         return IndS;
      end if;

      if (Speed > V_SBI and then not (In_AD and then Monitoring = 1))
        or else (Previous = IntS and Brake_Commanded)
      then
         return IntS;
      elsif Speed > V_Warning
        or else (Previous = WaS and then Speed > V_Perm)
      then
         return WaS;
      elsif Speed > V_Perm then
         return OvS;
      else
         return Base;
      end if;
   end Status;

end EVC_Supervision;
