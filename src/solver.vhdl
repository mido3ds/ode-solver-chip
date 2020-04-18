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
        --state signal sent from CPU
        in_state       : in std_logic_vector(1 downto 0);
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
    --constants:

    --SIGNALS:
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

    --Memory signals:
    --RD/WR:
    signal h_main_rd, h_main_wr                                        : std_logic                                  := '0';
    signal h_doubler_rd, h_doubler_wr                                  : std_logic                                  := '0';
    signal L_tol_rd, L_tol_wr                                          : std_logic                                  := '0';
    signal header_rd, header_wr                                        : std_logic                                  := '0';
    signal U_main_rd, U_main_wr                                        : std_logic                                  := '0';
    signal U_sub_rd, U_sub_wr                                          : std_logic                                  := '0';
    signal X_ware_rd, X_ware_wr                                        : std_logic                                  := '0';
    signal a_coeff_rd, a_coeff_wr                                      : std_logic                                  := '0';
    signal b_coeff_rd, b_coeff_wr                                      : std_logic                                  := '0';
    --signal address_pointer_rd,  address_pointer_wr: std_logic := '0';
    signal error_rd, error_wr                                          : std_logic                                  := '0';

    --Address:
    signal h_main_address                                              : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal h_doubler_address                                           : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal L_tol_address                                               : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal header_address                                              : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal U_main_address                                              : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal U_sub_address                                               : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal X_ware_address                                              : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal a_coeff_address                                             : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    signal b_coeff_address                                             : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
    --signal address_pointer_address: std_logic_vector(ADDR_LENGTH-1 downto 0) := (others => '0');
    signal error_address                                               : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');

    --DATA in and out:
    signal h_main_data_in, h_main_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal h_doubler_data_in, h_doubler_data_out                       : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal L_tol_data_in, L_tol_data_out                               : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal header_data_in, header_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal U_main_data_in, U_main_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal U_sub_data_in, U_sub_data_out                               : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal X_ware_data_in, X_ware_data_out                             : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal a_coeff_data_in, a_coeff_data_out                           : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal b_coeff_data_in, b_coeff_data_out                           : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    --signal address_pointer_data_in, address_pointer_data_out:   std_logic_vector(WORD_LENGTH-1 downto 0) := (others => '0');
    signal error_data_in, error_data_out                               : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    --Solver module's signals:

    --range [0:5], acts like a pointer to X_ware
    --signal counter      : std_logic_vector(2 downto 0)               := "000";
    --fp16, fp32, fp64
    signal mode_sig     : std_logic_vector(1 downto 0)               := "00";
    --address pointer: keeps track when initializing
    signal address_pointer: std_logic_vector(2 downto 0) := (others => '0');
    --declaring this fpu_adder unit as adder or subtractor
    signal thisIsAdder : std_logic  := '0';
    signal thisIsSub : std_logic  := '1';
    --N, used in looping at X, A, B
    signal N_X_A_B : integer range 0 to 50 ;
    --M, used in looping at B, U
    signal M_U_B :  integer range 0 to 50 ;
    --FIXED or VAR
    signal fixed_or_var : std_logic  := '0';
    --T_size
    signal t_size :  std_logic_vector(2 downto 0) := "000";
    --N*M, needed in looping at B
    signal N_M:  integer range 0 to 2500 ;
    --N*N, needed in looping at A
    signal N_N:  integer range 0 to 2500 ;
    --run a and b processes
    signal run_a_loop, a_high, a_is_read,write_a_coeff, increment_a_address,decrement_a_address : std_logic  := '0';
    signal a_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    --signal N_N_temp: integer range 0 to 2500 ;
    --read h
    signal read_h_please,h_is_read,h_high : std_logic  := '0';
    signal h_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');


    --result of a*H
    signal result_a_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');
    signal result_b_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');

    --run a and b processes
    signal run_b_loop, b_high, b_is_read,write_b_coeff ,increment_b_address, decrement_a_address: std_logic  := '0';
    signal b_temp : std_logic_vector(MAX_LENGTH-1 downto 0) := (others => '0');






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
    --Memo:
    -- h_main--> two (32) regs.
    h_main : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 2)
        port map(
            clk      => clk,
            rd       => h_main_rd,
            wr       => h_main_wr,
            address  => h_main_address,
            data_in  => h_main_data_in,
            data_out => h_main_data_out
        );
    h_doubler : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 2)
        port map(
            clk      => clk,
            rd       => h_doubler_rd,
            wr       => h_doubler_wr,
            address  => h_doubler_address,
            data_in  => h_doubler_data_in,
            data_out => h_doubler_data_out
        );
    --tolerance register, will be initiated at the begining of the program.
    L_tol : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 2)
        port map(
            clk      => clk,
            rd       => L_tol_rd,
            wr       => L_tol_wr,
            address  => L_tol_address,
            data_in  => L_tol_data_in,
            data_out => L_tol_data_out
        );
    -- header: holds N,M,Count,FP,mode(fixed/variable)
    header : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 1)
        port map(
            clk      => clk,
            rd       => header_rd,
            wr       => header_wr,
            address  => header_address,
            data_in  => header_data_in,
            data_out => header_data_out
        );
    -- U_main
    U_main : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100)
        port map(
            clk      => clk,
            rd       => U_main_rd,
            wr       => U_main_wr,
            address  => U_main_address,
            data_in  => U_main_data_in,
            data_out => U_main_data_out
        );
    -- U_sub
    U_sub : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100)
        port map(
            clk      => clk,
            rd       => U_sub_rd,
            wr       => U_sub_wr,
            address  => U_sub_address,
            data_in  => U_sub_data_in,
            data_out => U_sub_data_out
        );
    -- X_warehouse, holds X0 and X_1:5 for outputs
    X_ware : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 600)
        port map(
            clk      => clk,
            rd       => X_ware_rd,
            wr       => X_ware_wr,
            address  => X_ware_address,
            data_in  => X_ware_data_in,
            data_out => X_ware_data_out
        );
    -- A
    a_coeff : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000)
        port map(
            clk      => clk,
            rd       => a_coeff_rd,
            wr       => a_coeff_wr,
            address  => a_coeff_address,
            data_in  => a_coeff_data_in,
            data_out => a_coeff_data_out
        );
    -- B
    b_coeff : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000)
        port map(
            clk      => clk,
            rd       => b_coeff_rd,
            wr       => b_coeff_wr,
            address  => b_coeff_address,
            data_in  => b_coeff_data_in,
            data_out => b_coeff_data_out
        );
    -- address_pointer
    --address_pointer: entity work.ram(rtl) generic map (WORD_LENGTH=>WORD_LENGTH, NUM_WORDS=>1) 
    -- port map(
    --    clk => clk,
    --    rd => address_pointer_rd,
    --    wr => address_pointer_wr,
    --    address => address_pointer_address,
    --    data_in => address_pointer_data_in,
    --    data_out => address_pointer_data_out
    --);
    -- error
    error : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 2)
        port map(
            clk      => clk,
            rd       => error_rd,
            wr       => error_wr,
            address  => error_address,
            data_in  => error_data_in,
            data_out => error_data_out
        );
    --Many more register may be added....

    --PROCESSES:
    --1- RESET, done
    --2- initialize, done
    --3- error occured, done
    --4- fixed step size
    --5- variable step size
    --6- output is ready
    --7- prepare A, run once
    --8- prepare B, run once


    --1- RESET
    process (clk, rst)
    begin
        if rising_edge(clk) and rst = '1' then
            --RESET fpu's:
            enable_mul_1            <= '1';
            enable_add_1            <= '1';
            enable_add_2            <= '1';
            --Reset memory
            address_pointer <= (others => '0');

            --Reset system's signals
            --counter                 <= "00";
            h_main_address          <= (others => '0');
            h_doubler_address       <= (others => '0');
            L_tol_address           <= (others => '0');
            header_address          <= (others => '0');
            U_main_address          <= (others => '0');
            U_sub_address           <= (others => '0');
            X_ware_address          <= (others => '0');
            a_coeff_address         <= (others => '0');
            b_coeff_address         <= (others => '0');
            error_address           <= (others => '0');

        end if;
    end process;

    --2- Init:
        --It's divided into two processes:
    --2.1: to detect what type of addresses it this!  
    process (clk, in_state, in_data, adr)
    variable adr_var :unsigned(15 downto 0); 
    begin
        adr_var := resize(unsigned(adr),16);
        -- if in_State is           LOAD         or            WAIT      I can read..
        if rising_edge(clk) and (in_state = "00" or in_state = "01") then
            case adr_var is
                --Header
                when X"0000" =>
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';
                    address_pointer <= "001";
                --H
                when X"0001" =>
                    --Dont write at 'header' any more..
                    header_wr <= '0';
                    h_main_address <= (others => '0');
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "010";
                --error ie. Tolerance
                when X"0003" =>
                    h_main_wr <= '0';
                    h_main_address <= (others => '0');
                    L_tol_address <= (others => '0');
                    enable_mul_1 <= '0';
                    enable_add_1 <= '0';

                    address_pointer <= "011";
                --A
                when X"0005" =>
                    L_tol_wr <= '0';
                    L_tol_address <= (others => '0');
                    a_coeff_address <= (others => '0');
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "100";
                --B
                when X"138D" =>
                    a_coeff_wr <= '0';
                    a_coeff_address <= (others => '0');
                    b_coeff_address <= (others => '0');
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "101";
                --X0 ie. X_w[0]
                when X"2715" =>
                    b_coeff_wr <= '0';
                    b_coeff_address <= (others => '0');
                    X_ware_address <= (others => '0');
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "110";
                --U0 ie. Umain
                when X"296D" =>
                    X_ware_wr <= '0';
                    X_ware_address <= (others => '0');
                    U_main_address <= (others => '0');
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "111";
                --X_out, not mine
                when X"2779" =>
                    enable_mul_1 <= '0';
                    U_main_address <= (others => '0');

                    address_pointer <= "000";
                --T, not mine
                when X"29D1" =>
                    U_main_address <= (others => '0');
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "000";
                --Us, not mine
                when X"29D8" =>
                    enable_add_1 <= '0';
                    address_pointer <= "000";
                --Uint
                when X"2BCF" =>
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "000";
                --h_new
                when X"2C33" =>
                    enable_add_1 <= '0';
                    enable_mul_1 <= '0';

                    address_pointer <= "000";
                -- Not our address :D
                when others =>
                    enable_mul_1 <= '0';
                    enable_add_1 <= '0'; 
                    null;
            end case;
        end if;
    end process;
    --2.2: to enable reading on my address...
    process (clk, in_state, in_data, adr)
    begin
        -- if in_State is           LOAD         or            WAIT      I can read..
        if rising_edge(clk) and (in_state = "00" or in_state = "01") then
            case address_pointer is
                when "001" =>
                    --Header only one clock for one variable:
                    --adapt header register to store its data:
                    header_data_in <= in_data;
                    header_address <= (others => '0');
                    header_wr <= '1';
                    header_rd <= '0';
                    --Up till now, 'header' register is useless
                    N_X_A_B <= to_int(in_data(31 downto 26));
                    M_U_B <= to_int(in_data(25 downto 20));

                    fixed_or_var <= in_data(19);
                    mode_sig <= in_data(18 downto 17);
                    t_size <= in_data(16 downto 14);
                    --NOTE: You can use the adder unit untill the next clock cycle
                    --and you don't need to use it anyways...
                when "010" =>
                    --H
                    --write in_data at address [adr]
                    h_main_data_in <= in_data;
                    h_main_wr <= '1';
                    h_main_rd <= '0';
                    --then increment adr+=1
                    fpu_add_1_in_1 <= h_main_address;
                    fpu_add_1_in_2 <= X"0001";
                    enable_add_1 <= '1';
                    h_main_address <= fpu_add_1_out;
                    --I can prepare N_M here using fpu_mul_1
                    fpu_mul_1_in_1 <= std_logic_vector(to_unsigned(N_X_A_B, fpu_mul_1_in_1'length));
                    fpu_mul_1_in_2 <= std_logic_vector(to_unsigned(M_U_B, fpu_mul_1_in_2'length));
                    enable_mul_1 <= '1';
                    N_M <= to_integer(unsigned(fpu_mul_1_out));

                when "011" =>
                    --error tolerance
                    L_tol_data_in <= in_data;
                    L_tol_wr <= '1';
                    L_tol_rd <= '0';
                    --then increment adr+=1
                    fpu_add_1_in_1 <= L_tol_address;
                    fpu_add_1_in_2 <= X"0001";
                    enable_add_1 <= '1';
                    L_tol_address <= fpu_add_1_out;
                    --I can prepare N_N using fpu_mul_1
                    fpu_mul_1_in_1 <= std_logic_vector(to_unsigned(N_X_A_B, fpu_mul_1_in_1'length));
                    fpu_mul_1_in_2 <= std_logic_vector(to_unsigned(N_X_A_B, fpu_mul_1_in_2'length));
                    enable_mul_1 <= '1';
                    N_N <= to_integer(unsigned(fpu_mul_1_out));
                    --used in tracking and looping
                    --N_N_temp <= to_integer(unsigned(fpu_mul_1_out));
                when "100" =>
                    --a coefficient
                    a_coeff_data_in <= in_data;
                    a_coeff_wr <= '1';
                    a_coeff_rd <= '0';
                    --then increment adr+=1
                    fpu_add_1_in_1 <= a_coeff_address;
                    fpu_add_1_in_2 <= X"0001";
                    enable_add_1 <= '1';
                    a_coeff_address <= fpu_add_1_out;

                    --I can read H here..
                    read_h_please <= '1';

                when "101" =>
                    --since we got here, then A and H are ready
                    run_a_loop <= '1';
                    --b coefficient
                    b_coeff_data_in <= in_data;
                    b_coeff_wr <= '1';
                    b_coeff_rd <= '0';
                    --then increment adr+=1
                    fpu_add_1_in_1 <= b_coeff_address;
                    fpu_add_1_in_2 <= X"0001";
                    enable_add_1 <= '1';
                    b_coeff_address <= fpu_add_1_out;
                when "110" =>
                    --Since we got here, then B and H are ready
                    run_b_loop <= '1';
                    --X0
                    X_ware_data_in <= in_data;
                    X_ware_wr <= '1';
                    X_ware_rd <= '0';
                    --then increment adr+=1
                    fpu_add_1_in_1 <= X_ware_address;
                    fpu_add_1_in_2 <= X"0001";
                    enable_add_1 <= '1';
                    X_ware_address <= fpu_add_1_out;
                when "111" =>
                    --U0
                    U_main_data_in <= in_data;
                    U_main_wr <= '1';
                    U_main_rd <= '0';
                    --then increment adr+=1
                    fpu_add_1_in_1 <= U_main_address;
                    fpu_add_1_in_2 <= X"0001";
                    enable_add_1 <= '1';
                    U_main_address <= fpu_add_1_out;
                when others =>
                    null;
            end case;
        end if;
    end process;

    --3- Error process:
    --add here any other error_out signal that might occur
    errorOccured : process(clk, err_mul_1, err_add_1)
    begin
        if rising_edge(clk) then
            if (err_mul_1 = '1'
            or  err_add_1 = '1'
            or  err_add_2 = '1'
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

    --4- Fixed Step size :D
    FIXED : process(clk, fixed_or_var, interp_done_op) 
    begin
        null;
    end process ; -- FIXED

    runA : process(clk, run_a_loop, a_is_read, h_is_read, write_a_coeff)
    variable proceed:std_logic  := '0';
    variable with_one: std_logic  := '0';
    variable first_time: std_logic  := '1';
    variable N_N_temp:  integer range 0 to 2500 ;
    begin 
        if rising_edge(clk) and run_a_loop = '1' and a_is_read = '1' and h_is_read = '1' then
            if first_time = '1' then
                N_N_temp := N_N;
                a_coeff_address<= (others => '0');
                first_time := '0';
            end if;
            N_N_temp := N_N_temp - 1;
            --we reached the end of the loop            
            if N_N_temp = 0 then 
                proceed := '0';
                --EXIT LOOP
                run_a_loop <= '0';
            else 
                proceed := '1';
            end if;
            if proceed = '1' then
                if with_one = '0' then
                    fpu_mul_1_in_1 <= a_temp;
                    fpu_mul_1_in_2 <= h_temp;
                    enable_mul_1 <= '1';
                    -- we will wait till writing :'(
                    result_a_temp <= fpu_mul_1_out;
                    with_one := '1';
                    --write_a_coeff <= '1';
                    --a_is_read <= '0'; --to read another A
                else
                    --then result_a_temp = h*A[i], and fpu_add_3 is not used because we're not reading h
                    fpu_add_3_in_1 <= result_a_temp;
                    fpu_add_3_in_2 <= X"0001";
                    enable_add_3 <= '1';
                    result_a_temp <= fpu_add_3_out;
                    with_one := '0';
                    write_a_coeff <= '1'; --write this one then read me another one
                    a_is_read <= '0'; --read another one, after this one is written
                end if;
            end if;

        end if;

    end process ; -- runA

    --This process responsible for reading coeff A at addresses [x,x+1]
    --and update the address pointer for furhter adu
    read_a_coeff : process(clk, run_a_loop, a_is_read, write_a_coeff)
    begin
        if rising_edge(clk) and run_a_loop = '1' and a_is_read = '0' and write_a_coeff = '0' then
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
                    a_is_read <= '1';
                    decrement_a_address <= '1';
                end if;
            end if;
        end if;
        --rga3 el-7aga zay ma kant!
        a_coeff_rd <= '0';
    end process ; -- read_a_coeff

    read_h_main : process(clk, h_is_read, read_h_please)
    begin
        if rising_edge(clk) and h_is_read = '0' and read_h_please='1' then
            if h_high = '0' then
                --reading the low part
                h_main_rd <= '1';
                h_temp(63 downto 32) <= h_main_data_out;
                h_high <= '1';
            else
                h_main_rd <= '1';
                h_temp(31 downto 0) <= h_main_data_out;
                h_high <= '0';
                h_is_read <= '1';
            end if;
            fpu_add_3_in_1 <= h_main_address;
            fpu_add_3_in_2 <= X"0001";
            enable_add_3 <= '1';
            h_main_address <= fpu_add_2_out;
        end if;
        --rga3 el-7aga zay ma kant!
        h_main_rd <= '0';
        enable_add_3 <= '0';
    end process ; -- read_a_coeff


    
    --PROCESS to write result_A_temp --> A[i,i+1]
    write_a : process(clk, run_a_loop, write_a_coeff )
    begin
        -- result is at result_a_temp
        -- we can't read and write at the same time, so add_2 is free
        if rising_edge(clk) and run_a_loop = '1' and write_a_coeff = '1' then
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
                end if;
            end if;
        end if;
        a_coeff_wr <= '0';
    end process ; -- write_a_coeff

    run_h_b : process( clk, run_a_loop,run_b_loop, b_is_read, h_is_read )
    variable proceed:std_logic  := '0';
    variable first_time: std_logic  := '1';
    variable N_M_temp:  integer range 0 to 2500 ;
    
    begin
        -- I will run when:
        -- clk, I have the right, A is finished, next element is read, h is read.
        if rising_edge(clk) and run_b_loop ='1' and run_a_loop ='0' and b_is_read='1' and h_is_read ='1' then
            if first_time = '1' then
                N_M_temp := N_M;
                first_time := '0';
                b_coeff_address <= (others => '0');
            end if;
            N_M_temp := N_M_temp - 1;
            --we reached the end of the loop            
            if N_N_temp = 0 then 
                proceed := '0';
                --EXIT LOOP
                run_b_loop <= '0';
            else 
                proceed := '1';
            end if;

            if proceed = '1' then
                fpu_mul_1_in_1 <= b_temp;
                fpu_mul_1_in_2 <= h_temp;
                enable_mul_1 <= '1';
                -- we will wait till writing :'(
                result_b_temp <= fpu_mul_1_out;
                write_b_coeff <= '1';
                b_is_read <= '0'; --to read another A                
            end if;
        end if;
    end process ; -- run_h_b


    read_b_coeff : process(clk, run_b_loop, b_is_read, write_b_coeff)
    begin
        if rising_edge(clk) and run_b_loop = '1' and b_is_read = '0' and write_b_coeff = '0' then
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
                    b_is_read <= '1';
                    decrement_b_address <= '1';
                end if;
            end if;
        end if;
        --rga3 el-7aga zay ma kant!
        b_coeff_rd <= '0';
    end process ; -- read_a_coeff


    write_b : process(clk, run_b_loop, write_b_coeff)
    begin
        -- result is at result_a_temp
        -- we can't read and write at the same time, so add_2 is free
        if rising_edge(clk) and run_b_loop = '1' and write_b_coeff = '1' then
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
                end if;
            end if;
        end if;
        b_coeff_wr <= '0';
    end process ; -- write_a_coeff



    inc_a_address : process( clk, increment_a_address, done_add_2 )
    begin
        if rising_edge (clk) and increment_a_address = '1' then
            if done_add_2 = '0' then
                fpu_add_2_in_1 <= a_coeff_address;
                fpu_add_2_in_2 <= X"0001";
                enable_add_2 <= '1';
            else
                a_coeff_address <= fpu_add_2_out;
                enable_add_2 <= '0';
                increment_a_address <='0';
            end if;
        end if;
    end process ; -- inc_a_address


    dec_a_address : process( clk, decrement_a_address, done_sub_1 )
    begin
        if rising_edge (clk) and decrement_a_address = '1' then
            if done_sub_1 = '0' then 
                fpu_sub_1_in_1 <= a_coeff_address;
                fpu_sub_1_in_2 <= X"0001";
                enable_sub_1 <= '1';
            else
                a_coeff_address <= fpu_add_2_out;
                enable_sub_1 <= '0';
                decrement_a_address <='0';
                
            end if;
        end if;
    end process ; -- dec_a_address

    inc_b_address : process( clk, increment_b_address,done_add_2 )
    begin
        if rising_edge (clk) and increment_b_address = '1' then
            if done_add_2 = '0' then
                fpu_add_2_in_1 <= b_coeff_address;
                fpu_add_2_in_2 <= X"0001";
                enable_add_2 <= '1';
            else
                b_coeff_address <= fpu_add_2_out;
                enable_add_2 <= '0';
                increment_b_address <='0';
                
            end if;
        end if;
    end process ; -- inc_b_address


    dec_b_address : process( clk, decrement_b_address, done_sub_1)
    begin
        if rising_edge (clk) and decrement_b_address = '1' then
            if done_sub_1 = '0' then
                fpu_sub_1_in_1 <= b_coeff_address;
                fpu_sub_1_in_2 <= X"0001";
                enable_sub_1 <= '1'; 
            else
                b_coeff_address <= fpu_add_2_out;
                enable_sub_1 <= '0';
                decrement_b_address <='0';
                
            end if;
        end if;
    end process ; -- dec_b_address






end architecture;