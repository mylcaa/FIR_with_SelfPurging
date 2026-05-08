library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAC is
    generic (
        MUL_WIDTH : natural := 16;
        ACC_WIDTH : natural := 16;
        REG_CONST : integer := 0
    );
    port (
          clk:       in std_logic;
          mul_input: in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input: in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res:       out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end MAC;

architecture Behavioral of MAC is

signal reg_mul   : std_logic_vector(2*MUL_WIDTH-1 downto 0);
signal mul_res   : std_logic_vector(2*MUL_WIDTH-1 downto 0);
signal reg_acc   : std_logic_vector(ACC_WIDTH-1 downto 0);

begin

mul_res <= std_logic_vector(signed(mul_input) * REG_CONST);
res <= std_logic_vector(resize(signed(reg_mul), ACC_WIDTH) + signed(reg_acc));

pipeline_reg: process(clk) is
begin
    if(rising_edge(clk)) then
        reg_mul <= mul_res;
        reg_acc <= acc_input;
    end if;
end process;

end Behavioral;
