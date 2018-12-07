-- @author Marcos Canel
-- This work is entirely my own
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game is
   port (
      i_clk, i_rst : in std_logic;
      i_screen_x   : in integer range 0 to 639;
      i_screen_y   : in integer range 0 to 479;
      i_controls   : in std_logic_vector(3 downto 0);
      o_pixel      : out std_logic_vector(7 downto 0);
      o_player_one_score, o_player_two_score : out integer range 0 to 9
   );
end game;

architecture game_rtl of game is

   -- x in [min, max)
   function between(x, min, max : integer) return boolean is
   begin
      return min <= x and x < max;
   end;
   
   function max(x, y : integer) return integer is
   begin
      if x >= y then
         return x;
      else
         return y;
      end if;
   end;
   
   function min(x, y : integer) return integer is
   begin
      if x <= y then
         return x;
      else
         return y;
      end if;
   end;
   
   constant c_screen_w : integer := 640;
   constant c_screen_h : integer := 480;
   constant c_paddle_w : integer := 20;
   constant c_paddle_h : integer := 80;
   constant c_ball_w : integer := 10;
   constant c_ball_h : integer := 12;
   constant c_paddle_to_edge : integer := 30;
   constant c_player_one_x : integer := c_paddle_to_edge;
   constant c_player_two_x : integer := c_screen_w - c_paddle_w - c_paddle_to_edge;
   constant c_player_count_max : integer := 31250;
   constant c_ball_count_lower_limit : integer := 10000;
   constant c_ball_count_upper_limit : integer := 110000;
   constant c_ball_count_max_start : integer := 60000;
   constant c_ball_count_increment : integer := 10000;
   constant c_paddle_start_y : integer := c_screen_h / 2 - c_paddle_h / 2;
   constant c_ball_start_x : integer := c_screen_w / 2 - c_ball_w / 2;
   constant c_ball_start_y : integer := c_screen_h / 2 - c_ball_h / 2;
   
   signal s_player_one_score : integer range 0 to 9 := 0;
   signal s_player_two_score : integer range 0 to 9 := 0;
   signal s_player_one_y : integer range 0 to c_screen_h - c_paddle_h := c_paddle_start_y;
   signal s_player_two_y : integer range 0 to c_screen_h - c_paddle_h := c_paddle_start_y;
   signal s_player_count : integer range 0 to c_player_count_max := 0;

   signal s_ball_x : integer range 0 to c_screen_w - c_ball_w := c_ball_start_x;
   signal s_ball_y : integer range 0 to c_screen_h - c_ball_h := c_ball_start_y;
   signal s_ball_vel : std_logic_vector(1 downto 0) := "00";
   signal s_ball_count : integer range 0 to c_ball_count_upper_limit := 0;
   signal s_ball_count_max : integer range c_ball_count_lower_limit to c_ball_count_upper_limit := c_ball_count_max_start;
   
   -- pseudo-random bit vector
   signal s_random_bits : std_logic_vector(15 downto 0) := (others => '0');

