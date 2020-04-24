library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity fpu_multiplier_tb is
end entity;

architecture tb of fpu_multiplier_tb is
    signal testa, testb, testc1 , testc2 , testc3               : std_logic_vector (63 downto 0);
    signal mode                                             	: std_logic_vector(1 downto 0) := (others => '0');
    signal testDone1, testErr1, testZero1, testPosv1, enbl, rst : std_logic                    := '0';
	signal testDone2, testErr2, testZero2, testPosv2 			: std_logic                    := '0';
	signal testDone3, testErr3, testZero3, testPosv3 			: std_logic                    := '0';
    signal clk                                              	: std_logic                    := '1';
    constant CLKPERIOD                                      	: time                         := 200 ps;
begin
    Multiblier_1 : entity work.fpu_multiplier(first_algo)
        port map(
            mode  => mode,
            clk   => clk,
            rst   => rst,
            enbl  => enbl,
            in_a  => testa,
            in_b  => testb,
            out_c => testc1,
            done  => testDone1,
            err   => testErr1,
            zero  => testZero1,
            posv  => testPosv1
        );
	Multiblier_2 : entity work.fpu_multiplier(sec_algo)
	port map(
            mode  => mode,
            clk   => clk,
            rst   => rst,
            enbl  => enbl,
            in_a  => testa,
            in_b  => testb,
            out_c => testc2,
            done  => testDone2,
            err   => testErr2,
            zero  => testZero2,
            posv  => testPosv2
        );
	Multiblier_3 : entity work.fpu_multiplier(with_operators)
	port map(
            mode  => mode,
            clk   => clk,
            rst   => rst,
            enbl  => enbl,
            in_a  => testa,
            in_b  => testb,
            out_c => testc3,
            done  => testDone3,
            err   => testErr3,
            zero  => testZero3,
            posv  => testPosv3
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
            assert((testc1 = x"FFFFFFFFFFFFD5F0" and testDone1 = '1' and testErr1 = '1' and testZero1 = '0' and testPosv1 = '0') and
				   (testc2 = x"FFFFFFFFFFFFD5F0" and testDone2 = '1' and testErr2 = '1' and testZero2 = '0' and testPosv2 = '0') and
				   (testc3 = x"FFFFFFFFFFFFD5F0" and testDone3 = '1' and testErr3 = '1' and testZero3 = '0' and testPosv3 = '0')) 
			report "overflow test failed" severity ERROR;

            -- testing operation while error flag is 1
            testa <= "0000000000000000000000000000000000000000000000000000000000000101";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '0';
            enbl  <= '1';
            wait for CLKPERIOD;
			assert((testc1 = x"FFFFFFFFFFFFD5F0" and testDone1 = '1' and testErr1 = '1' and testZero1 = '0' and testPosv1 = '0') and
				   (testc2 = x"FFFFFFFFFFFFD5F0" and testDone2 = '1' and testErr2 = '1' and testZero2 = '0' and testPosv2 = '0') and
				   (testc3 = x"FFFFFFFFFFFFD5F0" and testDone3 = '1' and testErr3 = '1' and testZero3 = '0' and testPosv3 = '0')) 
			report "error flag 1 test failed" severity ERROR;

            -- testing operation while enable is 0 (it should reset all except error state)
            testa <= "0000000000000000000000000000000000000000000000000000000000000101";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '0';
            enbl  <= '0';
            wait for CLKPERIOD;
			assert((testc1 = x"0000000000000000" and testDone1 = '0' and testErr1 = '1' and testZero1 = '0' and testPosv1 = '0') and
				   (testc2 = x"0000000000000000" and testDone2 = '0' and testErr2 = '1' and testZero2 = '0' and testPosv2 = '0')) 
			report "enable 0 test failed" severity ERROR;

            -- resetting	while enable is 0 
            testa <= "0000000000000000000000000000000000000000000000000000000000000101";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '1';
            enbl  <= '0';
            wait for CLKPERIOD;
			assert((testc1 = x"0000000000000000" and testDone1 = '1' and testErr1 = '0' and testZero1 = '0' and testPosv1 = '0') and
				   (testc2 = x"0000000000000000" and testDone2 = '1' and testErr2 = '0' and testZero2 = '0' and testPosv2 = '0') and
				   (testc3 = x"0000000000000000" and testDone3 = '1' and testErr3 = '0' and testZero3 = '0' and testPosv3 = '0')) 
			report "reset test failed" severity ERROR;

            -- testing valid positive * positive operation 
            testa <= "0000000000000000000000000000000000000000000000000000000000000101";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '0';
            enbl  <= '1';
            wait for CLKPERIOD;
			assert((testc1 = x"00000000000002D8" and testDone1 = '1' and testErr1 = '0' and testZero1 = '0' and testPosv1 = '1') and
				   (testc2 = x"00000000000002D8" and testDone2 = '1' and testErr2 = '0' and testZero2 = '0' and testPosv2 = '1') and
				   (testc3 = x"00000000000002D8" and testDone3 = '1' and testErr3 = '0' and testZero3 = '0' and testPosv3 = '1')) 
			report "positive * positive test failed" severity ERROR;

            -- testing valid positive * negative operation 
            testa <= "1111111111111111111111111111111111111111111111111111111111111011";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '0';
            enbl  <= '1';
            wait for CLKPERIOD;
			assert((testc1 = x"FFFFFFFFFFFFFD27" and testDone1 = '1' and testErr1 = '0' and testZero1 = '0' and testPosv1 = '0') and
				   (testc2 = x"FFFFFFFFFFFFFD27" and testDone2 = '1' and testErr2 = '0' and testZero2 = '0' and testPosv2 = '0') and
				   (testc3 = x"FFFFFFFFFFFFFD27" and testDone3 = '1' and testErr3 = '0' and testZero3 = '0' and testPosv3 = '0')) 
			report "positive * negative test failed" severity ERROR;

            -- testing valid negative * negative operation 
            testa <= "1111111111111111111111111111111111111111111111111111111111111011";
            testb <= "1111111111111111111111111111111111111111111111111100100011100001";
            rst   <= '0';
            enbl  <= '1';
            wait for CLKPERIOD;
			assert((testc1 = x"0000000000000227" and testDone1 = '1' and testErr1 = '0' and testZero1 = '0' and testPosv1 = '1') and
				   (testc2 = x"0000000000000227" and testDone2 = '1' and testErr2 = '0' and testZero2 = '0' and testPosv2 = '1') and
				   (testc3 = x"0000000000000227" and testDone3 = '1' and testErr3 = '0' and testZero3 = '0' and testPosv3 = '1')) 
			report "negative * negative test failed" severity ERROR;

            -- testing valid zero * number operation 
            testa <= "1111111111111111111111111111111111111111111111111111111111111011";
            testb <= "0000000000000000000000000000000000000000000000000000000000000000";
            rst   <= '0';
            enbl  <= '1';
            wait for CLKPERIOD;
			assert((testc1 = x"0000000000000000" and testDone1 = '1' and testErr1 = '0' and testZero1 = '1' and testPosv1 = '0') and
				   (testc2 = x"0000000000000000" and testDone2 = '1' and testErr2 = '0' and testZero2 = '1' and testPosv2 = '0') and
				   (testc3 = x"0000000000000000" and testDone3 = '1' and testErr3 = '0' and testZero3 = '1' and testPosv3 = '0')) 
			report "zero * number test failed" severity ERROR;

            -- testing valid operation when enable is 0
            testa <= "1111111111111111111111111111111111111111111111111111111111111011";
            testb <= "0000000000000000000000000000000000000000000000000100100011100001";
            rst   <= '0';
            enbl  <= '0';
            wait for CLKPERIOD;
			assert((testc1 = x"0000000000000000" and testDone1 = '0' and testErr1 = '0' and testZero1 = '0' and testPosv1 = '0') and
				   (testc2 = x"0000000000000000" and testDone2 = '0' and testErr2 = '0' and testZero2 = '0' and testPosv2 = '0') and
				   (testc3 = x"0000000000000000" and testDone3 = '0' and testErr3 = '0' and testZero3 = '0' and testPosv3 = '0')) 
			report "enable 0 2nd test failed" severity ERROR;
    end process;
end architecture;