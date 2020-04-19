library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
--use std.env.stop;

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

architecture rtl of solver is
    --SIGNALS:

    --SIGNALS FOR UNITS
    --FPU MUL 1
    --signal operation_sig_1                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic                                  := '0';
    --FPU ADD 1
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1 : std_logic                                  := '0';

    --FPU ADD 2
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_add_2_in_1, fpu_add_2_in_2, fpu_add_2_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_add_2, err_add_2, zero_add_2, posv_add_2, enable_add_2 : std_logic                                  := '0';

    --FPU ADD 3
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_add_3_in_1, fpu_add_3_in_2, fpu_add_3_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_add_3, err_add_3, zero_add_3, posv_add_3, enable_add_3 : std_logic                                  := '0';

    --FPU SUB 3
    --signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_sub_1_in_1, fpu_sub_1_in_2, fpu_sub_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_sub_1, err_sub_1, zero_sub_1, posv_sub_1, enable_sub_1 : std_logic                                  := '0';

    --ADDRESS INCREMENTOR 1, ADDR_LENGTH is the maximum..
    signal address_inc_1_in, address_inc_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal address_inc_1_enbl : std_logic := '0';
    
    signal address_dec_1_in, address_dec_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal address_dec_1_enbl : std_logic := '0';

    signal int_adder_1_in_1,int_adder_1_in_2,int_adder_1_out: std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal int_adder_1_enbl, int_adder_1_cin, int_adder_1_cout: std_logic := '0';

    signal int_mul_1_in_1, int_mul_1_in_2, int_mul_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0)  := (others => '0');
    signal int_mul_1_enbl : std_logic := '0';




    --Memory signals:
    --RD/WR:
    signal U_main_rd, U_main_wr                                        : std_logic                                  := '0';
    signal U_sub_rd, U_sub_wr                                          : std_logic                                  := '0';
    signal X_ware_rd, X_ware_wr                                        : std_logic                                  := '0';
    signal a_coeff_rd, a_coeff_wr                                      : std_logic                                  := '0';
    signal b_coeff_rd, b_coeff_wr                                      : std_logic                                  := '0';
    
    --Address:
    signal U_main_address                                              : std_logic_vector(6 downto 0) := (others => '0');
    signal U_sub_address                                               : std_logic_vector(6 downto 0) := (others => '0');
    signal X_ware_address                                              : std_logic_vector(9 downto 0) := (others => '0');
    signal a_coeff_address                                             : std_logic_vector(12 downto 0) := (others => '0');
    signal b_coeff_address                                             : std_logic_vector(13 downto 0) := (others => '0');
    
    --DATA in and out:
    signal U_main_data_in, U_main_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal U_sub_data_in, U_sub_data_out                               : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal X_ware_data_in, X_ware_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal a_coeff_data_in, a_coeff_data_out                           : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal b_coeff_data_in, b_coeff_data_out                           : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    



    --Solver module's signals:
    --SEMI PROCESSES ENABLES:
    signal run_mul_n_m : std_logic_vector(1 downto 0) := "00";


    --range [0:5], acts like a pointer to X_ware
    --fp16, fp32, fp64
    signal mode_sig     : std_logic_vector(1 downto 0)               := "00";
    --address pointer: keeps track when initializing
    signal address_pointer: std_logic_vector(2 downto 0) := (others => '0');
    --declaring this fpu_adder unit as adder or subtractor
    signal thisIsAdder : std_logic  := '0';
    signal thisIsSub : std_logic  := '1';
    --N, used in looping at X, A, B
    signal N_X_A_B : integer range 0 to 50 ;
    signal N_X_A_B_vec : std_logic_vector(15 downto 0) := (others => '0');
    --M, used in looping at B, U
    signal M_U_B :  integer range 0 to 50 ;
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

    signal x_high, read_x, write_x, increment_x_address, decrement_x_address : std_logic  := '0';
    signal result_x_temp,x_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    --signal N_N_temp: integer range 0 to 2500 ;
    --read h
    --signal read_h_please,h_is_read,h_high : std_logic  := '0';
    signal h_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal h_main, L_tol : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal h_high, L_high : std_logic  := '0';

    --result of a*H
    signal result_a_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal result_b_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');

    --run a and b processes
    signal b_high, read_b_coeff, write_b_coeff ,increment_b_address, decrement_b_address: std_logic  := '0';
    signal b_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');

    signal fsm_run_h_b : std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_h_a : std_logic_vector(3 downto 0) := (others => '0');
    
    --fixed point special signals
    signal fixed_point_state: std_logic_vector(3 downto 0) := (others => '0'); --fixed point FSM states
    signal calculate_ax: std_logic := '0';


