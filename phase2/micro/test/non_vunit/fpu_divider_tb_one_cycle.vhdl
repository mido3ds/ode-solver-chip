library ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY fpu_divider_tb IS 
END fpu_divider_tb;

ARCHITECTURE testbench OF fpu_divider_tb IS 

SIGNAL testa, testb ,testc : std_logic_vector (63 downto 0) ;
SIGNAL mode : std_logic_vector(1 downto 0) := (others => '0');
SIGNAL testDone, testErr, testZero, testPosv, enbl, rst : std_logic := '0';
SIGNAL clk : std_logic := '1';
constant CLKPERIOD : time := 200 ps;
BEGIN 
	divider : entity work.fpu_divider(first_algo) PORT MAP (mode => mode , clk => clk , rst => rst , enbl => enbl , in_a => testa , in_b => testb , 
															out_c=>testc , done=>testDone , err=>testErr , zero=>testZero , posv=>testPosv);
PROCESS 
BEGIN
	clk <= not clk;
	wait for CLKPERIOD/2;
END PROCESS;

PROCESS
  BEGIN 
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

   wait;
 END PROCESS;

END testbench;
