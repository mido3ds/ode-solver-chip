library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity io_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of io_tb is
    constant CLK_FREQ    : integer   := 100e6; -- 100 MHz
    constant CLK_PERD    : time      := 1000 ms / CLK_FREQ;

    signal clk           : std_logic := '0';

    signal in_state      : std_logic_vector(1 downto 0);
    signal rst           : std_logic;

    signal cpu_data      : std_logic_vector(31 downto 0);
    signal in_data       : std_logic_vector(31 downto 0);

    signal adr           : std_logic_vector(15 downto 0);
    signal interrupt     : std_logic;
    signal error_success : std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    io : entity work.io
        port map(
            in_state      => in_state,
            clk           => clk,
            rst           => rst,
            cpu_data      => cpu_data,
            in_data       => in_data,
            adr           => adr,
            interrupt     => interrupt,
            error_success => error_success
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        rst <= '1';
        wait for 1 ps;
        rst <= '0';

        if run("name_this_test_case") then
            wait for CLK_PERD;
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;