begin
    --ENTITIES:

    --FPU's:
    fpu_mul_1 : entity work.fpu_multiplier(rtl)
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
    fpu_add_1 : entity work.fpu_adder(rtl)
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
            add_sub   => thisIsAdder
        );
    fpu_add_2 : entity work.fpu_adder(rtl)
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
            add_sub   => thisIsAdder
        );
    fpu_add_3 : entity work.fpu_adder(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_add_3,
            in_a      => fpu_add_3_in_1,
            in_b      => fpu_add_3_in_2,
            out_c     => fpu_add_3_out,
            done      => done_add_3,
            err       => err_add_3,
            zero      => zero_add_3,
            posv      => posv_add_3,
            add_sub   => thisIsAdder
        );
    fpu_sub_1 : entity work.fpu_adder(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_sub_1,
            in_a      => fpu_sub_1_in_1,
            in_b      => fpu_sub_1_in_2,
            out_c     => fpu_sub_1_out,
            done      => done_sub_1,
            err       => err_sub_1,
            zero      => zero_sub_1,
            posv      => posv_sub_1,
            add_sub   => thisIsSub
        );
    

    --Integer operators:
    address_inc_1 : entity work.incrementor(rtl) generic map (N => ADDR_LENGTH)
        port map(
            a      => address_inc_1_in,
            c      => address_inc_1_out,
            enbl   => address_inc_1_enbl
        );

    address_dec_1 : entity work.incrementor(rtl) generic map (N => ADDR_LENGTH)
        port map(
            a      => address_dec_1_in,
            c      => address_dec_1_out,
            enbl   => address_dec_1_enbl
        );

    int_adder_1 : entity work.int_adder(rtl) generic map (N => ADDR_LENGTH, M => ADDR_LENGTH)
        port map(
            a       =>  int_adder_1_in_1,
            b       =>  int_adder_1_in_2,
            enbl    =>  int_adder_1_enbl,
            cin     =>  int_adder_1_cin,
            c       =>  int_adder_1_out,
            cout    =>  int_adder_1_cout
        );
    int_mul_1 : entity work.int_multiplier(rtl) generic map (N => ADDR_LENGTH, M => ADDR_LENGTH)
        port map(
            a       =>  int_mul_1_in_1,
            b       =>  int_mul_1_in_2,
            enbl    =>  int_mul_1_enbl,
            c       =>  int_mul_1_out
        );

    --MEMORIES:

    -- U_main
    U_main : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
        port map(
            clk      => clk,
            rd       => U_main_rd,
            wr       => U_main_wr,
            address  => U_main_address,
            data_in  => U_main_data_in,
            data_out => U_main_data_out
        );
    -- U_sub
    U_sub : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
        port map(
            clk      => clk,
            rd       => U_sub_rd,
            wr       => U_sub_wr,
            address  => U_sub_address,
            data_in  => U_sub_data_in,
            data_out => U_sub_data_out
        );
    -- X_warehouse, holds X0 and X_1:5 for outputs
    X_ware : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 600, ADR_LENGTH=>10)
        port map(
            clk      => clk,
            rd       => X_ware_rd,
            wr       => X_ware_wr,
            address  => X_ware_address,
            data_in  => X_ware_data_in,
            data_out => X_ware_data_out
        );
    -- A
    a_coeff : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000, ADR_LENGTH=>13)
        port map(
            clk      => clk,
            rd       => a_coeff_rd,
            wr       => a_coeff_wr,
            address  => a_coeff_address,
            data_in  => a_coeff_data_in,
            data_out => a_coeff_data_out
        );
    -- B
    b_coeff : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000,ADR_LENGTH=>13)
        port map(
            clk      => clk,
            rd       => b_coeff_rd,
            wr       => b_coeff_wr,
            address  => b_coeff_address,
            data_in  => b_coeff_data_in,
            data_out => b_coeff_data_out
        );
    

    --PROCESSES:
    --1- RESET --> Done
    --2- initialize --> Done
    --3- error occured --> Done
    --4- fixed step size --> TBD
    --5- variable step size --> TBD
    --6- output is ready --> TBD
    --7- prepare A, run once --> TBD
    --8- prepare B, run once --> TBD

    --1- RESET
    -- handles reset signal for solver
    process (clk, rst)
    begin
        if rising_edge(clk) and rst = '1' then
            ----RESET fpu's:
            --enable_mul_1            <= '1';
            --enable_add_1            <= '1';
            --enable_add_2            <= '1';
            ----Reset memory
            --address_pointer <= (others => '0');

            ----Reset system's signals
            ----counter                 <= "00";
            --h_main_address          <= (others => '0');
            --h_doubler_address       <= (others => '0');
            --L_tol_address           <= (others => '0');
            --header_address          <= (others => '0');
            --U_main_address          <= (others => '0');
            --U_sub_address           <= (others => '0');
            --X_ware_address          <= (others => '0');
            --a_coeff_address         <= (others => '0');
            --b_coeff_address         <= (others => '0');
            --error_address           <= (others => '0');

        end if;
    end process;

    --2- Init:
    --Divided into two processes:

    --2.1: detects what type of addresses is this!  
    process (clk, in_state, in_data, adr)
    variable adr_var :unsigned(15 downto 0); 
    begin
        adr_var := resize(unsigned(adr),16);
        -- if in_State is           LOAD         or            WAIT      I can read..
        if rising_edge(clk) and (in_state = "00" or in_state = "01") then
            case adr_var is
                --Header
                when X"0000" =>
                    address_pointer <= "001";
                --H
                when X"0001" =>
                    h_high <= '0';
                    address_pointer <= "010";
                --error ie. Tolerance
                when X"0003" =>
                    L_high <= '0';
                    address_pointer <= "011";
                --A
                when X"0005" =>
                    a_coeff_address <= (others => '0');
                    address_pointer <= "100";
                --B
                when X"138D" =>
                    a_coeff_wr <= '0';
                    a_coeff_address <= (others => '0');
                    b_coeff_address <= (others => '0');
                    address_pointer <= "101";
                --X0 ie. X_w[0]
                when X"2715" =>
                    b_coeff_wr <= '0';
                    b_coeff_address <= (others => '0');
                    X_ware_address <= (others => '0');
                    address_pointer <= "110";
                --U0 ie. Umain
                when X"296D" =>
                    X_ware_wr <= '0';
                    X_ware_address <= (others => '0');
                    U_main_address <= (others => '0');
                    address_pointer <= "111";
                --X_out, not mine
                when X"2779" =>
                    address_pointer <= "000";
                --T, not mine
                when X"29D1" =>
                    U_main_address <= (others => '0');
                    U_main_wr <= '0';
                    address_pointer <= "000";
                --Us, not mine
                when X"29D8" =>
                    address_pointer <= "000";
                --Uint
                when X"2BCF" =>
                    address_pointer <= "000";
                --h_new
                when X"2C33" =>
                    address_pointer <= "000";
                -- Not our address :D
                when others =>
                    null;
            end case;
        end if;
    end process;

    --2.2: enables reading on my address
    process (clk, in_state, in_data, adr)
    begin
        -- if in_State is           LOAD         or            WAIT      I can read..
        if rising_edge(clk) and (in_state = "00" or in_state = "01") then
            case address_pointer is
                when "001" =>
                    --Header only one clock for one variable:
                    --Up till now, 'header' register is useless
                    N_X_A_B_vec <= in_data(31 downto 26);
                    M_U_B_vec <= in_data(25 downto 20);
                    N_X_A_B <= to_int(in_data(31 downto 26));
                    M_U_B <= to_int(in_data(25 downto 20));
                    fixed_or_var <= in_data(19);
                    mode_sig <= in_data(18 downto 17);
                    t_size <= in_data(16 downto 14);
                    --NOTE: You can not use the adder unit untill the next clock cycle
                    --and you don't need to use it anyways...

                when "010" =>
                    --H
                    if h_high = '0' then
                        h_main(MAX_LENGTH-1 downto 32) <= in_data;
                        h_high <= '1';
                    else
                        h_main(31 downto 0) <= in_data;
                    end if;
                    --this signal will initiate both:
                    -- N*M and N*N
                    run_mul_n_m <= "11"; 

                when "011" =>
                    --error tolerance
                    if L_high = '0' then
                        L_tol (MAX_LENGTH-1 downto 32) <= in_data;
                        L_high <= '1';
                    else
                        L_tol(31 downto 0) <= in_data;
                    end if;
                when "100" =>
                    --a coefficient
                    a_coeff_data_in <= in_data;
                    a_coeff_wr <= '1';

                    --then increment adr+=1
                    if done_add_1 = '0' then
                        fpu_add_1_in_1 <= a_coeff_address;
                        fpu_add_1_in_2 <= X"0001";
                        enable_add_1 <= '1';
                    else
                        a_coeff_address <= fpu_add_1_out;
                        enable_add_1 <= '0';
                    end if;        
                when "101" =>
                    --since we got here, then A and H are ready
                    if fixed_or_var = '0' then 
                        fsm_run_h_a <= "1111";
                    end if;
                    --b coefficient
                    b_coeff_data_in <= in_data;
                    b_coeff_wr <= '1';
                    --then increment adr+=1
                    if done_add_1 = '0' then
                        fpu_add_1_in_1 <= b_coeff_address;
                        fpu_add_1_in_2 <= X"0001";
                        enable_add_1 <= '1';
                    else
                        b_coeff_address <= fpu_add_1_out;
                        enable_add_1 <= '0';
                    end if;
                when "110" =>
                    --Since we got here, then B and H are ready
                    if fixed_or_var = '0' then 
                        fsm_run_h_b <= "111";
                        --at the begining of Fixed algorithm, you need to check that fsm_run_h_b = "000" or wait..
                    end if;
                    --X_ware[0] = X0
                    X_ware_data_in <= in_data;
                    X_ware_wr <= '1';
                    --then increment adr+=1
                    if done_add_1 = '0' then
                        fpu_add_1_in_1 <= X_ware_address;
                        fpu_add_1_in_2 <= X"0001";
                        enable_add_1 <= '1';
                    else
                        X_ware_address <= fpu_add_1_out;
                        enable_add_1 <= '0';
                    end if;
                when "111" =>
                    --X0
                    U_main_data_in <= in_data;
                    U_main_wr <= '1';
                    --then increment adr+=1
                    if done_add_1 = '0' then
                        fpu_add_1_in_1 <= U_main_address;
                        fpu_add_1_in_2 <= X"0001";
                        enable_add_1 <= '1';
                    else
                        U_main_address <= fpu_add_1_out;
                        enable_add_1 <= '0';
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    --3- Error process:
    --add here any other error_out signal that might occur
    errorOccured : process(clk, err_mul_1, err_add_1,err_add_2,err_add_3)
    begin
        if rising_edge(clk) then
            if (err_mul_1 = '1'
            or  err_add_1 = '1'
            or  err_add_2 = '1'
            or  err_add_3 = '1'
            )
            then
                error_success <= '0';
                interrupt <= '1';
                -- "wait" is not applicable with process
                -- std.env.stop;, std.env package does not exist
                -- you cant write: clk <= '0';
                -- you may try another solution if you wish  
            end if;
        end if;
    end process ;

    --4- Fixed Step Size
    --Applied Function (X[n+1] = X[n](I+hA) + (hB)U[n])
    --Let A = 1+hA and B = hB (computed once)
    --Divided into multiple processes

    --4.1: main fixed step driver
    fixed : process(clk, fixed_or_var, fixed_point_state) 
    begin
    --NOTE YA SHAWKY: at the begining of Fixed algorithm,
    --you need to check that fsm_run_h_b = "000" or wait..
        if rising_edge(clk) and fixed_or_var = '0' then
            case fixed_point_state is
                when "0000" => --wait for loop a and loop b
                    null;
                when "0001" => --send lower half of new h to interpolater 
                    in_data <= h_temp(31 downto 0);
                    adr <= X"2C33";
                    fixed_point_state <= "0010";
                when "0010" => --send higher half of new h to interpolater
                    in_data <= h_temp(63 downto 32);
                    adr <= X"2C33";
                    fixed_point_state <= "0011";
                when "0011" => --calculate AX
                    calculate_ax <= '1';
                when "0100" => --save AX in intermediate register
                    null;
                when "0101" => --wait for interpolator done signal
                    null;
                when "0110" => --calculate BU
                    null;
                when "0111" => --save BU
                    null;
                when "1000" => --AX + BU
                    null;
                when "1001" => --Xnew checks and save
                    null;
                when "1010" => --double h for fixed step
                    null;    
                when "1111" => --processing state (FSM hibernation)      
                    null;   
                when others =>
                    null;             
            end case;
        end if;
    end process ;

