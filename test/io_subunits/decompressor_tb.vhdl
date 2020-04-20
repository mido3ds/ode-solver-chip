library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity decompressor_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of decompressor_tb is
    constant CLK_FREQ : integer   := 100e6; -- 100 MHz
    constant CLK_PERD : time      := 1000 ms / CLK_FREQ;

    signal clk        : std_logic := '0';

    signal in_data    : std_logic_vector(31 downto 0);
    signal rst        : std_logic;
    signal enbl_in    : std_logic;

    signal out_data   : std_logic_vector(31 downto 0);
    signal buf        : std_logic_vector(128 - 1 downto 0);
    signal out_ready  : std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    decompressor : entity work.decompressor
        port map(
            in_data   => in_data,
            rst       => rst,
            enbl_in   => enbl_in,
            clk       => clk,
            out_data  => out_data,
            buf_test   => buf,
            out_ready => out_ready
        );

    main : process
        function packet(n, b : integer) return std_logic_vector is
        begin
            return to_vec(n - 1, 3) & to_std_logic(b);
        end function;

        procedure fill_64bit(b : integer) is
        begin
            in_data <= packet(8, b) & packet(8, b) & packet(8, b) & packet(8, b) &
                packet(8, b) & packet(8, b) & packet(8, b) & packet(8, b);
        end procedure;

        procedure fill_32bit(b : integer) is
        begin
            in_data <= packet(4, b) & packet(4, b) & packet(4, b) & packet(4, b) &
                packet(4, b) & packet(4, b) & packet(4, b) & packet(4, b);
        end procedure;

        procedure fill_24bit_arbitrary is
        begin
            in_data <= packet(3, 1) & packet(1, 0) & packet(8, 1) & packet(1, 1) &
                packet(2, 0) & packet(1, 1) & packet(6, 1) & packet(2, 0);
        end procedure;
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        rst <= '1';
        wait for 1 ps;
        enbl_in <= '1';
        rst     <= '0';

        if run("enbl_in") then
            fill_64bit(0);

            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now");

            wait until falling_edge(clk);
            check_equal(out_ready, '0', "should receive no more data");
        end if;

        if run("basic_buf_fill") then
            fill_24bit_arbitrary;
            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(flip(buf(23 downto 0)), to_vec("111011111111100111111100", 24), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");
        end if;

        if run("basic_buf_fill_repeated") then
            fill_24bit_arbitrary;
            wait until falling_edge(clk);
            check_equal(flip(buf(23 downto 0)), to_vec("111011111111100111111100", 24), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            wait until falling_edge(clk);
            check_equal(flip(buf(23 + 24 downto 0)), to_vec("111011111111100111111100" & "111011111111100111111100", 24 + 24), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(flip(buf(23 + 24 + 24 downto 0)), to_vec("111011111111100111111100" & "111011111111100111111100" & "111011111111100111111100", 24 + 24 + 24), "buffer");
            check_equal(out_ready, '1', "out_ready");
            check_equal(out_data, to_vec("11101111111110011111110011101111", 32), "out_data");
        end if;

        if run("fill_buf_64bits") then
            fill_64bit(0);
            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(flip(buf(63 downto 0)), to_vec('0', 64), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now");
            check_equal(out_data, to_vec('0', 32), "out_data");
        end if;

        if run("fill_buf_96bits") then
            -- [0]
            fill_64bit(0);
            wait until falling_edge(clk);
            check_equal(flip(buf(63 downto 0)), to_vec('0', 64), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            -- [1]
            fill_32bit(1);
            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(flip(buf(96 - 1 downto 0)), to_vec('0', 64) & to_vec('1', 32), "buffer");
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [0]
            check_equal(out_data, to_vec('0', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [0]
            check_equal(out_data, to_vec('0', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [1]
            check_equal(out_data, to_vec('1', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");
        end if;

        if run("fill_buf_all") then
            --[0]
            fill_64bit(0);
            wait until falling_edge(clk);
            check_equal(flip(buf(63 downto 0)), to_vec('0', 64), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            --[1]
            fill_32bit(1);
            wait until falling_edge(clk);
            check_equal(flip(buf(96 - 1 downto 0)), to_vec('0', 64) & to_vec('1', 32), "buffer");
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [0]
            check_equal(out_data, to_vec('0', 32), "out_data");

            --[2]
            fill_32bit(0);
            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(flip(buf(128 - 1 downto 0)), to_vec('0', 64) & to_vec('1', 32) & to_vec('0', 32), "buffer");
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [0]
            check_equal(out_data, to_vec('0', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [1]
            check_equal(out_data, to_vec('1', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [2]
            check_equal(out_data, to_vec('0', 32), "out_data");

            wait until falling_edge(clk);
            wait until falling_edge(clk);
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");
        end if;

        if run("fill_buf_wrap") then
            -- [0]
            fill_64bit(0);
            wait until falling_edge(clk);
            check_equal(flip(buf(63 downto 0)), to_vec('0', 64), "buffer");
            check_equal(out_ready, '0', "out_ready shouldn't be ready now");

            -- [1]
            fill_32bit(1);
            wait until falling_edge(clk);
            check_equal(flip(buf(96 - 1 downto 0)), to_vec('0', 64) & to_vec('1', 32), "buffer");
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [0]
            check_equal(out_data, to_vec('0', 32), "out_data");

            -- [2]
            fill_32bit(0);
            wait until falling_edge(clk);
            check_equal(flip(buf(128 - 1 downto 0)), to_vec('0', 64) & to_vec('1', 32) & to_vec('0', 32), "buffer");
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [0]
            check_equal(out_data, to_vec('0', 32), "out_data");

            -- [3]
            fill_24bit_arbitrary;
            wait until falling_edge(clk);
            enbl_in <= '0';
            check_equal(flip(buf), to_vec("111011111111100111111100", 24) & to_vec('0', 64 - 24) & to_vec('1', 32) & to_vec('0', 32), "buffer");
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [1]
            check_equal(out_data, to_vec('1', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '1', "out_ready should be ready now"); -- [2]
            check_equal(out_data, to_vec('0', 32), "out_data");

            wait until falling_edge(clk);
            check_equal(out_ready, '0', "out_ready shouldn't be ready now"); -- [4]
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;