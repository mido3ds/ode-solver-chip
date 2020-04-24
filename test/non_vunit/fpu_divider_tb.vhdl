library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity fpu_divider_tb is
end fpu_divider_tb;

architecture testbench of fpu_divider_tb is
    signal testa, testb, testc                              : std_logic_vector (63 downto 0);
    signal mode                                             : std_logic_vector(1 downto 0) := (others => '0');
    signal testDone, testErr, testZero, testPosv, enbl, rst : std_logic                    := '0';
    signal clk                                              : std_logic                    := '1';
    constant CLKPERIOD                                      : time                         := 100 ps;
begin
    divider : entity work.fpu_divider(first_algo) port map (mode => mode, clk => clk, rst => rst, enbl => enbl, in_a => testa, in_b => testb,
        out_c => testc, done => testDone, err => testErr, zero => testZero, posv => testPosv);
    process
    begin
        clk <= not clk;
        wait for CLKPERIOD/2;
    end process;

    process
    begin
        -- testing overflow error 
        rst   <= '1';
        enbl  <= '0';
        testa <= "0000000000000000000000000000000000000000000000000111111110000000";
        testb <= "0000000000000000000000000000000000000000000000000000000000000001";
        wait for CLKPERIOD/2;
        rst  <= '0';
        enbl <= '1';
        wait for CLKPERIOD * 23;
        wait for 1 ps;
        enbl <= '0';
        assert(testDone = '1' and testErr = '1' and testZero = '0' and testPosv = '0') report "Overflow test failed" severity ERROR;

        -- testing divide by zero error
        wait for CLKPERIOD;
        testa <= "0000000000000000000000000000000000000000000000000111111110000000";
        testb <= "0000000000000000000000000000000000000000000000000000000000000000";
        wait for CLKPERIOD/2;
        enbl <= '1';
        wait for CLKPERIOD;
        enbl <= '0';
        wait for CLKPERIOD * 22;
        wait for 1 ps;
        assert(testDone = '1' and testErr = '1' and testZero = '0' and testPosv = '0') report "Divide by zero test failed" severity ERROR;

        -- testing reset
        wait for CLKPERIOD;
        testa <= "0000000000000000000000000000000000000000000000000000000000000101";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '1';
        enbl  <= '0';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000000" and testDone = '0' and testErr = '0' and testZero = '0' and testPosv = '0') report "Reset test failed" severity ERROR;
        -- testing valid positive / positive operation 
        wait for CLKPERIOD;
        --rst	 <= '1';
        testa <= "0000000000000000000000000000000000000000000000000111111110000000"; -- a = 255
        testb <= "0000000000000000000000000000000000000000000000000000010100000000"; -- b = 10
        wait for CLKPERIOD/2;
        rst  <= '0';
        enbl <= '1';
        wait for CLKPERIOD * 23;
        wait for 1 ps;
        -- result = 0000000000000000000000000000000000000000000000000000110011000000 (25.5)
        assert(testc = x"0000000000000CC0" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '1') report "positive / positive test failed" severity ERROR;

        -- testing valid positive / negative operation 
        wait for CLKPERIOD;
        rst   <= '1';
        testa <= "1111111111111111111111111111111111111111111111111000000010000000"; -- a = -255
        testb <= "0000000000000000000000000000000000000000000000000000001010000000"; -- a = 5
        wait for CLKPERIOD/2;
        rst  <= '0';
        enbl <= '1';
        wait for CLKPERIOD * 23;
        wait for 1 ps;
        -- result = 1111111111111111111111111111111111111111111111111110011010000000 (-51.0)   
        assert(testc = x"FFFFFFFFFFFFE680" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '0') report "positive / negative test failed" severity ERROR;

        -- testing valid negative / negative operation
        wait for CLKPERIOD;
        rst   <= '1';
        testa <= "1111111111111111111111111111111111111111111111111000000010000000";
        testb <= "1111111111111111111111111111111111111111111111111111101100000000";
        wait for CLKPERIOD/2;
        rst  <= '0';
        enbl <= '1';
        wait for CLKPERIOD * 23;
        wait for 1 ps;
        assert(testc = x"0000000000000CC0" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '1') report "negative / negative test failed" severity ERROR;

        -- testing valid zero / number operation 
        wait for CLKPERIOD;
        rst   <= '1';
        testa <= "0000000000000000000000000000000000000000000000000000000000000000";
        testb <= "1111111111111111111111111111111111111111111111111000000010000000";
        wait for CLKPERIOD/2;
        rst  <= '0';
        enbl <= '1';
        wait for CLKPERIOD * 23;
        wait for 1 ps;
        assert(testc = x"0000000000000000" and testDone = '1' and testErr = '0' and testZero = '1' and testPosv = '0') report "zero / number test failed" severity ERROR;

        wait;
    end process;
end architecture;