library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity IO_tb is
end entity;

architecture arch of IO_tb is 

component io is
    port (
        in_state      : in std_logic_vector(1 downto 0);
        clk           : in std_logic;
        rst           : in std_logic;

        cpu_data      : inout std_logic_vector(31 downto 0);
        in_data       : inout std_logic_vector(31 downto 0);

        adr           : out std_logic_vector(15 downto 0);
        interrupt     : out std_logic;
        error_success : out std_logic
    );
end component;

signal in_state							: std_logic_vector(1 downto 0);
signal in_data , cpu_data           	: std_logic_vector(31 downto 0);
signal adr                          	: std_logic_vector(15 downto 0);
signal interrupt , error_success , rst	: std_logic;
signal clk 								: std_logic := '1';

constant CLKPERIOD : time := 100 ps;
begin
	IO_TEST : io port map(
            in_state      => in_state,
            clk           => clk,
            rst           => rst,
			cpu_data      => cpu_data,
            in_data       => in_data,
			adr			  => adr,
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
		rst <= '1';
		wait for CLKPERIOD;
		assert(interrupt = '0' and error_success = '1' and adr = x"FFFF") report "error in resetting" severity error;
		-- test loading
		rst <= '0';
		in_state <= "00";
		
		cpu_data <= x"63490101";
		wait for CLKPERIOD;
		assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF") report "data has been written - test1 failed" severity error;
		cpu_data <= x"43272112";
		wait for CLKPERIOD;
		assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF") report "data has been written - test2 failed" severity error;
		cpu_data <= x"72341010";
		wait for CLKPERIOD;
		assert(in_data = x"0C7D4679" and interrupt = '0' and adr = x"0000") report "data hasn't been written - test3 failed" severity error;
		cpu_data <= x"94366349";
		wait for CLKPERIOD;
		assert(in_data /= x"9E62BE30" and interrupt = '0' and adr = x"0000") report "data has been written - test4 failed" severity error;
		cpu_data <= x"01014327";
		wait for CLKPERIOD;
		assert(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0001") report "data hasn't been written - test5 failed" severity error;
		cpu_data <= x"21127234";
		wait for CLKPERIOD;
		assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"0001") report "data has been written - test6 failed" severity error;
		cpu_data <= x"10109436";
		wait for CLKPERIOD;
		assert(in_data = x"0C7D4679" and interrupt = '0' and adr = x"0003") report "data hasn't been written - test7 failed" severity error;
		
		-- WAIT 
		in_state <= "01";
		wait for CLKPERIOD;
		assert(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0005") report "data hasn't been written - test8 failed" severity error;
		
		-- OUT 
		in_state <= "11";
		in_data <= x"FFFFFFFF";
		wait for CLKPERIOD;
		assert(cpu_data = x"FFFFFFFF" and interrupt = '0' and error_success = '1') report "didn't out the data - test9 failed" severity error;
	end process;
end arch;