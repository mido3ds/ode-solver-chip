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
--Header Signals
--N
signal N : integer range 0 to 50 ;
signal N_vec : std_logic_vector(15 downto 0) := (others => '0');
--M
signal M : integer range 0 to 50 ;
signal M_vec : std_logic_vector(15 downto 0) := (others => '0');
--Data Mode
signal mode_sig : std_logic_vector(1 downto 0) := "00";
--Solver Mode
signal fixed_or_var : std_logic := '0';
--Output T Size
signal t_size : std_logic_vector(2 downto 0) := "000";

--Output Times Signals
signal out_time_1, out_time_2, out_time_3, out_time_4, out_time_5 : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');

--Received H Signal
signal h_new : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');

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
--U_out Memory
signal U_out_rd, U_out_wr : std_logic := '0';
signal U_out_address : std_logic_vector(3 downto 0) := (others => '0');
signal U_out_data_in, U_out_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

--Processes Signals
--Main FSM Signals
signal interp_state : std_logic_vector(3 downto 0) := (others => '0');
signal t_low, t_high : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --range boundaries
signal t_const : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --(Tk-Tn)/(Tz-Tn)
signal u_low_adr, u_high_adr : std_logic_vector(9 downto 0) := (others => '0'); --boundary Us addresses
signal u_low_temp, u_high_temp : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --boundary Us values
signal u_out_result : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --result of Uout

--Range Finder Signals
signal range_finder_enable : std_logic := '0';

--Us IO Signals
signal read_u_s_low, write_u_s_low, increment_u_s_low, decrement_u_s_low : std_logic := '0';
signal read_u_s_high, write_u_s_high, increment_u_s_high, decrement_u_s_high : std_logic := '0';

--Uout IO Signals
signal read_u_out, write_u_out, increment_u_out, decrement_u_out : std_logic := '0';

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
            add_sub   => '0'
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
            add_sub   => '1'
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
            add_sub   => '1'
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
    
    --Holding result output U
    U_out : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
            port map(
                clk      => clk,
                rd       => U_out_rd,
                wr       => U_out_wr,
                address  => U_out_address,
                data_in  => U_out_data_in,
                data_out => U_out_data_out
            );
-----------------------------------------------------------------PROCESSES-----------------------------------------------------------------------------------
-----------------------------------------------------------------RESET-----------------------------------------------------------------------------------
    --Reset
    --handles reset signal for interpolator
    reset : process (clk, rst)
    begin
        if rst = '1' then
            null;
        end if;
    end process;
-----------------------------------------------------------------INITIALIZATION-----------------------------------------------------------------------------------
    --Initialization
    --detects addresses changes
    detect_adr : process (clk, in_state, in_data, adr)
    begin
        null;
    end process;

    --enables data reading based on address
    enable_read : process (clk, in_state, in_data, adr)
    begin
        null;
    end process;
-----------------------------------------------------------------ERROR HANDLING-----------------------------------------------------------------------------------
    --Error Handling
    --outputs error interrupt in case of fp errors
    error_handler : process(clk, err_mul_1, err_div_1, err_add_1, err_sub_1, err_sub_2)
    begin
        null;
    end process;
-----------------------------------------------------------------MEMORY IO-----------------------------------------------------------------------------------
    --U_s
    --reads low Us
    read_low_us : process(clk, read_u_s_low, write_u_s_low)
    begin
        if rst = '0' and rising_edge(clk) and read_u_s_low = '1' and write_u_s_low = '0' then
            null;            
    end if;
    end process; 

    --writes low Us
    write_low_us : process(clk, read_u_s_low, write_u_s_low)
    begin
        if rst = '0' and rising_edge(clk) and read_u_s_low = '0' and write_u_s_low = '1' then       
            null;
        end if;
    end process;

    --increments low Us address
    inc_low_us : process(clk, increment_u_s_low)
    begin
        if rst = '0' and rising_edge(clk) and increment_u_s_low = '1' then
            null;
        end if;    
    end process;

    --decrements low Us address
    dec_low_us : process(clk, decrement_u_s_low)
    begin
        if rst = '0' and rising_edge(clk) and decrement_u_s_low = '1' then
            null;
        end if;    
    end process;

    --reads high Us
    read_high_us : process(clk, read_u_s_high, write_u_s_high)
    begin
        if rst = '0' and rising_edge(clk) and read_u_s_high = '1' and write_u_s_high = '0' then
            null;            
    end if;
    end process; 

    --writes high Us
    write_high_us : process(clk, read_u_s_high, write_u_s_high)
    begin
        if rst = '0' and rising_edge(clk) and read_u_s_high = '0' and write_u_s_high = '1' then       
            null;
        end if;
    end process ;

    --increments high Us address
    inc_high_us : process(clk, increment_u_s_high)
    begin
        if rst = '0' and rising_edge(clk) and increment_u_s_high = '1' then
            null;
        end if;    
    end process ;

    --decrements high Us address
    dec_high_us : process(clk, decrement_u_s_high)
    begin
        if rst = '0' and rising_edge(clk) and decrement_u_s_high = '1' then
            null;
        end if;    
    end process ;

    --U_out
    --reads Uout
    read_uout : process(clk, read_u_out, write_u_out)
    begin
        if rst = '0' and rising_edge(clk) and read_u_out = '1' and write_u_out = '0' then
            null;            
    end if;
    end process ; 

    --writes Uout
    write_uout : process(clk, read_u_out, write_u_out)
    begin
        if rst = '0' and rising_edge(clk) and read_u_out = '0' and write_u_out = '1' then       
            null;
        end if;
    end process ;

    --increments Uout address
    inc_uout : process(clk, increment_u_out)
    begin
        if rst = '0' and rising_edge(clk) and increment_u_out = '1' then
            null;
        end if;    
    end process ;

    --decrements Uout address
    dec_uout : process(clk, decrement_u_out)
    begin
        if rst = '0' and rising_edge(clk) and decrement_u_out = '1' then
            null;
        end if;    
    end process ;
