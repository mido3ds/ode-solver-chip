library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity io_tb2 is
end entity;

architecture tb of io_tb2 is
	signal in_state                      : std_logic_vector(1 downto 0);
	signal in_data, cpu_data             : std_logic_vector(31 downto 0);
	signal adr                           : std_logic_vector(15 downto 0);
	signal interrupt, error_success, rst : std_logic;
	signal clk                           : std_logic := '1';

	constant CLKPERIOD                   : time      := 100 ps;
begin
	IO_TEST : entity work.io port map(
		in_state      => in_state,
		clk           => clk,
		rst           => rst,
		cpu_data      => cpu_data,
		in_data       => in_data,
		adr           => adr,
		interrupt     => interrupt,
		error_success => error_success
		);

	process
	begin
		clk <= not clk;
		wait for CLKPERIOD/2;
	end process;

	process
	begin
		-- reset at the beginning
		rst      <= '1';
		in_data  <= (others => 'Z');
		in_state <= "00";
		wait for CLKPERIOD;
		wait for 1 ps;
		assert(interrupt = '0') report "error in resetting";
		assert(error_success = '1') report "error in resetting";

		-- test loading
		rst      <= '0';

		cpu_data <= x"63490101";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF") report "data has been written - test1 failed";

		cpu_data <= x"43272112";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF") report "data has been written - test2 failed";

		cpu_data <= x"72341010";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0C7D4679" and interrupt = '0' and adr = x"0000") report "data hasn't been written - test3 failed";

		cpu_data <= x"94366349";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"9E62BE30" and interrupt = '0' and adr = x"0000") report "data has been written - test4 failed";

		cpu_data <= x"01014327";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0001") report "data hasn't been written - test5 failed";

		cpu_data <= x"21127234";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"0001") report "data has been written - test6 failed";

		cpu_data <= x"10109436";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0C7D4679") report "data hasn't been written - test7 failed, in_data";
		assert(interrupt = '0') report "data hasn't been written - test7 failed, interrupt";
		assert(adr = x"0003") report "data hasn't been written - test7 failed, adr";

		cpu_data <= x"63610161";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0005") report "data hasn't  been written - test8 failed";

		cpu_data <= x"EAEEE632";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"0C284000" and interrupt = '0' and adr = x"0005") report "data has been written - test9 failed";

		cpu_data <= x"E6A36A10";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0C284000" and interrupt = '0' and adr = x"0007") report "data hasn't  been written - test10 failed";

		cpu_data <= x"653ED101";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0000000C" and interrupt = '0' and adr = x"0009") report "data hasn't  been written - test11 failed";

		cpu_data <= x"330EC841";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"00003002" and interrupt = '0' and adr = x"000B") report "data hasn't  been written - test12 failed";

		cpu_data <= x"66FFFFAE";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0F807FBE" and interrupt = '0' and adr = x"000D") report "data hasn't  been written - test13 failed";

		cpu_data <= x"C1A61EEE";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"00000100" and interrupt = '0' and adr = x"000F") report "data hasn't  been written - test14 failed";

		cpu_data <= x"83EEEA5E";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"FFFFFFFF" and interrupt = '0' and adr = x"0011") report "data hasn't  been written - test15 failed";

		cpu_data <= x"EE61EEEC";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"00000400" and interrupt = '0' and adr = x"0013") report "data hasn't  been written - test16 failed";

		cpu_data <= x"121EEEE4";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"80000003" and interrupt = '0' and adr = x"0015") report "data hasn't  been written - test17 failed";

		cpu_data <= x"3EEE0101";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"0C000001" and interrupt = '0' and adr = x"0015") report "data has been written - test18 failed";

		cpu_data <= x"EEE83EEE";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0C000001" and interrupt = '0' and adr = x"138D") report "data hasn't  been written - test19 failed";

		cpu_data <= x"81EEEC10";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"40000001" and interrupt = '0' and adr = x"138F") report "data hasn't  been written - test20 failed";

		cpu_data <= x"1EEE83EE";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"80000002" and interrupt = '0' and adr = x"1391") report "data hasn't  been written - test21 failed";

		cpu_data <= x"EE63EEE0";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"00000002" and interrupt = '0' and adr = x"1393") report "data hasn't  been written - test22 failed";

		cpu_data <= x"1EEEA121";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"80000003" and interrupt = '0' and adr = x"1395") report "data hasn't  been written - test23 failed";

		cpu_data <= x"EEE83012";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"00000000" and interrupt = '0' and adr = x"1397") report "data hasn't  been written - test24 failed";

		cpu_data <= x"3EEE163E";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"0C000001" and interrupt = '0' and adr = x"1399") report "data hasn't  been written - test25 failed";

		cpu_data <= x"EE21EEEA";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"00000002" and interrupt = '0' and adr = x"139B") report "data hasn't  been written - test26 failed";

		cpu_data <= x"1EEEC121";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"40000001" and interrupt = '0' and adr = x"139D") report "data hasn't  been written - test27 failed";

		cpu_data <= x"23EEC323";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data /= x"26000003" and interrupt = '0' and adr = x"139D") report "data has been written - test28 failed";

		cpu_data <= x"23EEC301";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"26000003" and interrupt = '0' and adr = x"139F") report "data hasn't  been written - test29 failed";

		cpu_data <= x"23EEA12F";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"33000001" and interrupt = '0' and adr = x"13A1") report "data hasn't  been written - test30 failed";

		-- WAIT 
		in_state <= "01";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"A6000004") report "data hasn't been written - test31 failed, in_data";
		assert(interrupt = '0') report "data hasn't been written - test31 failed, interrupt";
		assert(adr = x"13A3") report "data hasn't been written - test31 failed, adr";

		in_state <= "01";
		in_data  <= (others => 'Z');
		wait for CLKPERIOD;
		assert(in_data = x"A6000004") report "data hasn't been written - test32 failed, in_data";
		assert(interrupt = '1') report "data hasn't been written - test32 failed, interrupt";
		assert(adr = x"13A3") report "data hasn't been written - test32 failed, adr";

		-- OUT 
		in_state <= "11";
		in_data  <= x"FFFFFFFF";
		cpu_data <= (others => 'Z');
		wait for CLKPERIOD;
		assert(cpu_data = x"FFFFFFFF" and interrupt = '0' and error_success = '1') report "didn't out the data - test33 failed";

		wait;
	end process;
end architecture;