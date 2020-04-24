library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


package solver_pkg is
------------------------------------------------GLOBAL SIGNALS------------------------------------------
	




------------------------------------------------IO PROCEDURES---------------------------------------------------
	procedure read_before_write_reg(
			signal data_out : out std_logic_vector(63 downto 0);
			signal reg_data_out : in std_logic_vector(31 downto 0);
			signal reg_adrs: inout std_logic_vector;
			signal read_enbl : out std_logic;
			signal write_enbl : in std_logic;
			signal fsm : inout  std_logic_vector(1 downto 0)
			);

	--procedure read_reg_inc_adrs_twice(	
	--		signal data_out : out std_logic_vector(63 downto 0);
	--		signal reg_data_out : in std_logic_vector(31 downto 0);
	--		signal reg_adrs: inout std_logic_vector;
	--		signal read_enbl : out std_logic;
	--		signal write_enbl : in std_logic;
	--		signal fsm : inout  std_logic_vector(1 downto 0)
	--		);
	procedure read_reg_inc_adrs_once(	
			signal data_out : out std_logic_vector(31 downto 0);
			signal reg_data_out : in std_logic_vector(31 downto 0);
			signal reg_adrs: inout std_logic_vector;
			signal read_enbl : out std_logic;
			signal write_enbl : in std_logic;
			signal fsm : inout  std_logic_vector(1 downto 0);
			signal mode: in std_logic_vector(1 downto 0)
			);

	procedure write_after_read_reg(
			signal data_in: in std_logic_vector(63 downto 0);
			signal reg_data_in : out std_logic_vector(31 downto 0);
			signal reg_adrs: inout std_logic_vector;
			signal read_enbl : in std_logic;
			signal write_enbl : out std_logic;
			signal fsm : inout  std_logic_vector(1 downto 0)
			);

	procedure outing(
		--what belongs to system:
		signal mode: in std_logic_vector(1 downto 0);
		signal main_adr: inout std_logic_vector(15 downto 0);
		signal data_bus: out std_logic_vector(31 downto 0);
		--what belongs to x_ware
		signal x_ware_data_out: in std_logic_vector(31 downto 0);
		signal x_ware_address: inout std_logic_vector;
		signal read_enbl : out std_logic;
		signal write_enbl : in std_logic;
		--what the procedure nedds
		signal c_ware : in  std_logic_vector(2 downto 0);
		signal fsm : inout  std_logic_vector(2 downto 0);
		signal N_X_A_B: in std_logic_vector(5 downto 0);
		--what the procedure use as variables
		signal fsm_read: inout std_logic_vector(1 downto 0);
		signal N_X_A_B_counter: inout std_logic_vector(5 downto 0);
		signal c_ware_vec: inout std_logic_vector(2 downto 0)
			);

	procedure x_ware_find_address (
		signal c_ware: in  std_logic_vector(2 downto 0);
		signal x_ware_address: out std_logic_vector(9 downto 0);
		signal x_address_out: out std_logic_vector(15 downto 0)
		);


	procedure mul_L_9 (
		signal mode: in std_logic_vector(1 downto 0);
		signal L_tol: in  std_logic_vector(63 downto 0);
		signal L_nine: out  std_logic_vector(63 downto 0);
		signal fpu_mul_1_in_1, fpu_mul_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_mul_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_mul_1 : out std_logic ;
		signal done_mul_1 : in std_logic ;
		signal fsm : inout std_logic);


	procedure proc_run_err_h_L (
		signal mode: in std_logic_vector(1 downto 0);
		signal h_adapt, L_nine: in  std_logic_vector(63 downto 0);
		signal fpu_mul_1_in_1, fpu_mul_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_mul_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_mul_1 : out std_logic ;
		signal done_mul_1 : in std_logic ;
		signal fpu_div_1_in_1, fpu_div_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_div_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_div_1 : out std_logic ;
		signal done_div_1 : in std_logic ;
		
		signal err_sum : inout  std_logic_vector(63 downto 0);
		signal fsm : inout std_logic_vector(1 downto 0)
		);

	procedure div_h_2 (
		signal mode: in std_logic_vector(1 downto 0);
		signal h_adapt: in  std_logic_vector(63 downto 0);
		signal h_div: out  std_logic_vector(63 downto 0);
		signal fpu_div_1_in_1, fpu_div_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_div_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_div_1 : out std_logic ;
		signal done_div_1 : in std_logic ;
		signal fsm : inout std_logic
		);


	procedure mul_N_N_and_M_N (
		
		signal N_vec,M_vec: in  std_logic_vector(5 downto 0);
		signal N_N_vec,N_M_vec: out  std_logic_vector(11 downto 0)
		);



