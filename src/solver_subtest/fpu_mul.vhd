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
        rst            : in std_logic;
       -- interp_done_op : in std_logic_vector(1 downto 0);
        in_data        : inout std_logic_vector(WORD_LENGTH - 1 downto 0);
        adr            : inout std_logic_vector(ADDR_LENGTH - 1 downto 0)
        --interrupt      : out std_logic;
        --error_success  : out std_logic
    );
end entity;

architecture rtl of solver_test is
    --signal X_intm_rd,first_time, X_intm_wr : std_logic    := '0';
    --signal X_intm_address : std_logic_vector(6 downto 0) := (others => '0');
    --signal X_intm_data_in, X_intm_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    --signal fsm_write : std_logic_vector(1 downto 0) := (others => '0');

    signal x_temp : std_logic_vector(63 downto 0) := (others => '1');
    --signal x_temp_2 : std_logic_vector(63 downto 0) := X"1111111122222222";
    
    signal main_fsm, fsm_out : std_logic_vector(1 downto 0) := (others => '0');
    signal N_counter: std_logic_vector(5 downto 0) := "000101";
    --signal M_counter: std_logic_vector(5 downto 0) := "000010";
    --signal N_N_vec : std_logic_vector(11 downto 0) := (others => '0');
    --signal N_M_vec : std_logic_vector(11 downto 0) := (others => '0');
    
    --signal N_counter_2: std_logic_vector(5 downto 0) := (others => '0');
    signal mode_sig : std_logic_vector(1 downto 0) := "00";
    --signal wares : std_logic_vector(2 downto 0) := "001";
    --signal procedure_dumm : std_logic_vector(10 downto 0) := (others => '0');
    --signal fsm_mul : std_logic := '0';
    
    signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic                                  := '0';
    
    signal fpu_div_1_in_1, fpu_div_1_in_2, fpu_div_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_div_1, err_div_1, zero_div_1, posv_div_1, enable_div_1 : std_logic                                  := '0';
    
    signal h_adapt : std_logic_vector(63 downto 0) := X"0000000000000280";
    signal L_tol: std_logic_vector(63 downto 0) := X"0000000000000080";

    signal L_nine: std_logic_vector(63 downto 0) := (others => '0');

    signal fsm_run_h_L : std_logic_vector(1 downto 0) := (others => '0');
    signal err_sum : std_logic_vector(63 downto 0) := X"0000000000000080";

    begin
    --X_i : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
    --    port map(
    --        clk      => clk,
    --        rd       => X_intm_rd,
    --        wr       => X_intm_wr,
    --        address  => X_intm_address,
    --        data_in  => X_intm_data_in,
    --        data_out => X_intm_data_out,
    --        rst      => rst
    --    );
    
        fpu_mul_1 : entity work.fpu_multiplier(first_algo)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_mul_1,
            in_a      => fpu_mul_1_in_1,
            in_b      => fpu_mul_1_in_2,
            out_c     => fpu_mul_1_out,
            done      => done_mul_1,
            err       => err_mul_1,
            zero      => zero_mul_1,
            posv      => posv_mul_1
        );

        fpu_div_1 : entity work.fpu_divider(first_algo)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_div_1,
            in_a      => fpu_div_1_in_1,
            in_b      => fpu_div_1_in_2,
            out_c     => fpu_div_1_out,
            done      => done_div_1,
            err       => err_div_1,
            zero      => zero_div_1,
            posv      => posv_div_1
        );

    main_proc : process(clk, rst)
    begin
        if rst = '0' and rising_edge(clk) then
            --Fill X_i with data..
            case( main_fsm ) is
                when "00" => 
                    --mul_N_N_and_M_N (
                    --    N_vec => N_counter,
                    --    M_vec => M_counter,
                    --    N_N_vec => N_N_vec,
                    --    N_M_vec => N_M_vec
                    --    );
                    --h_adapt <= to_vec(10,h_adapt'length);
                    --L_tol <= to_vec(10,L_tol'length);
                    fsm_run_h_L <= "11";
                    main_fsm <= "01";
                    --fsm_mul <= '1';
                when "01" =>
                    
                    proc_run_err_h_L(
                         mode => mode_sig,
                        h_adapt => h_adapt,
                        L_nine => L_nine,
                        fpu_mul_1_in_1 => fpu_mul_1_in_1,
                        fpu_mul_1_in_2 => fpu_mul_1_in_2,
                        fpu_mul_1_out => fpu_mul_1_out,
                        enable_mul_1 => enable_mul_1,
                        done_mul_1 => done_mul_1,
                        fpu_div_1_in_1 => fpu_div_1_in_1,
                        fpu_div_1_in_2 => fpu_div_1_in_2,
                        fpu_div_1_out => fpu_div_1_out,
                        enable_div_1 => enable_div_1,
                        done_div_1 => done_div_1,
                        err_sum => err_sum,
                        --for testing
                        ev => x_temp,
                        fsm => fsm_run_h_L
                        );

                    if fsm_run_h_L = "00" then
                        main_fsm <= "11";
                    end if;
		
		when others =>
			null;
            end case ;
            
        end if;
    end process ;   

end architecture;

