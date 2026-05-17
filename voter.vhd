library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils_pkg.all;

entity voter is
generic (
    ACC_WIDTH     : natural := ACC_WIDTH;
    MAC_INSTANCES : natural := MAC_INSTANCES;
    NaN           : std_logic_vector(ACC_WIDTH - 1 downto 0) := "0"
);
port (
    clk       : in std_logic;
    rst       : in std_logic;
    en        : in std_logic;
    data_in   : in data_array_acc(0 to MAC_INSTANCES-1);  
    voted_res : out std_logic_vector(ACC_WIDTH - 1 downto 0);
    switch_en : out std_logic_vector(0 to MAC_INSTANCES-1)
);
end voter;

architecture Behavioral of voter is

signal xor_reg_array  : data_array_mac_inst(0 to MAC_INSTANCES-1);
signal xor_next_array : data_array_mac_inst(0 to MAC_INSTANCES-1);

signal xor_low_reg_array  : std_logic_vector(MAC_INSTANCES-1 downto 0) := (others => '0');
signal xor_low_next_array : std_logic_vector(MAC_INSTANCES-1 downto 0) := (others => '0');

signal en_signal_reg  : std_logic_vector(0 to MAC_INSTANCES-1);
signal en_signal_next : std_logic_vector(0 to MAC_INSTANCES-1);

signal data_in_xor_reg, data_in_xor_next : data_array_acc(0 to MAC_INSTANCES-1);
signal data_in_low_reg, data_in_low_next : data_array_acc(0 to MAC_INSTANCES-1);
signal data_in_en_reg,  data_in_en_next  : data_array_acc(0 to MAC_INSTANCES-1);

begin

process (clk) begin

if (rising_edge(clk)) then
    if rst = '1' then
        xor_reg_array <= (others => (others => '0'));
        xor_low_reg_array <= (others => '0');  
        en_signal_reg <= (others => '0');    
        
        data_in_xor_reg <= (others => (others => '0'));
        data_in_low_reg <= (others => (others => '0'));
        data_in_en_reg  <= (others => (others => '0'));  
    else
        xor_reg_array <= xor_next_array;
        xor_low_reg_array <= xor_low_next_array; 
        en_signal_reg <= en_signal_next;
        
        data_in_xor_reg <= data_in_xor_next;
        data_in_low_reg <= data_in_low_next;
        data_in_en_reg  <= data_in_en_next;
    end if;
end if;
end process;

process (all)
begin
    if (en = '1') then
        for i in 0 to MAC_INSTANCES-2 loop
            for j in (i+1) to MAC_INSTANCES-1 loop
              xor_next_array(i)(j) <= '1' when data_in(i) = data_in(j) else '0';
            end loop;
        end loop;
    else 
        xor_next_array <= xor_reg_array;
    end if;
       
    if (en = '1') then 
        for i in 0 to MAC_INSTANCES-1 loop
            for j in 0 to MAC_INSTANCES-1 loop
                for k in 0 to MAC_INSTANCES-1 loop 
                    if ((j = i) or (k = i)) then
                        xor_low_next_array(i) <= xor_low_next_array(i) or not(xor_reg_array(j)(k));
                    end if;
                end loop;
            end loop;
            
            if (data_in_low_reg(i) = NaN) then
                en_signal_next(i) <= '0';
            else
                en_signal_next(i) <= xor_low_reg_array(i);
            end if;
        end loop;
    else 
        xor_low_next_array <= xor_low_reg_array;
        en_signal_next <= en_signal_reg;
    end if;
    
    if (en_signal_reg = (en_signal_reg'range => '0')) then
        for i in 0 to MAC_INSTANCES-1 loop
            if en_signal_reg(i) = '1' then
                voted_res <= data_in_en_reg(i);
                exit;
            end if;
        end loop;
    else
        voted_res <= data_in_en_reg(0);
    end if;
    
end process;

switch_en <= en_signal_reg;

data_in_xor_next <= data_in when (en = '1') else data_in_xor_reg;
data_in_low_next <= data_in_xor_reg when (en = '1') else data_in_low_reg;
data_in_en_next <= data_in_low_reg when (en = '1') else data_in_en_reg;
        

end Behavioral;
