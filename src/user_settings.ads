package User_Settings is

   type Toggle_T is (Basic_Speed_Hook);
   
   Toggle : array (Toggle_T) of Boolean := (others => False);

end User_Settings;
