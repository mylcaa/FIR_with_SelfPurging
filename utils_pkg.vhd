library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


package utils_pkg is
    type data_array_t is array (natural range <>) of std_logic_vector;
    type coeff_array_t is array (natural range <>) of integer;
end package;
