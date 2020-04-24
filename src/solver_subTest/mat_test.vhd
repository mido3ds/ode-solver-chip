library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.solver_pkg.all;


entity solver_test is
    generic (
        WORD_LENGTH : integer := 32;
        ADDR_LENGTH : integer := 16;
        MAX_LENGTH  : integer := 64
    );

    port (
        --in_state       : in std_logic_vector(1 downto 0); --state signal sent from CPU
        clk            : in std_logic;
        rst            : in std_logic
       -- interp_done_op : in std_logic_vector(1 downto 0);
       -- in_data        : inout std_logic_vector(WORD_LENGTH - 1 downto 0);
        --adr            : inout std_logic_vector(ADDR_LENGTH - 1 downto 0);
        --interrupt      : out std_logic;
        --error_success  : out std_logic
    );
end entity;

architecture rtl of solver_test is
	signal X_intm_rd,first_time, X_intm_wr : std_logic    := '0';
   	signal X_intm_address : std_logic_vector(6 downto 0) := (others => '0');
	signal X_intm_data_in, X_intm_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
	signal fsm_read,fsm_write,main_fsm : std_logic_vector(1 downto 0) := (others => '0');

	signal x_temp,x_temp_3 : std_logic_vector(63 downto 0) := (others => '1');
	signal x_temp_2 : std_logic_vector(63 downto 0) := X"1111111122222222";
	




	begin
	X_i : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
        port map(
            clk      => clk,
            rd       => X_intm_rd,
            wr       => X_intm_wr,
            address  => X_intm_address,
            data_in  => X_intm_data_in,
            data_out => X_intm_data_out,
            rst      => rst
        );
	
	main_proc : process(clk, rst)
    begin
        if rst = '0' and rising_edge(clk) then
        	--if fsm_read = "00" then
        	case( main_fsm ) is
        		

        	end case;
        	
	       
	        
		end if;
    end process ;
	
	

end architecture;