begin

   e_lfsr : entity work.lfsr
      port map (
         i_clk => i_clk,
         i_rst => i_rst,
         i_seed => X"ACE1",
         o_lfsr => s_random_bits
      );

   o_player_one_score <= s_player_one_score;
   o_player_two_score <= s_player_two_score;

   -- draw xor pattern for players and ball, otherwise black
   o_pixel <= std_logic_vector(to_unsigned(i_screen_x, 8) xor to_unsigned(i_screen_y, 8)) when
    ((between(i_screen_x, c_player_one_x, c_player_one_x + c_paddle_w) and between(i_screen_y, s_player_one_y, s_player_one_y + c_paddle_h)) or
     (between(i_screen_x, c_player_two_x, c_player_two_x + c_paddle_w) and between(i_screen_y, s_player_two_y, s_player_two_y + c_paddle_h)) or
     (between(i_screen_x, s_ball_x, s_ball_x + c_ball_w) and between(i_screen_y, s_ball_y, s_ball_y + c_ball_h)))
   else
      X"00";

   -- primary game logic process
   -- very dense if/else block, tried to comment as necessary but readability is low
   process (i_clk, i_controls) is
   begin
      if rising_edge(i_clk) then
         if i_rst = '1' then
            s_player_one_score <= 0;
            s_player_two_score <= 0;
            s_player_one_y <= c_paddle_start_y;
            s_player_two_y <= c_paddle_start_y;
            s_player_count <= 0;
            s_ball_x <= c_ball_start_x;
            s_ball_y <= c_ball_start_y;
            s_ball_vel <= s_random_bits(1 downto 0);
            s_ball_count <= 0;
            s_ball_count_max <= c_ball_count_max_start;
         else
            -- update players at given rate
            if s_player_count < c_player_count_max then
               s_player_count <= s_player_count + 1;
            else
               s_player_count <= 0;
               -- update player one
               if i_controls(0) = '1' then -- going up
                  s_player_one_y <= max(s_player_one_y - 1, 0);
               elsif i_controls(1) = '1' then -- going down
                  s_player_one_y <= min(s_player_one_y + 1, c_screen_h - c_paddle_h);
               end if;
               -- update player two
               if i_controls(3) = '1' then -- going up
                  s_player_two_y <= max(s_player_two_y - 1, 0);
               elsif i_controls(2) = '1' then -- going down
                  s_player_two_y <= min(s_player_two_y + 1, c_screen_h - c_paddle_h);
               end if;
            end if;
            -- update ball at given rate
            if s_ball_count < s_ball_count_max then
               s_ball_count <= s_ball_count + 1;
            else
               s_ball_count <= 0;
               -- goal on player one
               if s_ball_x = 0 then
                  s_player_two_score <= min(s_player_two_score + 1, 9);
                  s_ball_x <= c_ball_start_x;
                  s_ball_y <= c_ball_start_y;
                  s_ball_vel <= s_random_bits(1 downto 0);
                  s_ball_count_max <= c_ball_count_max_start;
               -- goal on player two
               elsif s_ball_x + c_ball_w = c_screen_w then
                  s_player_one_score <= min(s_player_one_score + 1, 9);
                  s_ball_x <= c_ball_start_x;
                  s_ball_y <= c_ball_start_y;
                  s_ball_vel <= s_random_bits(1 downto 0);
                  s_ball_count_max <= c_ball_count_max_start;
               else
                  -- player one paddle collision
                  if s_ball_x = c_player_one_x + c_paddle_w and between(s_ball_y, s_player_one_y, s_player_one_y + c_paddle_h) then
                     s_ball_x <= s_ball_x + 1;
                     s_ball_vel(0) <= '1';
                     -- increase/decrease the ball's velocity based on player one paddle movement
                     if i_controls(1) = '1' and s_player_one_y + c_paddle_h /= c_screen_h then -- player one travelling downwards
                        if s_ball_vel(1) = '0' then -- ball also travelling downwards, increase the velocity
                           s_ball_count_max <= min(s_ball_count_max + c_ball_count_increment, c_ball_count_upper_limit);
                        else -- ball and player travelling in opposite directions, decrease the velocity
                           s_ball_count_max <= max(s_ball_count_max - c_ball_count_increment, c_ball_count_lower_limit);
                        end if;
                     elsif i_controls(0) = '1' and s_player_one_y /= 0 then -- player one travelling upwards
                        if s_ball_vel(1) = '1' then -- ball also travelling upwards, increase the velocity
                           s_ball_count_max <= min(s_ball_count_max + c_ball_count_increment, c_ball_count_upper_limit);
                        else -- ball and player travelling in opposite directions, decrease the velocity
                           s_ball_count_max <= max(s_ball_count_max - c_ball_count_increment, c_ball_count_lower_limit);
                        end if;
                     end if;
                  -- player two paddle collision
                  elsif s_ball_x + c_ball_w = c_player_two_x and between(s_ball_y, s_player_two_y, s_player_two_y + c_paddle_h) then
                     s_ball_x <= s_ball_x - 1;
                     s_ball_vel(0) <= '0';
                     -- increase/decrease the ball velocity based on player two paddle movement
                     if i_controls(2) = '1' and s_player_two_y + c_paddle_h /= c_screen_h then -- player two travelling downwards
                        if s_ball_vel(1) = '0' then -- ball also travelling downwards, increase the velocity
                           s_ball_count_max <= min(s_ball_count_max + c_ball_count_increment, c_ball_count_upper_limit);
                        else -- ball and player travelling in opposite directions, decrease the velocity
                           s_ball_count_max <= max(s_ball_count_max - c_ball_count_increment, c_ball_count_lower_limit);
                        end if;
                     elsif i_controls(3) = '1' and s_player_two_y /= 0 then -- player two travelling upwards
                        if s_ball_vel(1) = '1' then -- ball also travelling upwards, increase the velocity
                           s_ball_count_max <= min(s_ball_count_max + c_ball_count_increment, c_ball_count_upper_limit);
                        else -- ball and player travelling in opposite directions, decrease the velocity
                           s_ball_count_max <= max(s_ball_count_max - c_ball_count_increment, c_ball_count_lower_limit);
                        end if;
                     end if;
                  else
                     -- no collisions, update normally
                     case s_ball_vel(0) is
                        when '0' => s_ball_x <= s_ball_x - 1;
                        when '1' => s_ball_x <= s_ball_x + 1;
                        when others => null;
                     end case;
                  end if;          
                  -- bottom border collision
                  if s_ball_y = 0 then
                     s_ball_y <= s_ball_y + 1;
                     s_ball_vel(1) <= '1';
                  -- top border collision
                  elsif s_ball_y + c_ball_h = c_screen_h then
                     s_ball_y <= s_ball_y - 1;
                     s_ball_vel(1) <= '0';
                  else
                     -- no collisions, update normally
                     case s_ball_vel(1) is
                        when '0' => s_ball_y <= s_ball_y - 1;
                        when '1' => s_ball_y <= s_ball_y + 1;
                        when others => null;
                     end case;
                  end if;
               end if;
            end if;
         end if;
      end if;
   end process;
   
end game_rtl;