library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.utils_pkg.all;

entity FIR is
    generic (
        INPUT_WIDTH  : natural  := 16;
        OUTPUT_WIDTH : natural := 16;
        FILTER_ORDER : natural := 3
    );
    port (
        clk: in std_logic;
        rst: in std_logic; 
        input : in  std_logic_vector(INPUT_WIDTH - 1 downto 0);
        output: out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
    );
end FIR;

architecture Behavioral of FIR is

--COMPONENTS:----------------------------------------------------------------------
component MAC_SelfPurging is
    generic (
        MUL_WIDTH     : natural;
        ACC_WIDTH     : natural;
        REG_CONST     : integer;
        MAC_INSTANCES : integer;
        NaN           : std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
    port (
          clk: in std_logic;
          rst: in std_logic;
          mul_input: in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input: in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res: out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end component;

--CONSTANTS:---------------------------------------------------------------------------
constant NaN : std_logic_vector(OUTPUT_WIDTH - 1 downto 0) := (others => '1');
constant numSelfPurgingMAC : natural := 3;
constant coefficients      : coeff_array_t(0 to FILTER_ORDER-1) := (0, 0, 0);
constant DELAY : natural := 2; --MAC one pipeline register + voter three pipeline registers

--SIGNALS:-----------------------------------------------------------------------------
signal MAC_output        : data_array_t(0 to FILTER_ORDER)(OUTPUT_WIDTH-1 downto 0);
signal mul_input         : data_array_t(0 to FILTER_ORDER-1)(INPUT_WIDTH-1 downto 0);
signal mul_reg_array     : data_array_t(0 to FILTER_ORDER-2)(INPUT_WIDTH-1 downto 0);
signal mul_next_array    : data_array_t(0 to FILTER_ORDER-2)(INPUT_WIDTH-1 downto 0);

type pipe_matrix_t is array (0 to DELAY-1) of data_array_t(0 to FILTER_ORDER-2)(INPUT_WIDTH-1 downto 0);
signal pipe_array : pipe_matrix_t;

begin

process (clk) begin

if (rising_edge(clk)) then
    if rst = '1' then
        mul_reg_array <= (others => "0");        
    else
        pipe_array(0) <= mul_next_array;
        
        for i in 1 to DELAY loop
            pipe_array(i) <= pipe_array(i-1);
        end loop;
        
        mul_reg_array <= pipe_array(DELAY);
    end if;
end if;
end process;

gen_modules : for i in 0 to FILTER_ORDER-1 generate
  MAC_i : MAC_SelfPurging
    generic map (
        MUL_WIDTH => INPUT_WIDTH,
        ACC_WIDTH => OUTPUT_WIDTH,
        REG_CONST => coefficients(i),
        MAC_INSTANCES => numSelfPurgingMAC,
        NaN => NaN
    )
    port map (
        clk => clk,
        rst => rst,
        mul_input => mul_input(i),
        acc_input => MAC_output(i),
        res => MAC_output(i+1)
    );
end generate;

process (all) begin
    MAC_output(0) <= (others => '0');
    mul_next_array(0) <= input;
    mul_input(0) <= input;
    
    for i in 0 to FILTER_ORDER-2 loop
        mul_input(i+1) <= mul_reg_array(i);
    end loop;
    
    for i in 0 to FILTER_ORDER-3 loop
        mul_next_array(i+1) <= mul_reg_array(i);
    end loop;
    
    output <= MAC_output(FILTER_ORDER-1);
end process;

end Behavioral;
