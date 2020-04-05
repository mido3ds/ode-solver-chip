library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity fpu_multiplier_tb is
    generic (runner_cfg: string);
end entity; 

architecture tb of fpu_multiplier_tb is
    constant CLK_FREQ: integer := 100e6; -- 100 MHz
    constant CLK_PERD: time    := 1000 ms / CLK_FREQ;

    signal clk: std_logic := '0';
    signal operation: std_logic_vector(1 downto 0);
    signal rst: std_logic;
    signal enbl: std_logic;
    signal in_a: std_logic_vector(63 downto 0);
    signal in_b: std_logic_vector(63 downto 0);

    signal out_c: std_logic_vector(63 downto 0);
    signal done: std_logic;
    signal err: std_logic;
    signal zero: std_logic;
    signal posv: std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    fpu_multiplier: entity work.fpu_multiplier port map (
        clk => clk, 
        operation => operation, 
        rst => rst, 
        enbl => enbl, 
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => err, 
        zero => zero, 
        posv => posv
    );

    main: process
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