-----------------------------------------------------------------MATRIX MANIPULATION-----------------------------------------------------------------------------------
-----------------------------------------------------------------UTILITIES-----------------------------------------------------------------------------------
    --finds the range in which the received T lies
    range_finder : process(clk, range_finder_enable)
        begin
            if rst = '0' and rising_edge(clk) and range_finder_enable = '1' then
                null;
            end if;
    end process;
-----------------------------------------------------------------MAIN FSM-----------------------------------------------------------------------------------
    --main interpolator driver FSM
    interpolate : process(clk, interp_state) 
    begin
        if rst = '0' and rising_edge(clk) then
            case interp_state is
                when "0000" => 
                    --check input address
                    --read lower part of h_new
                    if adr = X"2C34" then
                        h_new(31 downto 0) <= in_data;
                        interp_state <= "0001";
                    end if;
                when "0001" =>
                    --read higher part of h_new
                    --start range finder process
                    h_new(63 downto 32) <= in_data;
                    range_finder_enable <= '1';
                    interp_state <= "0010";
                when "0010" =>
                    --check range finder completion
                    --subtract Tz-Tn and Tk-Tn
                    if range_finder_enable = '0' then
                        fpu_sub_1_in_1 <= t_high;
                        fpu_sub_1_in_2 <= t_low;
                        enable_sub_1 <= '1';
                        fpu_sub_2_in_1 <= h_new;
                        fpu_sub_2_in_2 <= t_low;
                        enable_sub_2 <= '1';
                        interp_state <= "0011";
                    end if;
                when "0011" =>
                    if done_sub_1 = '1' and done_sub_2 = '1' then
                        fpu_div_1_in_1 <= fpu_sub_2_out;
                        fpu_div_1_in_2 <= fpu_sub_1_out;
                        enable_div_1 <= '1';
                        interp_state <= "0100";
                    end if;
                when "0100" =>
                    if done_div_1 = '1' then
                        t_const <= fpu_div_1_out;
                        read_u_s_low <= '1';
                        interp_state <= "0101";
                    end if;
                when "0101" =>
                    if read_u_s_low = '0' then
                        read_u_s_high <= '1';
                        interp_state <= "0110";
                    end if;
                when "0110" =>
                    if read_u_s_high = '0' then
                        fpu_sub_1_in_1 <= u_high_temp;
                        fpu_sub_1_in_2 <= u_low_temp;
                        enable_sub_1 <= '1';
                        interp_state <= "0111";
                    end if;
                when "0111" =>
                    if done_sub_1 = '1' then
                        fpu_mul_1_in_1 <= fpu_sub_1_out;
                        fpu_mul_1_in_2 <= t_const;
                        enable_mul_1 <= '1';
                        interp_state <= "1000";
                    end if;
                when "1000" =>
                    if done_mul_1 = '1' then
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= u_low_temp;
                        enable_add_1 <= '1';
                        interp_state <= "1001";
                    end if;
                when "1001" =>
                    if done_add_1 = '1' then
                        u_out_result <= fpu_add_1_out;
                        write_u_out <= '1';
                    end if;
                when others =>
                    --NOP
                    null;
            end case;
        end if;
    end process ;
end architecture;