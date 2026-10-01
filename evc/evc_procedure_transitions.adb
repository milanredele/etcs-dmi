--  ETCS on-board (EVC)
--  INTERIM: the transitions of the procedures half, implementation.

with EVC_Transition_Conditions; use EVC_Transition_Conditions;

package body EVC_Procedure_Transitions
  with SPARK_Mode => On
is

   type Ids_T is array (Positive range <>) of Condition_Id_T;

   --  One of the conditions holds
   function Any (L : Ids_T) return Boolean
     with Global => EVC_Procedures.State
   is
   begin
      for C of L loop
         if EVC_Transition_Conditions.Holds (C) then
            return True;
         end if;
      end loop;
      return False;
   end Any;

   --  The modes FS, AD, LS and OS share their trip conditions
   Supervised_Trips : constant Ids_T :=
     (C_11, C_12, C_16, C_17, C_18, C_20, C_41, C_65, C_66, C_69);

   function Holds (From, To : Mode_T) return Boolean is
   begin
      if From = M_NP then
         return False;
      end if;
      case To is
         when M_SB =>
            case From is
               when M_PS => return Any ((1 => C_22));
               when M_SH => return Any ((C_19, C_27, C_30));
               when M_SM => return Any ((C_28, C_82));
               when M_FS | M_AD | M_LS | M_SR | M_OS | M_UN | M_PT | M_SN
                  | M_NL | M_RV =>
                  return Any ((1 => C_28));
               when others => return False;
            end case;
         when M_SH =>
            case From is
               when M_SB | M_PT => return Any ((C_5, C_6, C_50));
               when M_PS => return Any ((1 => C_23));
               when M_SM => return Any ((1 => C_6));
               when M_FS | M_AD | M_LS | M_OS =>
                  return Any ((C_5, C_6, C_50, C_51));
               when M_SR => return Any ((C_5, C_6, C_51));
               when M_UN | M_SN => return Any ((C_5, C_61));
               when M_TR => return Any ((1 => C_68));
               when others => return False;
            end case;
         when M_SM =>
            return From in M_SB | M_FS | M_AD | M_LS | M_SR | M_OS | M_PT
              and then Any ((1 => C_81));
         when M_FS =>
            case From is
               when M_AD => return Any ((1 => C_9));
               when M_LS => return Any ((1 => C_76));
               when M_OS => return Any ((1 => C_75));
               when others => return False;
            end case;
         when M_LS =>
            case From is
               when M_SB | M_PT => return Any ((1 => C_70));
               when M_FS | M_AD => return Any ((C_70, C_72));
               when M_SR => return Any ((1 => C_72));
               when M_OS => return Any ((C_70, C_74));
               when M_UN | M_SN => return Any ((1 => C_71));
               when others => return False;
            end case;
         when M_SR =>
            return From in M_SB | M_FS | M_AD | M_LS | M_OS | M_PT
              and then Any ((1 => C_37));
         when M_OS =>
            case From is
               when M_SB | M_PT => return Any ((1 => C_15));
               when M_FS | M_AD => return Any ((C_15, C_40));
               when M_LS => return Any ((C_15, C_73));
               when M_SR => return Any ((1 => C_40));
               when M_UN | M_SN => return Any ((1 => C_34));
               when others => return False;
            end case;
         when M_UN =>
            return From = M_TR and then Any ((1 => C_62));
         when M_TR =>
            case From is
               when M_SB | M_UN | M_SN => return Any ((1 => C_20));
               when M_SH => return Any ((C_49, C_52, C_65));
               when M_SM =>
                  return Any ((C_16, C_17, C_20, C_41, C_65, C_66, C_69));
               when M_FS | M_AD | M_LS | M_OS =>
                  return Any (Supervised_Trips);
               when M_SR => return Any ((C_18, C_20, C_43, C_54, C_65));
               when others => return False;
            end case;
         when M_PT =>
            return From = M_TR and then Any ((1 => C_7));
         when M_SN =>
            return From = M_TR and then Any ((1 => C_63));
         when M_RV =>
            return From in M_FS | M_AD | M_LS | M_OS
              and then Any ((1 => C_59));
         when others =>
            return False;
      end case;
   end Holds;

end EVC_Procedure_Transitions;