proc_run_h_a : process( clk, fsm_run_h_a )
    variable N_N_temp, N_N_temp_2 : std_logic_vector(15 downto 0) :=(others => '0');
    variable N_X_A_B_2 : std_logic_vector(15 downto 0) :=(others => '0');
    begin
        if rising_edge (clk) then
            case( fsm_run_h_a ) is
            
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
                        if N_N_temp_2 = N_N_temp then
                            --add one
                            fpu_add_1_in_1 <= a_temp;
                            --fpu_add_1_in_2 <= (63 downto 16 => '0') & X"0080";
                            fpu_add_1_in_2 <= (55 => '1', others => '0');
                            enable_add_1 <= '1';
                            fsm_run_h_a <= "1011";
                        else
                            --continue 3ady
                            write_a_coeff <='1';
                            fsm_run_h_a <= "0100";
                        end if;
                    end if;
                when "0100" =>
                    if write_a_coeff = '0' then
                        if N_N_temp = X"0000" then
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
                        write_a_coeff <='1';
                        fsm_run_h_a <= "0100";
                    end if;
                --when "0110" => 
                --when "0111" => 
                --when "1000" =>
                --when "1001" =>
                when "1010" =>
                    N_N_temp_2 := int_adder_1_out;
                    int_adder_1_enbl <='0';
                    fsm_run_h_a <= "0101";
                when "1011" =>
                    --DECREMENT N_N_temp_2 with N+1 (N_X_A_B_2)
                    int_adder_1_enbl <='1';
                    int_adder_1_in_1 <= N_N_temp_2;
                    int_adder_1_in_2 <= not N_X_A_B_2;
                    int_adder_1_cin  <= '1';
                    fsm_run_h_a <= "1010";
                when "1100" =>
                    address_dec_1_in <= N_N_temp;
                    address_dec_1_enbl <= '1';
                    fsm_run_h_a <= "1101";

                when "1101" =>
                    --disable dec
                    address_dec_1_enbl <= '0';
                    N_N_temp := address_dec_1_out;
                    fsm_run_h_a <= "0001";

                when "1110" =>
                    N_X_A_B_2 := address_inc_1_out;
                    address_inc_1_enbl <= '0';
                    fsm_run_h_a <= "1100";
                when "1111" =>
                    --start here :D
                    --This variable to keep track of the main loop
                    N_N_temp := N_N;
                    --this var to keep track of % N+1
                    N_N_temp_2 := N_N;
                    address_inc_1_in <= N_X_A_B_vec;
                    address_inc_1_enbl <= '1';
                    a_coeff_address <= (others =>'0');
                    fsm_run_h_a <= "1110";
                when others =>
                    null;
            end case ;


        end if;
    end process ; -- proc_run_h_a

    
