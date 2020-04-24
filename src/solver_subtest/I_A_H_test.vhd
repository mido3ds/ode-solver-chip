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

    --signal X_intm_rd, X_intm_wr : std_logic    := '0';
    --signal X_intm_address : std_logic_vector(6 downto 0) := (others => '0');
    --signal X_intm_data_in, X_intm_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    --signal X_ware_rd, X_ware_wr : std_logic    := '0';
    --signal X_ware_address : std_logic_vector(9 downto 0) := (others => '0');
    --signal X_ware_data_in, X_ware_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

    signal a_coeff_rd, a_coeff_wr : std_logic    := '0';
    signal a_coeff_address : std_logic_vector(12 downto 0) := (others => '0');
    signal a_coeff_data_in, a_coeff_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal a_temp : std_logic_vector(63 downto 0) := (others => '1');
    

    signal x_temp,x_i_temp : std_logic_vector(63 downto 0) := (others => '1');
    signal x_temp_2 : std_logic_vector(63 downto 0) := X"1111111111111111";
    signal x_temp_3 : std_logic_vector(63 downto 0) := X"2222222222222222";
    signal h_main : std_logic_vector(63 downto 0) := X"1234567891234567";
        

    signal fsm_write_1,fsm_write_2 : std_logic_vector(1 downto 0) := (others => '0');
    signal main_fsm, fsm_out : std_logic_vector(2 downto 0) := (others => '0');
    

    signal N_X_A_B_vec: std_logic_vector(5 downto 0) := "000010";
    signal N_N: std_logic_vector(15 downto 0) :=(others => '0');
    signal N_N_counter: std_logic_vector(15 downto 0) :=(others => '0');
    --signal M_counter: std_logic_vector(5 downto 0) := "000010";
    --signal N_N_vec : std_logic_vector(11 downto 0) := (others => '0');
    --signal N_M_vec : std_logic_vector(11 downto 0) := (others => '0');
    
    --signal N_counter_2: std_logic_vector(5 downto 0) := (others => '0');
    signal mode_sig : std_logic_vector(1 downto 0) := "10";
    --signal wares : std_logic_vector(2 downto 0) := "001";
    signal procedure_dumm : std_logic_vector(11 downto 0) := (others => '0');
    


    signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1,thisIsAdder_1 : std_logic                                  := '0';
    
    signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic                                  := '0';
    

    --signal c_ware_vec : std_logic_vector(2 downto 0) := (others => '0');
    --signal from_i_to_c : std_logic    := '1';

    signal fsm_run_h_a :  std_logic_vector(2 downto 0) := (others => '0');
    begin
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
    --X_ware : entity work.ram generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 600, ADR_LENGTH=>10)
    --    port map(
    --        clk      => clk,
    --        rd       => X_ware_rd,
    --        wr       => X_ware_wr,
    --        address  => X_ware_address,
    --        data_in  => X_ware_data_in,
    --        data_out => X_ware_data_out,
    --        rst      => rst
    --    );

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

        --fpu_div_1 : entity work.fpu_divider(first_algo)
        --port map(
        --    clk       => clk,
        --    rst       => rst,
        --    mode      => mode_sig,
        --    enbl      => enable_div_1,
        --    in_a      => fpu_div_1_in_1,
        --    in_b      => fpu_div_1_in_2,
        --    out_c     => fpu_div_1_out,
        --    done      => done_div_1,
        --    err       => err_div_1,
        --    zero      => zero_div_1,
        --    posv      => posv_div_1
        --);

    main_proc : process(clk, rst)
    procedure proc_run_h_a (
        --dummies...
        signal fsm_read_a, fsm_write_a : inout std_logic_vector(1 downto 0);
        signal N_N_counter,N_N_diag_check : inout std_logic_vector(15 downto 0);
        signal diagonal : inout std_logic_vector(15 downto 0)
        )is
        begin
            case(fsm_run_h_a) is
                when "111" =>
                    --start here :D
                    fsm_read_a <= "11";
                    a_coeff_address <= (others =>'0');

                    diagonal <= to_vec(to_int(N_X_A_B_vec)+1, diagonal'length);
                    N_N_counter <= to_vec(to_int(N_N)-1, N_N_counter'length);
                    N_N_diag_check <= to_vec(to_int(N_N)-1, N_N_diag_check'length);
                    fsm_run_h_a <= "001";
                when "001" =>

                    read_before_write_reg
                        (
                        data_out => a_temp,
                        reg_data_out=>a_coeff_data_out,
                        reg_adrs => a_coeff_address,
                        read_enbl => a_coeff_rd,
                        write_enbl => a_coeff_wr,
                        fsm => fsm_read_a -->place ones (11) and wait for (00)
                        ); 
                    if fsm_read_a = "00" then
                        enable_mul_1 <= '1';
                        fpu_mul_1_in_1 <= a_temp;
                        fpu_mul_1_in_2 <= h_main;
                        --fsm_run_h_a <= "010";
                    end if;

                    if done_mul_1 = '1' then
                        a_temp <= fpu_mul_1_out;
                        fsm_run_h_a <= "011";
                    end if;

                when "011" =>
                    enable_mul_1 <= '0';
                    --check here whether to add 1 or not, before writing the output
                    if N_N_diag_check = N_N_counter then
                        --add 1 before you write please
                        fpu_add_1_in_1 <= a_temp;
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
                        
                        enable_add_1 <= '1';
                        thisIsAdder_1 <= '0';
                        fsm_run_h_a <= "101";
                    else
                        fsm_write_a <= "11";
                        fsm_run_h_a <= "100";
                    end if;
                when "100" =>
                    write_after_read_reg(
                        data_in => a_temp,
                        reg_data_in => a_coeff_data_in,
                        reg_adrs => a_coeff_address,
                        read_enbl => a_coeff_rd,
                        write_enbl => a_coeff_wr,
                        fsm => fsm_write_a
                        );
                    if fsm_write_a = "00" then
                        --check the end of the loop or not?
                        --decrement something here
                        if N_N_counter = X"0000" then
                            a_coeff_address <= (others =>'0');
                            fsm_run_h_a <= "000";
                        else
                            N_N_counter <= to_vec(to_int(N_N_counter)-1, N_N_counter'length);
                            fsm_read_a <= "11";
                            fsm_run_h_a <= "001";
                        end if;
                    end if;
                when "101" =>
                    if done_add_1 = '1' then
                        N_N_diag_check <= to_vec(to_int(N_N_diag_check)-to_int(diagonal), N_N_diag_check'length);
                        enable_add_1 <= '0';
                        a_temp <= fpu_add_1_out;
                        fsm_write_a <= "11";
                        fsm_run_h_a <= "100";
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
                    N_N_counter <= (others => '0');
                    N_N <= to_vec ( to_int(N_X_A_B_vec)* to_int(N_X_A_B_vec) ,N_N'length);
                    fsm_write_1 <= "11";
                    a_coeff_address <= (others => '0');
                    --fsm_write_2 <= "11";
                    main_fsm <= "001";
                when "001" =>

                write_after_read_reg (
                        data_in => x_temp_2,
                        reg_data_in => a_coeff_data_in,
                        reg_adrs => a_coeff_address,
                        read_enbl => a_coeff_rd,
                        write_enbl => a_coeff_wr,
                        fsm => fsm_write_1
                    );
                

                if fsm_write_1 = "00" and fsm_write_2 = "00" then 
                        main_fsm <= "010";
                        N_N_counter <= to_vec(to_int(N_N_counter) + 1, N_N_counter'length);
                    end if;

                when "010"=>
                    if N_N_counter = N_N then
                        main_fsm <= "011";
                        --init........
                        fsm_run_h_a <= "111";
                    else
                        fsm_write_1 <= "11";
                        x_temp_2 <= to_vec(to_int(x_temp_2) + 123456, x_temp_2'length);
                        main_fsm <= "001";
                    end if;
                when "011" =>
                    --run multiplication procedure
                    proc_run_h_a (
                        --dummies...
                         fsm_read_a => procedure_dumm (1 downto 0),
                         fsm_write_a  => procedure_dumm (3 downto 2),
                         N_N_counter  => x_temp_2(15 downto 0),
                         diagonal => x_temp_3 (15 downto 0),
                         N_N_diag_check => x_temp_2(31 downto 16)
                        );

                    if fsm_run_h_a = "000" then
                        main_fsm <= "111";
                    end if;
        when others =>
            null;
            end case ;
            
        end if;
    end process ;   

end architecture;

