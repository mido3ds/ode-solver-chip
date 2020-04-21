library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity fpu_adder_cla_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of fpu_adder_cla_tb is
    constant CLK_FREQ     : integer   := 100e6; -- 100 MHz
    constant CLK_PERD     : time      := 1000 ms / CLK_FREQ;

    signal clk            : std_logic := '0';

    signal A, B, F        : std_logic_vector(63 downto 0);
    signal error_Signal   : std_logic;
    signal zero_signal    : std_logic;
    signal done_signal    : std_logic;
    signal posv_signal    : std_logic;
    signal clk_signal     : std_logic;
    signal rst_signal     : std_logic;
    signal enable_signal  : std_logic;
    signal add_sub_signal : std_logic;
    signal mode_signal    : std_logic_vector(1 downto 0);
begin
    clk <= not clk after CLK_PERD / 2;

    fpu_adder_carry_select : entity work.fpu_adder(sec_algo)
        port map(
            mode => mode_signal, clk => clk_signal, rst => rst_signal,
            enbl => enable_signal, add_sub => add_sub_signal, in_a => A, in_b => B, out_c => F, done => done_signal,
            err => error_signal, zero => zero_signal, posv => posv_signal
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("all") then
            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("0000000000000000000000000000000000000000000000000000000000110100");
            B              <= ("0000000000000000000000000000000000000000000000000000000000101100");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000001100000");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 1: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("1111111111111111111111111111111111111111111111111111111111101110");
            B              <= ("0000000000000000000000000000000000000000000000000000000000111000");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000000100110");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 2: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("0000000000000000000000000000000000000000000000000000000000001000");
            B              <= ("0000000000000000000000000000000000000000000000000000000000000010");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000000001010");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 3: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("0000000000000000000000000000000000000000000000000000000010101100");
            B              <= ("1111111111111111111111111111111111111111111111111111111100111100");
            wait for 100 ps;
            assert(F = "1111111111111111111111111111111111111111111111111111111111101000");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '0');
            assert(done_signal = '1');
            report "Test Passed 4: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("0000000000000000000000000000000000000000000000000000000101000010");
            B              <= ("1111111111111111111111111111111111111111111111111111111010111110");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000000000000");
            assert(zero_signal = '1');
            assert(error_signal = '0');
            assert(posv_signal = '0');
            assert(done_signal = '1');
            report "Test Passed 5: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("1111111111111111111111111111111111111111111111111111111110101110");
            B              <= ("1111111111111111111111111111111111111111111111111111111111000100");
            wait for 100 ps;
            assert(F = "1111111111111111111111111111111111111111111111111111111101110010");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '0');
            assert(done_signal = '1');
            report "Test Passed 6: passed";

            -- Test subtraction 

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('1');
            A              <= ("0000000000000000000000000000000000000000000000000000000000110100");
            B              <= ("0000000000000000000000000000000000000000000000000000000000101100");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000000001000");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 7: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('1');
            A              <= ("1111111111111111111111111111111111111111111111111111111111101110");
            B              <= ("0000000000000000000000000000000000000000000000000000000000111000");
            wait for 100 ps;
            assert(F = "1111111111111111111111111111111111111111111111111111111110110110");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '0');
            assert(done_signal = '1');
            report "Test Passed 8: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('1');
            A              <= ("0000000000000000000000000000000000000000000000000000000000001000");
            B              <= ("0000000000000000000000000000000000000000000000000000000000000100");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000000000100");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 9: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('1');
            A              <= ("0000000000000000000000000000000000000000000000000000000010101100");
            B              <= ("1111111111111111111111111111111111111111111111111111111100111100");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000000101110000");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 10: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('1');
            A              <= ("0000000000000000000000000000000000000000000000000000000101000010");
            B              <= ("1111111111111111111111111111111111111111111111111111111010111110");
            wait for 100 ps;
            assert(F = "0000000000000000000000000000000000000000000000000000001010000100");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '1');
            assert(done_signal = '1');
            report "Test Passed 11: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('1');
            A              <= ("1111111111111111111111111111111111111111111111111111111110101110");
            B              <= ("1111111111111111111111111111111111111111111111111111111111000100");
            wait for 100 ps;
            assert(F = "1111111111111111111111111111111111111111111111111111111111101010");
            assert(zero_signal = '0');
            assert(error_signal = '0');
            assert(posv_signal = '0');
            assert(done_signal = '1');
            report "Test Passed 12: passed";

            --Test error signal 
            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("1011111111111111111111111111111111111111111111111111111111111111");
            B              <= ("1011111111111111111111111111111111111111111111111111111111111111");
            wait for 100 ps;
            assert(error_signal = '1');
            report "Test Passed 13: passed";

            rst_signal <= ('1');
            wait for 100 ps;
            enable_signal  <= ('1');
            rst_signal     <= ('0');
            add_sub_signal <= ('0');
            A              <= ("0111111111111111111111111111111111111111111111111111111111111111");
            B              <= ("0111111111111111111111111111111111111111111111111111111111111111");
            wait for 100 ps;
            assert(error_signal = '1');
            report "Test Passed 14: passed";
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;