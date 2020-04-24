library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


package solver_pkg is
------------------------------------------------PROCEDURES DECLARATION------------------------------------------
------------------------------------------------IO PROCEDURES---------------------------------------------------
	procedure read_before_write_reg(
			signal data_out : out std_logic_vector(63 downto 0);
			signal reg_data_out : in std_logic_vector(31 downto 0);
			signal reg_adrs: inout std_logic_vector;
			signal read_enbl : out std_logic;
			signal write_enbl : in std_logic;
			signal fsm : inout  std_logic_vector(1 downto 0)
			);

	procedure read_reg_inc_adrs(	
			signal data_out : out std_logic_vector(63 downto 0);
			signal reg_data_out : in std_logic_vector(31 downto 0);
			signal reg_adrs: inout std_logic_vector;
			signal read_enbl : out std_logic;
			signal write_enbl : in std_logic;
			signal fsm : inout  std_logic_vector(1 downto 0)
			);

	procedure write_after_read_reg(
			signal data_in: in std_logic_vector(63 downto 0);
			signal reg_data_in : out std_logic_vector(31 downto 0);
			signal reg_adrs: inout std_logic_vector;
			signal read_enbl : in std_logic;
			signal write_enbl : out std_logic;
			signal fsm : inout  std_logic_vector(1 downto 0)
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

	procedure read_reg_inc_adrs(
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
				reg_adrs <= to_vec(to_int(reg_adrs) + 1,16);
				data_out(63 downto 32) <= reg_data_out;
				fsm <= "10";
			end if;

		elsif fsm = "10" then
			data_out(31 downto 0) <= reg_data_out;	
			reg_adrs <= to_vec(to_int(reg_adrs) + 1,16);
			read_enbl <= '0';
			fsm <= "00";
		end if;
		
		end read_reg_inc_adrs;


end package body solver_pkg;