--If you want to run this:
--fsm_run_h_b <= "111"
--and wait until it equals "000"
proc_run_h_b : process( clk, fsm_run_h_b )
    variable N_M_temp : std_logic_vector(15 downto 0) := (others => '0'); 
    begin
        if rising_edge(clk) then
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
                        address_dec_1_in <= N_M_temp;
                        address_dec_1_enbl <= '1';
                        fsm_run_h_b <= "101";
                    end if;
                when "101" =>
                    address_dec_1_enbl <= '0';
                    N_M_temp := address_dec_1_out;
                    if N_M_temp = X"0000" then
                        --end loop
                        b_coeff_address <= (others => '0');
                        fsm_run_h_b <= "000";
                    else
                        --LOOP AGAIN
                        fsm_run_h_b <= "001";
                    end if;
                when "110" =>
                        null;
                when others =>
                    --START working, init w kda
                    b_coeff_address <= (others => '0');
                    N_M_temp := N_M;
                    fsm_run_h_b <= "001";
            end case ;

        end if;
    end process ; -- proc_run_h_b


   


    -- run_a_x : process(clk, run_x_loop)
    -- variable first_time: std_logic  := '1';
    -- variable proceed:std_logic  := '0';
    -- variable N_N_count:  integer range 0 to 2500;
    -- variable N_count: integer range 0 to 50;
    -- begin
    --     if rising_edge(clk) and run_x_loop ='1' then
    --         if first_time = '1' then
    --             first_time := '0';
    --             N_N_count := N_N;
    --             N_count := N_X_A_B;
    --             a_coeff_address <= (others => '0');
    --             X_ware_address <= (others => '0');
    --         end if;
    --         N_N_count := N_N_count - 1; 
    --         N_count := N_count - 1;     
    --         if N_N_count = 0 then 
    --             proceed := '0';
    --             run_x_loop <= '0';
    --         else 
    --             proceed := '1';
    --         end if;
    --         if N_count = 0 then
    --             N_count := N_X_A_B;
    --         end if;    
    --         if proceed = '1' then
    --             fpu_mul_1_in_1 <= a_temp;
    --             fpu_mul_1_in_2 <= x_temp;
    --             enable_mul_1 <= '1';
    --             result_x_temp <= fpu_mul_1_out;
    --             write_b_coeff <= '1';               
    --         end if;
    --     end if;
    -- end process ;

