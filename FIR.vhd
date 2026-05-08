library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FIR is
    generic (
        INPUT_WIDTH  : natural  := 16;
        OUTPUT_WIDTH : natural := 16;
        FILTER_ORDER : natural := 3;
        NaN          : std_logic_vector(INPUT_WIDTH - 1 downto 0) := "0"
    );
    port ( 
        input : in  std_logic_vector(INPUT_WIDTH - 1 downto 0);
        output: out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
    );
end FIR;

architecture Behavioral of FIR is

component SP_REDUN_MAC is
    generic (
        MUL_WIDTH        : natural;
        ACC_WIDTH        : natural;
        REG_CONST        : integer;
        MAC_INSTANCES    : integer;
        NaN              : std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
    port (
          clk: in std_logic;
          mul_input: in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input: in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res: out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end component;

begin

gen_modules : for i in 0 to MAC_INSTANCES-1 generate
  instMAC : MAC
    generic map (
        MUL_WIDTH => MUL_WIDTH,
        ACC_WIDTH => ACC_WIDTH,
        REG_CONST => REG_CONST
    )
    port map (
        clk => clk,
        mul_input => mul_input,
        acc_input => acc_input,
        res => MAC_output(i)
    );
end generate;


end Behavioral;
