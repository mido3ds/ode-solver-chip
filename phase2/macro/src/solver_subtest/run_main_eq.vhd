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
    signal x_i_temp : std_logic_vector (63 downto 0) := (others => '0');

    signal u_main_rd, u_main_wr : std_logic    := '0';
    signal u_main_address : std_logic_vector(6 downto 0) := (others => '0');
    signal u_main_data_in, u_main_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    signal X_ware_rd, X_ware_wr : std_logic    := '0';
    signal X_ware_address : std_logic_vector(9 downto 0) := (others => '0');
    signal X_ware_data_in, X_ware_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    signal a_coeff_rd, a_coeff_wr : std_logic    := '0';
    signal a_coeff_address : std_logic_vector(12 downto 0) := (others => '0');
    signal a_coeff_data_in,a_coeff_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    signal b_coeff_rd, b_coeff_wr : std_logic    := '0';
    signal b_coeff_address : std_logic_vector(12 downto 0) := (others => '0');
    signal b_coeff_data_in,b_coeff_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');


    signal x_temp : std_logic_vector(63 downto 0) := (others => '1');
    signal x_temp_1 : std_logic_vector(63 downto 0) := X"0000000000000080"; --inc + 1
    signal x_temp_2 : std_logic_vector(63 downto 0) := X"0000000000000100"; --inc + 2
    signal x_temp_3 : std_logic_vector(63 downto 0) := X"0000000000000000"; 

    --signal x_temp_3 : std_logic_vector(63 downto 0) := X"0000000000000180";

    signal h_adapt : std_logic_vector(63 downto 0) := X"0000000000000080";--1
    signal h_div : std_logic_vector(63 downto 0) := X"0000000000000180";--3


    signal fsm_write_1,fsm_write_2,fsm_write_3 : std_logic_vector(1 downto 0) := (others => '0');
    signal main_fsm, fsm_out : std_logic_vector(2 downto 0) := (others => '0');
    

    signal N_X_A_B_vec, N_counter: std_logic_vector(5 downto 0) := "000011";
    signal M_U_B_vec , M_counter : std_logic_vector(5 downto 0) := "000011";

    signal N_N,N_N_counter : std_logic_vector(15 downto 0) := (others => '0');
    signal N_M,N_M_counter : std_logic_vector(15 downto 0) := (others => '0');
    
    signal mode_sig : std_logic_vector(1 downto 0) := "00";
    
    signal procedure_dumm : std_logic_vector(63 downto 0) := (others => '0');
    signal x_temp_dump : std_logic_vector(63 downto 0) := (others => '0');


    signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1,thisIsAdder_1 : std_logic                                  := '0';
    
    signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic                                  := '0';
    
    signal fpu_div_1_in_1, fpu_div_1_in_2, fpu_div_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_div_1, err_div_1, zero_div_1, posv_div_1, enable_div_1 : std_logic                                  := '0';
    

    
    signal c_ware : std_logic_vector(2 downto 0) := (others => '0');
    signal from_i_to_c, div_or_adapt : std_logic    := '0';
    signal new_entry  :  std_logic_vector(63 downto 0) := (others => '0');
    
    --fsms:

    signal fsm_run_a_x_2,fsm_run_a_x,fsm_run_x_i_c, fsm_run_x_h : std_logic_vector(2 downto 0) := (others => '0');
    signal fsm_run_x_b_u, fsm_run_x_b_u_2 :std_logic_vector(3 downto 0) := (others => '0');
    signal fsm_main_eq : std_logic_vector (2 downto 0) := (others => '0');

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

    U_main : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
        port map(
            clk      => clk,
            rd       => u_main_rd,
            wr       => u_main_wr,
            address  => u_main_address,
            data_in  => u_main_data_in,
            data_out => u_main_data_out,
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

    b_coeff : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 5000, ADR_LENGTH=>13)
        port map(
            clk      => clk,
            rd       => b_coeff_rd,
            wr       => b_coeff_wr,
            address  => b_coeff_address,
            data_in  => b_coeff_data_in,
            data_out => b_coeff_data_out,
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

    procedure proc_run_a_x_2 (
        signal fsm_read_a, fsm_read_x, fsm_write_x : inout std_logic_vector(1 downto 0);
        signal N_N_counter : inout std_logic_vector(15 downto 0);
        signal N_counter : inout std_logic_vector(5 downto 0)

        )is
        begin 
            case(fsm_run_a_x_2) is
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
                    fsm_run_a_x_2 <= "010";
                when "010" =>
                    
                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_2,
                        reg_data_out=>X_intm_data_out,
                        reg_adrs => X_intm_address,
                        read_enbl => X_intm_rd,
                        write_enbl => X_intm_wr,
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
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        N_N_counter <= to_vec(to_int(N_N_counter) -1, N_N_counter'length);
                        N_counter <= to_vec(to_int(N_counter) -1, N_counter'length);
                        fsm_write_x <= "11";
                        fsm_run_a_x_2 <= "101";
                    end if;
                when "101" =>
                    if N_counter = "000000" then
                        write_after_read_reg(
                            data_in => new_entry,
                            reg_data_in => X_ware_data_in,
                            reg_adrs => x_ware_address,
                            read_enbl => X_ware_rd,
                            write_enbl => X_ware_wr,
                            fsm => fsm_write_x
                            );
                        if fsm_write_x = "00" then
                            N_counter <= N_X_A_B_vec; --reset N
                            new_entry <= (others => '0');
                            X_intm_address <= (others => '0');
                            fsm_run_a_x_2 <= "110";
                        end if;
                    else
                        fsm_run_a_x_2 <= "110";
                    end if;
                    
                when "110" =>
                    if N_N_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_a_x_2 <= "000"; --return to the NOP state
                    else
                        fsm_read_a <= "11";
                        fsm_read_X <= "11";
                        fsm_run_a_x_2 <= "010"; --return to the loop start
                    end if;
                when others =>
                    --NOP state
                    null;
            end case ;
        end procedure;
    
    procedure proc_run_x_b_u_2 (
        signal fsm_read_b, fsm_read_x,fsm_read_u, fsm_write_x : inout std_logic_vector(1 downto 0);
        signal N_M_counter : inout std_logic_vector(15 downto 0);
        signal M_counter : inout std_logic_vector(5 downto 0)

        )is
        begin 
            case(fsm_run_x_b_u_2) is
                when "1111" =>
                    -- initialization
                    N_M_counter <= N_M;
                    M_counter <= M_U_B_vec;
                    new_entry <= (others => '0');
                    
                    fsm_read_b <= "11";
                    fsm_read_u <= "11";
                    x_ware_find_address
                        (c_ware => c_ware,
                        x_address_out => adr,
                        x_ware_address => x_ware_address);
                    --X_intm_address <= (others => '0');
                    b_coeff_address <= (others => '0');
                    u_main_address <= (others => '0');
                    
                    fsm_run_x_b_u_2 <= "0010";
                when "0010" =>
                    
                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_2,
                        reg_data_out=>u_main_data_out,
                        reg_adrs => u_main_address,
                        read_enbl => U_main_rd,
                        write_enbl => u_main_wr,
                        fsm => fsm_read_u -->place ones (11) and wait for (00)
                        );

                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_1,
                        reg_data_out=> b_coeff_data_out,
                        reg_adrs => b_coeff_address,
                        read_enbl => b_coeff_rd,
                        write_enbl => b_coeff_wr,
                        fsm => fsm_read_b -->place ones (11) and wait for (00)
                        );

                    if fsm_read_b = "00" and fsm_read_u = "00" then --check for read completion
                        enable_mul_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_x_b_u_2 <= "0011";
                    end if;

                when "0011" =>
                    if done_mul_1 = '1' then --check for multiply completion
                        --add ax to the current entry
                        enable_mul_1 <= '0';
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= new_entry;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_x_b_u_2 <= "0100";
                    end if;

                when "0100" =>
                    if done_add_1 = '1' then --check for add completion
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        N_M_counter <= to_vec(to_int(N_M_counter) -1, N_M_counter'length);
                        M_counter <= to_vec(to_int(M_counter) -1, M_counter'length);
                        --it may be it may not...
                        fsm_read_x <= "11";
                        fsm_run_x_b_u_2 <= "0101";
                    end if;

                when "0101" =>
                    if M_counter = "000000" then
                        --read x_i
                        --add the value at new_entry
                        --store at x_intm
                        u_main_address <= (others => '0');
                        read_before_write_reg(
                            data_out => fpu_add_1_in_1,
                            reg_data_out=>X_ware_data_out,
                            reg_adrs => X_ware_address,
                            read_enbl => X_ware_rd,
                            write_enbl => X_ware_wr,
                            fsm => fsm_read_x -->place ones (11) and wait for (00)
                            );
                        if fsm_read_x = "00" then
                            fpu_add_1_in_2 <= new_entry;
                            enable_add_1 <= '1';
                            fsm_write_x <= "11";
                            fsm_run_x_b_u_2 <= "0111";
                        end if;
                    else
                        fsm_run_x_b_u_2 <= "0110";
                    end if;
                when "0111" =>
                    if done_add_1 = '1' then
                        write_after_read_reg(
                            data_in => fpu_add_1_out,
                            reg_data_in => X_ware_data_in,
                            reg_adrs => X_ware_address,
                            read_enbl => X_ware_rd,
                            write_enbl => X_ware_wr,
                            fsm => fsm_write_x
                            );
                        if fsm_write_x = "00" then
                            M_counter <= M_U_B_vec; --reset N
                            new_entry <= (others => '0');
                            fsm_run_x_b_u_2 <= "0110";
                        end if;
                    end if;
                        
                when "0110" =>
                    if N_M_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_x_b_u_2 <= "0000"; --return to the NOP state
                    else
                        fsm_read_b <= "11";
                        fsm_read_u <= "11";
                        fsm_run_x_b_u_2 <= "0010"; --return to the loop start
                    end if;
                when others =>
                    --NOP state
                    null;
            end case ;
        end procedure;

    procedure proc_run_x_b_u (
        signal fsm_read_b, fsm_read_x,fsm_read_u, fsm_write_x : inout std_logic_vector(1 downto 0);
        signal N_M_counter : inout std_logic_vector(15 downto 0);
        signal M_counter : inout std_logic_vector(5 downto 0)

        )is
        begin 
            case(fsm_run_x_b_u) is
                when "1111" =>
                    -- initialization
                    N_M_counter <= N_M;
                    M_counter <= M_U_B_vec;
                    new_entry <= (others => '0');
                    
                    fsm_read_b <= "11";
                    fsm_read_u <= "11";

                    X_intm_address <= (others => '0');
                    b_coeff_address <= (others => '0');
                    u_main_address <= (others => '0');
                    
                    fsm_run_x_b_u <= "0010";
                when "0010" =>
                    
                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_2,
                        reg_data_out=>u_main_data_out,
                        reg_adrs => u_main_address,
                        read_enbl => U_main_rd,
                        write_enbl => u_main_wr,
                        fsm => fsm_read_u -->place ones (11) and wait for (00)
                        );

                    read_reg_inc_adrs_once_64
                        (
                        data_out => fpu_mul_1_in_1,
                        reg_data_out=> b_coeff_data_out,
                        reg_adrs => b_coeff_address,
                        read_enbl => b_coeff_rd,
                        write_enbl => b_coeff_wr,
                        fsm => fsm_read_b -->place ones (11) and wait for (00)
                        );

                    if fsm_read_b = "00" and fsm_read_u = "00" then --check for read completion
                        enable_mul_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_x_b_u <= "0011";
                    end if;

                when "0011" =>
                    if done_mul_1 = '1' then --check for multiply completion
                        --add ax to the current entry
                        enable_mul_1 <= '0';
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= new_entry;
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_x_b_u <= "0100";
                    end if;

                when "0100" =>
                    if done_add_1 = '1' then --check for add completion
                        enable_add_1 <= '0';
                        new_entry <= fpu_add_1_out;
                        N_M_counter <= to_vec(to_int(N_M_counter) -1, N_M_counter'length);
                        M_counter <= to_vec(to_int(M_counter) -1, M_counter'length);
                        --it may be it may not...
                        fsm_read_x <= "11";
                        fsm_run_x_b_u <= "0101";
                    end if;

                when "0101" =>
                    if M_counter = "000000" then
                        --read x_i
                        --add the value at new_entry
                        --store at x_intm
                        u_main_address <= (others => '0');
                        read_before_write_reg(
                            data_out => fpu_add_1_in_1,
                            reg_data_out=>X_intm_data_out,
                            reg_adrs => X_intm_address,
                            read_enbl => X_intm_rd,
                            write_enbl => X_intm_wr,
                            fsm => fsm_read_x -->place ones (11) and wait for (00)
                            );
                        if fsm_read_x = "00" then
                            fpu_add_1_in_2 <= new_entry;
                            enable_add_1 <= '1';
                            fsm_write_x <= "11";
                            fsm_run_x_b_u <= "0111";
                        end if;
                    else
                        fsm_run_x_b_u <= "0110";
                    end if;
                when "0111" =>
                    if done_add_1 = '1' then
                        write_after_read_reg(
                            data_in => fpu_add_1_out,
                            reg_data_in => X_intm_data_in,
                            reg_adrs => X_intm_address,
                            read_enbl => X_intm_rd,
                            write_enbl => X_intm_wr,
                            fsm => fsm_write_x
                            );
                        if fsm_write_x = "00" then
                            M_counter <= M_U_B_vec; --reset N
                            new_entry <= (others => '0');
                            fsm_run_x_b_u <= "0110";
                        end if;
                    end if;
                        
                when "0110" =>
                    if N_M_counter = X"0000" then --check if the end of the loop is reached
                        fsm_run_x_b_u <= "0000"; --return to the NOP state
                    else
                        fsm_read_b <= "11";
                        fsm_read_u <= "11";

                        fsm_run_x_b_u <= "0010"; --return to the loop start
                    end if;
                when others =>
                    --NOP state
                    null;
            end case ;
        end procedure;

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

    procedure proc_run_x_i_c (
        --both have the same length, this is the iterator
        signal N_counter : inout std_logic_vector(5 downto 0);
        --no need for that
        --signal c_ware : std_logic_vector (2 downto 0);
        -- incremented address for x_intm
        --signal reg_address: std_logic_vector (9 downto 0);
        --to enable/disable read for both x_ware and x_intm
        signal fsm_read_1, fsm_read_2, fsm_write_1 : inout std_logic_vector (1 downto 0);
        --my dummies
        signal dumm : inout std_logic_vector (15 downto 0)
        

        )is

        begin
            case(fsm_run_x_i_c) is
                when "111" =>
                    X_intm_address <= (others => '0');
                    --decrement first m3l4 :D
                    --N_counter = N - 1
                    --if N = 5, loops when N_counter = 4,3,2,1,0 (loop then exit)
                    N_counter <= to_vec(to_int(N_X_A_B_vec) -1, N_counter'length);
                    x_ware_find_address
                        (c_ware => c_ware,
                        x_address_out => adr,
                        x_ware_address => x_ware_address);

                    fsm_read_1 <= "11";
                    fsm_read_2 <= "11";
                    fsm_run_x_i_c <= "001";


                when "001" =>
                --depending on from_i_to_c 
                -- from_i_to_c = 1 --> x_w = X_i + x_w --> read_x_i_normal, read_befire_write x_w
                --             = 0 --> x_i = x_i + x_w --> read_x_w_normal, read_befire_write x_i
                    if from_i_to_c = '0' then
                        --No, from c to i, then i will be overwritten
                        read_before_write_reg(
                            data_out => x_i_temp,
                            reg_data_out=>X_intm_data_out,
                            reg_adrs => X_intm_address,
                            read_enbl => X_intm_rd,
                            write_enbl => X_intm_wr,
                            fsm => fsm_read_2 -->place ones (11) and wait for (00)
                            );

                        read_reg_inc_adrs_once_64(
                            data_out => x_temp,
                            reg_data_out=>X_ware_data_out,
                            reg_adrs => x_ware_address,
                            read_enbl => X_ware_rd,
                            write_enbl => X_ware_wr,
                            fsm => fsm_read_1 -->place ones (11) and wait for (00)
                            );
                    else
                        --yes, from i to c
                        read_before_write_reg
                            (
                            data_out => x_temp,
                            reg_data_out=>X_ware_data_out,
                            reg_adrs => x_ware_address,
                            read_enbl => X_ware_rd,
                            write_enbl => X_ware_wr,
                            fsm => fsm_read_1 -->place ones (11) and wait for (00)
                            ); 

                        read_reg_inc_adrs_once_64(
                            data_out => x_i_temp,
                            reg_data_out=>X_intm_data_out,
                            reg_adrs => X_intm_address,
                            read_enbl => X_intm_rd,
                            write_enbl => X_intm_wr,
                            fsm => fsm_read_2 -->place ones (11) and wait for (00)
                            );
                    end if;
                    
                    if fsm_read_1 = "00" and fsm_read_2 = "00" then
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fpu_add_1_in_1 <= x_temp;
                        fpu_add_1_in_2 <= x_i_temp;
                        fsm_write_1 <= "11";

                        fsm_run_x_i_c <= "010";
                    end if;
                    
                when "010" =>
                   if done_add_1 = '1' then
                        --where to write at ?????

                        if from_i_to_c = '0' then
                            --no, from c to i, we will write at i
                            write_after_read_reg(
                                data_in => fpu_add_1_out,
                                reg_data_in => X_intm_data_in,
                                reg_adrs => X_intm_address,
                                read_enbl => X_intm_rd,
                                write_enbl => X_intm_wr,
                                fsm => fsm_write_1
                                );

                        else
                            write_after_read_reg(
                                data_in => fpu_add_1_out,
                                reg_data_in => X_ware_data_in,
                                reg_adrs => x_ware_address,
                                read_enbl => X_ware_rd,
                                write_enbl => X_ware_wr,
                                fsm => fsm_write_1
                                );
                        end if;

                        if fsm_write_1 = "00" then
                            enable_add_1 <= '0';
                            if N_counter = "000000" then
                                --end loop
                                --This trick to make sure that adress of X_ware is updated
                                --without updating c_ware
                                X_intm_address <= (others => '0');
                                fsm_run_x_i_c <= "000";
                            else
                                --LOOP AGAIN
                                N_counter <= to_vec(to_int(N_counter) -1, N_counter'length);
                                fsm_read_1 <= "11";
                                fsm_read_2 <= "11";
                                fsm_run_x_i_c <= "001";
                            end if;
                        end if;
                    end if;
             
                when others =>
                        null;
            end case;
        end procedure;

    procedure proc_run_main_eq is
        begin
            case(fsm_main_eq) is
                when "111" =>
                    --Let's start ya ray2
                    X_intm_address <= (others => '0');
                    --fsm_h_sent_U_recv <= (others => '1');
                    x_ware_find_address
                        (c_ware => c_ware,
                        --adr: could be any dummy. I don't need it...
                        x_address_out => adr,
                        x_ware_address => x_ware_address);
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

                        --proc_h_sent_U_recv(
                        --    N_counter_2 => procedure_dumm (5 downto 0)
                        --    );
                        proc_run_a_x (
                            fsm_read_a => procedure_dumm (17 downto 16),
                            fsm_read_x => procedure_dumm (15 downto 14),
                            fsm_write_x => procedure_dumm (13 downto 12),
                            N_N_counter => x_temp_dump(15 downto 0),
                            N_counter => procedure_dumm (11 downto 6)
                            );
                        --no, from c to i, regular
                        --NOTE: fsm_h_sent_U_recv is not triggered by this proc..
                        if fsm_run_a_x = "000" then
                            --then X_i = A * X_w and U_main is prepared
                            fsm_run_x_b_u <= (others => '1');
                            fsm_run_x_b_u_2 <= (others => '0');
                            u_main_address <= (others => '0');
                            X_intm_address <= (others => '0');
                            a_coeff_address <= (others => '0');
                            b_coeff_address <= (others => '0');
                            x_ware_find_address
                                (c_ware => c_ware,
                                --adr: could be any dummy. I don't need it...
                                x_address_out => adr,
                                x_ware_address => x_ware_address);
                            fsm_main_eq <= "101";
                        end if;
                    else
                        --proc_h_sent_U_recv(
                        --    N_counter_2 => procedure_dumm (5 downto 0)
                        --    );
                        proc_run_a_x_2 (
                            fsm_read_a => procedure_dumm (17 downto 16),
                            fsm_read_x => procedure_dumm (15 downto 14),
                            fsm_write_x => procedure_dumm (13 downto 12),
                            N_N_counter => x_temp_dump(15 downto 0),
                            N_counter => procedure_dumm (11 downto 6)
                            );
                        --yes, irregular
                        --NOTE: fsm_h_sent_U_recv is not triggered by this proc..
                        if fsm_run_a_x_2 = "000"  then
                            --then X_i = A * X_w and U_main is prepared
                            x_ware_find_address
                                (c_ware => c_ware,
                                --adr: could be any dummy. I don't need it...
                                x_address_out => adr,
                                x_ware_address => x_ware_address);
                            u_main_address <= (others => '0');
                            X_intm_address <= (others => '0');
                            a_coeff_address <= (others => '0');
                            b_coeff_address <= (others => '0');
                            fsm_run_x_b_u_2 <= (others => '1');
                            fsm_run_x_b_u <= (others => '0');
                            
                            fsm_main_eq <= "101";
                        end if;
                    end if;
                when "101" =>
                    --Do not worry, one of them will be called only
                    proc_run_x_b_u(
                        fsm_read_b => procedure_dumm (1 downto 0),
                        fsm_read_x => procedure_dumm (3 downto 2),
                        fsm_write_x => procedure_dumm (5 downto 4),
                        N_M_counter => x_temp_dump(15 downto 0),
                        M_counter => procedure_dumm (11 downto 6),
                        fsm_read_u => procedure_dumm (13 downto 12)
                        );
                    proc_run_x_b_u_2(
                        fsm_read_b => procedure_dumm (1 downto 0),
                        fsm_read_x => procedure_dumm (3 downto 2),
                        fsm_write_x => procedure_dumm (5 downto 4),
                        N_M_counter => x_temp_dump(15 downto 0),
                        M_counter => procedure_dumm (11 downto 6),
                        fsm_read_u => procedure_dumm (13 downto 12)
                        );
                    
                    if fsm_run_x_b_u = "0000" and fsm_run_x_b_u_2 = "0000" then
                        u_main_address <= (others => '0');
                        X_intm_address <= (others => '0');
                        a_coeff_address <= (others => '0');
                        b_coeff_address <= (others => '0');
                        x_ware_find_address
                            (c_ware => c_ware,
                            --adr: could be any dummy. I don't need it...
                            x_address_out => adr,
                            x_ware_address => x_ware_address);

                        fsm_run_x_h <= (others =>'1');
                        fsm_main_eq <= "010";
                    end if;
                    
                --when "110" =>

                when "010" => 
                    --I don't remember why I put fsm_run_h_2 here!!
                    --may be it has smth to do with main_procedure
                    
                    if from_i_to_c = '0' then
                        if div_or_adapt = '0' then
                            --X: X_i
                            --h: h_div
                            mul_vector_by_number(
                                fpu_mul_1_in_2 => fpu_mul_1_in_2,
                                fpu_mul_1_in_1 => fpu_mul_1_in_1,
                                fpu_mul_1_out => fpu_mul_1_out,
                                enable_mul_1 => enable_mul_1,
                                done_mul_1 => done_mul_1,

                                reg_data_out => X_intm_data_out,
                                reg_data_in => X_intm_data_in,
                                reg_address => X_intm_address,
                                read_enbl => X_intm_rd,
                                write_enbl => X_intm_wr,

                                N_vec => N_X_A_B_vec,
                                numb => h_div,
                                fsm =>fsm_run_x_h,
                                -------------You can use any dummy signal here, but make sure no one writes at it--------------------
                                N_counter => procedure_dumm(10 downto 5),
                                my_reg => x_temp_dump,
                                fsm_read =>procedure_dumm(4 downto 3),
                                fsm_write =>procedure_dumm(1 downto 0)        
                                );
                        else
                            --X: X_i
                            --h: h_adapt
                            mul_vector_by_number(
                                fpu_mul_1_in_2 => fpu_mul_1_in_2,
                                fpu_mul_1_in_1 => fpu_mul_1_in_1,
                                fpu_mul_1_out => fpu_mul_1_out,
                                enable_mul_1 => enable_mul_1,
                                done_mul_1 => done_mul_1,

                                reg_data_out => X_intm_data_out,
                                reg_data_in => X_intm_data_in,
                                reg_address => X_intm_address,
                                read_enbl => X_intm_rd,
                                write_enbl => X_intm_wr,

                                N_vec => N_X_A_B_vec,
                                numb => h_adapt,
                                fsm =>fsm_run_x_h,
                                -------------You can use any dummy signal here, but make sure no one writes at it--------------------
                                N_counter => procedure_dumm(10 downto 5),
                                my_reg => x_temp_dump,
                                fsm_read =>procedure_dumm(4 downto 3),
                                fsm_write =>procedure_dumm(1 downto 0)        
                                );
                        end if;
                    else
                        if div_or_adapt = '0' then
                            --X: X_ware
                            --h: h_div
                            mul_vector_by_number(
                                fpu_mul_1_in_2 => fpu_mul_1_in_2,
                                fpu_mul_1_in_1 => fpu_mul_1_in_1,
                                fpu_mul_1_out => fpu_mul_1_out,
                                enable_mul_1 => enable_mul_1,
                                done_mul_1 => done_mul_1,

                                reg_data_out => X_ware_data_out,
                                reg_data_in => X_ware_data_in,
                                reg_address => x_ware_address,
                                read_enbl => X_ware_rd,
                                write_enbl => X_ware_wr,

                                N_vec => N_X_A_B_vec,
                                numb => h_div,
                                fsm =>fsm_run_x_h,
                                -------------You can use any dummy signal here, but make sure no one writes at it--------------------
                                N_counter => procedure_dumm(10 downto 5),
                                my_reg => x_temp_dump,
                                fsm_read =>procedure_dumm(4 downto 3),
                                fsm_write =>procedure_dumm(1 downto 0)        
                                );
                        else
                            --X: X_ware
                            --h: h_adapt
                                mul_vector_by_number(
                                    fpu_mul_1_in_2 => fpu_mul_1_in_2,
                                    fpu_mul_1_in_1 => fpu_mul_1_in_1,
                                    fpu_mul_1_out => fpu_mul_1_out,
                                    enable_mul_1 => enable_mul_1,
                                    done_mul_1 => done_mul_1,

                                    reg_data_out => X_ware_data_out,
                                    reg_data_in => X_ware_data_in,
                                    reg_address => x_ware_address,
                                    read_enbl => X_ware_rd,
                                    write_enbl => X_ware_wr,

                                    N_vec => N_X_A_B_vec,
                                    numb => h_adapt,
                                    fsm =>fsm_run_x_h,
                                    -------------You can use any dummy signal here, but make sure no one writes at it--------------------
                                    N_counter => procedure_dumm(10 downto 5),
                                    my_reg => x_temp_dump,
                                    fsm_read =>procedure_dumm(4 downto 3),
                                    fsm_write =>procedure_dumm(1 downto 0)        
                                    );
                        end if;
                    end if;

                    if fsm_run_x_h = "000" then
                        fsm_run_x_i_c <= (others => '1');
                        u_main_address <= (others => '0');
                        X_intm_address <= (others => '0');
                        a_coeff_address <= (others => '0');
                        b_coeff_address <= (others => '0');
                        x_ware_find_address
                            (c_ware => c_ware,
                            --adr: could be any dummy. I don't need it...
                            x_address_out => adr,
                            x_ware_address => x_ware_address);
                        fsm_main_eq <= "100";
                    end if; 
                    
                when "100" =>
                    proc_run_x_i_c(
                        N_counter => procedure_dumm(5 downto 0),
                        fsm_read_1 => procedure_dumm(7 downto 6),
                        fsm_read_2 => procedure_dumm(9 downto 8),
                        fsm_write_1 => procedure_dumm(11 downto 10),
                        dumm => procedure_dumm(27 downto 12)
                        );
                    if fsm_run_x_i_c = "000" then
                        fsm_main_eq <= "000";
                    end if;
                when others =>
                    --zeros
                    null;
            end case;
        end procedure;








    begin
        if rst = '0' and rising_edge(clk) then
            --Fill X_i with data..
            case( main_fsm ) is
                when "000" => 
                    
                    N_N <= to_vec ( to_int(N_X_A_B_vec)* to_int(N_X_A_B_vec) ,N_N'length);
                    N_M <= to_vec ( to_int(N_X_A_B_vec)* to_int(M_U_B_vec) ,N_M'length);
                    N_N_counter <= (others => '0');
                    a_coeff_address <= (others => '0');
                    b_coeff_address <= (others => '0');
                    fsm_write_1 <= "11";
                    fsm_write_2 <= "11";
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
                write_after_read_reg (
                        data_in => x_temp_2,
                        reg_data_in => b_coeff_data_in,
                        reg_adrs => b_coeff_address,
                        read_enbl => b_coeff_rd,
                        write_enbl => b_coeff_wr,
                        fsm => fsm_write_2
                    );

                if fsm_write_1 = "00" and fsm_write_2 = "00" then 
                        main_fsm <= "010";
                        N_N_counter <= to_vec(to_int(N_N_counter) + 1, N_N_counter'length);
                        x_temp_1 <= to_vec(to_int(x_temp_1) + 128, x_temp_1'length); --inc 1
                        x_temp_2 <= to_vec(to_int(x_temp_2) + 256, x_temp_2'length); --inc 2
                    end if;

                when "010"=>
                    if N_N_counter = N_N then
                        main_fsm <= "011";
                        --init........
                        x_ware_find_address
                            (c_ware => c_ware,
                            x_address_out => adr,
                            x_ware_address => x_ware_address);
                        X_intm_address <= (others => '0');
                        u_main_address <= (others => '0');
                        x_temp_1 <= X"0000000000000080"; -- 1
                        x_temp_2 <= X"0000000000000100"; -- 2
                        x_temp_3 <= X"0000000000000180"; -- 3
                        fsm_write_1 <= "11";
                        fsm_write_2 <= "11";
                        fsm_write_3 <= "11";
                        N_counter <= (others => '0');
                    else
                        fsm_write_1 <= "11";
                        fsm_write_2 <= "11";
                        main_fsm <= "001";
                    end if;

                when "011" =>
                ------------------x i----------------1,2,3
                    write_after_read_reg (
                        data_in => x_temp_1,
                        reg_data_in => X_intm_data_in,
                        reg_adrs => X_intm_address,
                        read_enbl => X_intm_rd,
                        write_enbl => X_intm_wr,
                        fsm => fsm_write_1
                        );
                    ------------------u-----------------2,4,6
                    write_after_read_reg (
                        data_in => x_temp_2,
                        reg_data_in => u_main_data_in,
                        reg_adrs => u_main_address,
                        read_enbl => u_main_rd,
                        write_enbl => u_main_wr,
                        fsm => fsm_write_2
                        );
                    ------------------x_w[0]----------------3,6,9
                    write_after_read_reg (
                        data_in => x_temp_3,
                        reg_data_in => X_ware_data_in,
                        reg_adrs => x_ware_address,
                        read_enbl => X_ware_rd,
                        write_enbl => X_ware_wr,
                        fsm => fsm_write_3
                        );

                    if fsm_write_1 = "00" and fsm_write_2 = "00" and fsm_write_3 = "00" then
                        main_fsm <= "100";
                        N_counter <= to_vec(to_int(N_counter) + 1, N_counter'length);
                        x_temp_1 <= to_vec(to_int(x_temp_1) + 128, x_temp_1'length); --inc 1
                        x_temp_2 <= to_vec(to_int(x_temp_2) + 256, x_temp_2'length); --inc 2
                        x_temp_3 <= to_vec(to_int(x_temp_3) + 384, x_temp_3'length); --inc 3
                        
                    end if;


                when "100" =>
                    if N_counter = N_X_A_B_vec then
                        --end
                        main_fsm <= "101";
                        from_i_to_c <= '0';
                        div_or_adapt <= '1';
                        fsm_main_eq <= "111";
                        ----------------------init
                    else
                        fsm_write_1 <= "11";
                        fsm_write_2 <= "11";
                        fsm_write_3 <= "11";
                        main_fsm <= "011";
                    end if;
                when "101" =>

                    proc_run_main_eq;

                    if fsm_main_eq = "000" then
                        main_fsm <= "111";
                    end if;
        when others =>
            null;
            end case ;
            
        end if;
    end process ;   

end architecture;

