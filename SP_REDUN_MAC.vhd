library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.utils_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SP_REDUN_MAC is
    generic (
        MUL_WIDTH        : natural  := 16;
        ACC_WIDTH        : natural := 16;
        REG_CONST        : integer := 0;
        MAC_INSTANCES    : integer := 3;
        NaN              : std_logic_vector(ACC_WIDTH - 1 downto 0) := "0"
    );
    Port (
          clk: in std_logic;
          mul_input: in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input: in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res: out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end SP_REDUN_MAC;

architecture Behavioral of SP_REDUN_MAC is

signal MAC_output: data_array_t(0 to MAC_INSTANCES-1)(ACC_WIDTH - 1 downto 0);
signal voter_input : data_array_t(0 to MAC_INSTANCES-1)(ACC_WIDTH - 1 downto 0);

signal switch : std_logic_vector(MAC_INSTANCES-1 downto 0); -- 0 bit value for off and 1 for on

component MAC is
    generic (
        MUL_WIDTH : natural;
        ACC_WIDTH : natural;
        REG_CONST : integer
    );
    port (
          clk:       in std_logic;
          mul_input: in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input: in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res:       out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end component;

component voter is
    generic (
        ACC_WIDTH     : natural;
        MAC_INSTANCES : natural;
        NaN           : std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
    port (
        data_in        : in data_array_t(0 to MAC_INSTANCES-1)(ACC_WIDTH - 1 downto 0);  
        voted_res      : out std_logic_vector(ACC_WIDTH - 1 downto 0);
        en             : out std_logic_vector(0 to MAC_INSTANCES-1)
    );
end component;

begin

gen_modules : for i in 0 to MAC_INSTANCES-1 generate
  MAC_instance : MAC
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

voter_instance: voter
    generic map (
        ACC_WIDTH     => ACC_WIDTH,
        MAC_INSTANCES => MAC_INSTANCES,
        NaN           => NaN
    )
    port map (
        data_in   => voter_input,
        voted_res => res,
        en => switch
    );

--MUX to connect MAC output and voter input
process
begin
    for i in 0 to MAC_INSTANCES-1 loop
        voter_input(i) <= MAC_output(i) when (switch(i) = '1') else NaN;
    end loop;
end process;

end Behavioral;
