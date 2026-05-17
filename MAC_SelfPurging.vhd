library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.utils_pkg.all;

use IEEE.NUMERIC_STD.ALL;

entity MAC_SelfPurging is
    generic (
        MUL_WIDTH        : natural  := 16;
        ACC_WIDTH        : natural := 16;
        REG_CONST        : integer := 0;
        MAC_INSTANCES    : integer := 3;
        NaN              : std_logic_vector(ACC_WIDTH - 1 downto 0) := "0"
    );
    Port (
          clk       : in std_logic;
          rst       : in std_logic;
          en        : in std_logic;
          mul_input : in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input : in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res       : out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end MAC_SelfPurging;

architecture Behavioral of MAC_SelfPurging is

signal MAC_output: data_array_acc(0 to MAC_INSTANCES-1);
signal voter_input : data_array_acc(0 to MAC_INSTANCES-1);

signal switch : std_logic_vector(MAC_INSTANCES-1 downto 0); -- 0 bit value for off and 1 for on

component MAC is
    generic (
        MUL_WIDTH : natural;
        ACC_WIDTH : natural;
        REG_CONST : integer
    );
    port (
          clk       : in std_logic;
          rst       : in std_logic;  
          en        : in std_logic;
          mul_input : in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input : in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res       : out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end component;

component voter is
    generic (
        ACC_WIDTH     : natural;
        MAC_INSTANCES : natural;
        NaN           : std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
    port (    
        clk       : in std_logic;
        rst       : in std_logic;
        en        : in std_logic;
        data_in   : in data_array_acc(0 to MAC_INSTANCES-1);  
        voted_res : out std_logic_vector(ACC_WIDTH - 1 downto 0);
        switch_en : out std_logic_vector(0 to MAC_INSTANCES-1)
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
        clk       => clk,
        rst       => rst,
        en        => en,
        mul_input => mul_input,
        acc_input => acc_input,
        res       => MAC_output(i)
    );
end generate;

voter_instance: voter
    generic map (
        ACC_WIDTH     => ACC_WIDTH,
        MAC_INSTANCES => MAC_INSTANCES,
        NaN           => NaN
    )
    port map (
        clk       => clk,
        rst       => rst,
        en        => en,
        data_in   => voter_input,
        voted_res => res,
        switch_en => switch
    );

--MUX to connect MAC output and voter input
process (all) 
begin
    for i in 0 to MAC_INSTANCES-1 loop
        voter_input(i) <= MAC_output(i) when (switch(i) = '1') else NaN;
    end loop;
end process;

end Behavioral;
