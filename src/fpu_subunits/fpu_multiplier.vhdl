library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity fpu_multiplier is
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

-- Multiplier implementation with operators
-- Used by other components temporarily until other algos architectures are done
architecture with_operators of fpu_multiplier is

constant scale_factor : integer := 7;																		-- fixed point fixed scale factor
signal error : std_logic := '0';																			-- latched error bit

begin
	PROCESS(in_a,in_b,clk,rst,enbl)
	variable output : std_logic_vector(31 downto 0);
	variable out64  : std_logic_vector(63 downto 0);
	variable zero_flag , posv_flag : std_logic;
	variable error_local : std_logic := error;
	begin
		-- these initializations are for reset and enable 
		-- when enbl is 0 all outputs except err are reset , when rst is 1 all outputs are reset
		zero_flag := '0';
		posv_flag := '0';
		out64	  := (others => '0');
		if(rst = '1') then																					-- reset signal
			error_local := '0';
		elsif(enbl = '1' and error = '0' and rising_edge(clk)) then											-- enabled 
			output(31 downto 0) := std_logic_vector(signed(in_a(15 downto 0))*signed(in_b(15 downto 0)));	-- fixed point multiplication output
			
			out64(15 downto 0)  := output((scale_factor+15) downto scale_factor);							-- taking the right bits
			
			error_local := not((((output(31) and output(30)) and (output(29) and output(28))) and ((output(27) and output(26)) and (output(25) and output(24))) and (output(23) and output(22))) 
				 or not (((output(31) or output(30)) or (output(29) or output(28))) or ((output(27) or output(26)) or (output(25) or output(24))) or (output(23) or output(22))));
																											-- overflow flag (error flag)
			out64(63 downto 16) := (others => output(31));													-- extending the signbit
			
			if(unsigned(output((scale_factor+15) downto scale_factor)) = 0) then							-- zero flag 
				zero_flag := '1';
			end if;
			posv_flag := not output(15) and not zero_flag;													-- positive output?
		end if;
		err <= error_local;																					-- storing the error for output
		error <= error_local;																				-- storing the error for latching 
		zero <= zero_flag;																					
		posv <= posv_flag;																					
		done <= enbl;
		out_c <= out64;
	end PROCESS;
end architecture;

architecture first_algo of fpu_multiplier is

constant scale_factor : integer := 7;																-- fixed point fixed scale factor
constant size : integer := 16;																		-- fixed point operands' size

signal error : std_logic := '0';
begin
	PROCESS(in_a,in_b,clk,rst,enbl)
	variable output : std_logic_vector(2*size-1 downto 0);
	variable out64  : std_logic_vector(4*size-1 downto 0);
	variable zero_flag , posv_flag : std_logic;
	variable error_local : std_logic := error;
	variable multiplier : std_logic_vector(size downto 0);
	begin
		-- these initializations are for reset and enable 
		-- when enbl is 0 all outputs except err are reset , when rst is 1 all outputs are reset
		zero_flag := '0';
		posv_flag := '0';
		multiplier:= (others => '0');
		output 	  := (others => '0');
		out64	  := (others => '0');
		if(rst = '1') then																			-- reset signal
			error_local := '0';
		elsif(enbl = '1' and error = '0' and clk='1') then											-- enabled 
		
			-- booth algorithm
			multiplier(size downto 1) := in_b(size-1 downto 0);
			for i in 0 to size-1 loop
				if multiplier(i+1 downto i) = "10" then												-- subtract the multiplicand
					output(i+size-1 downto i) := output(i+size-1 downto i) - in_a(size-1 downto 0);	-- use the implemented adder/subtractor when it's done
				elsif multiplier(i+1 downto i) = "01" then											-- add the multiplicand
					output(i+size-1 downto i) := output(i+size-1 downto i) + in_a(size-1 downto 0); -- use the implemented adder/subtractor when it's done
				end if;
				output(i+size) := output(i+size-1);													-- extending the sign bit while shifting
			end loop;
			
			-- output signals 
			out64(size-1 downto 0)  := output((scale_factor+size-1) downto scale_factor);			-- taking the right bits
			
			error_local := not((((output(31) and output(30)) and (output(29) and output(28))) and ((output(27) and output(26)) and (output(25) and output(24))) and (output(23) and output(22))) 
				 or not (((output(31) or output(30)) or (output(29) or output(28))) or ((output(27) or output(26)) or (output(25) or output(24))) or (output(23) or output(22))));
																									-- overflow flag (error flag)
			out64(63 downto 16) := (others => output(31));											-- extending the signbit
			
			if(unsigned(output((scale_factor+size-1) downto scale_factor)) = 0) then				-- zero flag 
				zero_flag := '1';
			end if;
			posv_flag := not output(size-1) and not zero_flag;										-- positive output?
		end if;
		err <= error_local;																			-- storing the error for output
		error <= error_local;																		-- storing the error for latching 
		zero <= zero_flag;																					
		posv <= posv_flag;																					
		done <= enbl;
		out_c <= out64;
	end PROCESS;
end architecture;

architecture sec_algo of fpu_multiplier is
begin
-- TODO: implement second algo
end architecture;