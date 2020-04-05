library ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY Multiblier_TB IS 
END Multiblier_TB;

ARCHITECTURE testbench OF Multiblier_TB IS 
  COMPONENT multiplier IS 
	port (
		A , B : in std_logic_vector(15 downto 0);
		 C : out std_logic_vector(15 downto 0);
		 overflow : out std_logic
		);
  END COMPONENT;  
  

  SIGNAL testa, testb ,testc: std_logic_vector (15 downto 0) ;
  SIGNAL testOverflow       : std_logic ;

BEGIN 
	Multiblier_1 :  multiplier PORT MAP (A => testa, B=>testb,C=>testc , overflow=>testOverflow);

PROCESS
  BEGIN 
   testa <="1010011111100101";
   testb <="0100100011100001";	
   wait for 200ps;
   ASSERT(testc = "1101010111110000" and testOverflow ='1') REPORT  "wrong outputs" SEVERITY ERROR; 

   testa <="0011101111011111";
   testb <="0101110010110100";	
   wait for 200ps;
   ASSERT(testc = "0101110001111001" and testOverflow ='1') REPORT  "wrong outputs" SEVERITY ERROR; 

   testa <="1001000110000000";
   testb <="0110000101011000";	
   wait for 200ps;
   ASSERT(testc = "1111011100001000" and testOverflow ='1') REPORT  "wrong outputs" SEVERITY ERROR; 

   testa <="1110110011101110";
   testb <="0100011010000110";	
   wait for 200ps;
   ASSERT(testc = "0111111000110001" and testOverflow ='1') REPORT  "wrong outputs" SEVERITY ERROR; 


   testa <="1111111111100101";
   testb <="0000000011100001";	
   wait for 200ps;
   ASSERT(testc = "1111111111010000" and testOverflow ='0') REPORT  "wrong outputs" SEVERITY ERROR; 

   testa <="0000001111110100";
   testb <="0000011010001001";	
   wait for 200ps;
   ASSERT(testc = "0011001110101011" and testOverflow ='0') REPORT  "wrong outputs" SEVERITY ERROR; 

   testa <="0000000011101111";
   testb <="0000000101110010";	
   wait for 200ps;
   ASSERT(testc = "0000001010110010" and testOverflow ='0') REPORT  "wrong outputs" SEVERITY ERROR; 

   testa <="0000000011000000";
   testb <="0000000010101100";	
   wait for 200ps;
   ASSERT(testc = "0000000100000010" and testOverflow ='0') REPORT  "wrong outputs" SEVERITY ERROR;


 END PROCESS;
END testbench;
