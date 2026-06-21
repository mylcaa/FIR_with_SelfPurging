library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


package utils_pkg is
    constant ACC_WIDTH : natural := 16;
    constant MAC_INSTANCES : natural := 3;
    
    type coeff_array_t is array (natural range <>) of integer;
    type data_array_acc      is array (natural range <>) of std_logic_vector(ACC_WIDTH-1 downto 0);
    type data_array_mac_inst is array (natural range <>) of std_logic_vector(MAC_INSTANCES-1 downto 0);
    
end package;
