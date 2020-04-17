library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity range_extractor_cascade_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of range_extractor_cascade_tb is
    constant CLK_FREQ : integer   := 100e6; -- 100 MHz
    constant CLK_PERD : time      := 1000 ms / CLK_FREQ;

    signal clk        : std_logic := '0';

    type array_3s is array(0 to 7) of std_logic_vector(2 downto 0);
    type array_7s is array(0 to 7) of std_logic_vector(6 downto 0);

    signal first_a, first_size       : std_logic_vector(6 downto 0);

    signal in_sizes                  : array_3s;
    signal out_bs, out_as, out_sizes : array_7s;
begin
    clk <= not clk after CLK_PERD / 2;

    range_extr_0 : entity work.range_extractor
        port map(
            in_a        => first_a,
            in_size     => in_sizes(0),
            in_lastsize => first_size,
            out_size    => out_sizes(0),
            out_a       => out_as(0),
            out_b       => out_bs(0)
        );

    ranges : for i in 1 to 7 generate
        range_extr_i : entity work.range_extractor
            port map(
                in_a        => out_bs(i - 1),
                in_lastsize => out_sizes(i - 1),
                in_size     => in_sizes(i),
                out_size    => out_sizes(i),
                out_a       => out_as(i),
                out_b       => out_bs(i)
            );
    end generate;

    main : process
        procedure test is
        begin
            check_equal(out_as(0), to_vec(to_int(first_a) + 1, out_as(0)'length), "out_as at i=0");
            check_equal(out_bs(0), to_vec(to_int(first_a) + 1 + to_int(in_sizes(0)), out_bs(0)'length), "out_bs at i=0");
            check_equal(out_sizes(0), to_vec(to_int(first_size) + to_int(in_sizes(0)) + 1, out_sizes(0)'length), "out_sizes at i=0");

            for i in 1 to out_as'length - 1 loop
                check_equal(out_as(i), to_vec(to_int(out_bs(i - 1)) + 1, out_as(i)'length), "out_as at i=" & to_str(i));
                check_equal(out_bs(i), to_vec(to_int(out_bs(i - 1)) + 1 + to_int(in_sizes(i)), out_bs(i)'length), "out_bs at i=" & to_str(i));
                check_equal(out_sizes(i), to_vec(to_int(out_sizes(i - 1)) + to_int(in_sizes(i)) + 1, out_sizes(i)'length), "out_sizes at i=" & to_str(i));
            end loop;
        end procedure;

        procedure print_debug is
        begin
            for i in out_as'range loop
                info(
                "i=" & to_str(i)
                & ", " &
                "in_sizes=" & to_str(to_int(in_sizes(i)))
                & ", " &
                "out_as=" & to_str(to_int(out_as(i)))
                & ", " &
                "out_bs=" & to_str(to_int(out_bs(i)))
                & ", " &
                "out_sizes=" & to_str(to_int(out_sizes(i)))
                );
            end loop;
        end procedure;
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("all_zero") then
            -- fill all in_sizes with 1
            for i in in_sizes'range loop
                in_sizes(i) <= (others => '0');
            end loop;
            first_a    <= (others => '1');
            first_size <= (others => '0');

            wait for CLK_PERD;

            test;
        end if;

        if run("all_one") then
            -- fill all in_sizes with 1
            for i in in_sizes'range loop
                in_sizes(i) <= (others => '1');
            end loop;
            first_a    <= (others => '1');
            first_size <= (others => '0');

            wait for CLK_PERD;

            test;
        end if;

        if run("incremental") then
            -- fill all in_sizes with 1
            for i in in_sizes'range loop
                in_sizes(i) <= to_vec(i, in_sizes(i)'length);
            end loop;
            first_a    <= (others => '1');
            first_size <= (others => '0');

            wait for CLK_PERD;

            test;
        end if;

        if run("overflow") then
            -- fill all in_sizes with 1
            for i in in_sizes'range loop
                in_sizes(i) <= to_vec(-1, in_sizes(i)'length);
            end loop;
            first_a    <= (others => '1');
            first_size <= (others => '0');

            wait for CLK_PERD;

            test;
        end if;

        if run("start_zero_inc") then
            -- fill all in_sizes with 1
            for i in in_sizes'range loop
                in_sizes(i) <= to_vec(i, in_sizes(i)'length);
            end loop;
            first_a    <= (others => '0');
            first_size <= (others => '0');

            wait for CLK_PERD;

            test;
        end if;

        if run("start_one_inc") then
            -- fill all in_sizes with 1
            for i in in_sizes'range loop
                in_sizes(i) <= to_vec(i, in_sizes(i)'length);
            end loop;
            first_a    <= to_vec(1, first_a'length);
            first_size <= (others => '0');

            wait for CLK_PERD;

            test;
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;