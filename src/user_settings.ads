package User_Settings is

   type Toggle_T is (Basic_Speed_Hook, Release_Speed_Digital);
   
   Toggle : array (Toggle_T) of Boolean := (others => False);

end User_Settings;
