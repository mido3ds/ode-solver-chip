library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity next_adr_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of next_adr_tb is
    constant CLK_FREQ    : integer   := 100e6; -- 100 MHz
    constant CLK_PERD    : time      := 1000 ms / CLK_FREQ;

    signal clk           : std_logic := '0';

    signal in_data       : std_logic_vector(31 downto 0);
    signal in_ready, rst : std_logic;
    signal out_adr       : std_logic_vector(15 downto 0);
begin
    clk <= not clk after CLK_PERD / 2;

    nau : entity work.next_adr
        port map(
            in_data  => in_data,
            in_ready => in_ready,
            clk      => clk,
            rst      => rst,
            out_adr  => out_adr
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("test_case_name") then
            -- TODO
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;