end package solver_pkg;

package body solver_pkg is 
----------------------------------------------------IO PROCEDURES BODY-----------------------------------
	procedure read_before_write_reg(
		signal data_out : out std_logic_vector(63 downto 0);
		signal reg_data_out : in std_logic_vector(31 downto 0);

		signal reg_adrs: inout std_logic_vector;

		signal read_enbl : out std_logic;
		signal write_enbl : in std_logic;
		signal fsm : inout  std_logic_vector(1 downto 0)
			) is
		begin

			if fsm = "11" then
				if write_enbl = '0' then
					read_enbl <= '1';
					fsm <= "01";
				end if;
			elsif fsm = "01" then
				if write_enbl = '0' then
					read_enbl <= '1';
					reg_adrs <= to_vec(to_int(reg_adrs) + 1, reg_adrs'length);
					data_out(63 downto 32) <= reg_data_out;
					fsm <= "10";
				end if;

			elsif fsm = "10" then
				data_out(31 downto 0) <= reg_data_out;	
				reg_adrs <= to_vec(to_int(reg_adrs) - 1,reg_adrs'length);
				read_enbl <= '0';
				fsm <= "00";
			end if;
			
		end read_before_write_reg;

	procedure write_after_read_reg(
		signal data_in: in std_logic_vector(63 downto 0);
		signal reg_data_in : out std_logic_vector(31 downto 0);
		signal reg_adrs: inout std_logic_vector;
		signal read_enbl : in std_logic;
		signal write_enbl : out std_logic;
		signal fsm : inout  std_logic_vector(1 downto 0)
		) is
		begin

			if fsm = "11" then
				if read_enbl = '0' then
					write_enbl <= '1';
					reg_data_in <= data_in(63 downto 32);
					--reg_adrs <= to_vec(to_int(reg_adrs) + 1,7);
					fsm <= "01";
				end if;
			elsif fsm = "01" then
				if read_enbl = '0' then
					write_enbl <= '1';
					reg_data_in <= data_in(31 downto 0);
					reg_adrs <= to_vec(to_int(reg_adrs) + 1,reg_adrs'length);
					fsm <= "10";
				end if;

			elsif fsm = "10" then
				reg_adrs <= to_vec(to_int(reg_adrs) + 1,reg_adrs'length);
				write_enbl <= '0';
				fsm <= "00";
			end if;
			
		end write_after_read_reg;	


	procedure read_reg_inc_adrs_once(
		signal data_out : out std_logic_vector(31 downto 0);
		signal reg_data_out : in std_logic_vector(31 downto 0);
		signal reg_adrs: inout std_logic_vector;
		signal read_enbl : out std_logic;
		signal write_enbl : in std_logic;
		signal fsm : inout  std_logic_vector(1 downto 0);
		signal mode: in std_logic_vector(1 downto 0)
		) is
		begin

		if fsm = "11" then
			if write_enbl = '0' then
				read_enbl <= '1';
				fsm <= "01";
			end if;
		elsif fsm = "01" then
			if write_enbl = '0' then
				read_enbl <= '0';
				if mode = "10" then
					--fp64
					reg_adrs <= to_vec(to_int(reg_adrs) + 1,reg_adrs'length);
				else
					--fp16 and fp32
					reg_adrs <= to_vec(to_int(reg_adrs) + 2,reg_adrs'length);
				end if;
				data_out <= reg_data_out;
				fsm <= "00";
			end if;

		end if;
		
		end read_reg_inc_adrs_once;

	procedure outing(
		--what belongs to system:
		signal mode: in std_logic_vector(1 downto 0);
		signal main_adr: inout std_logic_vector(15 downto 0);
		signal data_bus: out std_logic_vector(31 downto 0);
		--what belongs to x_ware
		signal x_ware_data_out: in std_logic_vector(31 downto 0);
		signal x_ware_address: inout std_logic_vector;
		signal read_enbl : out std_logic;
		signal write_enbl : in std_logic;
		--what the procedure nedds
		signal c_ware : in  std_logic_vector(2 downto 0);
		signal fsm : inout  std_logic_vector(2 downto 0);
		signal N_X_A_B: in std_logic_vector(5 downto 0);
		--what the procedure use as variables
		signal fsm_read: inout std_logic_vector(1 downto 0);
		signal N_X_A_B_counter: inout std_logic_vector(5 downto 0);
		signal c_ware_vec: inout std_logic_vector(2 downto 0)

		) is 
		
		begin
			case( fsm ) is
			
				when "111" =>
					c_ware_vec <= "000";
					x_ware_find_address
						(c_ware => c_ware_vec,
						x_address_out => main_adr,
						x_ware_address => x_ware_address);
					fsm_read <= (others => '1');
					N_X_A_B_counter <= (others => '0');
					fsm <= "001";
				when "001" =>
					--reads 32 bits always
					read_reg_inc_adrs_once
						(
						data_out => data_bus,
						reg_data_out=>x_ware_data_out,
						reg_adrs => x_ware_address,
						read_enbl => read_enbl,
						fsm => fsm_read,
						write_enbl => write_enbl,
						mode => mode);
					if fsm_read = "00" then
						main_adr <= to_vec(to_int(main_adr) + 1,main_adr'length);
						fsm <= "010";
					end if;
				when "010" =>
					--check N
					N_X_A_B_counter <= to_vec(to_int(N_X_A_B_counter) + 1,6);
					fsm <= "011";
				when "011" =>
					if N_X_A_B_counter = N_X_A_B then
						--check on c_Ware
						c_ware_vec <= to_vec(to_int(c_ware_vec) + 1,3);
						fsm <= "100";
					else
						--go back to read and send
						fsm_read <= (others => '1');
						fsm <= "001";
					end if;
				when "100" =>
					if c_ware_vec = c_ware then
						--we are done
						fsm <= (others => '0');
					else
						--no, not yet

						fsm <= "111";
					end if;

				when others =>
					--exit...
					null;
			end case ;
		end outing;

	procedure x_ware_find_address (
		signal c_ware: in  std_logic_vector(2 downto 0);
		signal x_ware_address: out std_logic_vector(9 downto 0);
		signal x_address_out: out std_logic_vector(15 downto 0)
		)is

		begin

			case(c_ware) is
            when "000" =>
                x_ware_address <= (others => '0');
                x_address_out <= x"2779";
            when "001" =>
                x_ware_address <= "0001100100";
                x_address_out <= x"27DD";
            when "010" =>
                x_ware_address <=  "0011001000";
                x_address_out <= x"2841";
            when "011" =>
                x_ware_address <=  "0100101100";
                x_address_out <= x"28A5";
            when "100" =>
                x_ware_address <=  "0110010000";
                x_address_out <= x"2909";
            when "101" =>
                x_ware_address <=  "0111110100";
            when others =>
                null;
        end case ;


		end x_ware_find_address;
----------------err---------------------
	procedure mul_L_9 (
		signal mode: in std_logic_vector(1 downto 0);
		signal L_tol: in  std_logic_vector(63 downto 0);
		signal L_nine: out  std_logic_vector(63 downto 0);
		signal fpu_mul_1_in_1, fpu_mul_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_mul_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_mul_1 : out std_logic ;
		signal done_mul_1 : in std_logic ;
		signal fsm : inout std_logic
		)is

		begin
			case( fsm ) is
			
				when '1' =>
					enable_mul_1 <= '1';
                    fpu_mul_1_in_1 <= L_tol;
                    case( mode ) is
                    	when "00" =>
                    		fpu_mul_1_in_2 <= (others => '0');
                            fpu_mul_1_in_2(7 downto 0) <= "01110011";
                    	when "01" =>
                    		fpu_mul_1_in_2 <= (others => '0');
                            fpu_mul_1_in_2(31 downto 0) <= "00111111011001100110011001100110";
                    	when others =>
                    		fpu_mul_1_in_2 <= "0011111111101100110011001100110011001100110011001100110011001101";
                    end case ;
                    L_nine <= fpu_mul_1_out;
                    ------------------------ERROR here ya EV, check FPU_MUL------------------
                    if done_mul_1 = '1' then
                    	enable_mul_1 <= '0';
                    	fsm <= '0';
                    end if;
				when others =>
					--00
					null;
			end case ;
		end mul_L_9;

	--gets err_sum
	--and returns err_sum = (h*h*L9)/err_sum
	----------err------------
	procedure proc_run_err_h_L (
		signal mode: in std_logic_vector(1 downto 0);
		signal h_adapt, L_nine: in  std_logic_vector(63 downto 0);
		signal fpu_mul_1_in_1, fpu_mul_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_mul_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_mul_1 : out std_logic ;
		signal done_mul_1 : in std_logic ;
		signal fpu_div_1_in_1, fpu_div_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_div_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_div_1 : out std_logic ;
		signal done_div_1 : in std_logic ;
		
		signal err_sum : inout  std_logic_vector(63 downto 0);
		signal fsm : inout std_logic_vector(1 downto 0)
		)is

		begin
			case( fsm ) is
			
				when "11" =>
					--start the mul and div together
					enable_mul_1<='1';
                    fpu_mul_1_in_1 <= h_adapt;
                    fpu_mul_1_in_2 <= h_adapt;

                    enable_div_1 <= '1';
                    fpu_div_1_in_1 <= L_nine;
                    fpu_div_1_in_2 <= err_sum;

                    if done_mul_1 = '1' and done_div_1 = '1' then
                    	enable_div_1 <= '0';
                    	enable_mul_1<='0';
                    	fsm <= "01";
                    end if;

                when "01" =>
                	fpu_mul_1_in_1 <= fpu_div_1_out;
                    fpu_mul_1_in_2 <= fpu_mul_1_out;
                    enable_mul_1<= '1';
                    if done_mul_1 = '1' then
                    	--enable_mul_1<= '0';
                    	fsm <= "10";
                    end if;
                when "10" =>
                	err_sum <= fpu_mul_1_out;
                    enable_mul_1<= '0';
                    fsm <= "00";
 				when others =>
					--00
					null;
			end case ;

		end proc_run_err_h_L;
---------------err------------
	procedure div_h_2 (
		signal mode: in std_logic_vector(1 downto 0);
		signal h_adapt: in  std_logic_vector(63 downto 0);
		signal h_div: out  std_logic_vector(63 downto 0);
		signal fpu_div_1_in_1, fpu_div_1_in_2 : out std_logic_vector(64 - 1 downto 0) ;
		signal fpu_div_1_out : in std_logic_vector(64 - 1 downto 0) ;
		signal enable_div_1 : out std_logic ;
		signal done_div_1 : in std_logic ;
		signal fsm : inout std_logic
		)is

		begin
			case( fsm ) is
			
				when '1' =>
					enable_div_1 <= '1';
                    fpu_div_1_in_1 <= h_adapt;
                    case( mode ) is
                    	when "00" =>
                    		fpu_div_1_in_2 <= (others => '0');
                            fpu_div_1_in_2(15 downto 0) <= "0000000100000000";
                    	when "01" =>
                    		fpu_div_1_in_2 <= (others => '0');
                            fpu_div_1_in_2(31 downto 0) <= "01000000000000000000000000000000";
                    	when others =>
                    		fpu_div_1_in_2(63 downto 0) <= "0100000000000000000000000000000000000000000000000000000000000000";
                    end case ;
                    ----------------error---------------------
                    if done_div_1 = '1' then
                    	enable_div_1 <= '0';
                    	h_div <= fpu_div_1_out;
                    	fsm <= '0';
                    end if;
				when others =>
					--00
					null;
			end case ;
		end div_h_2;

	procedure mul_N_N_and_M_N (
		
		signal N_vec,M_vec: in  std_logic_vector(5 downto 0);
		signal N_N_vec,N_M_vec: out  std_logic_vector(15 downto 0)
		)is

		begin
			N_N_vec <= to_vec ( to_int(N_vec)* to_int(N_vec) ,N_N_vec'length);
			N_M_vec <= to_vec ( to_int(N_vec)* to_int(M_vec) ,N_M_vec'length);
			
		end mul_N_N_and_M_N;



	procedure 
end package body solver_pkg;