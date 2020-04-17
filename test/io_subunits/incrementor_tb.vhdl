library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity incrementor_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of incrementor_tb is
    constant CLK_FREQ : integer   := 100e6; -- 100 MHz
    constant CLK_PERD : time      := 1000 ms / CLK_FREQ;

    signal clk        : std_logic := '0';

    signal a          : std_logic_vector(6 downto 0);
    signal c          : std_logic_vector(6 downto 0);
begin
    clk <= not clk after CLK_PERD / 2;

    incrementor : entity work.incrementor
        generic map(N => 7)
        port map(
            a => a,
            c => c
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("basic") then
            a <= to_vec(30, a'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(31, c'length));
        end if;

        if run("overflow") then
            a <= to_vec(127, a'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(0, c'length));
        end if;

        if run("zero") then
            a <= to_vec(0, a'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(1, c'length));
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;