library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity multiplier is
	port(A , B : in std_logic_vector(15 downto 0);
		 C : out std_logic_vector(15 downto 0);
		 overflow : out std_logic
		);
end multiplier;

architecture arch of multiplier is
constant scale_factor : integer := 7;
signal output : std_logic_vector(31 downto 0);
begin
	output(31 downto 0) <= std_logic_vector(signed(A(15 downto 0))*signed(B(15 downto 0)));
	C <= output((scale_factor+15) downto scale_factor);
	overflow <= not((((output(31) and output(30)) and (output(29) and output(28))) and ((output(27) and output(26)) and (output(25) and output(24))) and (output(23) and output(22))) 
			 or not (((output(31) or output(30)) or (output(29) or output(28))) or ((output(27) or output(26)) or (output(25) or output(24))) or (output(23) or output(22))));
end arch;


