library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.utils_pkg.all;

entity Shift_Reg is
  generic (
   WIDTH : natural := 16;
   DELAY_CYCLES : natural := 4
    );
  port (
   clk    : in std_logic;
   rst    : in std_logic;
   en     : in std_logic;
   input  : in std_logic_vector(WIDTH-1 downto 0);
   output : out std_logic_vector(WIDTH-1 downto 0)
   );
end Shift_Reg;

architecture Behavioral of Shift_Reg is

signal pipe_next_array : data_array_t(0 to DELAY_CYCLES-1)(WIDTH-1 downto 0);
signal pipe_reg_array : data_array_t(0 to DELAY_CYCLES-2)(WIDTH-1 downto 0); -- the last pipe_reg is output

begin

process (clk) begin

if (rising_edge(clk)) then
    if rst = '1' then
        pipe_reg_array <= (others => "0");
        output <= (others => '0');
    else
        for i in 0 to DELAY_CYCLES-2 loop
            pipe_reg_array(i) <= pipe_next_array(i);
        end loop;
        output <= pipe_next_array(DELAY_CYCLES-1);
    end if;
end if;
end process;

process (all) begin
    pipe_next_array(0) <= input when (en = '1') else pipe_reg_array(1);
    
    for i in 1 to DELAY_CYCLES-2 loop
        pipe_next_array(i) <= pipe_reg_array(i-1) when (en = '1') else pipe_reg_array(i+1);
    end loop;
    
    pipe_next_array(DELAY_CYCLES-1) <= pipe_reg_array(DELAY_CYCLES-2) when (en = '1') else output;
end process;

end Behavioral;
