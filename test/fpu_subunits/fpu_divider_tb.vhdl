library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity fpu_divider_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of fpu_divider_tb is
    constant CLK_FREQ : integer   := 100e6; -- 100 MHz
    constant CLK_PERD : time      := 1000 ms / CLK_FREQ;

    signal clk        : std_logic := '0';
    signal mode       : std_logic_vector(1 downto 0);
    signal rst        : std_logic;
    signal enbl       : std_logic;
    signal in_a       : std_logic_vector(63 downto 0);
    signal in_b       : std_logic_vector(63 downto 0);

    -- outputs for fpu_divider_with_operators instance
    signal wo_out_c   : std_logic_vector(63 downto 0);
    signal wo_done    : std_logic;
    signal wo_err     : std_logic;
    signal wo_zero    : std_logic;
    signal wo_posv    : std_logic;

    -- outputs for fpu_divider_first_algo instance
    signal fa_out_c   : std_logic_vector(63 downto 0);
    signal fa_done    : std_logic;
    signal fa_err     : std_logic;
    signal fa_zero    : std_logic;
    signal fa_posv    : std_logic;

    -- outputs for fpu_divider_sec_algo instance
    signal sa_out_c   : std_logic_vector(63 downto 0);
    signal sa_done    : std_logic;
    signal sa_err     : std_logic;
    signal sa_zero    : std_logic;
    signal sa_posv    : std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    fpu_divider_with_operators : entity work.fpu_divider(with_operators)
        port map(
            clk   => clk,
            mode  => mode,
            rst   => rst,
            enbl  => enbl,
            in_a  => in_a,
            in_b  => in_b,
            out_c => wo_out_c,
            done  => wo_done,
            err   => wo_err,
            zero  => wo_zero,
            posv  => wo_posv
        );

    fpu_divider_first_algo : entity work.fpu_divider(first_algo)
        port map(
            clk   => clk,
            mode  => mode,
            rst   => rst,
            enbl  => enbl,
            in_a  => in_a,
            in_b  => in_b,
            out_c => fa_out_c,
            done  => fa_done,
            err   => fa_err,
            zero  => fa_zero,
            posv  => fa_posv
        );

    fpu_divider_sec_algo : entity work.fpu_divider(sec_algo)
        port map(
            clk   => clk,
            mode  => mode,
            rst   => rst,
            enbl  => enbl,
            in_a  => in_a,
            in_b  => in_b,
            out_c => sa_out_c,
            done  => sa_done,
            err   => sa_err,
            zero  => sa_zero,
            posv  => sa_posv
        );

    main : process
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