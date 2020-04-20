library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

-----------------------------------------------------------------ENTITY-----------------------------------------------------------------------------------
entity interp is
    generic (
        WORD_LENGTH : integer := 32;
        ADDR_LENGTH : integer := 16;
        MAX_LENGTH  : integer := 64
    );

    port (
        in_state       : in std_logic_vector(1 downto 0); --state signal sent from CPU
        clk            : in std_logic;
        rst            : in std_logic;
        adr            : in std_logic_vector(15 downto 0);
        in_data        : inout std_logic_vector(31 downto 0);
        interp_done_op : out std_logic_vector(1 downto 0);
        interrupt      : out std_logic;
        error_success  : out std_logic
    );
end entity;

-----------------------------------------------------------------ARCHITECTURE-----------------------------------------------------------------------------------
architecture rtl of interp is
-----------------------------------------------------------------SIGNALS-----------------------------------------------------------------------------------
--FPUs Signals
--FPU MUL 1
signal fpu_mul_1_in_1, fpu_mul_1_in_2, fpu_mul_1_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_mul_1, err_mul_1, zero_mul_1, posv_mul_1, enable_mul_1 : std_logic := '0';  
--FPU DIV 1
signal fpu_div_1_in_1, fpu_div_1_in_2, fpu_div_1_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_div_1, err_div_1, zero_div_1, posv_div_1, enable_div_1 : std_logic := '0';
--FPU ADD 1
signal fpu_add_1_in_1, fpu_add_1_in_2, fpu_add_1_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_add_1, err_add_1, zero_add_1, posv_add_1, enable_add_1 : std_logic := '0';
--FPU SUB 1
signal fpu_sub_1_in_1, fpu_sub_1_in_2, fpu_sub_1_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_sub_1, err_sub_1, zero_sub_1, posv_sub_1, enable_sub_1 : std_logic := '0';
--FPU SUB 2
signal fpu_sub_2_in_1, fpu_sub_2_in_2, fpu_sub_2_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_sub_2, err_sub_2, zero_sub_2, posv_sub_2, enable_sub_2 : std_logic := '0'; 

--ALUs Signals
--INT ADD 1
signal int_adder_1_in_1,int_adder_1_in_2,int_adder_1_out: std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
signal int_adder_1_enbl, int_adder_1_cin, int_adder_1_cout: std_logic := '0';
--INT MUL 1
signal int_mul_1_in_1, int_mul_1_in_2, int_mul_1_out : std_logic_vector(ADDR_LENGTH - 1 downto 0) := (others => '0');
signal int_mul_1_enbl : std_logic := '0';

--Memory Signals
--Us Memory
signal U_s_rd, U_s_wr : std_logic := '0';
signal U_s_address : std_logic_vector(9 downto 0) := (others => '0');
signal U_s_data_in, U_s_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
--Ts Memory
signal T_s_rd, T_s_wr : std_logic := '0';
signal T_s_address : std_logic_vector(3 downto 0) := (others => '0');
signal T_s_data_in, T_s_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

begin
-----------------------------------------------------------------PORT MAPS-----------------------------------------------------------------------------------
    --FPUs:
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
    fpu_div_1 : entity work.fpu_divider(rtl)
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
    fpu_sub_2 : entity work.fpu_adder(rtl)
        port map(
            clk       => clk,
            rst       => rst,
            mode      => mode_sig,
            enbl      => enable_sub_2,
            in_a      => fpu_sub_2_in_1,
            in_b      => fpu_sub_2_in_2,
            out_c     => fpu_sub_2_out,
            done      => done_sub_2,
            err       => err_sub_2,
            zero      => zero_sub_2,
            posv      => posv_sub_2,
            add_sub   => thisIsSub
        );

    --ALUs (Integer Operations):
    int_add_1 : entity work.int_adder(rtl) generic map (N => ADDR_LENGTH, M => ADDR_LENGTH)
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
    
    --Memories:
    --Holding all given Us
    U_s : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 600, ADR_LENGTH=>10)
            port map(
                clk      => clk,
                rd       => U_s_rd,
                wr       => U_s_wr,
                address  => U_s_address,
                data_in  => U_s_data_in,
                data_out => U_s_data_out
            );
    
    --Holding given output times
    T_s : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 10, ADR_LENGTH=>4)
            port map(
                clk      => clk,
                rd       => T_s_rd,
                wr       => T_s_wr,
                address  => T_s_address,
                data_in  => T_s_data_in,
                data_out => T_s_data_out
            );
-----------------------------------------------------------------PROCESSES-----------------------------------------------------------------------------------
-----------------------------------------------------------------RESET-----------------------------------------------------------------------------------
-----------------------------------------------------------------INITIALIZATION-----------------------------------------------------------------------------------
-----------------------------------------------------------------ERROR HANDLING-----------------------------------------------------------------------------------
-----------------------------------------------------------------MEMORY IO-----------------------------------------------------------------------------------
-----------------------------------------------------------------MATRIX MANIPULATION-----------------------------------------------------------------------------------
-----------------------------------------------------------------UTILITIES-----------------------------------------------------------------------------------
-----------------------------------------------------------------MAIN FSM-----------------------------------------------------------------------------------
end architecture;