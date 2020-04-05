library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity main_tb is
    generic (runner_cfg: string);
end entity; 

architecture tb of main_tb is
    constant CLK_FREQ: integer := 100e6; -- 100 MHz
    constant CLK_PERD: time    := 1000 ms / CLK_FREQ;

    signal clk: std_logic := '0';

    signal in_state: std_logic_vector(1 downto 0);
    signal rst: std_logic := '0';

    signal cpu_data: std_logic_vector(31 downto 0);
    
    signal interrupt: std_logic;
    signal error_success: std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    main: entity work.main port map (
        clk => clk, 
        in_state => in_state,
        rst => rst, 
        cpu_data => cpu_data, 
        interrupt => interrupt, 
        error_success => error_success
    );

    process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("test_case_name") then
            -- TODO
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;