proc_run_mul_n_m_and_n_n : process( clk, run_mul_n_m )
    --variable first_operation: std_logic  := '0';
    begin
        if rising_edge (clk) then
            case( run_mul_n_m ) is
            
                when "00" => null;
                when "01" =>
                    --assuming answer is ready
                    N_N <= int_mul_1_out;
                    int_mul_1_in_2 <= M_U_B_vec;
                    int_mul_1_enbl <= '1';
                    run_mul_n_m <= "01";
                when "10" =>
                    N_M <= int_mul_1_out;
                    int_mul_1_enbl <= '0';
                    run_mul_n_m <= "00";
                when others =>
                    --11
                    --START
                    int_mul_1_enbl <= '1';
                    int_mul_1_in_1 <= N_X_A_B_vec;
                    int_mul_1_in_2 <= N_X_A_B_vec;
                    run_mul_n_m <= "01";
            end case ;
        end if;
    end process ; -- proc_run_n_m_and_n_n

--This sub_process is responsible for reading a[address,address+1]
--and store it at a_temp[63:0]
proc_read_a_coeff : process(clk, read_a_coeff, write_a_coeff)
    begin
        if rising_edge(clk) and read_a_coeff = '1' and write_a_coeff = '0' then
            if a_high = '0' then
                if increment_a_address = '0' then
                    --reading the low part
                    a_coeff_rd <= '1';
                    a_temp(63 downto 32) <= a_coeff_data_out;
                    a_high <= '1';
                    increment_a_address <= '1';
                end if;
            else
                if increment_a_address = '0' then
                    a_coeff_rd <= '1';
                    a_temp(31 downto 0) <= a_coeff_data_out;
                    a_high <= '0';
                    decrement_a_address <= '1';
                    read_a_coeff <= '0';
                end if;
            end if;        
        end if;
    end process ; -- proc_read_a_coeff
    --This sub process takes data from resut_a_temo and stores it at a[adr,adr+1]
