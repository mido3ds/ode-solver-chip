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

    signal a_coeff_rd, a_coeff_wr : std_logic    := '0';
    signal a_coeff_address : std_logic_vector(12 downto 0) := (others => '0');
    signal a_coeff_data_in,a_coeff_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');


    signal x_temp : std_logic_vector(63 downto 0) := (others => '1');
    signal x_temp_1 : std_logic_vector(63 downto 0) := X"0000000000000080"; --inc + 1
    signal x_temp_2 : std_logic_vector(63 downto 0) := X"0000000000000100"; --inc + 2

    --signal x_temp_3 : std_logic_vector(63 downto 0) := X"0000000000000180";

    --signal h_adapt : std_logic_vector(63 downto 0) := X"0000000000000280";
    --signal L_tol: std_logic_vector(63 downto 0) := X"0000000000000080";

    --signal L_nine: std_logic_vector(63 downto 0) := (others => '0');

    signal fsm_write_1,fsm_write_2 : std_logic_vector(1 downto 0) := (others => '0');
    signal main_fsm, fsm_out : std_logic_vector(2 downto 0) := (others => '0');
    

    signal N_X_A_B_vec, N_counter: std_logic_vector(5 downto 0) := "000011";
    --signal M_counter: std_logic_vector(5 downto 0) := "000010";
    signal N_N,N_N_counter : std_logic_vector(15 downto 0) := (others => '0');
    --signal N_M_vec : std_logic_vector(11 downto 0) := (others => '0');
    
    --signal N_counter_2: std_logic_vector(5 downto 0) := (others => '0');
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
    signal new_entry  :  std_logic_vector(63 downto 0) := (others => '0');
    signal error_tolerance_is_good : std_logic    := '0';
    signal fsm_run_a_x : std_logic_vector (2 downto 0);


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

        fpu_add_1 : entity work.fpu_adder(first_algo)
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
        
        

    main_proc : process(clk, rst)
  procedure proc_run_a_x (
        signal fsm_read_a, fsm_read_x, fsm_write_x : inout std_logic_vector(1 downto 0);
        signal N_N_counter : inout std_logic_vector(15 downto 0);
        signal N_counter : inout std_logic_vector(5 downto 0)

        )is
        begin 
            case(fsm_run_a_x) is
                when "111" =>
                    -- initialization
                    N_N_counter <= N_N;
                    N_counter <= N_X_A_B_vec;
                    new_entry <= (others => '0');
                    
                    fsm_read_a <= "11";
                    fsm_read_X <= "11";
                    X_intm_address <= (others => '0');
                    a_coeff_address <= (others => '0');
                    x_ware_find_address
                        (c_ware => c_ware,
                        x_address_out => adr,
                        x_ware_address => x_ware_address);
                    fsm_run_a_x <= "010";
                when "010" =>
                    
                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_2,
                        reg_data_out=>X_ware_data_out,
                        reg_adrs => x_ware_address,
                        read_enbl => X_ware_rd,
                        write_enbl => X_ware_wr,
                        fsm => fsm_read_x -->place ones (11) and wait for (00)
                        );

                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_1,
                        reg_data_out=>a_coeff_data_out,
                        reg_adrs => a_coeff_address,
                        read_enbl => a_coeff_rd,
                        write_enbl => a_coeff_wr,
                        fsm => fsm_read_a -->place ones (11) and wait for (00)
                        );

                    if fsm_read_a = "00" and fsm_read_x = "00" then --check for read completion
                       
                        enable_mul_1 <= '1';
                        thisIsAdder_1 <= '0';
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
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        N_N_counter <= to_vec(to_int(N_N_counter) -1, N_N_counter'length);
                        N_counter <= to_vec(to_int(N_counter) -1, N_counter'length);
                        fsm_write_x <= "11";
                        fsm_run_a_x <= "101";
                    end if;
                when "101" =>
                    if N_counter = "000000" then
                        write_after_read_reg(
                            data_in => new_entry,
                            reg_data_in => X_intm_data_in,
                            reg_adrs => X_intm_address,
                            read_enbl => X_intm_rd,
                            write_enbl => X_intm_wr,
                            fsm => fsm_write_x
                            );
                        if fsm_write_x = "00" then
                            N_counter <= N_X_A_B_vec; --reset N
                            new_entry <= (others => '0');
                            x_ware_find_address
                                (c_ware => c_ware,
                                x_address_out => adr,
                                x_ware_address => x_ware_address);
                            fsm_run_a_x <= "110";
                        end if;
                    else
                        fsm_run_a_x <= "110";
                    end if;
                    
                when "110" =>
                    if N_N_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_a_x <= "000"; --return to the NOP state
                    else
                        fsm_read_a <= "11";
                        fsm_read_X <= "11";
                        fsm_run_a_x <= "010"; --return to the loop start
                    end if;
                when others =>
                    --NOP state
                    null;
            end case ;
        end procedure;


    
    begin
        if rst = '0' and rising_edge(clk) then
            --Fill X_i with data..
            case( main_fsm ) is
                when "000" => 
                    
                    N_N <= to_vec ( to_int(N_X_A_B_vec)* to_int(N_X_A_B_vec) ,N_N'length);
                    N_N_counter <= (others => '0');
                    a_coeff_address <= (others => '0');
                    fsm_write_1 <= "11";
                    main_fsm <= "001";
                when "001" =>

                write_after_read_reg (
                        data_in => x_temp_1,
                        reg_data_in => a_coeff_data_in,
                        reg_adrs => a_coeff_address,
                        read_enbl => a_coeff_rd,
                        write_enbl => a_coeff_wr,
                        fsm => fsm_write_1
                    );
                

                if fsm_write_1 = "00" then 
                        main_fsm <= "010";
                        N_N_counter <= to_vec(to_int(N_N_counter) + 1, N_N_counter'length);
                        x_temp_1 <= to_vec(to_int(x_temp_1) + 128, x_temp_1'length);
                        
                    end if;

                when "010"=>
                    if N_N_counter = N_N then
                        main_fsm <= "011";
                        --init........
                        x_ware_find_address
                            (c_ware => c_ware,
                            x_address_out => adr,
                            x_ware_address => x_ware_address);
                        fsm_write_1 <= "11";
                        N_counter <= (others => '0');
                        --fsm_run_sum_err <= "1111";
                    else
                        fsm_write_1 <= "11";
                        main_fsm <= "001";
                    end if;

                when "011" =>
                    write_after_read_reg (
                        data_in => x_temp_2,
                        reg_data_in => X_ware_data_in,
                        reg_adrs => x_ware_address,
                        read_enbl => X_ware_rd,
                        write_enbl => X_ware_wr,
                        fsm => fsm_write_1
                        );
                    if fsm_write_1 = "00" then
                        main_fsm <= "100";
                        N_counter <= to_vec(to_int(N_counter) + 1, N_counter'length);
                        x_temp_2 <= to_vec(to_int(x_temp_2) + 256, x_temp_2'length);
                    end if;


                when "100" =>
                    if N_counter = N_X_A_B_vec then
                        --end
                        main_fsm <= "101";
                        fsm_run_a_x <= "111";
                        ----------------------init
                    else
                        fsm_write_1 <= "11";
                        main_fsm <= "011";
                    end if;
                when "101" =>
                    --run multiplication procedure
                    proc_run_a_x(
                        fsm_read_a => procedure_dumm (1 downto 0),
                        fsm_read_x => procedure_dumm (3 downto 2),
                        fsm_write_x => procedure_dumm (5 downto 4),
                        N_N_counter => x_temp (15 downto 0),
                        N_counter => procedure_dumm (11 downto 6)
                        );

                    if fsm_run_a_x = "000" then
                        main_fsm <= "111";
                    end if;
        when others =>
            null;
            end case ;
            
        end if;
    end process ;   

end architecture;

