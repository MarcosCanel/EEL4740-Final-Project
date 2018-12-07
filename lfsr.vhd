-- @author Marcos Canel
-- This work is entirely my own
library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
   port (
      i_clk, i_rst : in std_logic;
      i_seed : in std_logic_vector(15 downto 0);
      o_lfsr : out std_logic_vector(15 downto 0)
   );
end lfsr;

architecture lfsr_rtl of lfsr is

   signal r_lfsr : std_logic_vector(15 downto 0) := (others => '0');

begin

   o_lfsr <= r_lfsr;

   process (i_clk) is
   begin
      if i_rst = '1' then
         r_lfsr <= i_seed;
      elsif rising_edge(i_clk) then
         r_lfsr <= (r_lfsr(0) xor r_lfsr(2) xor r_lfsr(3) xor r_lfsr(5)) & r_lfsr(15 downto 1);
      end if;
   end process;

end lfsr_rtl;