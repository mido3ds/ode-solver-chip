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
signal i : integer;
constant CLKPERIOD : time := 200 ps;
BEGIN 
	divider : entity work.fpu_divider(first_algo) PORT MAP (mode => mode , clk => clk , rst => rst , enbl => enbl , in_a => testa , in_b => testb , 
														out_c => testc , done => testDone , err => testErr , zero => testZero , posv => testPosv, i_test => i);
PROCESS 
BEGIN
	clk <= not clk;
	wait for CLKPERIOD/4;
END PROCESS;

PROCESS
  BEGIN 
     
	-- testing overflow error 
   rst	 <= '1';
   enbl  <= '0';
   testa <= "0000000000000000000000000000000000000000000000000111111110000000";
   testb <= "0000000000000000000000000000000000000000000000000000000000000001";
   wait for CLKPERIOD/2;
   rst   <= '0';
   enbl  <= '1';
   wait for CLKPERIOD*23;
   wait for 1 ps;   
   enbl  <= '0';
   ASSERT(testDone ='1' and testErr = '1' and testZero = '0' and testPosv = '0') REPORT  "Overflow test failed" SEVERITY ERROR; 
   
   -- testing divide by zero error
   wait for CLKPERIOD;
   testa <= "0000000000000000000000000000000000000000000000000111111110000000";
   testb <= "0000000000000000000000000000000000000000000000000000000000000000";
   enbl  <= '1';
   wait for CLKPERIOD/2;
   wait for CLKPERIOD*23; 
   wait for 1 ps;  
   enbl  <= '0';
   ASSERT(testDone ='1' and testErr = '1' and testZero = '0' and testPosv = '0') REPORT  "Divide by zero test failed" SEVERITY ERROR;

   -- testing reset
   wait for CLKPERIOD;
   testa <= "0000000000000000000000000000000000000000000000000000000000000101";
   testb <= "0000000000000000000000000000000000000000000000000100100011100001";	
   rst   <= '1';
   enbl  <= '0';
   wait for CLKPERIOD;				
   ASSERT(testc = x"0000000000000000" and testDone ='0' and testErr = '0' and testZero = '0' and testPosv = '0') REPORT  "Reset test failed" SEVERITY ERROR;   

   -- testing valid positive / positive operation 
   wait for CLKPERIOD;
   rst   <= '0';
   enbl  <= '1';
   testa <= "0000000000000000000000000000000000000000000000000111111110000000"; -- a = 255
   testb <= "0000000000000000000000000000000000000000000000000000010100000000";	-- b = 10
   wait for CLKPERIOD*23; 
   wait for 1 ps; 
   enbl  <= '0';
   -- result = 0000000000000000000000000000000000000000000000000000110011000000 (25.5)
   ASSERT(testc = x"0000000000000CC0" and testDone ='1' and testErr = '0' and testZero = '0' and testPosv = '1') REPORT  "positive / positive test failed" SEVERITY ERROR;

   -- testing valid positive / negative operation 
   wait for CLKPERIOD;
   enbl  <= '1';
   testa <= "1111111111111111111111111111111111111111111111111000000010000000"; -- a = -255
   testb <= "0000000000000000000000000000000000000000000000000000001010000000"; -- a = 5
   wait for CLKPERIOD*23;	
   wait for 1 ps;
   enbl  <= '0';
   -- result = 1111111111111111111111111111111111111111111111111110011010000000 (-51.0)   
   ASSERT(testc = x"FFFFFFFFFFFFE680" and testDone ='1' and testErr = '0' and testZero = '0' and testPosv = '0') REPORT  "positive / negative test failed" SEVERITY ERROR;

   -- testing valid negative / negative operation
   wait for CLKPERIOD;   
   enbl	 <= '1';
   testa <= "1111111111111111111111111111111111111111111111111000000010000000";
   testb <= "1111111111111111111111111111111111111111111111111111101100000000";	
   wait for CLKPERIOD*23;
   wait for 1 ps;
   enbl  <= '0';   
   ASSERT(testc = x"0000000000000CC0" and testDone ='1' and testErr = '0' and testZero = '0' and testPosv = '1') REPORT  "negative / negative test failed" SEVERITY ERROR;
   
   -- testing valid zero / number operation 
   wait for CLKPERIOD;
   enbl	 <= '1';
   testa <= "0000000000000000000000000000000000000000000000000000000000000000";
   testb <= "1111111111111111111111111111111111111111111111111000000010000000";
   wait for CLKPERIOD*23;
   wait for 1 ps;  
   enbl  <= '0';   
   ASSERT(testc = x"0000000000000000" and testDone ='1' and testErr = '0' and testZero = '1' and testPosv = '0') REPORT  "zero / number test failed" SEVERITY ERROR;

   wait;
 END PROCESS;

END testbench;

