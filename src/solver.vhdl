library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

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
    --FPU 1
    signal operation_sig_1                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_1_in_1, fpu_1_in_2, fpu_1_out                           : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_sig_1, err_sig_1, zero_sig_1, posv_sig_1, enable_sig_1 : std_logic                                  := '0';
    --FPU 2
    signal operation_sig_2                                             : std_logic_vector(1 downto 0)               := "00";
    signal fpu_2_in_1, fpu_2_in_2, fpu_2_out                           : std_logic_vector(MAX_LENGTH - 1 downto 0)  := (others => '0');
    signal done_sig_2, err_sig_2, zero_sig_2, posv_sig_2, enable_sig_2 : std_logic                                  := '0';

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
    signal counter                                                     : std_logic_vector(1 downto 0)               := "00";
    --fp16, fp32, fp64
    signal mode_sig                                                    : std_logic_vector(1 downto 0)               := "00";
    --address pointer: Do I need this signal?
    --or can I compare adr port with abolute values 3la tool!
    --signal address_pointer: std_logic_vector(ADDR_LENGTH-1 downto 0) := (others => '0');
begin
    --ENTITIES:
    --FPU's:
    fpu_unit_1 : entity work.fpu(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_sig_1,
            in_a      => fpu_1_in_1,
            in_b      => fpu_1_in_2,
            out_c     => fpu_1_out,
            operation => operation_sig_1,
            done      => done_sig_1,
            err       => err_sig_1,
            zero      => zero_sig_1,
            posv      => posv_sig_1
        );
    fpu_unit_2 : entity work.fpu(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_sig_2,
            in_a      => fpu_2_in_1,
            in_b      => fpu_2_in_2,
            out_c     => fpu_2_out,
            operation => operation_sig_2,
            done      => done_sig_2,
            err       => err_sig_2,
            zero      => zero_sig_2,
            posv      => posv_sig_2
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
            wr       => Usub_wr,
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
    process (rst)
    begin
        if rst = '1' then
            --RESET fpu's:
            enable_sig_1            <= '1';
            enable_sig_2            <= '1';

            --Reset memory
            address_pointer_address <= (others => '0');
            address_pointer_data_in <= (others => '0');
            address_pointer_wr      <= '1';
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
            address_pointer_address <= (others => '0');
            error_address           <= (others => '0');

        end if;
    end process;

    process (rst, in_state, in_data, adr)
    begin
        -- if in_State is LOAD or WAIT I can read..
        if rst = '1' and (in_state = "00" or in_state = "01") then
            --Switch case on ads and address_pointer...TBC
        end if;
    end process;
end architecture;