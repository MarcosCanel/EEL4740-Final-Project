-- @author Marcos Canel
-- This work is entirely my own
library ieee;
use ieee.std_logic_1164.all;

-- 640x480 vga output
entity vga is
   port (
      i_clk   : in std_logic;
      
      i_pixel  : in std_logic_vector(7 downto 0);
      o_x      : out integer;
      o_y      : out integer;
      
      o_hsync : out std_logic;
      o_vsync : out std_logic;
      o_r     : out std_logic_vector(2 downto 0);
      o_g     : out std_logic_vector(2 downto 0);
      o_b     : out std_logic_vector(1 downto 0)
   );
end vga;

architecture vga_rtl of vga is

   -- x in [min, max)
   function between(x, min, max : integer) return boolean is
   begin
      return min <= x and x < max;
   end;

   -- https://tinyvga.com/vga-timing/640x480@60Hz
   -- Horizontal timing constants
   constant c_hvisible : integer := 640;
   constant c_hfront   : integer := c_hvisible + 16;
   constant c_hsync    : integer := c_hfront   + 96;
   constant c_hback    : integer := c_hsync    + 48;
   -- Vertical timing constants
   constant c_vvisible : integer := 480;
   constant c_vfront   : integer := c_vvisible + 10;
   constant c_vsync    : integer := c_vfront   + 2;
   constant c_vback    : integer := c_vsync    + 33;

   signal s_hcount : integer range 0 to 799 := 1;
   signal s_vcount : integer range 0 to 524 := 1;

begin

   o_x <= s_hcount;
   o_y <= s_vcount;
   o_hsync <= '0' when between(s_hcount, c_hfront, c_hsync) else '1';
   o_vsync <= '0' when between(s_vcount, c_vfront, c_vsync) else '1';
   o_r <= i_pixel(7 downto 5) when between(s_hcount, 0, c_hvisible) and between(s_vcount, 0, c_vvisible) else "000";
   o_g <= i_pixel(4 downto 2) when between(s_hcount, 0, c_hvisible) and between(s_vcount, 0, c_vvisible) else "000";
   o_b <= i_pixel(1 downto 0) when between(s_hcount, 0, c_hvisible) and between(s_vcount, 0, c_vvisible) else "00";         
   
   process (i_clk) is
   begin
      if rising_edge(i_clk) then
         if s_hcount < 799 then
            s_hcount <= s_hcount + 1;
         else
            s_hcount <= 0;
            if s_vcount < 524 then
               s_vcount <= s_vcount + 1;
            else
               s_vcount <= 0;
            end if;
         end if;
      end if;
   end process;

end vga_rtl;