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

        if run("all") then
			-- testing overflow error
		   testa <= "0000000000000000000000000000000000000000000000000111111110000000";
		   testb <= "0000000000000000000000000000000000000000000000000000000000000001";	
		   rst   <= '0';
		   enbl  <= '1';
		   wait for CLKPERIOD;
		   ASSERT(testDone ='1' and testErr = '1' and testZero = '0' and testPosv = '0') REPORT  "Overflow test failed" SEVERITY ERROR; 
		   
		   -- testing divide by zero error 
		   testa <= "0000000000000000000000000000000000000000000000000111111110000000";
		   testb <= "0000000000000000000000000000000000000000000000000000000000000000";	
		   rst   <= '0';
		   enbl  <= '1';
		   wait for CLKPERIOD;				
		   ASSERT(testDone ='1' and testErr = '1' and testZero = '0' and testPosv = '0') REPORT  "Divide by zero test failed" SEVERITY ERROR; 

		   -- testing operation while enable is 0 (it should reset all except error state)
		   testa <= "0000000000000000000000000000000000000000000000000000000000000101";
		   testb <= "0000000000000000000000000000000000000000000000000100100011100001";	
		   rst   <= '0';
		   enbl  <= '0';
		   wait for CLKPERIOD;				
		   ASSERT(testc = x"0000000000000000" and testDone ='0' and testErr = '1' and testZero = '0' and testPosv = '0') REPORT  "Enable 0 test failed" SEVERITY ERROR;  

		   -- resetting	while enable is 0 
		   testa <= "0000000000000000000000000000000000000000000000000000000000000101";
		   testb <= "0000000000000000000000000000000000000000000000000100100011100001";	
		   rst   <= '1';
		   enbl  <= '0';
		   wait for CLKPERIOD;				
		   ASSERT(testc = x"0000000000000000" and testDone ='0' and testErr = '0' and testZero = '0' and testPosv = '0') REPORT  "Reset test failed" SEVERITY ERROR;  


		   -- testing valid positive / positive operation 
		   testa <= "0000000000000000000000000000000000000000000000000111111110000000";
		   testb <= "0000000000000000000000000000000000000000000000000000010100000000";	
		   rst   <= '0';
		   enbl  <= '1';
		   wait for CLKPERIOD;				
		   ASSERT(testc = x"0000000000000CC0" and testDone ='1' and testErr = '0' and testZero = '0' and testPosv = '1') REPORT  "positive / positive test failed" SEVERITY ERROR;

		   -- testing valid positive / negative operation 
		   testa <= "1111111111111111111111111111111111111111111111111000000010000000";
		   testb <= "0000000000000000000000000000000000000000000000000000010100000000";	
		   rst   <= '0';
		   enbl  <= '1';
		   wait for CLKPERIOD;				
		   ASSERT(testc = x"FFFFFFFFFFFFF340" and testDone ='1' and testErr = '0' and testZero = '0' and testPosv = '0') REPORT  "positive / negative test failed" SEVERITY ERROR;

		   -- testing valid negative / negative operation 
		   testa <= "1111111111111111111111111111111111111111111111111000000010000000";
		   testb <= "1111111111111111111111111111111111111111111111111111101100000000";	
		   rst   <= '0';
		   enbl  <= '1';
		   wait for CLKPERIOD;				
		   ASSERT(testc = x"0000000000000CC0" and testDone ='1' and testErr = '0' and testZero = '0' and testPosv = '1') REPORT  "negative / negative test failed" SEVERITY ERROR;
		   
		   -- testing valid zero / number operation 
		   testa <= "0000000000000000000000000000000000000000000000000000000000000000";
		   testb <= "1111111111111111111111111111111111111111111111111000000010000000";	
		   rst   <= '0';
		   enbl  <= '1';
		   wait for CLKPERIOD;				
		   ASSERT(testc = x"0000000000000000" and testDone ='1' and testErr = '0' and testZero = '1' and testPosv = '0') REPORT  "zero / number test failed" SEVERITY ERROR;


        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;