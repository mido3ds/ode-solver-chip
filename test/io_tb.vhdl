library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
            rst <= '1';
            in_data <= (others => 'Z');
            cpu_data <= (others => 'Z');
            wait for CLK_PERD;
            assert(interrupt = '0' and error_success = '1') report "error in resetting" severity error;
            -- test loading
            in_state <= "00";
            rst      <= '0';

            cpu_data <= x"63490101";
            wait for CLK_PERD;
            assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF") report "data has been written - test1 failed" severity error;
            cpu_data <= x"43272112";
            wait for CLK_PERD;
            assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"FFFF") report "data has been written - test2 failed" severity error;
            cpu_data <= x"72341010";
            wait for CLK_PERD;
            assert(in_data = x"0C7D4679" and interrupt = '0' and adr = x"0000") report "data hasn't been written - test3 failed" severity error;
            cpu_data <= x"94366349";
            wait for CLK_PERD;
            assert(in_data /= x"9E62BE30" and interrupt = '0' and adr = x"0000") report "data has been written - test4 failed" severity error;
            cpu_data <= x"01014327";
            wait for CLK_PERD;
            assert(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0001") report "data hasn't been written - test5 failed" severity error;
            cpu_data <= x"21127234";
            wait for CLK_PERD;
            assert(in_data /= x"0C7D4679" and interrupt = '0' and adr = x"0001") report "data has been written - test6 failed" severity error;
            cpu_data <= x"10109436";
            wait for CLK_PERD;
            assert(in_data = x"0C7D4679" and interrupt = '0' and adr = x"0003") report "data hasn't been written - test7 failed" severity error;

            -- WAIT 
            in_state <= "01";
            wait for CLK_PERD;
            assert(in_data = x"9E62BE30" and interrupt = '0' and adr = x"0005") report "data hasn't been written - test8 failed" severity error;

            -- OUT 
            in_state <= "11";
            in_data  <= x"FFFFFFFF";
            wait for CLK_PERD;
            assert(cpu_data = x"FFFFFFFF" and interrupt = '0' and error_success = '1') report "didn't out the data - test9 failed" severity error;
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;