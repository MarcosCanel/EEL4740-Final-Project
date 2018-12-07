-- @author Marcos Canel
-- This work is entirely my own
library ieee;
use ieee.std_logic_1164.all;

entity score_display is
    port (
      i_clk : in std_logic;
      i_a   : in integer range 0 to 9;
      i_b   : in integer range 0 to 9;
      o_en  : out std_logic_vector(2 downto 0);
      o_ss  : out std_logic_vector(7 downto 0)
   );
end score_display;

architecture score_display_rtl of score_display is

    -- bcd digit to seven segment code (+ decimal point)
   function int2ss (x : integer) return std_logic_vector is
   begin
      case x is
         when 0 => return "00000011"; -- "0"
         when 1 => return "10011111"; -- "1" 
         when 2 => return "00100101"; -- "2" 
         when 3 => return "00001101"; -- "3" 
         when 4 => return "10011001"; -- "4" 
         when 5 => return "01001001"; -- "5" 
         when 6 => return "01000001"; -- "6" 
         when 7 => return "00011111"; -- "7" 
         when 8 => return "00000001"; -- "8"     
         when 9 => return "00001001"; -- "9"   
         when others => return "11111111"; -- " "
      end case;
   end;
   
   constant c_count_max : integer := 10000;
   
   signal s_count : integer range 0 to c_count_max := 0;
   signal s_en : std_logic_vector(2 downto 0) := "011";

begin

   o_en <= s_en;
   o_ss <= int2ss(i_a) when s_en = "011" else
           int2ss(i_b) when s_en = "110" else
           "11111111";
   
   process (i_clk) is
   begin
      if rising_edge(i_clk) then
         if s_count < c_count_max then
            s_count <= s_count + 1;
         else
            s_count <= 0;
            s_en <= s_en(1 downto 0) & s_en(2);
         end if;
      end if;
   end process;

end score_display_rtl;