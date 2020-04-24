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
    signal testa      : std_logic_vector(63 downto 0);
    signal testb      : std_logic_vector(63 downto 0);

    signal testc      : std_logic_vector(63 downto 0);
    signal testDone   : std_logic;
    signal testErr    : std_logic;
    signal testZero   : std_logic;
    signal testPosv   : std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    fpu_divider_first_algo : entity work.fpu_divider(first_algo)
        port map(
            clk   => clk,
            mode  => mode,
            rst   => rst,
            enbl  => enbl,
            in_a  => testa,
            in_b  => testb,
            out_c => testc,
            done  => testDone,
            err   => testErr,
            zero  => testZero,
            posv  => testPosv
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("all") then
            -- testing overflow error 
            rst   <= '1';
            enbl  <= '0';
            testa <= "0000000000000000000000000000000000000000000000000111111110000000";
            testb <= "0000000000000000000000000000000000000000000000000000000000000001";
            wait for CLK_PERD/2;
            rst  <= '0';
            enbl <= '1';
            wait for CLK_PERD * 23;
            wait for 1 ps;
            enbl <= '0';
            assert(testDone = '1' and testErr = '1' and testZero = '0' and testPosv = '0') report "Overflow test failed" severity ERROR;

            -- testing divide by zero error
            wait for CLK_PERD;
            testa <= "0000000000000000000000000000000000000000000000000111111110000000";
            testb <= "0000000000000000000000000000000000000000000000000000000000000000";
            wait for CLK_PERD/2;
            enbl <= '1';
            wait for CLK_PERD;
            enbl <= '0';
            wait for CLK_PERD * 22;
            wait for 1 ps;
            assert(testDone = '1' and testErr = '1' and testZero = '0' and testPosv = '0') report "Divide by zero test failed" severity ERROR;

            -- testing reset
            wait for CLK_PERD;
            testa <= "0000000000000000000000000000000000000000000000000000000000000101";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '1';
            enbl  <= '0';
            wait for CLK_PERD;
            assert(testc = x"0000000000000000" and testDone = '0' and testErr = '0' and testZero = '0' and testPosv = '0') report "Reset test failed" severity ERROR;
            -- testing valid positive / positive operation 
            wait for CLK_PERD;
            --rst	 <= '1';
            testa <= "0000000000000000000000000000000000000000000000000111111110000000"; -- a = 255
            testb <= "0000000000000000000000000000000000000000000000000000010100000000"; -- b = 10
            wait for CLK_PERD/2;
            rst  <= '0';
            enbl <= '1';
            wait for CLK_PERD * 23;
            wait for 1 ps;
            -- result = 0000000000000000000000000000000000000000000000000000110011000000 (25.5)
            assert(testc = x"0000000000000CC0" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '1') report "positive / positive test failed" severity ERROR;

            -- testing valid positive / negative operation 
            wait for CLK_PERD;
            rst   <= '1';
            testa <= "1111111111111111111111111111111111111111111111111000000010000000"; -- a = -255
            testb <= "0000000000000000000000000000000000000000000000000000001010000000"; -- a = 5
            wait for CLK_PERD/2;
            rst  <= '0';
            enbl <= '1';
            wait for CLK_PERD * 23;
            wait for 1 ps;
            -- result = 1111111111111111111111111111111111111111111111111110011010000000 (-51.0)   
            assert(testc = x"FFFFFFFFFFFFE680" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '0') report "positive / negative test failed" severity ERROR;

            -- testing valid negative / negative operation
            wait for CLK_PERD;
            rst   <= '1';
            testa <= "1111111111111111111111111111111111111111111111111000000010000000";
            testb <= "1111111111111111111111111111111111111111111111111111101100000000";
            wait for CLK_PERD/2;
            rst  <= '0';
            enbl <= '1';
            wait for CLK_PERD * 23;
            wait for 1 ps;
            assert(testc = x"0000000000000CC0" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '1') report "negative / negative test failed" severity ERROR;

            -- testing valid zero / number operation 
            wait for CLK_PERD;
            rst   <= '1';
            testa <= "0000000000000000000000000000000000000000000000000000000000000000";
            testb <= "1111111111111111111111111111111111111111111111111000000010000000";
            wait for CLK_PERD/2;
            rst  <= '0';
            enbl <= '1';
            wait for CLK_PERD * 23;
            wait for 1 ps;
            assert(testc = x"0000000000000000" and testDone = '1' and testErr = '0' and testZero = '1' and testPosv = '0') report "zero / number test failed" severity ERROR;
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;