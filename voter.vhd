library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils_pkg.all;

entity voter is
generic (
    ACC_WIDTH     : natural := 16;
    MAC_INSTANCES : natural := 3;
    NaN           : std_logic_vector(ACC_WIDTH - 1 downto 0) := "0"
);
port (
    clk       : in std_logic;
    rst       : in std_logic;
    data_in   : in data_array_t(0 to MAC_INSTANCES-1)(ACC_WIDTH - 1 downto 0);  
    voted_res : out std_logic_vector(ACC_WIDTH - 1 downto 0);
    en        : out std_logic_vector(0 to MAC_INSTANCES-1)
);
end voter;

architecture Behavioral of voter is

signal xor_reg_array  : data_array_t(0 to MAC_INSTANCES-1)(MAC_INSTANCES - 1 downto 0);
signal xor_next_array : data_array_t(0 to MAC_INSTANCES-1)(MAC_INSTANCES - 1 downto 0);

signal xor_low_reg_array  : std_logic_vector := (others => '0');
signal xor_low_next_array : std_logic_vector := (others => '0');

signal en_signal_reg : std_logic_vector(0 to MAC_INSTANCES-1);
signal en_signal_next : std_logic_vector(0 to MAC_INSTANCES-1);

begin

process (clk) begin

if (rising_edge(clk)) then
    if rst = '1' then
        xor_reg_array <= (others => "0");
        xor_low_reg_array <= (others => '0');  
        en_signal_reg <= (others => '0');      
    else
        xor_reg_array <= xor_next_array;
        xor_low_reg_array <= xor_low_next_array; 
        en_signal_reg <= en_signal_next;
    end if;
end if;
end process;

process (all)
begin
    for i in 0 to MAC_INSTANCES-2 loop
        for j in (i+1) to MAC_INSTANCES-1 loop
            xor_next_array(i)(j) <= '1' when data_in(i) = data_in(j) else '0';
        end loop;
    end loop;
    
    for i in 0 to MAC_INSTANCES-1 loop
        for j in 0 to MAC_INSTANCES-1 loop
            for k in 0 to MAC_INSTANCES-1 loop 
                if ((j = i) or (k = i)) then
                    xor_low_next_array(i) <= xor_low_next_array(i) or not(xor_reg_array(j)(k));
                end if;
            end loop;
        end loop;
        
        if (data_in(i) = NaN) then
            en_signal_next(i) <= '0';
        else
            en_signal_next(i) <= xor_low_reg_array(i);
        end if;
    end loop;
    
    if (en_signal_reg = "0") then
        for i in 0 to MAC_INSTANCES-1 loop
            if en_signal_reg(i) = '1' then
                voted_res <= data_in(i);
                exit;
            end if;
        end loop;
    else
        voted_res <= data_in(0);
    end if;
    
end process;

en <= en_signal_reg;

end Behavioral;
