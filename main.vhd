-- @author Marcos Canel
-- This work is entirely my own
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
   port (
      i_clk, i_rst : in std_logic;
      
      -- directional pad (buttons)
      i_dpad : in std_logic_vector(3 downto 0);
      
      -- vga
      o_hsync : out std_logic;
      o_vsync : out std_logic;
      o_r     : out std_logic_vector(2 downto 0);
      o_g     : out std_logic_vector(2 downto 0);
      o_b     : out std_logic_vector(1 downto 0);
      
      -- seven segment to display score
      o_en : out std_logic_vector(2 downto 0);
      o_ss : out std_logic_vector(7 downto 0)
   );
end main;

architecture main_rtl of main is
   
   -- internal clock signals
   signal s_clk : std_logic := '0';
   signal s_clk_210 : std_logic := '0';
   
   -- input datapath variable to vga
   signal s_vga_pixel : std_logic_vector(7 downto 0) := (others => '0');
   
   -- output datapath variables from vga
   signal s_vga_x : integer := 0;
   signal s_vga_y : integer := 0;
   
   -- from 'game'
   signal s_player_one_score : integer range 0 to 9 := 0;
   signal s_player_two_score : integer range 0 to 9 := 0;
   
begin

   e_clk_210 : entity work.clk21m10d
      port map (
         clkin_in => i_clk,
         rst_in => '0',
         clk0_out => s_clk,
         clkfx_out => s_clk_210
      );
      
   e_vga : entity work.vga
      port map (
         i_clk => s_clk_210,
         i_pixel => s_vga_pixel,
         o_x => s_vga_x,
         o_y => s_vga_y,
         o_hsync => o_hsync,
         o_vsync => o_vsync,
         o_r => o_r,
         o_g => o_g,
         o_b => o_b
      );
      
   e_game : entity work.game
      port map (
         i_clk => s_clk,
         i_rst => not i_rst,
         i_screen_x => s_vga_x,
         i_screen_y => s_vga_y,
         i_controls => not i_dpad,
         o_pixel => s_vga_pixel,
         o_player_one_score => s_player_one_score,
         o_player_two_score => s_player_two_score
      );

   e_score_display : entity work.score_display
      port map (
         i_clk => s_clk,
         i_a => s_player_one_score,
         i_b => s_player_two_score,
         o_en => o_en,
         o_ss => o_ss
      );

end main_rtl;