proc_write_a_coeff : process(clk, read_a_coeff, write_a_coeff)
    begin
        if rising_edge(clk) and read_a_coeff = '0' and write_a_coeff = '1' then
            if a_high = '0' then
                if decrement_a_address = '0' then 
                    a_coeff_wr <= '1';
                    a_coeff_data_in <= result_a_temp (63 downto 32) ;
                    a_high <= '1';
                    increment_a_address <= '1';
                end if;
            else
                if increment_a_address = '0' then
                    a_coeff_wr <= '1';
                    a_coeff_data_in <= result_a_temp (31 downto 0) ;
                    a_high <= '0';
                    increment_a_address <= '1';
                    write_a_coeff <= '0';
                end if;
            end if;            
    end if;
    end process ; -- proc_write_a_coeff
inc_a_address : process( clk, increment_a_address )
    begin
        if rising_edge(clk) and increment_a_address = '1' then
            if address_inc_1_enbl = '0' then
                address_inc_1_in <= (others => '0');
                address_inc_1_in(12 downto 0) <= a_coeff_address;
                address_inc_1_enbl <= '1';
                a_coeff_rd <= '0';
                a_coeff_wr <= '0';
            else
                a_coeff_address <= address_inc_1_out(12 downto 0);
                address_inc_1_enbl <= '0';
                increment_a_address <='0';
            end if;
        end if;    
    end process ; -- inc_a_address
dec_a_address : process( clk, decrement_a_address)
    begin
        if rising_edge(clk) and decrement_a_address = '1' then
            if address_dec_1_enbl = '0' then
                address_dec_1_in <= (others => '0');
                address_dec_1_in(12 downto 0) <= a_coeff_address;
                address_dec_1_enbl <= '1';
                a_coeff_rd <= '0';
                a_coeff_wr <= '0';
            else
                a_coeff_address <= address_dec_1_out(12 downto 0);
                address_dec_1_enbl <= '0';
                decrement_a_address <='0';
            end if;
        end if;    
    end process ; -- dec_a_address

