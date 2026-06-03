library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_FIR is
end entity;

architecture sim of tb_FIR is

-- DUT generics
constant INPUT_WIDTH  : natural := 16;
constant OUTPUT_WIDTH : natural := 16;
constant FILTER_ORDER : natural := 3;

-- Clock period
constant CLK_PERIOD : time := 10 ns;

-- DUT signals
signal clk : std_logic := '0';
signal rst : std_logic := '1';

signal s_axis_tdata  : std_logic_vector(INPUT_WIDTH - 1 downto 0) := (others => '0');
signal s_axis_tvalid : std_logic := '0';
signal s_axis_tlast  : std_logic := '0';
signal s_axis_tready : std_logic;

signal m_axis_tdata  : std_logic_vector(OUTPUT_WIDTH - 1 downto 0);
signal m_axis_tvalid : std_logic;
signal m_axis_tlast  : std_logic;
signal m_axis_tready : std_logic := '1';

begin

-- DUT:------------------------------------------------------------------
uut : entity work.FIR
    generic map (
        INPUT_WIDTH  => INPUT_WIDTH,
        OUTPUT_WIDTH => OUTPUT_WIDTH,
        FILTER_ORDER => FILTER_ORDER
    )
    port map (
        clk => clk,
        rst => rst,

        s_axis_tdata  => s_axis_tdata,
        s_axis_tvalid => s_axis_tvalid,
        s_axis_tlast  => s_axis_tlast,
        s_axis_tready => s_axis_tready,

        m_axis_tdata  => m_axis_tdata,
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tlast  => m_axis_tlast,
        m_axis_tready => m_axis_tready
    );

-- CLOCK GENERATION:------------------------------------------------------------------
clk_gen : process
begin
    clk <= '0', '1' after CLK_PERIOD / 2;
    wait for CLK_PERIOD;
end process;

-- RESET PROCESS:------------------------------------------------------------------
rst_process : process
begin
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';
    wait;
end process;

-- STIMULUS PROCESS:------------------------------------------------------------------
stim_process : process
    variable sample : integer := 0;
begin
    wait until rst = '0';
    wait until rising_edge(clk);

    for i in 0 to 20 loop

        -- Apply data
        s_axis_tdata <= std_logic_vector(to_signed(sample, INPUT_WIDTH));
        s_axis_tvalid <= '1';
        
            if i = 20 then
                s_axis_tlast <= '1';
            else
                s_axis_tlast <= '0';
            end if;

        -- Wait handshake
        loop
            wait until rising_edge(clk);
            exit when s_axis_tready = '1';
        end loop;

        sample := sample + 1;

        -- optional gap between transfers
--        if i mod 3 = 0 then
--            s_axis_tvalid <= '0';
--            wait for CLK_PERIOD;
--        end if;

    end loop;

    -- stop sending
    s_axis_tvalid <= '0';
    s_axis_tlast  <= '0';

    wait;
end process;

end architecture;