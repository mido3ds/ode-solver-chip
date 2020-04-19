library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use IEEE.STD_LOGIC_ARITH.ALL;

entity fpu_divider is
    port (
        mode: in std_logic_vector(1 downto 0);
        clk: in std_logic;
        rst: in std_logic;
        enbl: in std_logic;
        in_a: in std_logic_vector(63 downto 0);
        in_b: in std_logic_vector(63 downto 0);

        out_c: out std_logic_vector(63 downto 0);
        done: out std_logic;
        err: out std_logic;
        zero: out std_logic;
        posv: out std_logic
    );
end entity; 

-- Divider implementation with operators
architecture with_operators of fpu_divider is
	constant scale_factor : integer := 7;																-- fixed scale factor
	constant size : integer := 16;																		-- operands' size
	signal Q: std_logic_vector(size -1 downto 0);
	signal F: std_logic_vector(scale_factor-1 downto 0);
begin
PROCESS(in_a,in_b,clk)
		
		variable zero_flag , posv_flag, ovfl_flag, divide_by_zero_error, ready : std_logic;
		variable quotient : std_logic_vector(size + scale_factor -1 downto 0);
		variable a, b, out64 : std_logic_vector(4*size-1 downto 0);
		variable out_neg : std_logic_vector(4*size-1 downto 0);

		begin
			a := std_logic_vector(abs(signed(in_a)) sll scale_factor);
			b := std_logic_vector(abs(signed(in_b)));
			quotient 	:= (others => '0');	
			out64	  	:= (others => '0');
			zero_flag 	:= '0';
			posv_flag 	:= '0';
			ovfl_flag 	:= '0';
			ready 		:= '0';

			if(rst = '1') then															-- reset signal
				divide_by_zero_error := '0';
			elsif(enbl = '1' and rising_edge(clk)) then									-- enabled 
				
				-- divide by zero flag 
				if(unsigned(in_b) = 0) then									
					divide_by_zero_error := '1';
				else
					quotient := std_logic_vector(unsigned(a(size + scale_factor -1 downto 0)) / unsigned(b(size + scale_factor -1 downto 0)));
				end if;
				-- Overflow check
				if(quotient(22) = '1' or quotient(21)= '1'  or quotient(20)= '1'  or quotient(19)= '1'  
					or quotient(18)= '1'  or quotient(17)= '1'  or quotient(16)= '1')then 
					ovfl_flag := '1';
				end if;
				out64(size - 1 downto 0) := quotient(size - 1 downto 0);
				-- Sign check
				if(in_a(size-1) = '1' xor in_b(size-1) = '1' ) then
					out_neg := std_logic_vector(unsigned(not out64) + 1);
					out64 := out_neg;
				end if;
				-- zero flag 
				if(unsigned(out64(size+scale_factor-1 downto scale_factor)) = 0 and divide_by_zero_error ='0') then								
					zero_flag := '1';
				end if;

				-- positive flag
				posv_flag := not out64(size - 1) and not zero_flag and not divide_by_zero_error;			
				ready := '1';
			end if;																		
			err <= divide_by_zero_error or ovfl_flag;														
			zero <= zero_flag;																					
			posv <= posv_flag;																					
			done <= ready;
			out_c <= out64;			
		end PROCESS;
end architecture;

architecture first_algo of fpu_divider is
	constant scale_factor : integer := 7;																-- fixed scale factor
	constant size : integer := 16;																		-- operands' size
	signal Q: std_logic_vector(size -1 downto 0);
	signal F: std_logic_vector(scale_factor-1 downto 0);
begin
PROCESS(in_a,in_b,clk)
		
		variable zero_flag , posv_flag, ovfl_flag, divide_by_zero_error, ready : std_logic;
		variable sub, quotient, divider, shift : std_logic_vector(size + scale_factor -1 downto 0);
		variable a, b, out64 : std_logic_vector(4*size-1 downto 0);
		variable out_neg : std_logic_vector(4*size-1 downto 0);

		begin
			-- when enbl is 0 all outputs except err are reset , when rst is 1 all outputs are reset
			a := std_logic_vector(abs(signed(in_a)) sll scale_factor);
			b := std_logic_vector(abs(signed(in_b)));
			quotient 	:= (others => '0');
			divider		:= (others => '0');
			shift		:= (others => '0');
			sub	:= (others => '0');			
			out64	  	:= (others => '0');
			zero_flag 	:= '0';
			posv_flag 	:= '0';
			ovfl_flag 	:= '0';
			ready 		:= '0';

			if(rst = '1') then															-- reset signal
				divide_by_zero_error := '0';
			elsif(enbl = '1' and rising_edge(clk)) then									-- enabled 

				for i in 0 to size + scale_factor - 1 loop
					divider(0) := a(size + scale_factor - i - 1);
					if(divider < b(size + scale_factor - 1 downto 0)) then
						quotient(size + scale_factor - i - 1) := '0';
						ready:='0';
					else 
						quotient(size + scale_factor - i - 1) := '1';
						sub := std_logic_vector(unsigned(divider) - unsigned(b(size + scale_factor - 1 downto 0)));
						divider := sub;
						ready:='1';
					end if;
					shift := std_logic_vector(unsigned(divider) sll 1);
					divider := shift;
				end loop;
				-- Overflow check
				if(quotient(22) = '1' or quotient(21)= '1'  or quotient(20)= '1'  or quotient(19)= '1'  
					or quotient(18)= '1'  or quotient(17)= '1'  or quotient(16)= '1')then 
					ovfl_flag := '1';
				end if;
				out64(size - 1 downto 0) := quotient(size - 1 downto 0);
				-- Sign check
				if(in_a(size-1) = '1' xor in_b(size-1) = '1' ) then
					out_neg := std_logic_vector(unsigned(not out64) + 1);
					out64 := out_neg;
				end if;

				-- zero flag 
				if(unsigned(out64(size+scale_factor-1 downto scale_factor)) = 0) then								
					zero_flag := '1';
				end if;
				-- divide by zero flag 
				if(unsigned(in_b) = 0) then									
					divide_by_zero_error := '1';
				end if;
				-- positive flag
				posv_flag := not out64(size - 1) and not zero_flag;			
				ready := '1';
				out_c <= out64;
			end if;																		
			err <= divide_by_zero_error or ovfl_flag;														
			zero <= zero_flag;																					
			posv <= posv_flag;																					
			done <= ready;
			out_c <= out64;			
		end PROCESS;
end architecture;