proc_read_b_coeff : process(clk, read_b_coeff, write_b_coeff)
    begin
        if rising_edge(clk) and read_b_coeff = '1' and write_b_coeff = '0' then
            if b_high = '0' then
                if increment_b_address = '0' then
                    --reading the low part
                    b_coeff_rd <= '1';
                    b_temp(63 downto 32) <= b_coeff_data_out;
                    b_high <= '1';
                    increment_b_address <= '1';
                end if;
            else
                if increment_b_address = '0' then
                    b_coeff_rd <= '1';
                    b_temp(31 downto 0) <= b_coeff_data_out;
                    b_high <= '0';
                    decrement_b_address <= '1';
                    read_b_coeff <= '0';
                end if;
            end if;            
    end if;
    end process ; 
proc_write_b_coeff : process(clk, read_b_coeff, write_b_coeff)
    begin
        if rising_edge(clk) and read_b_coeff = '0' and write_b_coeff = '1' then
            if b_high = '0' then
                    if decrement_b_address = '0' then 
                        b_coeff_wr <= '1';
                        b_coeff_data_in <= result_b_temp (63 downto 32) ;
                        b_high <= '1';
                        increment_b_address <= '1';
                    end if;
                else
                    if increment_b_address = '0' then
                        b_coeff_wr <= '1';
                        b_coeff_data_in <= result_b_temp (31 downto 0) ;
                        b_high <= '0';
                        increment_b_address <= '1';
                        write_b_coeff <= '0';
                    end if;
                end if;            

        end if;
    end process ; -- proc_write_b_coeff
inc_b_address : process( clk, increment_b_address )
    begin
        if rising_edge(clk) and increment_b_address = '1' then
            if address_inc_1_enbl = '0' then
                address_inc_1_in <= (others => '0');
                address_inc_1_in(12 downto 0) <= b_coeff_address;
                address_inc_1_enbl <= '1';
                b_coeff_rd <= '0';
                b_coeff_wr <= '0';
            else
                b_coeff_address <= address_inc_1_out(12 downto 0);
                address_inc_1_enbl <= '0';
                increment_b_address <='0';
            end if;
        end if;    
        
    end process ; -- inc_b_address

 --4.10: decrements address of part A
dec_b_address : process( clk, decrement_b_address)
    begin
        if rising_edge(clk) and decrement_b_address = '1' then
            if address_dec_1_enbl = '0' then
                address_dec_1_in <= (others => '0');
                address_dec_1_in(12 downto 0) <= b_coeff_address;
                address_dec_1_enbl <= '1';
                b_coeff_rd <= '0';
                b_coeff_wr <= '0';
            else
                b_coeff_address <= address_dec_1_out(12 downto 0);
                address_dec_1_enbl <= '0';
                decrement_b_address <='0';
            end if;
        end if;    
    end process ; -- dec_b_address
    
proc_read_x : process(clk, read_x, write_x)
    begin
        if rising_edge(clk) and read_x = '1' and write_x = '0' then
            if x_high = '0' then
                if increment_x_address = '0' then
                    --reading higher part
                    X_ware_rd <= '1';
                    x_temp(63 downto 32) <= x_ware_data_out;
                    x_high <= '1';
                    increment_x_address <= '1';
                end if;
            else
                if increment_x_address = '0' then
                    --reading lower part
                    X_ware_rd <= '1';
                    x_temp(31 downto 0) <= x_ware_data_out;
                    x_high <= '0';
                    decrement_x_address <= '1';
                    read_x <= '0';
                end if;
            end if;        
        end if;
    end process ; -- proc_read_x
proc_write_x : process(clk, read_x, write_x)
    begin
        if rising_edge(clk) and read_x = '0' and write_x = '1' then
            if x_high = '0' then
                    if decrement_x_address = '0' then 
                        X_ware_wr <= '1';
                        x_ware_data_in <= result_x_temp(63 downto 32) ;
                        x_high <= '1';
                        increment_x_address <= '1';
                    end if;
                else
                    if increment_x_address = '0' then
                        X_ware_wr <= '1';
                        x_ware_data_in <= result_x_temp(31 downto 0) ;
                        x_high <= '0';
                        increment_x_address <= '1';
                        write_x <= '0';
                    end if;
                end if;            
        end if;
    end process ; -- proc_write_x_coeff
inc_x_address : process(clk, increment_x_address)
    begin
        if rising_edge(clk) and increment_x_address = '1' then
            if address_inc_1_enbl = '0' then
                address_inc_1_in <= (others => '0');
                address_inc_1_in(9 downto 0) <= x_ware_address;
                address_inc_1_enbl <= '1';
                x_ware_rd <= '0';
                x_ware_wr <= '0';
            else
                x_ware_address <= address_inc_1_out(9 downto 0);
                address_inc_1_enbl <= '0';
                increment_x_address <='0';
            end if;
        end if;    
    end process ; -- inc_x_address
