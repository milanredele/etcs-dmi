--  ETCS DMI test simulator
--  The juridical recorder of the bench: implementation.

with EVC_Ports;

package body Sim_JRU is

   Ring      : array (0 .. Capacity - 1) of Record_T;
   Next      : Natural range 0 .. Capacity - 1 := 0;
   Total     : Natural := 0;
   Bad       : Natural := 0;
   By_Event  : array (EVC_Bytes.Byte) of Natural := (others => 0);

   procedure Reset is
   begin
      Ring := (others => (others => <>));
      Next := 0;
      Total := 0;
      Bad := 0;
      By_Event := (others => 0);
   end Reset;

   function Inc (N : Natural) return Natural is
     (if N < Natural'Last then N + 1 else N);

   procedure Put (Payload : EVC_Bytes.Byte_Array) is
      function U (First, Count : Natural) return Unsigned_64 is
         V : Unsigned_64 := 0;
      begin
         for I in reverse 0 .. Count - 1 loop
            V := V * 256 + Unsigned_64 (Payload (Payload'First + First + I));
         end loop;
         return V;
      end U;
   begin
      if Payload'Length /= EVC_Ports.JRU_Record_Length then
         Bad := Inc (Bad);
         return;
      end if;
      Ring (Next) :=
        (Event   => Payload (Payload'First),
         B2      => Payload (Payload'First + 1),
         B3      => Payload (Payload'First + 2),
         B4      => Payload (Payload'First + 3),
         Cycle   => Unsigned_32 (U (4, 4)),
         Time_Ms => U (8, 8));
      Next := (Next + 1) mod Capacity;
      Total := Inc (Total);
      By_Event (Payload (Payload'First)) :=
        Inc (By_Event (Payload (Payload'First)));
   end Put;

   function Count return Natural is (Total);
   function Available return Natural is (Natural'Min (Total, Capacity));
   function Malformed return Natural is (Bad);
   function Count_Of (Event : EVC_Bytes.Byte) return Natural is
     (By_Event (Event));

   function Get (Age : Natural) return Record_T is
   begin
      if Age >= Available then
         return (others => <>);
      end if;
      return Ring ((Next + Capacity - 1 - Age) mod Capacity);
   end Get;

   ---------------------------------------------------------------------
   --  Texts
   ---------------------------------------------------------------------

   Mode_Names : constant array (0 .. 18) of String (1 .. 2) :=
     ("FS", "AD", "LS", "OS", "SR", "SM", "SH", "UN", "PS", "SL", "SB",
      "TR", "PT", "SF", "IS", "NP", "NL", "SN", "RV");

   Status_Names : constant array (0 .. 4) of String (1 .. 4) :=
     ("NoS ", "IndS", "OvS ", "WaS ", "IntS");

   procedure Describe (R    : Record_T;
                       Text : out String;
                       Last : out Natural)
   is
      procedure Add (S : String) is
      begin
         for C of S loop
            if Last < Text'Last then
               Last := Last + 1;
               Text (Last) := C;
            end if;
         end loop;
      end Add;

      procedure Add_Nat (N : Unsigned_64) is
         Digits_Of : String (1 .. 20);
         K : Natural := Digits_Of'Last + 1;
         V : Unsigned_64 := N;
      begin
         loop
            K := K - 1;
            Digits_Of (K) := Character'Val (Character'Pos ('0')
                                            + Natural (V mod 10));
            V := V / 10;
            exit when V = 0 or else K = Digits_Of'First;
         end loop;
         Add (Digits_Of (K .. Digits_Of'Last));
      end Add_Nat;

      procedure Add_Nat (N : EVC_Bytes.Byte) is
      begin
         Add_Nat (Unsigned_64 (N));
      end Add_Nat;

      function U24 return Unsigned_64 is
        (Unsigned_64 (R.B2) + 256 * Unsigned_64 (R.B3)
         + 65_536 * Unsigned_64 (R.B4));

      --  a balise group: NID_C * 2**14 + NID_BG
      procedure Add_Group is
      begin
         Add_Nat (U24 / 16_384);
         Add ("/");
         Add_Nat (U24 mod 16_384);
      end Add_Group;

      procedure Add_Mode (M : EVC_Bytes.Byte) is
      begin
         if Natural (M) <= Mode_Names'Last then
            Add (Mode_Names (Natural (M)));
         else
            Add_Nat (M);
         end if;
      end Add_Mode;

      procedure Add_Level (Status, Level : EVC_Bytes.Byte) is
      begin
         case Status is
            when 0 => Add ("unknown");
            when 1 => Add ("invalid");
            when others =>
               case Level is
                  when 0 => Add ("0");
                  when 1 => Add ("NTC");
                  when 2 => Add ("1");
                  when 3 => Add ("2");
                  when others => Add_Nat (Level);
               end case;
         end case;
      end Add_Level;

      procedure Add_Brakes is
      begin
         if (R.B2 and 7) = 0 then
            Add ("released");
         else
            if (R.B2 and 1) /= 0 then
               Add ("EB ");
            end if;
            if (R.B2 and 2) /= 0 then
               Add ("SB ");
            end if;
            if (R.B2 and 4) /= 0 then
               Add ("TCO ");
            end if;
            Add ("(");
            if (R.B3 and 1) /= 0 then
               Add (" supervision");
            end if;
            if (R.B3 and 2) /= 0 then
               Add (" SB failed");
            end if;
            if (R.B3 and 4) /= 0 then
               Add (" roll away");
            end if;
            if (R.B3 and 8) /= 0 then
               Add (" direction");
            end if;
            if (R.B3 and 16) /= 0 then
               Add (" standstill");
            end if;
            Add (" )");
         end if;
      end Add_Brakes;

      Info_Names : constant array (1 .. 16) of String (1 .. 15) :=
        ("national values", "SSP            ", "gradients      ",
         "ASP            ", "TSR            ", "default grad.  ",
         "MA             ", "signal. speed  ", "track cond.    ",
         "traction       ", "big metal mass ", "route suitab.  ",
         "mode profile   ", "level crossing ", "adhesion       ",
         "balise group   ");

      Change_Names : constant array (1 .. 13) of String (1 .. 15) :=
        ("stored         ", "deleted        ", "rejected       ",
         "section timeout", "End Section t/o", "overlap timeout",
         "LOA t/o        ", "MA shortened   ", "NV applicable  ",
         "NV to defaults ", "trip order     ", "not kept       ",
         "TSRs deleted   ");

      function Trim (S : String) return String is
         L : Natural := S'Last;
      begin
         while L >= S'First and then S (L) = ' ' loop
            L := L - 1;
         end loop;
         return S (S'First .. L);
      end Trim;
   begin
      Text := (others => ' ');
      Last := Text'First - 1;
      Add_Nat (R.Time_Ms / 1000);
      Add (".");
      Add_Nat ((R.Time_Ms mod 1000) / 100);
      Add (" s  ");
      case R.Event is
         when 1 =>
            Add ("mode ");
            Add_Mode (R.B2);
            Add (", level ");
            Add_Level (R.B3, R.B4);
         when 2 =>
            Add ("telegram of group ");
            Add_Group;
         when 3 =>
            Add ("radio message ");
            Add_Nat (R.B2);
         when 4 =>
            Add ("linking reaction ");
            Add_Nat (R.B2);
            Add (case R.B3 is
                    when 1 => ", group early",
                    when 2 => ", group not detected",
                    when 3 => ", other group",
                    when others => ", cause ?");
         when 5 =>
            Add ("unexpected group ");
            Add_Group;
         when 6 =>
            Add ("missed group ");
            Add_Group;
         when 7 =>
            Add ("odometer ");
            Add (case R.B2 is
                    when 0 => "nominal",
                    when 1 => "impaired",
                    when others => "safety threshold exceeded");
         when 8 =>
            Add ("position ");
            Add (case R.B2 is
                    when 0 => "unknown",
                    when 1 => "valid",
                    when others => "invalid");
         when 9 =>
            Add ("cold movement detected");
         when 10 =>
            Add ("LRBG ");
            Add_Group;
         when 20 =>
            Add ("brakes ");
            Add_Brakes;
         when 21 =>
            Add (case R.B2 is
                    when 0 => "CSM ",
                    when 1 => "TSM ",
                    when others => "RSM ");
            if Natural (R.B3) <= Status_Names'Last then
               Add (Trim (Status_Names (Natural (R.B3))));
            end if;
            Add (", target ");
            Add_Nat (R.B4);
         when 22 =>
            Add (if R.B2 = 1 then "EOA passed" else "SvL passed");
         when 32 =>
            if R.B2 in 1 .. 16 then
               Add (Trim (Info_Names (Natural (R.B2))));
            else
               Add ("info ");
               Add_Nat (R.B2);
            end if;
            Add (" ");
            if R.B3 in 1 .. 13 then
               Add (Trim (Change_Names (Natural (R.B3))));
            else
               Add_Nat (R.B3);
            end if;
            Add (" ");
            Add_Nat (R.B4);
         when others =>
            Add ("event ");
            Add_Nat (R.Event);
            Add (": ");
            Add_Nat (R.B2);
            Add (" ");
            Add_Nat (R.B3);
            Add (" ");
            Add_Nat (R.B4);
      end case;
   end Describe;

end Sim_JRU;
