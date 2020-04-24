library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.solver_pkg.all;
-----------------------------------------------------------------ENTITY-----------------------------------------------------------------------------------
entity solver is
    generic (
        WORD_LENGTH : integer := 32;
        ADDR_LENGTH : integer := 16;
        MAX_LENGTH  : integer := 64
    );

    port (
        in_state       : in std_logic_vector(1 downto 0); --state signal sent from CPU
        clk            : in std_logic;
        rst            : in std_logic;
        interp_done_op : in std_logic_vector(1 downto 0);
        in_data        : inout std_logic_vector(WORD_LENGTH - 1 downto 0);
        adr            : inout std_logic_vector(ADDR_LENGTH - 1 downto 0);
        interrupt      : out std_logic;
        error_success  : out std_logic
    );
end entity;

-----------------------------------------------------------------ARCHITECTURE-----------------------------------------------------------------------------------
architecture rtl of solver is
-----------------------------------------------------------------SIGNALS-----------------------------------------------------------------------------------
    --SIGNALS FOR UNITS
    --FPU MUL 1
    --signal operation_sig_1                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic                                  := '0';
    --FPU ADD 1
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1, thisIsAdder_1 : std_logic                                  := '0';

    --FPU ADD 2
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_add_2_in_1, fpu_add_2_in_2, fpu_add_2_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_add_2, err_add_2, zero_add_2, posv_add_2, enable_add_2, thisIsAdder_2 : std_logic                                  := '0';
    --FPU DIV 1
    signal fpu_div_1_in_1, fpu_div_1_in_2, fpu_div_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_div_1, err_div_1, zero_div_1, posv_div_1, enable_div_1 : std_logic                                  := '0';

    --FPU ADD 3
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    --signal fpu_add_3_in_1, fpu_add_3_in_2, fpu_add_3_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    --signal done_add_3, err_add_3, zero_add_3, posv_add_3, enable_add_3, thisIsAdder_3 : std_logic                                  := '0';

    --FPU SUB 3
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    --signal fpu_sub_1_in_1, fpu_sub_1_in_2, fpu_sub_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    --signal done_sub_1, err_sub_1, zero_sub_1, posv_sub_1, enable_sub_1 : std_logic                                  := '0';

    --ADDRESS INCREMENTOR 1, ADDR_LENGTH is the maximum..
    signal address_inc_1_in, address_inc_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal address_inc_1_enbl : std_logic := '0';
    
    signal address_dec_1_in, address_dec_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal address_dec_1_enbl : std_logic := '0';

    signal address_inc_2_in, address_inc_2_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal address_inc_2_enbl : std_logic := '0';
    
    signal address_dec_2_in, address_dec_2_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal address_dec_2_enbl : std_logic := '0';


    signal int_adder_1_in_1,int_adder_1_in_2,int_adder_1_out: std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal int_adder_1_enbl, int_adder_1_cin, int_adder_1_cout: std_logic := '0';

    signal int_mul_1_in_1, int_mul_1_in_2, int_mul_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal int_mul_1_enbl : std_logic := '0';

    --Memory signals:
    --RD/WR:
    signal U_main_rd, U_main_wr                                        : std_logic                                  := '0';
    --signal U_sub_rd, U_sub_wr                                          : std_logic                                  := '0';
    signal X_ware_rd, X_ware_wr                                        : std_logic                                  := '0';
    signal a_coeff_rd, a_coeff_wr                                      : std_logic                                  := '0';
    signal b_coeff_rd, b_coeff_wr                                      : std_logic                                  := '0';
    signal X_intm_rd, X_intm_wr                                        : std_logic                                  := '0';
    
    --Address:
    signal U_main_address                                              : std_logic_vector(6 downto 0) := (others => '0');
    --signal U_sub_address                                               : std_logic_vector(6 downto 0) := (others => '0');
    signal X_ware_address                                              : std_logic_vector(9 downto 0) := (others => '0');
    signal a_coeff_address                                             : std_logic_vector(12 downto 0) := (others => '0');
    signal b_coeff_address                                             : std_logic_vector(12 downto 0) := (others => '0');
    signal X_intm_address                                              : std_logic_vector(6 downto 0) := (others => '0');
    
    --DATA in and out:
    signal U_main_data_in, U_main_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    --signal U_sub_data_in, U_sub_data_out                               : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal X_ware_data_in, X_ware_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal a_coeff_data_in, a_coeff_data_out                           : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal b_coeff_data_in, b_coeff_data_out                           : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal X_intm_data_in, X_intm_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    
    --Solver module's signals:
    
    --range [0:5], acts like a pointer to X_ware
    --fp16, fp32, fp64
    signal mode_sig     : std_logic_vector(1 downto 0)               := "00";
    --declaring this fpu_adder unit as adder or subtractor
    --N, used in looping at X, A, B
    --signal N_X_A_B : integer range 0 to 50 ;
    signal N_X_A_B_vec : std_logic_vector(15 downto 0) := (others => '0');
    --M, used in looping at B, U
    --signal M_U_B :  integer range 0 to 50 ;
    signal M_U_B_vec :  std_logic_vector(15 downto 0) := (others => '0');
    --FIXED or VAR
    signal fixed_or_var : std_logic  := '0';
    --T_size
    signal t_size :  std_logic_vector(2 downto 0) := "000";
    --N*M, needed in looping at B
    --signal N_M:  integer range 0 to 2500 ;
    signal N_M: std_logic_vector(15 downto 0) :=(others => '0');
    signal N_N: std_logic_vector(15 downto 0) :=(others => '0');
    --N*N, needed in looping at A
    --signal N_N:  integer range 0 to 2500 ;
    --run a and b processes
    signal a_high, read_a_coeff,write_a_coeff, increment_a_address,decrement_a_address : std_logic  := '0';
    signal a_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal result_a_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    
    --X_C
    signal x_high, read_x, write_x, increment_x_address, decrement_x_address : std_logic  := '0';
    signal result_x_temp,x_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    --X_i
    signal x_i_high, read_x_i, write_x_i, increment_x_i_address, decrement_x_i_address : std_logic  := '0';
    signal result_x_i_temp,x_i_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');

    --U_main
    signal u_main_high, read_u_main, write_u_main, increment_u_main_address, decrement_u_main_address : std_logic  := '0';
    signal result_u_main_temp, u_main_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');

    --signal N_N_temp: integer range 0 to 2500 ;
    --read h
    --signal read_h_please,h_is_read,h_high : std_logic  := '0';
    signal h_main, L_tol,L_nine : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal h_high, L_high : std_logic  := '0'; -- You don't need them ,just listen to both addresses..

    signal h_doubler : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal h_adapt : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal h_div : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');

    signal err_sum : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    
    
    --run b processes
    signal b_high, read_b_coeff, write_b_coeff ,increment_b_address, decrement_b_address: std_logic  := '0';
    signal b_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal result_b_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');


    signal fsm_run_h_b   : std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_h_a   : std_logic_vector(3 downto 0) := (others => '0');
    signal fsm_main_eq   : std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_x_h   : std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_x_i_c : std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_var_step_main : std_logic_vector(4 downto 0) := (others => '0');
    signal fsm_run_L_nine : std_logic_vector(1 downto 0) := (others => '0');
    signal fsm_run_mul_n_m : std_logic_vector(1 downto 0) := "00";
    signal fsm_run_err_h_L : std_logic_vector(1 downto 0) := "00";
    signal fsm_run_h_2 : std_logic_vector(1 downto 0) := "00";
    signal fsm_run_sum_err : std_logic_vector(3 downto 0) := "0000";
    signal fsm_h_sent_U_recv : std_logic_vector(2 downto 0) := "000";     
    signal fsm_send_h_init :  std_logic_vector(1 downto 0) := "00";
    signal fsm_run_a_x: std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_x_b_u: std_logic_vector(3 downto 0) := (others => '0');
    signal fsm_run_a_x_2: std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_x_b_u_2: std_logic_vector(3 downto 0) := (others => '0');
    signal fsm_place_x_i_at_x_c_or_vv: std_logic_vector(2 downto 0) := (others => '0');
    signal fixed_point_state: std_logic_vector(3 downto 0) := (others => '0'); --fixed point FSM states
    signal fsm_terminate: std_logic_vector(1 downto 0) := (others => '0');
    signal fsm_outing: std_logic_vector(3 downto 0) := (others => '0');

    --fixed point special signals
    --Like a pointer at X_ware, once it changes address value is updated
    signal c_ware :  std_logic_vector(2 downto 0) := (others => '0');
    signal listen_to_me:  std_logic  := '0';
    signal div_or_zero, div_or_adapt: std_logic  := '0';
    signal from_i_to_c, error_tolerance_is_good: std_logic  := '0';

    --ITERATORS
    signal N_Counter, N_Counter_2, N_M_counter, N_N_counter, N_N_counter_2, N_incremented : std_logic_vector(15 downto 0) := (others => '0'); 
    signal M_Counter : std_logic_vector(15 downto 0) := (others => '0'); 
    signal beenThere_1, beenThere_2, beenThere_3, addThisError, write_high_low : std_logic  := '0';
    signal new_entry : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal to_write : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal x_address_out : std_logic_vector(ADDR_LENGTH-1 downto 0) := (others => '0');
    signal interp_done_sig : std_logic_vector(1 downto 0) := (others => '0');

begin
-----------------------------------------------------------------PORT MAPS-----------------------------------------------------------------------------------
    --FPUs:
    fpu_mul_1 : entity work.fpu_multiplier
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
    fpu_add_1 : entity work.fpu_adder
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_add_1,
            in_a      => fpu_add_1_in_1,
            in_b      => fpu_add_1_in_2,
            out_c     => fpu_add_1_out,
            done      => done_add_1,
            err       => err_add_1,
            zero      => zero_add_1,
            posv      => posv_add_1,
            add_sub   => thisIsAdder_1
        );
    fpu_add_2 : entity work.fpu_adder
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_add_2,
            in_a      => fpu_add_2_in_1,
            in_b      => fpu_add_2_in_2,
            out_c     => fpu_add_2_out,
            done      => done_add_2,
            err       => err_add_2,
            zero      => zero_add_2,
            posv      => posv_add_2,
            add_sub   => thisIsAdder_2
        );
    fpu_div_1 : entity work.fpu_divider
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
    
    --Integer operators:
    address_inc_1 : entity work.incrementor generic map (N => ADDR_LENGTH)
        port map(
            a      => address_inc_1_in,
            c      => address_inc_1_out,
            enbl   => address_inc_1_enbl
        );

    address_dec_1 : entity work.decrementor generic map (N => ADDR_LENGTH)
        port map(
            a      => address_dec_1_in,
            c      => address_dec_1_out,
            enbl   => address_dec_1_enbl
        );

    address_inc_2 : entity work.incrementor generic map (N => ADDR_LENGTH)
        port map(
            a      => address_inc_2_in,
            c      => address_inc_2_out,
            enbl   => address_inc_2_enbl
        );

    address_dec_2 : entity work.decrementor generic map (N => ADDR_LENGTH)
        port map(
            a      => address_dec_2_in,
            c      => address_dec_2_out,
            enbl   => address_dec_2_enbl
        );

    int_adder_1 : entity work.int_adder generic map (N => ADDR_LENGTH, M => ADDR_LENGTH)
        port map(
            a       =>  int_adder_1_in_1,
            b       =>  int_adder_1_in_2,
            enbl    =>  int_adder_1_enbl,
            cin     =>  int_adder_1_cin,
            c       =>  int_adder_1_out,
            cout    =>  int_adder_1_cout
        );
    int_mul_1 : entity work.int_multiplier generic map (N => ADDR_LENGTH, M => ADDR_LENGTH)
        port map(
            a       =>  int_mul_1_in_1,
            b       =>  int_mul_1_in_2,
            enbl    =>  int_mul_1_enbl,
            c       =>  int_mul_1_out
        );

    --MEMORIES:
    -- U_main
    U_main : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
        port map(
            clk      => clk,
            rd       => U_main_rd,
            wr       => U_main_wr,
            address  => U_main_address,
            data_in  => U_main_data_in,
            data_out => U_main_data_out,
            rst      => rst
        );
    -- U_sub
    --U_sub : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
    --    port map(
    --        clk      => clk,
    --        rst => rst,
    --        rd       => U_sub_rd,
    --        wr       => U_sub_wr,
    --        address  => U_sub_address,
    --        data_in  => U_sub_data_in,
    --        data_out => U_sub_data_out
    --    );
    -- X_warehouse, holds X0 and X_1:5 for outputs
    X_ware : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 600, ADR_LENGTH=>10)
        port map(
            clk      => clk,
            rd       => X_ware_rd,
            wr       => X_ware_wr,
            address  => X_ware_address,
            data_in  => X_ware_data_in,
            data_out => X_ware_data_out,
            rst      => rst
        );
    -- X_intermediate, holds Xi
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
    -- A
    a_coeff : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000, ADR_LENGTH=>13)
        port map(
            clk      => clk,
            rd       => a_coeff_rd,
            wr       => a_coeff_wr,
            address  => a_coeff_address,
            data_in  => a_coeff_data_in,
            data_out => a_coeff_data_out,
            rst      => rst
        );
    -- B
    b_coeff : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000,ADR_LENGTH=>13)
        port map(
            clk      => clk,
            rd       => b_coeff_rd,
            wr       => b_coeff_wr,
            address  => b_coeff_address,
            data_in  => b_coeff_data_in,
            data_out => b_coeff_data_out,
            rst      => rst
        );
