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

    signal X_intm_rd, X_intm_wr : std_logic    := '0';
    signal X_intm_address : std_logic_vector(6 downto 0) := (others => '0');
    signal X_intm_data_in, X_intm_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    signal X_ware_rd, X_ware_wr : std_logic    := '0';
    signal X_ware_address : std_logic_vector(9 downto 0) := (others => '0');
    signal X_ware_data_in, X_ware_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');


    signal x_temp,x_i_temp : std_logic_vector(63 downto 0) := (others => '1');
    signal x_temp_2 : std_logic_vector(63 downto 0) := X"0000000000000000";

    signal x_temp_3 : std_logic_vector(63 downto 0) := X"0000000000000180";

    signal h_adapt : std_logic_vector(63 downto 0) := X"0000000000000280";
    signal L_tol: std_logic_vector(63 downto 0) := X"0000000000000080";

    signal L_nine: std_logic_vector(63 downto 0) := (others => '0');

    signal fsm_write_1,fsm_write_2 : std_logic_vector(1 downto 0) := (others => '0');
    signal main_fsm, fsm_out : std_logic_vector(2 downto 0) := (others => '0');
    

    signal N_X_A_B_vec: std_logic_vector(5 downto 0) := "000101";
    --signal M_counter: std_logic_vector(5 downto 0) := "000010";
    --signal N_N_vec : std_logic_vector(11 downto 0) := (others => '0');
    --signal N_M_vec : std_logic_vector(11 downto 0) := (others => '0');
    
    signal N_counter_2: std_logic_vector(5 downto 0) := (others => '0');
    signal mode_sig : std_logic_vector(1 downto 0) := "00";
    --signal wares : std_logic_vector(2 downto 0) := "001";
    signal procedure_dumm : std_logic_vector(15 downto 0) := (others => '0');
    


    signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1,thisIsAdder_1 : std_logic                                  := '0';
    
    signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic                                  := '0';
    
    signal fpu_div_1_in_1, fpu_div_1_in_2, fpu_div_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_div_1, err_div_1, zero_div_1, posv_div_1, enable_div_1 : std_logic                                  := '0';
    

    
    signal c_ware : std_logic_vector(2 downto 0) := (others => '0');
    signal from_i_to_c : std_logic    := '1';
    signal fsm_run_sum_err :  std_logic_vector(3 downto 0) := (others => '0');
    signal fsm_L_nine : std_logic    := '1';
    signal err_sum  :  std_logic_vector(63 downto 0) := (others => '0');
    signal error_tolerance_is_good : std_logic    := '0';
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

        fpu_add_1 : entity work.fpu_adder(with_operators)
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
    procedure proc_run_sum_err (

        --dummies..
        signal N_counter : inout std_logic_vector(5 downto 0);
        signal fsm_read_1, fsm_read_2 : inout std_logic_vector (1 downto 0);
        signal error_check :  inout std_logic_vector (63 downto 0);
        signal fsm_run_err_h_L : inout std_logic_vector (1 downto 0)

        )is
        begin
            case(fsm_run_sum_err) is
                when "1111" =>
                    --START:
                    X_intm_address <= (others => '0');
                    err_sum <= (others =>'0');

                    x_ware_find_address
                        (c_ware => c_ware,
                        x_address_out => adr,
                        x_ware_address => x_ware_address);

                    N_counter <= N_X_A_B_vec;
                    fsm_read_1 <= "11";
                    fsm_read_2 <= "11";
                    fsm_run_sum_err <= "0001";
               
                when "0001" =>
                    --call the readers and store at x_temp and x_i_temp
                    read_reg_inc_adrs_once_64(
                        data_out => fpu_add_1_in_2,
                        reg_data_out=>X_intm_data_out,
                        reg_adrs => X_intm_address,
                        read_enbl => X_intm_rd,
                        write_enbl => X_intm_wr,
                        fsm => fsm_read_2 -->place ones (11) and wait for (00)
                        );

                    read_reg_inc_adrs_once_64(
                        data_out => fpu_add_1_in_1,
                        reg_data_out=>X_ware_data_out,
                        reg_adrs => x_ware_address,
                        read_enbl => X_ware_rd,
                        write_enbl => X_ware_wr,
                        fsm => fsm_read_1 -->place ones (11) and wait for (00)
                        );

                    if fsm_read_1 = "00" and fsm_read_2 = "00" then
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '1'; ---no SUBTRACTOR
                        fsm_run_sum_err <= "0010";
                    end if;
                    
                when "0010" =>
                    if done_add_1 = '1' then
                        enable_add_1 <= '0';
                        error_check <= fpu_add_1_out;
                        fsm_run_sum_err <= "0011";
                    end if;

                when "0011" =>

                    if posv_add_1 = '0' then
                        --negative
                        --take absolute then continue
                        --enable_add_1 <= '0';
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= error_check;
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
                        if done_mul_1 = '1' then
                            fpu_add_1_in_1 <= fpu_mul_1_out;
                            fpu_add_1_in_2 <= err_sum;
                            fsm_run_sum_err <= "0100";
                        end if;
                        
                    else
                        --positive
                        --continue
                        --enable_add_1 <= '0';
                        fpu_add_1_in_1 <= error_check;
                        fpu_add_1_in_2 <= err_sum;
                        fsm_run_sum_err <= "0100";
                    end if;


                    when "0100" =>
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        if done_add_1 = '1' then
                            err_sum <= fpu_add_1_out;
                            enable_add_1 <= '0';
                            N_counter <= to_vec(to_int(N_counter) -1, N_counter'length);
                            fsm_run_sum_err <= "0101";
                        end if;

                    when "0101" =>
                        if N_counter = "000000" then
                            X_intm_address <= (others => '0');
                            enable_add_1 <= '1';
                            thisIsAdder_1 <= '1'; --1 for sub
                            fpu_add_1_in_1 <= err_sum;
                            fpu_add_1_in_2 <= L_tol;
                            --init here, won't be affective until we reach the procedure call
                            fsm_run_err_h_L <= (others => '1');
                            fsm_run_sum_err <= "0110";
                        else
                            --keep looping
                            fsm_read_1 <= "11";
                            fsm_read_2 <= "11";
                            fsm_run_sum_err <= "0001";
                        end if;

                    when "0110" =>
                        if done_add_1 = '0' then
                            if posv_add_1 = '0' or zero_add_1 = '1' then
                                --negative or zero means err_sum <= L
                                error_tolerance_is_good <= '1';
                                fsm_run_sum_err <= "0000";
                            else
                                --positive and non-zero means err_sum > L
                                error_tolerance_is_good <= '0';
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
                                    fsm => fsm_run_err_h_L
                                    );
                                if fsm_run_err_h_L =  "00" then
                                    fsm_run_sum_err <= "0000";
                                end if;
                                fsm_run_sum_err <= "0000";
                            end if;
                        end if;

                    when others => 
                        null;
            end case ;
        end procedure;





    
    begin
        if rst = '0' and rising_edge(clk) then
            --Fill X_i with data..
            case( main_fsm ) is
                when "000" => 
                    
                    mul_L_9(
                        mode => mode_sig,
                        L_tol => L_tol,
                        L_nine => L_nine,
                        fpu_mul_1_in_1 => fpu_mul_1_in_1,
                        fpu_mul_1_in_2 => fpu_mul_1_in_2,
                        fpu_mul_1_out => fpu_mul_1_out,
                        enable_mul_1 => enable_mul_1,
                        done_mul_1 => done_mul_1,
                        fsm => fsm_L_nine
                        );

                    if fsm_L_nine = '0' then
                        N_counter_2 <= (others => '0');
                        fsm_write_1 <= "11";
                        fsm_write_2 <= "11";
                        main_fsm <= "001";
                    end if;
                when "001" =>

                write_after_read_reg (
                        data_in => x_temp_2,
                        reg_data_in => X_intm_data_in,
                        reg_adrs => X_intm_address,
                        read_enbl => X_intm_rd,
                        write_enbl => X_intm_wr,
                        fsm => fsm_write_1
                    );
                write_after_read_reg (
                        data_in => x_temp_3,
                        reg_data_in => X_ware_data_in,
                        reg_adrs => x_ware_address,
                        read_enbl => X_ware_rd,
                        write_enbl => X_ware_wr,
                        fsm => fsm_write_2
                    );

                if fsm_write_1 = "00" and fsm_write_2 = "00" then 
                        main_fsm <= "010";
                        N_counter_2 <= to_vec(to_int(N_counter_2) + 1, N_counter_2'length);
                    end if;

                when "010"=>
                    if N_counter_2 = N_X_A_B_vec then
                        main_fsm <= "011";
                        --init........
                        fsm_run_sum_err <= "1111";
                    else
                        fsm_write_1 <= "11";
                        fsm_write_2 <= "11";
                        main_fsm <= "001";
                    end if;
                when "011" =>
                    --run multiplication procedure
                    
                    proc_run_sum_err (
                        N_counter => procedure_dumm (5 downto 0),
                        fsm_read_1 =>  procedure_dumm (7 downto 6),
                        fsm_read_2 =>  procedure_dumm (9 downto 8),
                        error_check => x_temp,
                        fsm_run_err_h_L => procedure_dumm (11 downto 10)
                        );

                    if fsm_run_sum_err = "0000" then
                        main_fsm <= "111";
                    end if;
        when others =>
            null;
            end case ;
            
        end if;
    end process ;   

end architecture;

