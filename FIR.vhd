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
    clk : in std_logic;
    rst : in std_logic;
    -- AXI Stream Slave Interface (input)
    s_axis_tdata  : in  std_logic_vector(INPUT_WIDTH - 1 downto 0);
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;
    -- AXI Stream Master Interface (output)
    m_axis_tdata  : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic
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
          clk       : in std_logic;
          rst       : in std_logic;
          en        : in std_logic;
          mul_input : in std_logic_vector(MUL_WIDTH - 1 downto 0);               
          acc_input : in std_logic_vector(ACC_WIDTH - 1 downto 0);                         
          res       : out std_logic_vector(ACC_WIDTH - 1 downto 0)
    );
end component;

component Shift_Reg is
  generic (
   WIDTH : natural;
   DELAY_CYCLES : natural
    );
  port (
   clk    : in std_logic;
   rst    : in std_logic;
   en     : in std_logic;
   input  : in std_logic_vector(WIDTH-1 downto 0);
   output : out std_logic_vector(WIDTH-1 downto 0)
   );
end component;

--CONSTANTS:---------------------------------------------------------------------------
constant NaN               : std_logic_vector(OUTPUT_WIDTH - 1 downto 0) := (others => '1');
constant DELAY             : natural := 4; --MAC one pipeline register + voter three pipeline registers
constant numSelfPurgingMAC : natural := 3;
constant coefficients      : coeff_array_t(0 to FILTER_ORDER-1) := (0, 0, 0);

--SIGNALS:-----------------------------------------------------------------------------
signal MAC_output        : data_array_output(0 to FILTER_ORDER-2); --MAC_output is the output for all MAC mods except for the last
signal mul_input         : data_array_input(0 to FILTER_ORDER-2);  --mul_input is the mul input for all MAC mods except for the first

signal m_axis_tvalid_signal : std_logic_vector(0 downto 0);
signal en_axis_signal : std_logic;

begin

--AXI SIGNALS:-----------------------------------------------------------------------------
s_axis_tready <= '1';
en_axis_signal <= m_axis_tready and s_axis_tvalid;

VALID_DATA_REG: Shift_Reg
generic map (
   WIDTH        => 1,
   DELAY_CYCLES => DELAY*FILTER_ORDER
)
port map (
   clk    => clk,
   rst    => rst,
   en     => en_axis_signal,
   input  => (others => s_axis_tvalid),
   output => m_axis_tvalid_signal
);

m_axis_tvalid <= m_axis_tvalid_signal(0);

--MAC + REGISTER INSTANTIATION:-----------------------------------------------------------------------------
MAC_0: MAC_SelfPurging
generic map (
    MUL_WIDTH     => INPUT_WIDTH,
    ACC_WIDTH     => OUTPUT_WIDTH,
    REG_CONST     => coefficients(0),
    MAC_INSTANCES => numSelfPurgingMAC,
    NaN           => NaN
)
port map (
    clk       => clk,
    rst       => rst,
    en        => en_axis_signal,
    mul_input => s_axis_tdata,
    acc_input => (others => '0'),
    res       => MAC_output(0)
);

REG_0: Shift_Reg
generic map (
   WIDTH        => INPUT_WIDTH,
   DELAY_CYCLES => DELAY
)
port map (
   clk    => clk,
   rst    => rst,
   en     => en_axis_signal,
   input  => s_axis_tdata,
   output => mul_input(0)
);

gen_modules : for i in 1 to FILTER_ORDER-2 generate
  MAC_i : MAC_SelfPurging
    generic map (
        MUL_WIDTH     => INPUT_WIDTH,
        ACC_WIDTH     => OUTPUT_WIDTH,
        REG_CONST     => coefficients(i),
        MAC_INSTANCES => numSelfPurgingMAC,
        NaN           => NaN
    )
    port map (
        clk       => clk,
        rst       => rst,
        en        => en_axis_signal,
        mul_input => mul_input(i-1),
        acc_input => MAC_output(i-1),
        res       => MAC_output(i)
    );
    
  REG_i : Shift_Reg
    generic map (
       WIDTH        => INPUT_WIDTH,
       DELAY_CYCLES => DELAY
    )
    port map (
       clk    => clk,
       rst    => rst,
       en     => en_axis_signal,
       input  => mul_input(i-1),
       output => mul_input(i)
    );
end generate;

MAC_N: MAC_SelfPurging
generic map (
    MUL_WIDTH => INPUT_WIDTH,
    ACC_WIDTH => OUTPUT_WIDTH,
    REG_CONST => coefficients(FILTER_ORDER-1),
    MAC_INSTANCES => numSelfPurgingMAC,
    NaN => NaN
)
port map (
    clk       => clk,
    rst       => rst,
    en        => en_axis_signal,
    mul_input => mul_input(FILTER_ORDER-2),
    acc_input => MAC_output(FILTER_ORDER-2),
    res       => m_axis_tdata
);

end Behavioral;
