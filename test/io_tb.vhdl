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

        if run("simple") then
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

        if run("sample_f16") then
            -- reset at the beginning
            rst      <= '1';
            in_data  <= (others => 'Z');
            in_state <= "00";
            wait for CLK_PERD;
            wait for 1 ps;
            check_equal(interrupt, '0', "error in resetting");
            check_equal(error_success, '1', "error in resetting");

            -- test loading
            rst      <= '0';

            cpu_data <= x"63490101";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF", "data has been written - test1 failed");

            cpu_data <= x"43272112";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF", "data has been written - test2 failed");

            cpu_data <= x"72341010";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"0C7D4679" and interrupt = '0' and adr = x"0000", "data hasn't been written - test3 failed");

            cpu_data <= x"94366349";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"9E62BE30" and interrupt = '0' and adr = x"0000", "data has been written - test4 failed");

            cpu_data <= x"01014327";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0001", "data hasn't been written - test5 failed");

            cpu_data <= x"21127234";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"0001", "data has been written - test6 failed");

            cpu_data <= x"10109436";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(in_data, to_vec(x"0C7D4679", in_data'length), "data hasn't been written - test7 failed, in_data");
            check_equal(interrupt, '0', "data hasn't been written - test7 failed, interrupt");
            check_equal(adr, to_vec(x"0003", adr'length), "data hasn't been written - test7 failed, adr");

            cpu_data <= x"63610161";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0005", "data hasn't  been written - test8 failed");

            cpu_data <= x"EAEEE632";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"0C284000" and interrupt = '0' and adr = x"0005", "data has been written - test9 failed");

            cpu_data <= x"E6A36A10";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"0C284000" and interrupt = '0' and adr = x"0007", "data hasn't  been written - test10 failed");

            cpu_data <= x"653ED101";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"0000000C" and interrupt = '0' and adr = x"0009", "data hasn't  been written - test11 failed");

            cpu_data <= x"330EC841";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"00003002" and interrupt = '0' and adr = x"000B", "data hasn't  been written - test12 failed");

            cpu_data <= x"66FFFFAE";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"0F807FBE" and interrupt = '0' and adr = x"000D", "data hasn't  been written - test13 failed");

            cpu_data <= x"C1A61EEE";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"00000100" and interrupt = '0' and adr = x"000F", "data hasn't  been written - test14 failed");

            cpu_data <= x"83EEEA5E";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"FFFFFFFF" and interrupt = '0' and adr = x"0011", "data hasn't  been written - test15 failed");

            cpu_data <= x"EE61EEEC";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"00000400" and interrupt = '0' and adr = x"0013", "data hasn't  been written - test16 failed");

            cpu_data <= x"121EEEE4";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"80000003" and interrupt = '0' and adr = x"0015", "data hasn't  been written - test17 failed");

            cpu_data <= x"3EEE0101";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"0C000001" and interrupt = '0' and adr = x"0015", "data has been written - test18 failed");

            cpu_data <= x"EEE83EEE";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"0C000001" and interrupt = '0' and adr = x"138D", "data hasn't  been written - test19 failed");

            cpu_data <= x"81EEEC10";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"40000001" and interrupt = '0' and adr = x"138F", "data hasn't  been written - test20 failed");

            cpu_data <= x"1EEE83EE";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"80000002" and interrupt = '0' and adr = x"1391", "data hasn't  been written - test21 failed");

            cpu_data <= x"EE63EEE0";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"00000002" and interrupt = '0' and adr = x"1393", "data hasn't  been written - test22 failed");

            cpu_data <= x"1EEEA121";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"80000003" and interrupt = '0' and adr = x"1395", "data hasn't  been written - test23 failed");

            cpu_data <= x"EEE83012";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"00000000" and interrupt = '0' and adr = x"1397", "data hasn't  been written - test24 failed");

            cpu_data <= x"3EEE163E";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"0C000001" and interrupt = '0' and adr = x"1399", "data hasn't  been written - test25 failed");

            cpu_data <= x"EE21EEEA";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"00000002" and interrupt = '0' and adr = x"139B", "data hasn't  been written - test26 failed");

            cpu_data <= x"1EEEC121";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"40000001" and interrupt = '0' and adr = x"139D", "data hasn't  been written - test27 failed");

            cpu_data <= x"23EEC323";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data /= x"26000003" and interrupt = '0' and adr = x"139D", "data has been written - test28 failed");

            cpu_data <= x"23EEC301";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"26000003" and interrupt = '0' and adr = x"139F", "data hasn't  been written - test29 failed");

            cpu_data <= x"23EEA12F";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check(in_data = x"33000001" and interrupt = '0' and adr = x"13A1", "data hasn't  been written - test30 failed");

            -- WAIT 
            in_state <= "01";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(in_data, to_vec(x"A6000004", in_data'length), "data hasn't been written - test31 failed, in_data");
            check_equal(interrupt, '0', "data hasn't been written - test31 failed, interrupt");
            check_equal(adr, to_vec(x"13A3", adr'length), "data hasn't been written - test31 failed, adr");

            in_state <= "01";
            in_data  <= (others => 'Z');
            wait for CLK_PERD;
            check_equal(in_data, to_vec(x"A6000004", in_data'length), "data hasn't been written - test32 failed, in_data");
            check_equal(interrupt, '1', "data hasn't been written - test32 failed, interrupt");
            check_equal(adr, to_vec(x"13A3", adr'length), "data hasn't been written - test32 failed, adr");

            -- OUT 
            in_state <= "11";
            in_data  <= x"FFFFFFFF";
            cpu_data <= (others => 'Z');
            wait for CLK_PERD;
            check(cpu_data = x"FFFFFFFF" and interrupt = '0' and error_success = '1', "didn't out the data - test33 failed");
        end if;

        wait for CLK_PERD;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;