dec_x_address : process(clk, decrement_x_address)
    begin
        if rising_edge(clk) and decrement_x_address = '1' then
            if address_dec_1_enbl = '0' then
                address_dec_1_in <= (others => '0');
                address_dec_1_in(9 downto 0) <= x_ware_address;
                address_dec_1_enbl <= '1';
                x_ware_rd <= '0';
                x_ware_wr <= '0';
            else
                x_ware_address <= address_dec_1_out(9 downto 0);
                address_dec_1_enbl <= '0';
                decrement_x_address <='0';
            end if;
        end if;       
    end process ; -- dec_x_address

    --process for AX calculation
    calc_ax : process(clk, calculate_ax)
    variable proceed: std_logic  := '0';
    variable first_time: std_logic  := '1';
    variable N_N_count:  integer range 0 to 2500;
    variable N_count:  integer range 0 to 50;
    variable new_entry: std_logic_vector(MAX_LENGTH-1 downto 0);
    begin
        if rising_edge(clk) and calculate_ax = '1' then
            if first_time = '1' then
                N_N_count := N_N;
                N_count := N_X_A_B;
                first_time := '0';
                new_entry := (others => '0');
                x_ware_address <= (others => '0');
            end if;
            N_N_count := N_N_count - 1;
            N_count := N_count - 1;
            --we reached the end of the loop            
            if N_N_count = 0 then 
                proceed := '0';
                --EXIT LOOP
                run_b_loop <= '0';
            else 
               proceed := '1';
            end if;
            --reset new entry accumulator
            if N_count = 0 then 
                N_count := N_X_A_B;
                result_a_temp <= new_entry;
                write_x <= '1';
                new_entry := (others => '0'); 
            end if;
            --this statement needs to be divided into multiple cycles!!!
            if proceed = '1' then
                --multiply A entry with X entry
                fpu_mul_1_in_1 <= a_temp;
                fpu_mul_1_in_2 <= x_temp;
                enable_mul_1 <= '1';
                --add result to the current entry
                fpu_sub_1_in_1 <= fpu_mul_1_out;
                fpu_sub_1_in_2 <= new_entry;
                enable_sub_1 <= '1'; 
                --save result in the current entry
                new_entry := fpu_add_2_out;         
            end if;
        end if;
    end process; --calc_ax

--fsm_main_eq will be 3 bits for now...
--my loop will be like this:
--      send h
--      X_i = A*X_c
--      X_i = X_i + B*U
--      X_i = X_i * h, only if we are variable step size
--      X_i = X_i + X_c, only if we are variable step size
--      exit
proc_run_main_eq : process(clk, fsm_main_eq )
    begin
        if rising_edge (clk) then
            case( fsm_main_eq ) is
            
                when "001" =>
                    --send lower bits
                    adr <= X"2C34";
                    in_data <= h_doubler(31 downto 0);
                    --start the AX process
                    ------------------------------------------------error---------------------
                    run_a_x <= '1';
                    fsm_main_eq <= "010";
                when "010" =>
                    --don't send anything...CLEAR
                    adr <= (others => '0');
                    in_data <= (others => '0');
                    if run_a_x = '0' then
                        if interp_done_op = "01" or interp_done_op = "10" then
                        ----------------------------------------error-------------------------
                            run_b_u <= '1';
                            fsm_main_eq <= "011";
                        end if;
                    end if;
                when "011" =>
                ----------------------------------------error-------------------------
                    if run_b_u <= '0' then
                    ----------------------------------------error-------------------------
                        run_x_h <='1';
                        fsm_main_eq <= "100";
                    end if;
                when "100" =>
                                ----------------------------------------error-------------------------
                    if run_x_h = '0' then
                                    ----------------------------------------error-------------------------
                        run_x_i_c <= '1';
                        fsm_main_eq <= "101";
                    end if;
                when "101" =>
                    --END LOOP
                    fsm_main_eq <= "000";
                --when "110" =>
                --when "111" =>
                    --STARTING POINT...
                    --Send h_doubler to interpolator..
                    --Send only the upper bits
                    adr <= X"2C33";
                    in_data <= h_doubler(63 downto 32);
                    fsm_main_eq <= "001";
                when others =>
                    --"000" and not used states...
                    null;
            end case ;


        end if;
    end process ; -- proc_run_main_eq


end architecture;