-----------------------------------------------------------------MEMORY IO-----------------------------------------------------------------------------------
    --reads A coefficient
    --This sub_process is responsible for reading a[address,address+1]
    --and store it at a_temp[63:0]
    --proc_read_a_coeff : process(clk, read_a_coeff, write_a_coeff)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_a_coeff = '1' and write_a_coeff = '0' then
    --        if a_high = '0' then
    --            if increment_a_address = '0' then
    --                --reading the low part
    --                a_coeff_rd <= '1';
    --                a_temp(63 downto 32) <= a_coeff_data_out;
    --                a_high <= '1';
    --                increment_a_address <= '1';
    --            end if;
    --        else
    --            if increment_a_address = '0' then
    --                a_coeff_rd <= '1';
    --                a_temp(31 downto 0) <= a_coeff_data_out;
    --                a_high <= '0';
    --                decrement_a_address <= '1';
    --                read_a_coeff <= '0';
    --            end if;
    --        end if;        
    --    end if;
    --end process ; -- proc_read_a_coeff

    ----writes A coefficient
    ----This sub process takes data from resut_a_temo and stores it at a[adr,adr+1]
    --proc_write_a_coeff : process(clk, read_a_coeff, write_a_coeff)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_a_coeff = '0' and write_a_coeff = '1' then
    --        if a_high = '0' then
    --            if decrement_a_address = '0' then 
    --                a_coeff_wr <= '1';
    --                a_coeff_data_in <= result_a_temp (63 downto 32) ;
    --                a_high <= '1';
    --                increment_a_address <= '1';
    --            end if;
    --        else
    --            if increment_a_address = '0' then
    --                a_coeff_wr <= '1';
    --                a_coeff_data_in <= result_a_temp (31 downto 0) ;
    --                a_high <= '0';
    --                increment_a_address <= '1';
    --                write_a_coeff <= '0';
    --            end if;
    --        end if;            
    --end if;
    --end process ; -- proc_write_a_coeff

    ----increments A address
    --inc_a_address : process( clk, increment_a_address )
    --begin
    --    if rst = '0' and rising_edge(clk) and increment_a_address = '1' then
    --        if address_inc_1_enbl = '0' then
    --            address_inc_1_in <= (others => '0');
    --            address_inc_1_in(12 downto 0) <= a_coeff_address;
    --            address_inc_1_enbl <= '1';
    --            a_coeff_rd <= '0';
    --            a_coeff_wr <= '0';
    --        else
    --            a_coeff_address <= address_inc_1_out(12 downto 0);
    --            address_inc_1_enbl <= '0';
    --            increment_a_address <='0';
    --        end if;
    --    end if;    
    --end process ; -- inc_a_address

    ----decrements A address
    --dec_a_address : process( clk, decrement_a_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and decrement_a_address = '1' then
    --        if address_dec_1_enbl = '0' then
    --            address_dec_1_in <= (others => '0');
    --            address_dec_1_in(12 downto 0) <= a_coeff_address;
    --            address_dec_1_enbl <= '1';
    --            a_coeff_rd <= '0';
    --            a_coeff_wr <= '0';
    --        else
    --            a_coeff_address <= address_dec_1_out(12 downto 0);
    --            address_dec_1_enbl <= '0';
    --            decrement_a_address <='0';
    --        end if;
    --    end if;    
    --end process ; -- dec_a_address

    ----reads B coefficient
    --proc_read_b_coeff : process(clk, read_b_coeff, write_b_coeff)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_b_coeff = '1' and write_b_coeff = '0' then
    --        if b_high = '0' then
    --            if increment_b_address = '0' then
    --                --reading the low part
    --                b_coeff_rd <= '1';
    --                b_temp(63 downto 32) <= b_coeff_data_out;
    --                b_high <= '1';
    --                increment_b_address <= '1';
    --            end if;
    --        else
    --            if increment_b_address = '0' then
    --                b_coeff_rd <= '1';
    --                b_temp(31 downto 0) <= b_coeff_data_out;
    --                b_high <= '0';
    --                decrement_b_address <= '1';
    --                read_b_coeff <= '0';
    --            end if;
    --        end if;            
    --end if;
    --end process ; 

    ----writes B coefficient
    --proc_write_b_coeff : process(clk, read_b_coeff, write_b_coeff)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_b_coeff = '0' and write_b_coeff = '1' then
    --        if b_high = '0' then
    --                if decrement_b_address = '0' then 
    --                    b_coeff_wr <= '1';
    --                    b_coeff_data_in <= result_b_temp (63 downto 32) ;
    --                    b_high <= '1';
    --                    increment_b_address <= '1';
    --                end if;
    --            else
    --                if increment_b_address = '0' then
    --                    b_coeff_wr <= '1';
    --                    b_coeff_data_in <= result_b_temp (31 downto 0) ;
    --                    b_high <= '0';
    --                    increment_b_address <= '1';
    --                    write_b_coeff <= '0';
    --                end if;
    --            end if;            

    --    end if;
    --end process ; -- proc_write_b_coeff

    ----increments B address
    --inc_b_address : process( clk, increment_b_address )
    --begin
    --    if rst = '0' and rising_edge(clk) and increment_b_address = '1' then
    --        if address_inc_1_enbl = '0' then
    --            address_inc_1_in <= (others => '0');
    --            address_inc_1_in(12 downto 0) <= b_coeff_address;
    --            address_inc_1_enbl <= '1';
    --            b_coeff_rd <= '0';
    --            b_coeff_wr <= '0';
    --        else
    --            b_coeff_address <= address_inc_1_out(12 downto 0);
    --            address_inc_1_enbl <= '0';
    --            increment_b_address <='0';
    --        end if;
    --    end if;    
    --end process ; -- inc_b_address

    ----decrements B address
    --dec_b_address : process( clk, decrement_b_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and decrement_b_address = '1' then
    --        if address_dec_1_enbl = '0' then
    --            address_dec_1_in <= (others => '0');
    --            address_dec_1_in(12 downto 0) <= b_coeff_address;
    --            address_dec_1_enbl <= '1';
    --            b_coeff_rd <= '0';
    --            b_coeff_wr <= '0';
    --        else
    --            b_coeff_address <= address_dec_1_out(12 downto 0);
    --            address_dec_1_enbl <= '0';
    --            decrement_b_address <='0';
    --        end if;
    --    end if;    
    --end process ; -- dec_b_address
    
    ----reads X from X_ware
    --proc_read_x : process(clk, read_x, write_x)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_x = '1' and write_x = '0' then
    --        if x_high = '0' then
    --            if increment_x_address = '0' then
    --                --reading higher part
    --                X_ware_rd <= '1';
    --                x_temp(63 downto 32) <= x_ware_data_out;
    --                x_high <= '1';
    --                increment_x_address <= '1';
    --            end if;
    --        else
    --            if increment_x_address = '0' then
    --                --reading lower part
    --                X_ware_rd <= '1';
    --                x_temp(31 downto 0) <= x_ware_data_out;
    --                x_high <= '0';
    --                decrement_x_address <= '1';
    --                read_x <= '0';
    --            end if;
    --        end if;        
    --    end if;
    --end process ; -- proc_read_x

    ----writes X in X_ware
    --proc_write_x : process(clk, read_x, write_x)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_x = '0' and write_x = '1' then
    --        if x_high = '0' then
    --                if decrement_x_address = '0' then 
    --                    X_ware_wr <= '1';
    --                    x_ware_data_in <= result_x_temp(63 downto 32) ;
    --                    x_high <= '1';
    --                    increment_x_address <= '1';
    --                end if;
    --            else
    --                if increment_x_address = '0' then
    --                    X_ware_wr <= '1';
    --                    x_ware_data_in <= result_x_temp(31 downto 0) ;
    --                    x_high <= '0';
    --                    increment_x_address <= '1';
    --                    write_x <= '0';
    --                end if;
    --            end if;            
    --    end if;
    --end process ; -- proc_write_x_coeff

    ----increments X address
    --inc_x_address : process(clk, increment_x_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and increment_x_address = '1' then
    --        if address_inc_1_enbl = '0' then
    --            address_inc_1_in <= (others => '0');
    --            address_inc_1_in(9 downto 0) <= x_ware_address;
    --            address_inc_1_enbl <= '1';
    --            x_ware_rd <= '0';
    --            x_ware_wr <= '0';
    --        else
    --            x_ware_address <= address_inc_1_out(9 downto 0);
    --            address_inc_1_enbl <= '0';
    --            increment_x_address <='0';
    --        end if;
    --    end if;    
    --end process ; -- inc_x_address

    ----decrements X address
    --dec_x_address : process(clk, decrement_x_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and decrement_x_address = '1' then
    --        if address_dec_1_enbl = '0' then
    --            address_dec_1_in <= (others => '0');
    --            address_dec_1_in(9 downto 0) <= x_ware_address;
    --            address_dec_1_enbl <= '1';
    --            x_ware_rd <= '0';
    --            x_ware_wr <= '0';
    --        else
    --            x_ware_address <= address_dec_1_out(9 downto 0);
    --            address_dec_1_enbl <= '0';
    --            decrement_x_address <='0';
    --        end if;
    --    end if;       
    --end process ; -- dec_x_address   

    ----reads X intermediate
    --proc_read_x_i : process(clk, read_x_i, write_x_i)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_x_i = '1' and write_x_i = '0' then
    --        if x_i_high = '0' then
    --            if increment_x_i_address = '0' then
    --                --reading higher part
    --                X_intm_rd <= '1';
    --                x_i_temp(63 downto 32) <= X_intm_data_out;
    --                x_i_high <= '1';
    --                increment_x_i_address <= '1';
    --            end if;
    --        else
    --            if increment_x_i_address = '0' then
    --                --reading lower part
    --                X_intm_rd <= '1';
    --                x_i_temp(31 downto 0) <= X_intm_data_out;
    --                x_i_high <= '0';
    --                decrement_x_i_address <= '1';
    --                read_x_i <= '0';
    --            end if;
    --        end if;        
    --    end if;
    --end process ; -- proc_read_x_i
    
    ----writes X intermediate
    --proc_write_x_i : process(clk, read_x_i, write_x_i)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_x_i = '0' and write_x_i = '1' then
    --        if x_i_high = '0' then
    --                if decrement_x_i_address = '0' then 
    --                    X_intm_wr <= '1';
    --                    X_intm_data_in <= result_x_temp(63 downto 32) ;
    --                    x_i_high <= '1';
    --                    increment_x_i_address <= '1';
    --                end if;
    --            else
    --                if increment_x_i_address = '0' then
    --                    X_intm_wr <= '1';
    --                    X_intm_data_in <= result_x_i_temp(31 downto 0) ;
    --                    x_i_high <= '0';
    --                    increment_x_i_address <= '1';
    --                    write_x_i <= '0';
    --                end if;
    --            end if;            
    --    end if;
    --end process ; -- proc_write_x_i_coeff

    ----increments X_i address
    ----when we calculate x_i = x_i + x_c
    ----x_c uses address_inc_1 and address_dec_1
    ----so I need another one...e4m3na hwa :'(
    --inc_x_i_address : process(clk, increment_x_i_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and increment_x_i_address = '1' then
    --        if address_inc_2_enbl = '0' then
    --            address_inc_2_in <= (others => '0');
    --            address_inc_2_in(6 downto 0) <= X_intm_address;
    --            address_inc_2_enbl <= '1';
    --            X_intm_rd <= '0';
    --            X_intm_wr <= '0';
    --        else
    --            X_intm_address <= address_inc_2_out(6 downto 0);
    --            address_inc_2_enbl <= '0';
    --            increment_x_i_address <='0';
    --        end if;
    --    end if;    
    --end process ; -- inc_x_i_address

    ----decrements X_i address
    --dec_x_i_address : process(clk, decrement_x_i_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and decrement_x_i_address = '1' then
    --        if address_dec_2_enbl = '0' then
    --            address_dec_2_in <= (others => '0');
    --            address_dec_2_in(6 downto 0) <= X_intm_address;
    --            address_dec_2_enbl <= '1';
    --            X_intm_rd <= '0';
    --            X_intm_wr <= '0';
    --        else
    --            X_intm_address <= address_dec_2_out(6 downto 0);
    --            address_dec_2_enbl <= '0';
    --            decrement_x_i_address <='0';
    --        end if;
    --    end if;       
    --end process ; -- dec_x_i_address

    ----reads U main
    --proc_read_u_main : process(clk, read_u_main, write_u_main)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_u_main = '1' and write_u_main = '0' then
    --        if u_main_high = '0' then
    --            if increment_u_main_address = '0' then
    --                --reading the low part
    --                u_main_rd <= '1';
    --                u_main_temp(63 downto 32) <= u_main_data_out;
    --                u_main_high <= '1';
    --                increment_u_main_address <= '1';
    --            end if;
    --        else
    --            if increment_u_main_address = '0' then
    --                u_main_rd <= '1';
    --                u_main_temp(31 downto 0) <= u_main_data_out;
    --                u_main_high <= '0';
    --                decrement_u_main_address <= '1';
    --                read_u_main <= '0';
    --            end if;
    --        end if;            
    --    end if;
    --end process ; --proc_read_u_main

    ----writes U main
    --proc_write_u_main : process(clk, read_u_main, write_u_main)
    --begin
    --    if rst = '0' and rising_edge(clk) and read_u_main = '0' and write_u_main = '1' then
    --        if u_main_high = '0' then
    --                if decrement_u_main_address = '0' then 
    --                    u_main_wr <= '1';
    --                    u_main_data_in <= result_u_main_temp (63 downto 32) ;
    --                    u_main_high <= '1';
    --                    increment_u_main_address <= '1';
    --                end if;
    --            else
    --                if increment_u_main_address = '0' then
    --                    u_main_wr <= '1';
    --                    u_main_data_in <= result_u_main_temp (31 downto 0) ;
    --                    u_main_high <= '0';
    --                    increment_u_main_address <= '1';
    --                    write_u_main <= '0';
    --                end if;
    --            end if;            

    --    end if;
    --end process ; -- proc_write_u_main

    ----increments U main address
    --inc_u_main_address : process(clk, increment_u_main_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and increment_u_main_address = '1' then
    --        if address_inc_1_enbl = '0' then
    --            address_inc_1_in <= (others => '0');
    --            address_inc_1_in(6 downto 0) <= u_main_address;
    --            address_inc_1_enbl <= '1';
    --            u_main_rd <= '0';
    --            u_main_wr <= '0';
    --        else
    --            u_main_address <= address_inc_1_out(6 downto 0);
    --            address_inc_1_enbl <= '0';
    --            increment_u_main_address <='0';
    --        end if;
    --    end if;    
    --end process ; --inc_u_main_address

    ----decrements U main address
    --dec_u_main_address : process(clk, decrement_u_main_address)
    --begin
    --    if rst = '0' and rising_edge(clk) and decrement_u_main_address = '1' then
    --        if address_dec_1_enbl = '0' then
    --            address_dec_1_in <= (others => '0');
    --            address_dec_1_in(6 downto 0) <= u_main_address;
    --            address_dec_1_enbl <= '1';
    --            u_main_rd <= '0';
    --            u_main_wr <= '0';
    --        else
    --            u_main_address <= address_dec_1_out(6 downto 0);
    --            address_dec_1_enbl <= '0';
    --            decrement_u_main_address <='0';
    --        end if;
    --    end if;    
    --end process ; --dec_u_main_address
-----------------------------------------------------------------MAIN PROCESS-----------------------------------------------------------------------------------
    ----Code Flow and Comments

    --Fixed Step Size
    --Applied Function (X[n+1] = X[n](I+hA) + (hB)U[n])
    --Let A = 1+hA and B = hB (computed once)

    --YA SHAWKY, replaced interp_done_sig with interp_done_op...
    --variable interp_done_sig : std_logic_vector(1 downto 0) := (others => '0');

    --Variable Step Size
    -- LOOP:
    -- 0- START:
    --      h_adapt = h_main
    
    -- 1- calc two steps equations:
            --h_sent = 0 (n), U_recv = U0 (n)
            --1.1- Xi       = X_w[c] +  h_div (X_w[c],  U_main)
            --h_sent = h_adapt/2, U_recv is interpolated
            --1.2- X_w[c+1] = Xi     +  h_div (Xi,      U_main) --irrecgular equation fsm :D
    -- 2- calc one step equation: (fsm_main_eq)
    --        h_sent = h_adapt, U_recv is interpolated,
    --          not every time actually.. 
    --             X_i      = X_w[c] +  h_adapt(X_w[c], U_main)
    -- 3- calc error
    -- 4.1- error is bad (err > L_tol):
    --      h_adapt = h_adapt * h_adapt * L_nine / err
    --      jump back to 1
    -- 4.2- error is good (err <= L_tol):
    --      run fsm main eq
    -- 5- check for termination

    --NOTES:
    -- You can use h_div as h_doubler...
    -- you have both L and L_nine = (0.9 * L) so as not to compute it every time

    --Useful tools:
    --div_or_zero
    --div_or_adapt
    --from_i_to_c

    --STATES:
    -- 00000: nop or done
    -- 11111: start at a new point
    -- 00001: first equation
    -- 00010: inc c_Ware
    -- 00011: second equation
    -- 00100: dec c_ware
    -- 00101: when decremented go to 00110
    -- 00110: third equation
    -- 00111: run error calculator
    -- 01000: if error is bad, repeat: 00001,
    --                          with h_adapt updated
    --                          with c_ware decremented (the same)
    --                          with x_w[c] holds x0 (not updated)
    --          if it is good, go to: 10001
    --------break-----------------------------
    -- 01001: inc c_ware
    -- 01010: place x_w[c] at x_i
    -- 01011: dec c_ware
    -- 01100: place x_w[c] at x_i
    -- 01101: h_div = h_adapt and start main equation at: 01110
    -- 01110: start: x_i = x_w[c] + h(X_w[c], U_h)
    -- 01111: when it is finished go to 10000
    -- 10000: navigates you to 10011
    ---------break-------------------------------
    -- REMEMBER we are here cuz error is good!
    -- 10001: send h_adapt to interpolator at the unique address for it to store it
    -- 10010: when it is sent, proceed with the main equation at 01001
    --------break-------------------------------
    -- REMEMBER we are here cuz 10000 navigates us
    -- 10011: place what's inside x_i at x_w
    -- 10100: when done, if x_w[c] is an output point: go to: 10110
    --                                                  if not: 10101
    -- 10101: h_div = h_div + h_adapt then go to 11000
    -- 11000: go to 01110 to start main equation

    -- 10110: inc c_Ware
    -- 10111: go to 11001 to check for termination..

    -- 11001: terminate (00000) or move to next point (00001)

    --proc_run_x_h is called only from var_step_proc
    --and we need to define:
    --which h is used? h_div or h_adapt-->signal div_or_adapt
    --which X's are used? Xi-> XC or Xc->Xi --> from_i_to_c

    --proc_run_main_eq
    --STEPS:
        --start: init the counter
        --1- X_i = A * X_w
        --2- X_i = X_i + B*U
        --3- X_i = X_i * h
        --4- X_i = X_i + X_c
        --7- end
    --NOTE:
    --I'm not responsible for sending h!
    --But also I can not proceed with case() without making sure that U is read perfectly
    --this proc is only called within variable step size
    --so we know for sure that it is a variable step size operation

    --proc_h_sent_U_recv
    --A copy of the main equation, used to calculate:
    --Steps:
    --1- send h_high at 2C33
    --2- send h_low at 2C34
    --3- wait for done signal...
    --   when recevied, store U at U_main
    --4- end :D
    --NOTE: this proc sends zero or h_div, depending on a signal called div_or_zero

    process(clk, rst, in_data, adr, in_state, fixed_or_var, fixed_point_state, fsm_var_step_main, err_mul_1, err_add_1, err_add_2, err_div_1) 
    
    --calculates (I+hA)
    procedure proc_run_h_a is
        begin
            case(fsm_run_h_a) is
                when "0000" =>
                    --END
                    null;
                when "0001" =>
                    read_a_coeff <= '1';
                    fsm_run_h_a <= "0010";
                when "0010" =>
                    if read_a_coeff = '0' then
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= a_temp;
                        fpu_mul_1_in_2 <= h_main;
                        fsm_run_h_a <= "0011";
                    end if;
                when "0011" =>
                    if done_mul_1 = '1' then
                        enable_mul_1 <= '0';
                        --SHOULD WE ADD 1 ?????
                        if N_N_counter_2 = N_N_counter then
                            --add one
                            fpu_add_1_in_1 <= a_temp;
                            --fpu_add_1_in_2 <= (63 downto 16 => '0') & X"0080";
                            case( mode_sig ) is
                            
                                when "00" =>
                                    fpu_add_1_in_2 <= (others => '0');
                                    fpu_add_1_in_2(15 downto 0) <=  "0000000010000000";
                                when "01" =>
                                    fpu_add_1_in_2 <= (others => '0');
                                    fpu_add_1_in_2(31 downto 0) <="00111111100000000000000000000000";
                                when others =>
                                    fpu_add_1_in_2 <= "0011111111110000000000000000000000000000000000000000000000000000";
                            end case ;
                            fpu_add_1_in_2 <= (others =>'0');
                            fpu_add_1_in_2(55) <= '1';
                            enable_add_1 <= '1';
                            thisIsAdder_1 <= '0';
                            fsm_run_h_a <= "1011";
                        else
                            --continue 3ady
                            write_a_coeff <='1';
                            fsm_run_h_a <= "0100";
                        end if;
                    end if;
                when "0100" =>
                    if write_a_coeff = '0' then
                        if N_N_counter = X"0000" then
                            --END LOOOOOP
                            a_coeff_address <= (others => '0');
                            fsm_run_h_a <= "0000";
                        else
                            fsm_run_h_a <= "1100";
                        end if;
                    end if;
                when "0101" => 
                    if done_add_1 = '1' then
                        enable_add_1<= '0';
                        thisIsAdder_1 <= '0';
                        write_a_coeff <='1';
                        fsm_run_h_a <= "0100";
                    end if;
                --when "0110" => 
                --when "0111" => 
                --when "1000" =>
                --when "1001" =>
                when "1010" =>
                    N_N_counter_2 <= int_adder_1_out;
                    int_adder_1_enbl <='0';
                    fsm_run_h_a <= "0101";
                when "1011" =>
                    --DECREMENT N_N_temp_2 with N+1 (N_incremented)
                    int_adder_1_enbl <='1';
                    int_adder_1_in_1 <= N_N_counter_2;
                    int_adder_1_in_2 <= not N_incremented;
                    int_adder_1_cin  <= '1';
                    fsm_run_h_a <= "1010";
                when "1100" =>
                    address_dec_1_in <= N_N_counter;
                    address_dec_1_enbl <= '1';
                    fsm_run_h_a <= "1101";

                when "1101" =>
                    --disable dec
                    address_dec_1_enbl <= '0';
                    N_N_counter <= address_dec_1_out;
                    fsm_run_h_a <= "0001";

                when "1110" =>
                    N_incremented <= address_inc_1_out;
                    address_inc_1_enbl <= '0';
                    fsm_run_h_a <= "1100";
                when "1111" =>
                    --start here :D
                    --This variable to keep track of the main loop
                    N_N_counter <= N_N;
                    --this var to keep track of % N+1
                    N_N_counter_2 <= N_N;
                    address_inc_1_in <= N_X_A_B_vec;
                    address_inc_1_enbl <= '1';
                    a_coeff_address <= (others =>'0');
                    fsm_run_h_a <= "1110";
                when others =>
                    null;
            end case ;
        end procedure;

    --calculate (hB)
    procedure proc_run_h_b is
        begin
            case( fsm_run_h_b ) is
                when "000" =>
                    --NOP for now
                    null;
                when "001" =>
                    --read B coeff
                    --operated only once
                    read_b_coeff <='1';
                    fsm_run_h_b <= "010";
                when "010" =>
                    if read_b_coeff = '0' then
                        --b_temp holds current b element..
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= b_temp;
                        fpu_mul_1_in_2 <= h_main;
                        result_b_temp<= fpu_mul_1_out;
                        fsm_run_h_b <= "011";
                    end if;
                when "011" =>
                    --store hb at b
                    if done_mul_1 = '1' then
                        enable_mul_1 <= '0';
                        write_b_coeff <= '1';
                        fsm_run_h_b <= "100";
                    end if;
                when "100" =>
                    -- check if we reached end of the loop!!
                    --assuming N_M = 4, then we decrement it-->3-->2-->1-->0
                    -- if it's zero, we escape
                    if write_b_coeff = '0' then
                        address_dec_1_in <= N_M_counter;
                        address_dec_1_enbl <= '1';
                        fsm_run_h_b <= "101";
                    end if;
                when "101" =>
                    address_dec_1_enbl <= '0';
                    N_M_counter <= address_dec_1_out;
                    fsm_run_h_b <= "110";
                when "110" =>
                        if N_M_counter = X"0000" then
                            --end loop
                            b_coeff_address <= (others => '0');
                            fsm_run_h_b <= "000";
                        else
                            --LOOP AGAIN
                            fsm_run_h_b <= "001";
                        end if;
                when others =>
                    if fsm_run_h_a = "0000" then
                        --START working, init w kda
                        b_coeff_address <= (others => '0');
                        N_M_counter <= N_M;
                        fsm_run_h_b <= "001";
                    end if;
            end case ;
        end procedure;

    --calculates AX
    procedure proc_run_a_x is
        begin 
            case(fsm_run_a_x) is
                when "111" =>
                    -- initialization
                    N_N_counter <= N_N;
                    N_counter <= N_X_A_B_vec;
                    new_entry <= (others => '0');
                    to_write <= (others => '0');
                    fsm_run_a_x <= "001";
                when "001" =>
                    --read A coeff nad X_c
                    read_a_coeff <='1';
                    read_x <= '1';
                    fsm_run_a_x <= "010";
                when "010" =>
                    if read_a_coeff = '0' and read_x = '0' then --check for read completion
                        --multiply a with x
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= a_temp;
                        fpu_mul_1_in_2 <= x_temp;
                        fsm_run_a_x <= "011";
                    end if;
                when "011" =>
                    if done_mul_1 = '1' then --check for multiply completion
                        --add ax to the current entry
                        enable_mul_1 <= '0';
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= new_entry;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_a_x <= "100";
                    end if;
                when "100" =>
                    if done_add_1 = '1' then --check for add completion
                        --get output and decrement N_N_counter and N_counter
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        address_dec_1_in <= N_N_counter;
                        address_dec_1_enbl <= '1';
                        address_dec_2_in <= N_counter;
                        address_dec_2_enbl <= '1';
                        fsm_run_a_x <= "101";
                    end if;
                when "101" =>
                    --update counters
                    N_N_counter <= address_dec_1_out;
                    N_counter <= address_dec_2_out;
                    --check if the end of the column is reached
                    if N_counter = X"0000" then
                        to_write <= new_entry;
                        --ERROR DETECTED HERE YA SHAWKY
                        --result_x_temp <= to_write; --write the current entry
                        result_x_i_temp <= to_write; --write the current entry
                        write_x_i <= '1';
                        N_counter <= N_X_A_B_vec; --reset N
                        new_entry <= (others => '0');
                    end if;
                    fsm_run_a_x <= "110";
                when "110" =>
                    if N_N_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_a_x <= "000"; --return to the NOP state
                    else
                        fsm_run_a_x <= "001"; --return to the loop start
                    end if;
                when others =>
                    --NOP state
                    null;
            end case ;
        end procedure;

    --calculates X_w[c] = A * X_i
    procedure proc_run_a_x_2 is
        begin
            case(fsm_run_a_x_2) is
                when "111" =>
                    -- initialization
                    N_N_counter <= N_N;
                    N_counter <= N_X_A_B_vec;
                    new_entry <= (others => '0');
                    to_write <= (others => '0');
                    fsm_run_a_x_2 <= "001";
                when "001" =>
                    --read A coeff nad X_c
                    read_a_coeff <='1';
                    read_x_i <= '1';
                    fsm_run_a_x_2 <= "010";
                when "010" =>
                    if read_a_coeff = '0' and read_x_i = '0' then --check for read completion
                        --multiply a with x
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= a_temp;
                        fpu_mul_1_in_2 <= x_i_temp;
                        fsm_run_a_x_2 <= "011";
                    end if;
                when "011" =>
                    if done_mul_1 = '1' then --check for multiply completion
                        --add ax to the current entry
                        enable_mul_1 <= '0';
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= new_entry;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_a_x_2 <= "100";
                    end if;
                when "100" =>
                    if done_add_1 = '1' then --check for add completion
                        --get output and decrement N_N_counter and N_counter
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        address_dec_1_in <= N_N_counter;
                        address_dec_1_enbl <= '1';
                        address_dec_2_in <= N_counter;
                        address_dec_2_enbl <= '1';
                        fsm_run_a_x_2 <= "101";
                    end if;
                when "101" =>
                    --update counters
                    N_N_counter <= address_dec_1_out;
                    N_counter <= address_dec_2_out;
                    --check if the end of the column is reached
                    if N_counter = X"0000" then
                        to_write <= new_entry;
                        result_x_temp <= to_write; --write the current entry
                        write_x <= '1';
                        N_counter <= N_X_A_B_vec; --reset N
                        new_entry <= (others => '0');
                    end if;
                    fsm_run_a_x_2 <= "110";
                when "110" =>
                    if N_N_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_a_x_2 <= "000"; --return to the NOP state
                    else
                        fsm_run_a_x_2 <= "001"; --return to the loop start
                    end if;
                when others =>
                    --NOP state
                    null;
            end case;
        end procedure;

    --calculates X+BU
    procedure proc_run_x_b_u is
        begin
            case(fsm_run_x_b_u) is
                when "1111" =>
                    -- initialization
                    N_M_counter <= N_M;
                    M_Counter <= M_U_B_vec;
                    new_entry <= (others => '0');
                    to_write <= (others => '0');
                    fsm_run_x_b_u <= "0001";
                when "0001" =>
                    --read B coeff nad U_main
                    read_b_coeff <='1';
                    read_u_main <= '1';
                    fsm_run_x_b_u <= "0010";
                when "0010" =>
                    if read_b_coeff = '0' and read_u_main = '0' then --check for read completion
                        --multiply b with u
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= b_temp;
                        fpu_mul_1_in_2 <= u_main_temp;
                        fsm_run_x_b_u <= "0011";
                    end if;
                when "0011" =>
                    if done_mul_1 = '1' then --check for multiply completion
                        --add bu to the current entry
                        enable_mul_1 <= '0';
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= new_entry;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_x_b_u <= "0100";
                    end if;
                when "0100" =>
                    if done_add_1 = '1' then --check for add completion
                        --get output and decrement N_M_counter and M_Counter
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        address_dec_1_in <= N_M_counter;
                        address_dec_1_enbl <= '1';
                        address_dec_2_in <= M_Counter;
                        address_dec_2_enbl <= '1';
                        fsm_run_x_b_u <= "0101";
                    end if;
                when "0101" =>
                    --update counters
                    N_M_counter <= address_dec_1_out;
                    M_Counter <= address_dec_2_out;
                    --check if the end of the column is reached
                    if M_Counter = X"0000" then
                        M_Counter <= M_U_B_vec; --reset M
                        read_x_i <= '1'; --read corresponding X_i
                        fsm_run_x_b_u <= "0110";
                    else
                        fsm_run_x_b_u <= "1000"; --else move to the final state directly
                    end if;
                when "0110" =>
                    if read_x_i = '0' then --check X_i read completion
                        --add X_i to new entry
                        fpu_add_2_in_1 <= x_temp;
                        fpu_add_2_in_2 <= new_entry;
                        enable_add_2 <= '1';
                        fsm_run_x_b_u <= "0111";
                    end if;
                when "0111" =>
                    if done_add_2 = '1' then --check for add completion
                        enable_add_2 <= '0';
                        to_write <= fpu_add_2_out;
                        result_x_temp <= to_write; --write the current entry
                        write_x <= '1';
                        new_entry <= (others => '0'); --reset the new entry
                        fsm_run_x_b_u <= "1000";
                    end if;
                when "1000" =>
                    if N_M_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_x_b_u <= "0000"; --return to the NOP state
                    else
                        fsm_run_x_b_u <= "0001"; --return to the loop start
                    end if;
                when others =>
                    --NOP
                    null;
            end case;
        end procedure;

    --calculates X_w[c] = X_w[c] + B * U
    procedure proc_run_x_b_u_2 is
        begin
            case(fsm_run_x_b_u_2) is
                when "1111" =>
                    -- initialization
                    N_M_counter <= N_M;
                    M_Counter <= M_U_B_vec;
                    new_entry <= (others => '0');
                    to_write <= (others => '0');
                    fsm_run_x_b_u_2 <= "0001";
                when "0001" =>
                    --read B coeff nad U_main
                    read_b_coeff <='1';
                    read_u_main <= '1';
                    fsm_run_x_b_u_2 <= "0010";
                when "0010" =>
                    if read_b_coeff = '0' and read_u_main = '0' then --check for read completion
                        --multiply b with u
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= b_temp;
                        fpu_mul_1_in_2 <= u_main_temp;
                        fsm_run_x_b_u_2 <= "0011";
                    end if;
                when "0011" =>
                    if done_mul_1 = '1' then --check for multiply completion
                        --add bu to the current entry
                        enable_mul_1 <= '0';
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= new_entry;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_x_b_u_2 <= "0100";
                    end if;
                when "0100" =>
                    if done_add_1 = '1' then --check for add completion
                        --get output and decrement N_M_counter and M_Counter
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        address_dec_1_in <= N_M_counter;
                        address_dec_1_enbl <= '1';
                        address_dec_2_in <= M_Counter;
                        address_dec_2_enbl <= '1';
                        fsm_run_x_b_u_2 <= "0101";
                    end if;
                when "0101" =>
                    --update counters
                    N_M_counter <= address_dec_1_out;
                    M_Counter <= address_dec_2_out;
                    --check if the end of the column is reached
                    if M_Counter = X"0000" then
                        M_Counter <= M_U_B_vec; --reset M
                        read_x <= '1'; --read corresponding X
                        fsm_run_x_b_u_2 <= "0110";
                    else
                        fsm_run_x_b_u_2 <= "1000"; --else move to the final state directly
                    end if;
                when "0110" =>
                    if read_x = '0' then --check X read completion
                        --add X_i to new entry
                        fpu_add_2_in_1 <= x_i_temp;
                        fpu_add_2_in_2 <= new_entry;
                        enable_add_2 <= '1';
                        fsm_run_x_b_u_2 <= "0111";
                    end if;
                when "0111" =>
                    if done_add_2 = '1' then --check for add completion
                        enable_add_2 <= '0';
                        to_write <= fpu_add_2_out;
                        result_x_i_temp <= to_write; --write the current entry
                        write_x_i <= '1';
                        new_entry <= (others => '0'); --reset the new entry
                        fsm_run_x_b_u_2 <= "1000";
                    end if;
                when "1000" =>
                    if N_M_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_x_b_u_2 <= "0000"; --return to the NOP state
                    else
                        fsm_run_x_b_u_2 <= "0001"; --return to the loop start
                    end if;
                when others =>
                    --NOP
                    null;
            end case;
        end procedure;

    --calculates hX (for variable step)
    procedure proc_run_x_h is
        begin
            case( fsm_run_x_h ) is
                when "000" =>
                    --NOP for now
                    null;
                when "001" =>
                    --read X coeff
                    --operated only once
                    if from_i_to_c = '0' then
                        --from c to i then
                        read_x <='1';
                    else
                        --from i to c then
                        read_x_i <= '1';
                    end if;
                    fsm_run_x_h <= "010";
                when "010" =>
                    if from_i_to_c = '0' then
                        --from c to i then
                        if read_x = '0' then
                        --b_temp holds current b element..
                            if div_or_adapt = '0' then
                                --div
                                enable_mul_1 <= '1';
                                fpu_mul_1_in_1 <= x_temp;
                                fpu_mul_1_in_2 <= h_div;
                                fsm_run_x_h <= "011";
                            else
                                --adapt
                                enable_mul_1 <= '1';
                                fpu_mul_1_in_1 <= x_temp;
                                fpu_mul_1_in_2 <= h_adapt;
                                fsm_run_x_h <= "011";
                            end if;
                        end if;
                    else
                        --from i to c then
                        if read_x_i = '0' then
                            --b_temp holds current b element..
                            if div_or_adapt = '0' then
                                --div
                                enable_mul_1 <= '1';
                                fpu_mul_1_in_1 <= x_i_temp;
                                fpu_mul_1_in_2 <= h_div;
                                fsm_run_x_h <= "011";
                            else
                                --adapt
                                enable_mul_1 <= '1';
                                fpu_mul_1_in_1 <= x_temp;
                                fpu_mul_1_in_2 <= h_adapt;
                                fsm_run_x_h <= "011";
                            end if;
                        end if;
                    end if;
                when "011" =>
                    --store hb at b
                    if done_mul_1 = '1' then
                        if from_i_to_c = '0' then
                            --from c to i then
                            result_x_i_temp<= fpu_mul_1_out;
                            enable_mul_1 <= '0';
                            write_x_i <= '1';
                            fsm_run_x_h <= "100";
                        else
                            --from i to c then
                            result_x_temp<= fpu_mul_1_out;
                            enable_mul_1 <= '0';
                            write_x <= '1';
                            fsm_run_x_h <= "100";
                        end if;
                    end if;
                when "100" =>
                    -- check if we reached end of the loop!!
                    --assuming N_M = 4, then we decrement it-->3-->2-->1-->0
                    -- if it's zero, we escape
                    if from_i_to_c = '0' then
                        --from c to i then
                        if write_x_i = '0' then
                            address_dec_1_in <= N_counter;
                            address_dec_1_enbl <= '1';
                            fsm_run_x_h <= "101";
                        end if;
                    else
                        --from i to c then
                        if write_x = '0' then
                            address_dec_1_in <= N_counter;
                            address_dec_1_enbl <= '1';
                            fsm_run_x_h <= "101";
                        end if;
                    end if;
                when "101" =>
                    address_dec_1_enbl <= '0';
                    N_counter <= address_dec_1_out;
                    if N_counter = X"0000" then
                        --end loop
                        X_intm_address <= (others => '0');
                        fsm_run_x_h <= "000";
                    else
                        --LOOP AGAIN
                        fsm_run_x_h <= "001";
                    end if;
                when "110" =>
                        null;
                when others =>
                    --START working, init w kda
                    X_intm_address <= (others => '0');
                    N_counter <= N_X_A_B_vec;
                    fsm_run_x_h <= "001";
            end case ;
        end procedure;

    --calculates X_i + X_c (for variable step)
    procedure proc_run_x_i_c is
        begin
            case(fsm_run_x_i_c) is
                when "000" =>
                    --NOP for now
                    null;
                when "001" =>
                    --read x's coeff
                    --operated only once
                    read_x_i <='1';
                    read_x <= '1';
                    fsm_run_x_i_c <= "010";
                when "010" =>
                    if read_x_i = '0' and read_x = '0' then
                        --b_temp holds current b element..
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fpu_add_1_in_1 <= x_temp;
                        fpu_add_1_in_2 <= x_i_temp;
                        fsm_run_x_i_c <= "011";
                    end if;
                when "011" =>
                    --store hb at b
                    if done_add_1 = '1' then
                        if from_i_to_c = '0' then
                            --from c to i then
                            result_x_i_temp<= fpu_add_1_out;
                            enable_add_1 <= '0';
                            write_x_i <= '1';
                            fsm_run_x_i_c <= "100";
                        else
                            --from i to c then
                            result_x_temp<= fpu_add_1_out;
                            enable_add_1 <= '0';
                            write_x <= '1';
                            fsm_run_x_i_c <= "100";
                        end if;
                    end if;
                when "100" =>
                    -- check if we reached end of the loop!!
                    --assuming N_M = 4, then we decrement it-->3-->2-->1-->0
                    -- if it's zero, we escape
                    if from_i_to_c = '0' then
                        --from c to i then
                        if write_x_i = '0' then
                            address_dec_1_in <= N_counter;
                            address_dec_1_enbl <= '1';
                            fsm_run_x_i_c <= "101";
                        end if;
                    else
                        --from i to c then
                        if write_x = '0' then
                            address_dec_1_in <= N_counter;
                            address_dec_1_enbl <= '1';
                            fsm_run_x_i_c <= "101";
                        end if;
                    end if;
                when "101" =>
                    address_dec_1_enbl <= '0';
                    N_counter <= address_dec_1_out;
                    if N_counter = X"0000" then
                        --end loop
                        --This trick to make sure that adress of X_ware is updated
                        --without updating c_ware
                        listen_to_me <= not listen_to_me;
                        X_intm_address <= (others => '0');
                        fsm_run_x_i_c <= "000";
                    else
                        --LOOP AGAIN
                        fsm_run_x_i_c <= "001";
                    end if;
                when "110" =>
                        null;
                when others =>
                    --START working, init w kda
                    X_intm_address <= (others => '0');
                    --x_ware_address is already updated as C_ware is updated
                    --check proc_update_X_ware_address for more info :D
                    N_counter <= N_X_A_B_vec;
                    fsm_run_x_i_c <= "001";
            end case;
        end procedure;

    --calculates err_sum = sum(abs(Xi[i] - X_w[i]))
    procedure proc_run_sum_err is
        begin
            case(fsm_run_sum_err) is
                when "1111" =>
                    --START:
                    X_intm_address <= (others => '0');
                    --x_ware_address is already updated as C_ware is updated
                    --check proc_update_X_ware_address for more info :D
                    N_counter <= N_X_A_B_vec;
                    fsm_run_sum_err <= "0001";
                    --clear the err_sum first
                    err_sum <= (others =>'0');
                when "0001" =>
                    read_x_i <='1';
                    read_x <= '1';
                    fsm_run_sum_err <= "0010";
                when "0010" =>
                    if read_x_i = '0' and read_x = '0' then
                        --b_temp holds current b element..
                        enable_add_1 <= '1';
                        fpu_add_1_in_1 <= x_temp;
                        fpu_add_1_in_2 <= x_i_temp;
                        thisIsAdder_1 <= '1'; --1 for subtracting
                        fsm_run_sum_err <= "0011";
                    end if;
                when "0011" =>
                    if done_add_1 = '1' then
                        --non zero value
                        enable_add_1 <= '0';
                        to_write <= fpu_add_1_out;
                        if zero_add_1 = '0' then
                            if posv_add_1 = '0' then
                                --negative
                                --take absolute then continue
                                enable_mul_1 <= '1';
                                fpu_mul_1_in_1 <= to_write;
                                --What is -1 ?
                                case( mode_sig ) is
                                    when "00" => 
                                        fpu_mul_1_in_2 <= (others =>'0');
                                        fpu_mul_1_in_2(15 downto 0) <= "1111111110000000";
                                    when "01" =>
                                        fpu_mul_1_in_2 <= (others =>'0');
                                        fpu_mul_1_in_2(31 downto 0) <= "10111111100000000000000000000000";
                                    when "10" =>
                                        fpu_mul_1_in_2(63 downto 0) <= "1011111111110000000000000000000000000000000000000000000000000000";
                                    when others =>
                                end case ;
                                fsm_run_sum_err <= "1000";
                            else
                                --positive
                                --continue
                                fsm_run_sum_err <= "0100";
                            end if;
                        else
                            --we don't have to add it
                            --jump to where you decrement the counter
                            addThisError <= '1';
                            fsm_run_sum_err <= "0101";
                        end if;
                    end if;
                when "0100" =>
                    --add this error ya 7abeby
                    enable_add_1 <= '1';
                    thisIsAdder_1 <= '0';
                    fpu_add_1_in_1 <= err_sum;
                    fpu_add_1_in_2 <= to_write; --abs (x1[i] - x2[i])
                    fsm_run_sum_err <= "0101";
                when "0101" =>
                    if done_add_1 = '1' or addThisError = '1' then
                        --decrement the counter
                        addThisError <= '0';
                        err_sum <= fpu_add_1_out;
                        enable_add_1 <= '0';
                        fsm_run_sum_err <= "0110";
                    end if;
                when "0110" =>
                    --CHECK if err_sum <= L or not?
                    enable_add_1 <= '1';
                    thisIsAdder_1 <= '1'; --1 for sub
                    fpu_add_1_in_1 <= err_sum;
                    fpu_add_1_in_2 <= L_tol;
                    fsm_run_sum_err <= "1001";
                when "1000" =>
                    if done_mul_1 = '1' then
                        to_write <= fpu_mul_1_out;
                        enable_mul_1 <='0';
                        fsm_run_sum_err <= "0100";
                    end if;
                when "1001" =>
                    if done_add_1 = '0' then
                        if posv_add_1 = '0' or zero_add_1 = '1' then
                            --negative or zero means err_sum <= L
                            error_tolerance_is_good <= '1';
                            fsm_run_sum_err <= "1010";
                        else
                            --positive and non-zero means err_sum > L
                            error_tolerance_is_good <= '0';
                            fsm_run_sum_err <= "1010";
                        end if;
                    end if;
                when "1010" =>
                    address_dec_1_in <= N_counter;
                    address_dec_1_enbl <= '1';
                    fsm_run_sum_err <= "1011";
                when "1011" =>
                    address_dec_1_enbl <= '0';
                    N_counter <= address_dec_1_out;
                    if N_counter = X"0000" then
                        --end loop
                        if error_tolerance_is_good = '1' then
                            fsm_run_sum_err <= "1100";
                        else
                            fsm_run_sum_err <= "1100";
                            fsm_run_err_h_L <= "11";
                        end if;
                    else
                        --LOOP AGAIN
                        fsm_run_sum_err <= "0001";
                    end if;
                when "1100" =>
                    if fsm_run_err_h_L = "00" then
                        fsm_run_sum_err <= "0000";
                    end if;
                --when "1101" =>
                --when "1110" =>
                when others =>
                    --zeros and others
                    null;
            end case ;
        end procedure;

    --calculates main equation (for variable step)
    procedure proc_run_main_eq is
        begin
            case(fsm_main_eq) is
                when "111" =>
                    --Let's start ya ray2
                    X_intm_address <= (others => '0');
                    fsm_h_sent_U_recv <= (others => '1');
                    --x_ware_address is already updated as C_ware is updated
                    --check proc_update_X_ware_address for more info :D
                    --NOTE: this sub_proc is called only once
                    if from_i_to_c = '0' then
                        --no, from c to i, regular
                        fsm_run_a_x <= (others => '1');
                        fsm_main_eq <= "001";
                    else
                        --yes, irregular
                        --run the other equation, that calculates:
                        --X_w[c] = A* X_w[c]
                        fsm_run_a_x_2 <= (others => '1');
                        fsm_main_eq <= "001";
                    end if;
                when "001" =>
                    if from_i_to_c = '0' then
                        --no, from c to i, regular
                        --NOTE: fsm_h_sent_U_recv is not triggered by this proc..
                        if fsm_run_a_x = "000" and fsm_h_sent_U_recv = "000" then
                            --then X_i = A * X_w and U_main is prepared
                            fsm_run_x_b_u <= (others => '1');
                            fsm_main_eq <= "010";
                        end if;
                    else
                        --yes, irregular
                        --NOTE: fsm_h_sent_U_recv is not triggered by this proc..
                        if fsm_run_a_x_2 = "000" and fsm_h_sent_U_recv = "000" then
                            --then X_i = A * X_w and U_main is prepared
                            fsm_run_x_b_u_2 <= (others => '1');
                            fsm_main_eq <= "010";
                        end if;
                    end if;
                when "010" => 
                    if fsm_run_x_b_u = "0000" and fsm_run_h_2 = "00" then
                        --then X_i = X_i + BU
                        fsm_run_x_h <= (others =>'1');
                        fsm_main_eq <= "011";
                    end if;
                when "011" =>
                    if fsm_run_x_h = "000" then
                        --then X_i = h X_i
                        fsm_run_x_i_c <= (others => '1');
                        fsm_main_eq <= "100";
                    end if;
                when "100" =>
                    if fsm_run_x_i_c = "000" then
                        --then X_i = X_i + X_c
                        --then we're done...
                        listen_to_me <= not listen_to_me;
                        fsm_main_eq <= "000";
                    end if;
                --when "101" =>
                --when "110" =>
                when others =>
                    --zeros
                    null;
            end case;
        end procedure;

    --sends h and receives U
    procedure proc_h_sent_U_recv is
        begin
            case(fsm_h_sent_U_recv) is
                when "111" =>
                    -- we may use h_div, so we need to wait until its counted...
                    if fsm_run_h_2 = "00" then
                        if write_high_low = '0' then
                            adr <= X"2C33";
                            if div_or_zero = '0' then
                                --div
                                in_data <= h_div(63 downto 32);
                                write_high_low <= '1';
                            else
                                --zeros
                                in_data <= (others => '0');
                                write_high_low <= '1';
                            end if;
                        else
                            adr <= X"2C34";
                            if div_or_zero = '0' then
                                --div
                                in_data <= h_div(31 downto 0);
                                write_high_low <= '0';
                                u_main_address <= (others =>'0');
                                fsm_h_sent_U_recv <= "001";
                            else
                                --zero
                                in_data <= (others => '0');
                                U_main_address <= (others => '0');
                                write_high_low <= '0';
                                fsm_h_sent_U_recv <= "001";
                            end if;
                        end if;
                    end if;
                when "001" =>
                    --start the reading loop
                    N_counter_2 <= N_X_A_B_vec;
                    fsm_h_sent_U_recv <= "010";
                when "010" =>
                    if (interp_done_op = "01" or interp_done_op = "10") then
                        if write_u_main = '0' and increment_u_main_address = '0' then --no one else is writing at U
                            --here we write the high part at even addresses
                            u_main_wr <= '1';
                            u_main_data_in <= in_data;
                            u_main_high <= '1';
                            increment_u_main_address <= '1';
                            fsm_h_sent_U_recv <= "011";
                        end if;
                    end if;
                    --if interp_done_op = "00" or 
                when "011" =>  
                    if (interp_done_op = "01" or interp_done_op = "10") then
                        if write_u_main = '0' and increment_u_main_address = '0' then --no one else is writing at U 
                            u_main_wr <= '1';
                            u_main_data_in <= in_data ;
                            u_main_high <= '0';
                            increment_u_main_address <= '1';
                            fsm_h_sent_U_recv <= "100";--switch back
                        end if;
                    end if;
                when "100" =>
                    -- decrement the counter
                    address_dec_1_in <= N_counter_2;
                    address_dec_1_enbl <= '1';
                    fsm_h_sent_U_recv <= "101";
                when "101" =>
                    --decrement the counter
                    address_dec_1_enbl <= '0';
                    N_counter_2 <= address_dec_1_out;
                    if N_counter_2 = X"0000" then
                        --end loop
                        u_main_high <= '0';
                        u_main_address <= (others => '0');
                        fsm_h_sent_U_recv <= "000";
                    else
                        --LOOP AGAIN
                        fsm_h_sent_U_recv <= "010";
                    end if;
                when others =>
                    null;
            end case;
        end procedure;

    --sends h_new (or h_init) to interpolator (for variable step)
    procedure proc_send_h_init is
        begin
            case(fsm_send_h_init) is
                when "11" =>
                    adr <= X"2C35";
                    in_data <= h_adapt (63 downto 32);
                    fsm_send_h_init <= "01";
                when "01" =>
                    adr <= X"2C36";
                    in_data <= h_adapt (31 downto 0);
                    fsm_send_h_init <= "00";
                when others =>
                    null;
            end case ;
        end procedure;

    --replaces X_i and X_c (for variable step)
    procedure proc_place_x_i_at_x_c_or_vv is
        begin
            case(fsm_place_x_i_at_x_c_or_vv) is
                when "000" =>
                    --NOP for now
                    null;
                when "001" =>
                    --read X coeff
                    --operated only once
                    if from_i_to_c = '0' then
                        --from c to i then
                        read_x <='1';
                    else
                        --from i to c then
                        read_x_i <= '1';
                    end if;
                    fsm_place_x_i_at_x_c_or_vv <= "010";
                when "010" =>
                    if from_i_to_c = '0' then
                        --from c to i then
                        if read_x = '0' then
                            result_x_i_temp <= x_temp;
                            write_x_i <= '1';
                            fsm_place_x_i_at_x_c_or_vv <= "011";
                        end if;
                    else
                        if read_x_i = '0' then
                            result_x_temp <= x_i_temp;
                            write_x <= '1';
                            fsm_place_x_i_at_x_c_or_vv <= "011";
                        end if;
                    end if;
                when "011" =>
                    if from_i_to_c = '0' then
                        --from c to i then
                        if write_x_i = '0' then
                            fsm_place_x_i_at_x_c_or_vv <= "100";
                        end if;
                    else
                        if write_x = '0' then
                           fsm_place_x_i_at_x_c_or_vv <= "100";
                        end if;
                    end if;
                when "100" =>
                    -- check if we reached end of the loop!!
                    --assuming N_M = 4, then we decrement it-->3-->2-->1-->0
                    -- if it's zero, we escape
                    address_dec_1_in <= N_counter;
                    address_dec_1_enbl <= '1';
                    fsm_place_x_i_at_x_c_or_vv <= "101";
                when "101" =>
                    address_dec_1_enbl <= '0';
                    N_counter <= address_dec_1_out;
                    if N_counter = X"0000" then
                        --end loop
                        X_intm_address <= (others => '0');
                        fsm_place_x_i_at_x_c_or_vv <= "000";
                    else
                        --LOOP AGAIN
                        fsm_place_x_i_at_x_c_or_vv <= "001";
                    end if;
                when "110" =>
                        null;
                when others =>
                    --START working, init w kda
                    X_intm_address <= (others => '0');
                    N_counter <= N_X_A_B_vec;
                    fsm_place_x_i_at_x_c_or_vv <= "001";
            end case;
        end procedure;

    --multiples N*N or N*M
    --procedure proc_run_mul_n_m_and_n_n is
    --    begin
    --        case(fsm_run_mul_n_m) is
    --            when "00" => null;
    --            when "01" =>
    --                --assuming answer is ready
    --                N_N <= int_mul_1_out;
    --                int_mul_1_in_2 <= M_U_B_vec;
    --                int_mul_1_enbl <= '1';
    --                fsm_run_mul_n_m <= "01";
    --            when "10" =>
    --                N_M <= int_mul_1_out;
    --                int_mul_1_enbl <= '0';
    --                fsm_run_mul_n_m <= "00";
    --            when others =>
    --                --11
    --                --START
    --                int_mul_1_enbl <= '1';
    --                int_mul_1_in_1 <= N_X_A_B_vec;
    --                int_mul_1_in_2 <= N_X_A_B_vec;
    --                fsm_run_mul_n_m <= "01";
    --        end case;
    --    end procedure;

    --updates X_ware address pointer                       
    --proc_update_X_ware_address : process( c_ware,listen_to_me )
    --begin
    --    case(c_ware) is
    --        when "000" =>
    --            x_ware_address <= (others => '0');
    --            x_address_out <= x"2779";
    --        when "001" =>
    --            x_ware_address <= "0001100100";
    --            x_address_out <= x"27DD";
    --        when "010" =>
    --            x_ware_address <=  "0011001000";
    --            x_address_out <= x"2841";
    --        when "011" =>
    --            x_ware_address <=  "0100101100";
    --            x_address_out <= x"28A5";
    --        when "100" =>
    --            x_ware_address <=  "0110010000";
    --            x_address_out <= x"2909";
    --        when "101" =>
    --            x_ware_address <=  "0111110100";
    --        when others =>
    --            null;
    --    end case ;
    --end process ; -- proc_update_X_ware_address


    --f16: 0000000001110011
    --f32: 0011 1111 0110 0110 0110 0110 0110 0110
    --f64: 0011111111101100110011001100110011001100110011001100110011001101
    --proc_run_L_nine : process(clk, fsm_run_L_nine )
    --begin
    --    if rising_edge(clk) then
    --        case( fsm_run_L_nine ) is
            
    --            when "11" =>
    --                --START
    --                case( mode_sig ) is
                    
    --                    when "00" =>
    --                        fpu_mul_1_in_2 <= (others => '0');
    --                        fpu_mul_1_in_2(7 downto 0) <= "01110011";
    --                    when "01" =>
    --                        fpu_mul_1_in_2 <= (others => '0');
    --                        fpu_mul_1_in_2(31 downto 0) <= "00111111011001100110011001100110";
    --                    when "10" =>
    --                        fpu_mul_1_in_2 <= "0011111111101100110011001100110011001100110011001100110011001101";
    --                    when others =>
    --                        null;
    --                end case ;
    --                fsm_run_L_nine <= "01";
    --            when "01" =>
    --                enable_mul_1 <= '1';
    --                fpu_mul_1_in_1 <= L_tol;
    --                fsm_run_L_nine <= "10";
    --            when "10" =>
    --                if done_mul_1 = '1' then
    --                    L_nine <= fpu_mul_1_out;
    --                    enable_mul_1 <= '0';
    --                    fsm_run_L_nine <= "00";
    --                end if;
    --            when others =>
    --                --zeros and others
    --                null;
    --        end case ;
    --    end if;
    --end process ; -- proc_run_L_nine

    --you know the regs. err_sum
    --this process takes err_sum
    -- and produce : err_sum = (h*h*L*0.9)/err_sum
    --proc_run_err_h_L : process( clk, fsm_run_err_h_L)
    --begin
    --    if rising_edge(clk) then
    --        case( fsm_run_err_h_L ) is
            
    --            when "11" =>
    --                --start
    --                enable_mul_1<='1';
    --                fpu_mul_1_in_1 <= h_adapt;
    --                fpu_mul_1_in_2 <= h_adapt;

    --                enable_div_1 <= '1';
    --                fpu_div_1_in_1 <= L_nine;
    --                fpu_div_1_in_2 <= err_sum;

    --                fsm_run_err_h_L <= "01";
    --            when "01" =>
    --                if done_mul_1 = '1' and done_div_1 = '1' then
    --                    fpu_mul_1_in_1 <= fpu_mul_1_out; --h*h
    --                    enable_div_1 <= '0';
    --                    fpu_mul_1_in_2 <= fpu_div_1_out; --L*0.9/err_sum
    --                    enable_mul_1<='1'; --just to make sure y3ny..
    --                    fsm_run_err_h_L <= "10";
    --                end if;
    --            when "10" =>
    --                if done_mul_1 = '1' then
    --                    h_adapt <= fpu_mul_1_out;
    --                    enable_mul_1 <= '0';
    --                    fsm_run_err_h_L <= "00";
    --                end if;
    --                when others =>
    --                --zeros and others
    --                null;
    --        end case ;
    --    end if;        
    --end process ; -- proc_run_err_h_L

    --h_div = h_adapt/2
    --proc_run_h_2 : process( clk, fsm_run_h_2 )
    --begin
    --    if rising_edge(clk) then
    --        case( fsm_run_h_2 ) is
            
    --            when "11" =>
    --                --start
    --                enable_div_1 <= '1';
    --                fpu_div_1_in_1 <= h_adapt;
    --                fsm_run_h_2 <= "01";
    --                case( mode_sig ) is
    --                    when "00" => 
    --                        fpu_div_1_in_2 <= (others =>'0');
    --                        fpu_div_1_in_2(15 downto 0) <= "0000000100000000";
    --                    when "01" =>
    --                        fpu_div_1_in_2 <= (others =>'0');
    --                        fpu_div_1_in_2(31 downto 0) <= "01000000000000000000000000000000";
    --                    when "10" =>
    --                        fpu_div_1_in_2(63 downto 0) <= "0100000000000000000000000000000000000000000000000000000000000000";
    --                    when others =>
    --                end case ;
    --            when "01" =>
    --                if done_div_1 = '1' then
    --                    enable_div_1 <= '0';
    --                    h_div <= fpu_div_1_out;
    --                    fsm_run_h_2 <= "00";
    --                end if;
    --            when others =>
    --                --zeros and unused: end
    --                null;
    --        end case ;

    --    end if;
    --end process ; -- proc_run_h_2

    --runs termination
    procedure proc_termination is
        begin
            case(fsm_terminate) is
                when "11" =>
                    error_success <= '1';
                    interrupt <= '1';
                    fsm_terminate <= "01";
                when "01" =>
                    if in_state = "11" then
                        fsm_outing <= (others => '1');
                        fsm_terminate <= "00";
                    end if;
                when others =>
                    null;
            end case;
        end procedure;

    --proc_outing : process( clk, fsm_outing )
    --begin
    --    if rising_edge(clk) and in_state = "11" then
    --        case( fsm_outing ) is
            
    --            when "1111" =>
    --                --reset c_Ware
    --                c_ware <= (others => '0');
    --                adr <= x_address_out;

    --                fsm_outing <= "0001";
    --            when "0001" =>
    --                --start sending x_w[c]
    --                read_x <= '1';
    --                fsm_outing <= "0010";
    --            when "0010" =>
    --                if read_x = '0' then
    --                    in_data <= x_temp(63 downto 32);
    --                    fsm_outing <= "0011";
    --                end if;
    --            when "0011" =>
    --                address_inc_1_in <= adr;
    --                address_inc_1_enbl <= '1';
    --                fsm_outing <= "0100";
    --            when "0100" =>
    --                adr <= address_inc_1_out;
    --                address_inc_1_enbl <= '0';
    --                in_data <= x_temp(31 downto 0);
    --                fsm_outing <= "0101";
    --            when "0101" =>
    --                --check for the end of the loop against N_X_A_B_vec
    --                address_inc_1_in <= N_Counter;
    --                address_inc_1_enbl <= '1';
    --                fsm_outing <= "0110";
    --            when "0110" =>
    --                N_Counter <= address_inc_1_out;
    --                address_inc_1_enbl <= '0';
    --                --N_X_A_B_vec [1:50]
    --                fsm_outing <= "1001";

                    
    --            when "0111" =>
    --                --check for c_Ware and inc or terminate..
    --                address_inc_1_in <= c_ware;
    --                address_inc_1_enbl <= '1';
    --                fsm_outing <= "1000";
    --            when "1000" =>
    --                c_ware <= address_inc_1_out;
    --                address_inc_1_enbl <= '0';
    --                fsm_outing <= "1010";
    --            when "1001" =>
    --                if N_Counter = N_X_A_B_vec then
    --                    --done
    --                    fsm_outing <= "0111";
    --                else
    --                    --continue
    --                    fsm_outing <= "0001";
    --                end if;
    --            when "1010" =>
    --                if c_ware = t_size then
    --                    --we are done
    --                    fsm_outing <= "0000";
    --                else
    --                    adr <= x_address_out;
    --                    fsm_outing <= "0001";
    --                end if;
    --            --when "1011" =>
    --            --when "1100" =>
    --            --when "1101" =>
    --            --when "1110" =>
                
    --            when others =>
    --                null;
    --        end case ;

    --    end if;
    --end process ; -- proc_outing
-----------------------------------------------------------------MAIN FSM-----------------------------------------------------------------------------------
    --Fixed Step Size
    --Applied Function (X[n+1] = X[n](I+hA) + (hB)U[n])
    --Let A = 1+hA and B = hB (computed once)
    --Divided into multiple processes

    --main process implementation
    begin

        --RESET
        if rst = '1' then
            --port signals
            interrupt <= '0';
            error_success <= '1';
            in_data <= (others => 'Z');
            adr <= (others => 'Z');
            ----RESET fpu's:
            enable_mul_1 <= '1';
            enable_add_1 <= '1';
            enable_add_2 <= '1';
            enable_div_1 <= '1';
            --Reset memory
            U_main_address <= (others => '0');
            X_ware_address <= (others => '0');
            a_coeff_address <= (others => '0');
            b_coeff_address <= (others => '0');
            X_intm_address <= (others => '0');
            --RESET FSM's
            fsm_run_h_b <= (others => '0');
            fsm_run_h_a <= (others => '0');
            fsm_main_eq <= (others => '0');
            fsm_run_x_h <= (others => '0');
            fsm_run_x_i_c <= (others => '0');
            fsm_var_step_main <= (others => '0');
            fsm_run_L_nine <= (others => '0');
            fsm_run_mul_n_m <= "00";
            fsm_run_err_h_L <= "00";
            fsm_run_h_2 <= "00";
            fsm_run_sum_err <= "0000";
            fsm_h_sent_U_recv <= "000";     
            fsm_send_h_init <= "00";
            fsm_run_a_x <= (others => '0');
            fsm_run_x_b_u <= (others => '0');
            fsm_run_a_x_2 <= (others => '0');
            fsm_run_x_b_u_2 <= (others => '0');
            fsm_place_x_i_at_x_c_or_vv <= (others => '0');
            fixed_point_state <= (others => '0');
            fsm_terminate <= (others => '0');
            fsm_outing <= (others => '0');
            --RESET variables
            N_X_A_B_vec <= (others => '0');
            M_U_B_vec <= (others => '0');
            --N_X_A_B <= (others => '0');
            --M_U_B <= (others => '0');
            fixed_or_var <= '0';
            mode_sig <= (others => '0');
            t_size <= (others => '0');
            h_main <= (others => '0');
            L_tol <= (others => '0');
            error_tolerance_is_good <= '0';
        
        --ERROR HANDLING
        elsif rising_edge(clk) and rst = '0' and (err_mul_1 = '1' or  err_add_1 = '1' or err_add_2 = '1' or err_div_1 = '1') then
                error_success <= '0';
                interrupt <= '1';
        
        --DATA LOADER
        elsif rising_edge(clk) and rst = '0' and (in_state = STATE_LOAD or in_state = STATE_WAIT) then
            a_coeff_wr <= '0';
            b_coeff_wr <= '0';
            X_ware_wr <= '0';
            U_main_wr <= '0';
            U_main_address <= (others => '0');
            a_coeff_address <= (others => '0');
            b_coeff_address <= (others => '0');
            x_ware_address <= (others => '0');
            if adr = MM_HDR_0 then
                N_X_A_B_vec(5 downto 0) <= in_data(31 downto 26);
                M_U_B_vec(5 downto 0) <= in_data(25 downto 20);
                --N_X_A_B <= to_int(in_data(31 downto 26));
                --M_U_B <= to_int(in_data(25 downto 20));
                fixed_or_var <= in_data(19);
                mode_sig <= in_data(18 downto 17);
                t_size <= in_data(16 downto 14);
            elsif adr = MM_H_0 then
                h_main(MAX_LENGTH-1 downto 32) <= in_data;
            elsif adr = MM_H_1 then
                h_main(31 downto 0) <= in_data;
                --this signal will initiate both: N*M and N*N
                if beenThere_3 = '0' then
                    mul_N_N_and_M_N (
                        N_vec => N_X_A_B_vec,
                        M_vec => M_U_B_vec,
                        N_N_vec => N_N,
                        N_M_vec => N_M
                        );
                    fsm_run_mul_n_m <= "11"; 
                    beenThere_3 <= '1';
                end if;
            elsif adr = MM_ERR_0 then
                L_tol (MAX_LENGTH-1 downto 32) <= in_data;
            elsif adr = MM_ERR_1 then
                L_tol(31 downto 0) <= in_data;
            elsif adr >= MM_A_0 and adr <= MM_A_1 then
                a_coeff_data_in <= in_data;
                a_coeff_wr <= '1';
                -- shift adr from [MM_A_0:MM_A_1] to [0:MM_A_1-MM_A_0]
                a_coeff_address <= std_logic_vector(unsigned(adr) - unsigned(MM_A_0));                
            elsif adr >= MM_B_0 and adr <= MM_B_1 then
                --b coefficient
                b_coeff_data_in <= in_data;
                b_coeff_wr <= '1';
                -- shift adr from [MM_B_0:MM_B_1] to [0:MM_B_1-MM_B_0]
                b_coeff_address <= std_logic_vector(unsigned(adr) - unsigned(MM_B_0));
                --since we got here, then A and H are ready
                if beenThere_1 = '0' then
                    if fixed_or_var = '0' then 
                        fsm_run_h_a <= "1111";
                    else
                        --L_tol is read, so:
                        fsm_run_L_nine <= "11";
                    end if;
                    beenThere_1 <= '1';
                end if;
            elsif adr >= MM_X_0 and adr <= MM_X_1 then
                --X_ware[0] = X0
                X_ware_data_in <= in_data;
                X_ware_wr <= '1';
                -- shift adr from [MM_X_0:MM_X_1] to [0:MM_X_1-MM_X_0]
                X_ware_address <= std_logic_vector(unsigned(adr) - unsigned(MM_X_0));
                    -- Since we got here, then B and H are ready
                if fixed_or_var = '0' and beenThere_2 = '0' then 
                    fsm_run_h_b <= "111";
                    beenThere_2 <= '1';
                end if;
            elsif adr >= MM_U0_0 and adr <= MM_U0_1 then
                U_main_data_in <= in_data;
                U_main_wr <= '1';
                -- shift adr from [MM_U0_0:MM_X_1] to [0:MM_X_1-MM_U0_0]
                U_main_address <= std_logic_vector(unsigned(adr) - unsigned(MM_U0_0));
            end if;

        --FIXED SETP FSM
        elsif rising_edge(clk) and rst = '0' and in_state = STATE_PROC and fixed_or_var = '0' then
            case fixed_point_state is
                when "0000" => 
                    --wait for loop a and loop b 
                    --send lower half of new h to interpolater
                    if fsm_run_h_b = "000" and fsm_run_h_a = "0000" then
                        adr <= X"2C34";
                        in_data <= h_doubler(31 downto 0);
                        fixed_point_state <= "0001";
                    end if;
                when "0001" =>
                    --send higher half of new h to interpolater
                    --run AX calculation
                    adr <= X"2C33";
                    in_data <= h_doubler(63 downto 32);
                    fsm_run_a_x <= "111";
                    fixed_point_state <= "0010";
                when "0010" =>
                    --check AX and interpolator done signal
                    --read first half of U_new
                    --navigate to the suitable next state
                    if fsm_run_a_x = "000" then
                        --ERROR HERE YA SHAWKY
                        --if interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11" then
                        if interp_done_op = "01" or interp_done_op = "10" then
                            interp_done_sig <= interp_done_op;
                            result_u_main_temp(31 downto 0) <= in_data;
                            fixed_point_state <= "0011";
                        end if;
                    end if;
                when "0011" =>
                    --read higher part of U_new
                    --enable U_new write
                    result_u_main_temp(63 downto 32) <= in_data;
                    write_u_main <= '1';
                    fixed_point_state <= "0100";
                when "0100" =>
                    --check completion of U_new write
                    --run X+BU calculation
                    --navigate to the suitable state
                    if write_u_main = '0' then
                        fsm_run_x_b_u <= "1111";
                        if interp_done_sig = "01" then
                            fixed_point_state <= "0101";
                        else
                            fixed_point_state <= "0111";
                        end if;
                    end if;
                when "0101" =>
                    --activated in case of no current output point
                    --check X+BU completion
                    --increment h_doubler by h_main
                    if fsm_run_x_b_u <= "0000" then
                        fpu_add_1_in_1 <= h_doubler;
                        fpu_add_1_in_2 <= h_main;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fixed_point_state <= "0110";
                    end if;
                when "0110" =>
                    --check increment completion 
                    --update h_doubler
                    if done_add_1 = '1' then
                        h_doubler <= fpu_add_1_out;
                        fixed_point_state <= "0000"; 
                    end if;
                when "0111" =>
                    --activated in case of current output point
                    --check X+BU completion
                    --increment h_doubler by h_main
                    --increment x_ware address
                    --output lower part of the current X on data bus
                    if fsm_run_x_b_u = "0000" then
                        fpu_add_1_in_1 <= h_doubler;
                        fpu_add_1_in_2 <= h_main;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        increment_x_address <= '1';
                        in_data <= result_x_temp(31 downto 0);
                        fixed_point_state <= "1000";
                    end if;
                when "1000" =>
                    --check h_doubler and X_c increment completion 
                    --update h_doubler
                    --check whether to output higher part of current X or not based on mode
                    --output interrupt succes signal
                    if done_add_1 = '1' and increment_x_address = '0' then
                        h_doubler <= fpu_add_1_out;
                        if mode_sig = "10" then --case fp64
                            in_data <= result_x_temp(63 downto 32);
                        end if;
                        interrupt <= '1';
                        error_success <= '1';
                        if interp_done_op = "11" then
                            fixed_point_state <= "1111"; 
                        else
                            fixed_point_state <= "0000"; 
                        end if;
                    end if;
                when others =>
                    --NOP
                    null;
            end case;

        --VARIABLE STEP FSM
        elsif rising_edge(clk) and rst = '0' and in_state = STATE_PROC and fixed_or_var = '1' then
            case( fsm_var_step_main ) is
                when "11111" =>
                    --START babyyy
                    -- we reach here when output is produced and c_ware is incremented
                    --h_adapt always starts with the initial fixed value of h, h_main
                    h_adapt <= h_main;
                    fsm_var_step_main <= "00001";
                when "00001" => 
                    div_or_zero <= '1'; --h_sent: zerp
                    div_or_adapt <= '0'; --h_mul: h_div
                    from_i_to_c <= '0'; --no, from c to i
                    fsm_run_h_2 <= (others =>'1');
                    fsm_main_eq <= (others =>'1');
                    fsm_var_step_main <= "00010";
                when "00010" =>
                    if fsm_main_eq = "000" then
                        --NOW: calculate the irregular equation
                        --only when you're finished, increment c_ware
                        address_inc_1_in <= (others => '0');
                        address_inc_1_in(2 downto 0) <= c_ware;
                        address_inc_1_enbl <= '1';
                        fsm_var_step_main <= "00011";
                    end if;
                when "00011" =>
                    --we know for sure that address_inc_1 is already incremented
                    c_ware <= address_inc_1_out;
                    listen_to_me <= not listen_to_me; --just to make sure :D
                    address_inc_1_enbl <= '0';
                    --Now X_Ware_address is updated...
                    --let's run the irregular equation
                    div_or_zero <= '0'; --h_sent: div
                    div_or_adapt <= '0'; --h_mul: h_div
                    from_i_to_c <= '1'; --yes, from i to c
                    fsm_main_eq <= (others =>'1');
                    fsm_var_step_main <= "00100";
                when "00100" =>
                    if fsm_main_eq = "000" then
                        --Decrement C_ware first
                        address_dec_1_enbl <= '1';
                        address_dec_1_in <= (others => '0');
                        address_dec_1_in(2 downto 0) <= c_ware;
                        fsm_var_step_main <= "00101";
                    end if;
                when "00101" =>
                    c_ware <= address_dec_1_out;
                    address_dec_1_enbl <= '0';
                    fsm_var_step_main <= "00110"; 
                when "00110" =>
                    div_or_zero <= '1'; --h_sent: zero
                    div_or_adapt <= '1'; --h_mul: adapt
                    from_i_to_c <= '0'; --no, from c to i
                    fsm_main_eq <= (others =>'1');
                    fsm_var_step_main <= "00111"; 
                when "00111" =>
                    if fsm_main_eq = "000" then
                        error_tolerance_is_good <= '0';
                        fsm_run_sum_err <= (others => '1');
                        fsm_var_step_main <= "01000"; 
                    end if;
                when "01000" =>
                    if fsm_run_sum_err = "0000" then
                        if error_tolerance_is_good = '1' then
                            --yes it is good
                            error_tolerance_is_good<='0';
                            --eventually you'll hit this :D
                            --first go to interpolator and send h_adapt
                            fsm_var_step_main <= "10001"; 
                        else
                            --bad..so?
                            --h_adapt is already adapted xD
                            fsm_var_step_main <= "00001"; 
                        end if;
                    end if;
                when "01001" =>
                    --Place what's inside X_w[c+] at X_i
                    --then place what's inside X_i at X_w[c]
                    --but first increment c_ware
                    address_inc_1_in <= (others => '0');
                    address_inc_1_in(2 downto 0) <= c_ware;
                    address_inc_1_enbl <= '1';
                    fsm_var_step_main <= "01010";
                when "01010" =>
                    c_ware <= address_inc_1_out;
                    listen_to_me <= not listen_to_me; --just to make sure :D
                    address_inc_1_enbl <= '0';
                    from_i_to_c <= '0'; --no, from c to i
                    fsm_place_x_i_at_x_c_or_vv <= "111";
                    fsm_var_step_main <= "01011";
                when "01011" =>
                    if fsm_place_x_i_at_x_c_or_vv = "000" then
                        --decrement c_ware
                        address_dec_1_enbl <= '1';
                        address_dec_1_in <= (others => '0');
                        address_dec_1_in(2 downto 0) <= c_ware;
                        fsm_var_step_main <= "01100";
                    end if;
                when "01100" =>
                    c_ware <= address_dec_1_out;
                    address_dec_1_enbl <= '0';
                    from_i_to_c <= '1'; --yes, from i to c
                    fsm_place_x_i_at_x_c_or_vv <= "111";
                    fsm_var_step_main <= "01101";
                when "01101" =>
                    if fsm_place_x_i_at_x_c_or_vv = "000" then
                        --Now we are ready to proceed with our main equation
                        h_div <= h_adapt;
                        fsm_var_step_main <= "01110";
                    end if;
                when "01110" =>
                    --from now on, we'll treat h_div as h_doubler
                    --  and h_adapt as h_main
                    --h_adapt has the value that passed the tolerance test
                    --c_ware is lastly decremented, so it is ok
                    div_or_zero <= '0'; --h_sent: div:doubler
                    div_or_adapt <= '1'; --h_mul: h_adapt
                    from_i_to_c <= '0'; --no, from c to i
                    fsm_main_eq <= (others =>'1');
                    fsm_var_step_main <= "01111";
                when "01111" =>
                    if fsm_main_eq = "000" then
                        --listen to outpur or not
                        fsm_var_step_main <= "10000";
                    end if;
                when "10000" =>
                    --Replace X_w[c+] -> X_w[c]
                    fsm_var_step_main <= "10011";
                when "10001" =>
                    fsm_send_h_init <= "11";
                    fsm_var_step_main <= "10010";
                when "10010" =>
                    if fsm_send_h_init = "00" then
                        fsm_var_step_main <= "01001"; 
                    end if;
                when "10011" =>
                    --just place X_i at X_c
                    from_i_to_c <= '1'; --yes, place X-i at X-w[c]
                    fsm_place_x_i_at_x_c_or_vv <= "111";
                    fsm_var_step_main <= "10100"; 
                when "10100" =>
                    if fsm_place_x_i_at_x_c_or_vv = "000" then
                        if interp_done_op = "01" then
                            --it is not an output point
                            --start all over again
                            fsm_var_step_main <= "10101";
                        elsif interp_done_op = "10" then
                            --it is an output point
                            --GO INC C_ware
                            fsm_var_step_main <= "10110";
                        end if;
                    end if; 
                when "10101" =>
                    --increment h and repeat
                    fpu_add_1_in_1 <= h_adapt;
                    fpu_add_1_in_2 <= h_div;
                    enable_add_1 <= '1';
                    thisIsAdder_1 <= '0';
                    fsm_var_step_main <= "11000";
                when "10110" =>
                    address_inc_1_in <= (others => '0');
                    address_inc_1_in(2 downto 0) <= c_ware;
                    address_inc_1_enbl <= '1';
                    fsm_var_step_main <= "10111";
                when "10111" =>
                    c_ware <= address_inc_1_out;
                    listen_to_me <= not listen_to_me; --just to make sure :D
                    address_inc_1_enbl <= '0';
                    --we incremented c_ware...
                    --check for termination..
                    fsm_var_step_main <= "11001";
                    --fsm_var_step_main <= "10011";
                when "11000" =>
                    if done_add_1 = '0' then
                        h_div <= fpu_add_1_out;
                        enable_add_1 <= '0';
                        fsm_var_step_main <= "01110";
                    end if;
                when "11001" =>
                    --check for termination
                    --and go to 00001 or 00000
                    if c_ware = t_size then
                        --terminate
                        fsm_terminate <= (others => '1');
                        fsm_var_step_main <= "00000";
                    else
                        --go to 00001
                        fsm_var_step_main <= "00001";
                    end if;
                --when "11010" =>
                --when "11011" =>
                when others =>
                    -- zeros and other cases
                    null;
            end case ;
        end if;
    end process;
end architecture;
