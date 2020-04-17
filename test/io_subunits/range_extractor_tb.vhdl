library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity range_extractor_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of range_extractor_tb is
    constant CLK_FREQ            : integer   := 100e6; -- 100 MHz
    constant CLK_PERD            : time      := 1000 ms / CLK_FREQ;

    signal clk                   : std_logic := '0';

    signal in_a                  : std_logic_vector(6 downto 0);
    signal in_size               : std_logic_vector(2 downto 0);
    signal in_lastsize, out_size : std_logic_vector(6 downto 0);

    signal out_a, out_b          : std_logic_vector(6 downto 0);
begin
    clk <= not clk after CLK_PERD / 2;

    range_extractor : entity work.range_extractor
        port map(
            in_a        => in_a,
            in_size     => in_size,
            in_lastsize => in_lastsize,
            out_size    => out_size,
            out_a       => out_a,
            out_b       => out_b
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("basic") then
            in_lastsize <= to_vec(2, in_lastsize'length);
            in_a        <= to_vec(3, in_a'length);
            in_size     <= to_vec(6, in_size'length);
            wait for CLK_PERD;
            check_equal(out_a, to_vec(3 + 1, out_a'length));
            check_equal(out_b, to_vec(3 + 1 + 6, out_b'length));
            check_equal(out_size, to_vec(2 + 6 + 1, out_size'length));
        end if;

        if run("zero_edge") then
            in_lastsize <= to_vec(0, in_lastsize'length);
            in_a        <= to_vec(0, in_a'length);
            in_size     <= to_vec(0, in_size'length);
            wait for CLK_PERD;
            check_equal(out_a, to_vec(1, out_a'length));
            check_equal(out_b, to_vec(1, out_b'length));
            check_equal(out_size, to_vec(1, out_size'length));
        end if;

        if run("overflow") then
            in_lastsize <= to_vec(120, in_lastsize'length);
            in_a        <= to_vec(127, in_a'length);
            in_size     <= to_vec(7, in_size'length);
            wait for CLK_PERD;
            check_equal(out_a, to_vec(0, out_a'length));
            check_equal(out_b, to_vec(7, out_b'length));
            check_equal(out_size, to_vec(0, out_size'length));
        end if;

        if run("no_overflow") then
            in_lastsize <= to_vec(119, in_lastsize'length);
            in_a        <= to_vec(0, in_a'length);
            in_size     <= to_vec(7, in_size'length);
            wait for CLK_PERD;
            check_equal(out_a, to_vec(1, out_a'length));
            check_equal(out_b, to_vec(8, out_b'length));
            check_equal(out_size, to_vec(127, out_size'length));
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;