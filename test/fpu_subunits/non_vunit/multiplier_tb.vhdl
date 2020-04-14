library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity multiplier_tb is
end multiplier_tb;

architecture tb of multiplier_tb is
    signal testa, testb, testc                              : std_logic_vector (63 downto 0);
    signal mode                                             : std_logic_vector(1 downto 0) := (others => '0');
    signal testDone, testErr, testZero, testPosv, enbl, rst : std_logic                    := '0';
    signal clk                                              : std_logic                    := '1';
    constant CLKPERIOD                                      : time                         := 200 ps;
begin
    Multiblier_1 : entity work.fpu_multiplier(first_algo)
        port map(
            mode  => mode,
            clk   => clk,
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

    process
    begin
        clk <= not clk;
        wait for CLKPERIOD/2;
    end process;

    process
    begin
        -- testing overflow error
        testa <= "1111111111111111111111111111111111111111111111111010011111100101";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '0';
        enbl  <= '1';
        wait for CLKPERIOD;
        assert(testc = x"FFFFFFFFFFFFD5F0" and testDone = '1' and testErr = '1' and testZero = '0' and testPosv = '0') report "overflow test failed" severity ERROR;

        -- testing operation while error flag is 1
        testa <= "0000000000000000000000000000000000000000000000000000000000000101";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '0';
        enbl  <= '1';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000000" and testDone = '1' and testErr = '1' and testZero = '0' and testPosv = '0') report "error flag 1 test failed" severity ERROR;

        -- testing operation while enable is 0 (it should reset all except error state)
        testa <= "0000000000000000000000000000000000000000000000000000000000000101";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '0';
        enbl  <= '0';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000000" and testDone = '0' and testErr = '1' and testZero = '0' and testPosv = '0') report "enable 0 test failed" severity ERROR;

        -- resetting	while enable is 0 
        testa <= "0000000000000000000000000000000000000000000000000000000000000101";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '1';
        enbl  <= '0';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000000" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '0') report "reset test failed" severity ERROR;
        -- testing valid positive * positive operation 
        testa <= "0000000000000000000000000000000000000000000000000000000000000101";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '0';
        enbl  <= '1';
        wait for CLKPERIOD;
        assert(testc = x"00000000000002D8" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '1') report "positive * positive test failed" severity ERROR;

        -- testing valid positive * negative operation 
        testa <= "1111111111111111111111111111111111111111111111111111111111111011";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '0';
        enbl  <= '1';
        wait for CLKPERIOD;
        assert(testc = x"FFFFFFFFFFFFFD27" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '0') report "positive * negative test failed" severity ERROR;

        -- testing valid negative * negative operation 
        testa <= "1111111111111111111111111111111111111111111111111111111111111011";
        testb <= "1111111111111111111111111111111111111111111111111100100011100001";
        rst   <= '0';
        enbl  <= '1';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000227" and testDone = '1' and testErr = '0' and testZero = '0' and testPosv = '1') report "negative * negative test failed" severity ERROR;

        -- testing valid zero * number operation 
        testa <= "1111111111111111111111111111111111111111111111111111111111111011";
        testb <= "0000000000000000000000000000000000000000000000000000000000000000";
        rst   <= '0';
        enbl  <= '1';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000000" and testDone = '1' and testErr = '0' and testZero = '1' and testPosv = '0') report "zero * number test failed" severity ERROR;

        -- testing valid operation when enable is 0
        testa <= "1111111111111111111111111111111111111111111111111111111111111011";
        testb <= "0000000000000000000000000000000000000000000000000100100011100001";
        rst   <= '0';
        enbl  <= '0';
        wait for CLKPERIOD;
        assert(testc = x"0000000000000000" and testDone = '0' and testErr = '0' and testZero = '0' and testPosv = '0') report "enable 0 2nd test failed" severity ERROR;
    end process;
end architecture;