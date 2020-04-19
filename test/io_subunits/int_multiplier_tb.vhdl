library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity int_multiplier_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of int_multiplier_tb is
    constant CLK_FREQ : integer   := 100e6; -- 100 MHz
    constant CLK_PERD : time      := 1000 ms / CLK_FREQ;

    signal clk        : std_logic := '0';

    constant N        : integer   := 7;
    constant M        : integer   := 3;
    signal a          : std_logic_vector(N - 1 downto 0);
    signal b          : std_logic_vector(M - 1 downto 0);
    signal c          : std_logic_vector(N - 1 downto 0);
    signal enbl       : std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    int_multiplier : entity work.int_multiplier
        generic map(N => N, M => M)
        port map(
            a    => a,
            b    => b,
            enbl => enbl,
            c    => c
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        enbl <= '1';

        if run("basic") then
            a <= to_vec(30, a'length);
            b <= to_vec(3, b'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(90, c'length));
        end if;

        if run("overflow") then
            a <= to_vec(64, a'length);
            b <= to_vec(2, b'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(0, c'length));
        end if;

        if run("overflow2") then
            a <= to_vec(127, a'length);
            b <= to_vec(2, b'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(126, c'length));
        end if;

        if run("zero") then
            a <= to_vec(0, a'length);
            b <= to_vec(0, b'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(0, c'length));
        end if;

        if run("one") then
            a <= to_vec(1, a'length);
            b <= to_vec(1, b'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(1, c'length));
        end if;

        if run("enbl") then
            a <= to_vec(30, a'length);
            b <= to_vec(3, b'length);
            wait for CLK_PERD;
            check_equal(c, to_vec(90, c'length));

            enbl <= '0';
            a    <= to_vec(0, a'length);
            b    <= to_vec(10, b'length);
            check_equal(c, to_vec(90, c'length));
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;