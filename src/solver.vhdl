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
    signal counter      : std_logic_vector(1 downto 0)               := "00";
    --fp16, fp32, fp64
    signal mode_sig     : std_logic_vector(1 downto 0)               := "00";
    --address pointer: keeps track when initializing
    signal address_pointer: std_logic_vector(2 downto 0) := (others => '0');
    signal thisIsAdder : std_logic  := '0';
    signal thisIsSub : std_logic  := '0';

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
    --1- RESET, almost done
    --2- initialize
    --3- error occured
    --4- fixed step size
    --5- variable step size
    --6- output is ready

    --1- RESET
    process (clk, rst)
    begin
        if rising_edge(clk) and rst = '1' then
            --RESET fpu's:
            enable_mul_1            <= '1';
            enable_add_1            <= '1';

            --Reset memory
            address_pointer <= (others => '0');

            --Reset system's signals
            counter                 <= "00";
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
                    address_pointer <= "001";
                --H
                when X"0001" =>
                    --Dont write at 'header' any more..
                    header_wr <= '0';
                    address_pointer <= "010";
                    h_main_address <= (others => '0');
                --error ie. Tolerance
                when X"0003" =>
                    h_main_wr <= '0';
                    h_main_address <= (others => '0');
                    L_tol_address <= (others => '0');

                    address_pointer <= "011";
                --A
                when X"0005" =>
                    L_tol_wr <= '0';
                    L_tol_address <= (others => '0');
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
                    U_main_address <= (others => '0');
                    address_pointer <= "000";
                --T, not mine
                when X"29D1" =>
                    U_main_address <= (others => '0');
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
                when "101" =>
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
            or err_add_1 = '1')
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


end architecture;