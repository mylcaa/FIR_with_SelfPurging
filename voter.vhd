library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.utils_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity voter is
generic (
    ACC_WIDTH     : natural := 16;
    MAC_INSTANCES : natural := 3;
    NaN           : std_logic_vector(ACC_WIDTH - 1 downto 0) := "0"
);
port (
    data_in        : in data_array_t(0 to MAC_INSTANCES-1)(ACC_WIDTH - 1 downto 0);  
    voted_res      : out std_logic_vector(ACC_WIDTH - 1 downto 0);
    en             : out std_logic_vector(0 to MAC_INSTANCES-1)
);
end voter;

architecture Behavioral of voter is

signal xor_array : data_array_t(0 to MAC_INSTANCES-1)(MAC_INSTANCES - 1 downto 0);

begin

process
    variable xor_iterator : integer := 0;
    variable any_xor_low : std_logic;
begin
    for i in 0 to MAC_INSTANCES-2 loop
        for j in (i+1) to MAC_INSTANCES-1 loop
            xor_array(i)(j) <= '1'
                when data_in(i) = data_in(j)
                else '0';
            xor_iterator := xor_iterator + 1;
        end loop;
    end loop;
    
    for i in 0 to MAC_INSTANCES-1 loop
        any_xor_low := '0';
        for j in 0 to MAC_INSTANCES-1 loop
            for k in 0 to MAC_INSTANCES-1 loop 
                if ((j = i) or (k = i)) then
                    any_xor_low := any_xor_low or not(xor_array(j)(k));
                end if;
            end loop;
        end loop;
        
        if (unsigned(data_in(i)) = NaN) then
            en(i) <= '0';
        else
            if (any_xor_low = '0') then
                en(i) <= '0';
            else 
                en(i) <= '1';
            end if;
        end if;
    end loop;
    
    if (en = "0") then
        for i in 0 to MAC_INSTANCES-1 loop
            if en(i) = '1' then
                voted_res <= data_in(i);
                exit;
            end if;
        end loop;
    else
        voted_res <= data_in(0);
    end if;
    
end process;

end Behavioral;
