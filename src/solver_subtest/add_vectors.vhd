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
    signal x_temp_2 : std_logic_vector(63 downto 0) := X"1111111111111111";
    signal x_temp_3 : std_logic_vector(63 downto 0) := X"2222222222222222";
    

    signal fsm_write_1,fsm_write_2 : std_logic_vector(1 downto 0) := (others => '0');
    signal main_fsm, fsm_out : std_logic_vector(2 downto 0) := (others => '0');
    

    signal N_X_A_B_vec: std_logic_vector(5 downto 0) := "000101";
    --signal M_counter: std_logic_vector(5 downto 0) := "000010";
    --signal N_N_vec : std_logic_vector(11 downto 0) := (others => '0');
    --signal N_M_vec : std_logic_vector(11 downto 0) := (others => '0');
    
    signal N_counter_2: std_logic_vector(5 downto 0) := (others => '0');
    signal mode_sig : std_logic_vector(1 downto 0) := "10";
    --signal wares : std_logic_vector(2 downto 0) := "001";
    signal procedure_dumm : std_logic_vector(11 downto 0) := (others => '0');
    


    signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out               : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '1');
    signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1,thisIsAdder_1 : std_logic                                  := '0';
    
    signal c_ware_vec : std_logic_vector(2 downto 0) := (others => '0');
    signal from_i_to_c : std_logic    := '1';
    signal fsm_run_x_i_c :  std_logic_vector(2 downto 0) := (others => '0');
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
        --fpu_mul_1 : entity work.fpu_multiplier(first_algo)
        --port map(
        --    clk       => clk,
        --    rst       => rst,
        --    mode      => mode_sig,
        --    enbl      => enable_mul_1,
        --    in_a      => fpu_mul_1_in_1,
        --    in_b      => fpu_mul_1_in_2,
        --    out_c     => fpu_mul_1_out,
        --    done      => done_mul_1,
        --    err       => err_mul_1,
        --    zero      => zero_mul_1,
        --    posv      => posv_mul_1
        --);

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
    procedure proc_run_x_i_c (
        --both have the same length, this is the iterator
        signal N_counter : inout std_logic_vector(5 downto 0);
        --no need for that
        --signal c_ware_vec : std_logic_vector (2 downto 0);
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
                        (c_ware => c_ware_vec,
                        x_address_out => dumm,
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

    
    begin
        if rst = '0' and rising_edge(clk) then
            --Fill X_i with data..
            case( main_fsm ) is
                when "000" => 
                    N_counter_2 <= (others => '0');
                    fsm_write_1 <= "11";
                    fsm_write_2 <= "11";
                    main_fsm <= "001";
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
                        fsm_run_x_i_c <= "111";
                    else
                        fsm_write_1 <= "11";
                        fsm_write_2 <= "11";
                        main_fsm <= "001";
                    end if;
                when "011" =>
                    --run multiplication procedure
                    proc_run_x_i_c (
                        N_counter => procedure_dumm (11 downto 6),
                        fsm_read_1 => procedure_dumm (1 downto 0),
                        fsm_read_2=> procedure_dumm (3 downto 2),
                        fsm_write_1=> procedure_dumm (5 downto 4),
                        dumm => adr
                        );

                    if fsm_run_x_i_c = "000" then
                        main_fsm <= "111";
                    end if;
        when others =>
            null;
            end case ;
            
        end if;
    end process ;   

end architecture;

