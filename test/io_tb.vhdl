library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

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

        if run("all") then
            -- reset at the beginning
            rst      <= '1';
            in_data  <= (others => 'Z');
            cpu_data <= (others => 'Z');
            wait for CLK_PERD;
            wait for 1 ps; -- shift checks 1 ps for combinational circuits to calculate their output
            check_equal(interrupt, '0', "error in resetting, interrupt, interrupt");
            check_equal(error_success, '1', "error in resetting, error_success");

            -- test loading
            in_state <= "00";
            rst      <= '0';

            cpu_data <= "0110" & "0011" & "0100" & "1001" & "0000" & "0001" & "0000" & "0001";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= "00001100011111010100011001111001", "data has been written - test1 failed, in_data");
            check_equal(interrupt, '0', "data has been written - test1 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"FFFF", adr'length), "data has been written - test1 failed, adr");

            cpu_data <= "0100" & "0011" & "0010" & "0111" & "0010" & "0001" & "0001" & "0010";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= "00001100011111010100011001111001", "data has been written - test2 failed, in_data");
            check_equal(interrupt, '0', "data has been written - test2 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"FFFF", adr'length), "data has been written - test2 failed, adr");

            cpu_data <= "0111" & "0010" & "0011" & "0100" & "0001" & "0000" & "0001" & "0000";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(in_data, to_vec("00001100011111010100011001111001", in_data'length), "data hasn't been written - test3 failed, in_data");
            check_equal(interrupt, '0', "data hasn't been written - test3 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"0000", adr'length), "data hasn't been written - test3 failed, adr");

            cpu_data <= "1001" & "0100" & "0011" & "0110" & "0110" & "0011" & "0100" & "1001";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= "10011110011000101011111000110000", "data has been written - test4 failed, in_data");
            check_equal(interrupt, '0', "data has been written - test4 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"0000", adr'length), "data has been written - test4 failed, adr");

            cpu_data <= "0000" & "0001" & "0000" & "0001" & "0100" & "0011" & "0010" & "0111";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(in_data, to_vec("10011110011000101011111000110000", in_data'length), "data hasn't been written - test5 failed");
            check_equal(interrupt, '0', "data hasn't been written - test5 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"0001", adr'length), "data hasn't been written - test5 failed, adr");

            cpu_data <= "0010" & "0001" & "0001" & "0010" & "0111" & "0010" & "0011" & "0100";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= "00001100011111010100011001111001", "data has been written - test6 failed, in_data");
            check_equal(interrupt, '0', "data has been written - test6 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"0001", adr'length), "data has been written - test6 failed, adr");

            cpu_data <= "0001" & "0000" & "0001" & "0000" & "1001" & "0100" & "0011" & "0110";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(in_data, to_vec("00001100011111010100011001111001", in_data'length), "data hasn't been written - test7 failed");
            check_equal(interrupt, '0', "data hasn't been written - test7 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"0003", adr'length), "data hasn't been written - test7 failed, adr");

            -- WAIT 
            in_state <= "01";
            wait for CLK_PERD;
            check_equal(in_data, to_vec("10011110011000101011111000110000", in_data'length), "data hasn't been written - test8 failed");
            check_equal(interrupt, '0', "data hasn't been written - test8 failed, interrupt, interrupt");
            check_equal(adr, to_vec(x"0005", adr'length), "data hasn't been written - test8 failed, adr");

            -- OUT 
            in_state <= "11";
            in_data  <= x"FFFFFFFF";
            cpu_data <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(cpu_data, to_vec(x"FFFFFFFF", cpu_data'length), "didn't out the data - test9 failed, cpu_data");
            check_equal(interrupt, '0', "didn't out the data - test9 failed, interrupt, interrupt");
            check_equal(error_success, '1', "didn't out the data - test9 failed, error_success");
        end if;

        wait for CLK_PERD;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;