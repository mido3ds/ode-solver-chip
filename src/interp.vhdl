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
        adr            : in std_logic_vector(ADDR_LENGTH - 1 downto 0);
        in_data        : inout std_logic_vector(WORD_LENGTH - 1 downto 0);
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
signal N_vec : std_logic_vector(15 downto 0) := (others => '0');
--M
signal M : integer range 0 to 50;
signal M_vec : std_logic_vector(15 downto 0) := (others => '0');
--Data Mode
signal mode_sig : std_logic_vector(1 downto 0) := "00";
--Solver Mode
signal fixed_or_var : std_logic := '0';
--Output T Size
signal t_size : std_logic_vector(2 downto 0) := "000";

--Output Times Signals
signal out_time_1, out_time_2, out_time_3, out_time_4, out_time_5 : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal t_count : integer range 0 to 10;

--Received H Signal
signal h_step : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --main step size (read in init and updated in variable step)
signal h_new : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --current received time

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
signal this_is_add : std_logic := '0';
--FPU SUB 1
signal fpu_sub_1_in_1, fpu_sub_1_in_2, fpu_sub_1_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_sub_1, err_sub_1, zero_sub_1, posv_sub_1, enable_sub_1 : std_logic := '0';
signal this_is_sub : std_logic := '1';
--FPU SUB 2
signal fpu_sub_2_in_1, fpu_sub_2_in_2, fpu_sub_2_out : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0');
signal done_sub_2, err_sub_2, zero_sub_2, posv_sub_2, enable_sub_2 : std_logic := '0'; 

--Memory Signals
--U0 Memory
signal U_0_rd, U_0_wr : std_logic := '0';
signal U_0_address : std_logic_vector(6 downto 0) := (others => '0');
signal U_0_data_in, U_0_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
--Us Memory
signal U_s_rd, U_s_wr : std_logic := '0';
signal U_s_address : std_logic_vector(8 downto 0) := (others => '0');
signal U_s_data_in, U_s_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
--U_out Memory
signal U_out_rd, U_out_wr : std_logic := '0';
signal U_out_address : std_logic_vector(6 downto 0) := (others => '0');
signal U_out_data_in, U_out_data_out : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');

--Processes Signals
--Main FSM Signals
signal interp_state : std_logic_vector(3 downto 0) := "1111";
signal t_low, t_high : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --range boundaries
signal t_const : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --(Tk-Tn)/(Tz-Tn)
signal u_low_adr, u_high_adr : std_logic_vector(8 downto 0) := (others => '0'); --boundary Us addresses
signal u_0_adr, u_out_adr : std_logic_vector(6 downto 0) := (others => '0'); --initial and output U addresses
signal u_0_temp, u_low_temp, u_high_temp, u_out_temp : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --boundary Us values
signal u_out_result : std_logic_vector(MAX_LENGTH - 1 downto 0) := (others => '0'); --result of Uout

--Range Finder Signals
signal range_finder_enable : std_logic := '0';
signal is_stored : std_logic := '0'; --whether the received h_new is a stored point
signal out_from : std_logic := '0'; --determines which memory to out from in case of h_new = 0

--Send Output Signals
signal send_output_enable, send_u_0_enable, send_u_s_enable : std_logic := '0';

--U0 IO Signals
signal read_u_0, u_0_high : std_logic := '0';

--Us IO Signals
signal read_u_s_low, u_s_low_high : std_logic := '0';
signal read_u_s_high, u_s_high_high : std_logic := '0';

--Uout IO Signals
signal read_u_out, write_u_out, u_out_high : std_logic := '0';

begin
-----------------------------------------------------------------PORT MAPS-----------------------------------------------------------------------------------
    --FPUs:
    fpu_mul_1 : entity work.fpu_multiplier(sec_algo)
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
    fpu_add_1 : entity work.fpu_adder(sec_algo)
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
            add_sub   => this_is_add
        );
    fpu_sub_1 : entity work.fpu_adder(sec_algo)
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
            add_sub   => this_is_sub
        );
    fpu_sub_2 : entity work.fpu_adder(sec_algo)
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
            add_sub   => this_is_sub
        );

    --Memories:
    --Holding initial U
    U_0 : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
    port map(
        clk      => clk,
        rst => rst,
        rd       => U_0_rd,
        wr       => U_0_wr,
        address  => U_0_address,
        data_in  => U_0_data_in,
        data_out => U_0_data_out
    );
    --Holding all given Us
    U_s : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 500, ADR_LENGTH=>9)
            port map(
                clk      => clk,
                rd       => U_s_rd,
                rst => rst,
                wr       => U_s_wr,
                address  => U_s_address,
                data_in  => U_s_data_in,
                data_out => U_s_data_out
            );
    
    --Holding result output U
    U_out : entity work.ram(rtl) generic map (WORD_LENGTH => WORD_LENGTH, NUM_WORDS => 100, ADR_LENGTH=>7)
            port map(
                clk      => clk,
                rst => rst,
                rd       => U_out_rd,
                wr       => U_out_wr,
                address  => U_out_address,
                data_in  => U_out_data_in,
                data_out => U_out_data_out
            );
-----------------------------------------------------------------MAIN PROCESS-----------------------------------------------------------------------------------
    process(clk, rst, in_state, in_data, adr, interp_state, adr, err_mul_1, err_div_1, err_add_1, err_sub_1, err_sub_2) 
    --variables
    variable adr_temp : std_logic_vector(15 downto 0) := (others => '0');

    --finds the range in which the received T lies
    procedure range_finder is
    begin
        if h_new = X"0000" then
            is_stored <= '1';
            if t_low = X"0000" then
                t_low <= h_new;
                t_high <= h_new;
                u_low_adr <= (others => '0');
                u_high_adr <= (others => '0');
                u_0_adr <= (others => '0');
                out_from <= '0';
            elsif t_low = out_time_1 then
                t_low <= out_time_1;
                t_high <= out_time_1;
                u_low_adr <= (others => '0');
                u_high_adr <= (others => '0');
                u_0_adr <= (others => '0');
                out_from <= '1';
            elsif t_low = out_time_2 then
                t_low <= out_time_2;
                t_high <= out_time_2;
                u_low_adr <= "001100100";
                u_high_adr <= "001100100";
                u_0_adr <= (others => '0');
                out_from <= '1';
            elsif t_low = out_time_3 then
                t_low <= out_time_3;
                t_high <= out_time_3;
                u_low_adr <= "011001000";
                u_high_adr <= "011001000";
                u_0_adr <= (others => '0');
                out_from <= '1';
            elsif t_low = out_time_4 then
                t_low <= out_time_4;
                t_high <= out_time_4;
                u_low_adr <= "100101100";
                u_high_adr <= "100101100";
                u_0_adr <= (others => '0');
                out_from <= '1';
            elsif t_low = out_time_5 then
                t_low <= out_time_5;
                t_high <= out_time_5;
                u_low_adr <= "110010000";
                u_high_adr <= "110010000";
                u_0_adr <= (others => '0');
                out_from <= '1';
            end if;
        elsif h_new > X"0000" and h_new < out_time_1 then
            is_stored <= '0';
            t_low <= X"0000";
            t_high <= out_time_1;
            u_low_adr <= (others => '0');
            u_high_adr <= (others => '0');
            u_0_adr <= (others => '0');
        elsif h_new = out_time_1 then
            is_stored <= '1';
            t_low <= out_time_1;
            t_high <= out_time_1;
            u_low_adr <= (others => '0');
            u_high_adr <= (others => '0');
            u_0_adr <= (others => '0');
        elsif h_new > out_time_1 and h_new < out_time_2 then 
            is_stored <= '0';
            t_low <= out_time_1;
            t_high <= out_time_2;
            u_low_adr <= (others => '0');
            u_high_adr <= "001100100";
            u_0_adr <= (others => '0');
        elsif h_new = out_time_2 then
            is_stored <= '1';
            t_low <= out_time_2;
            t_high <= out_time_2;
            u_low_adr <= "001100100";
            u_high_adr <= "001100100";
            u_0_adr <= (others => '0');
        elsif h_new > out_time_2 and h_new < out_time_3 then 
            is_stored <= '0';
            t_low <= out_time_2;
            t_high <= out_time_3;
            u_low_adr <= "001100100";
            u_high_adr <= "011001000";
            u_0_adr <= (others => '0');
        elsif h_new = out_time_3 then
            is_stored <= '1';
            t_low <= out_time_3;
            t_high <= out_time_3;
            u_low_adr <= "011001000";
            u_high_adr <= "011001000";
            u_0_adr <= (others => '0');
        elsif h_new > out_time_3 and h_new < out_time_4 then 
            is_stored <= '0';
            t_low <= out_time_3;
            t_high <= out_time_4;
            u_low_adr <= "011001000";
            u_high_adr <= "100101100";
            u_0_adr <= (others => '0');
        elsif h_new = out_time_4 then
            is_stored <= '1';
            t_low <= out_time_4;
            t_high <= out_time_4;
            u_low_adr <= "100101100";
            u_high_adr <= "100101100";
            u_0_adr <= (others => '0');
        elsif h_new > out_time_4 and h_new < out_time_5 then 
            is_stored <= '0';
            t_low <= out_time_4;
            t_high <= out_time_5;
            u_low_adr <= "100101100";
            u_high_adr <= "110010000";
            u_0_adr <= (others => '0');
        elsif h_new = out_time_5 then
            is_stored <= '1';
            t_low <= out_time_5;
            t_high <= out_time_5;
            u_low_adr <= "110010000";
            u_high_adr <= "110010000";
            u_0_adr <= (others => '0');
        end if;
        range_finder_enable <= '0';
    end procedure;
    
    --sends U_out on output bus cycle by cycle
    procedure send_output is
    begin
        if u_out_adr = "0000000" then
            U_out_address <= u_out_adr;
            U_out_wr <= '0';
            U_out_rd <= '1';
            adr_temp := std_logic_vector(unsigned(u_out_adr) + 1); 
            u_out_adr <= adr_temp(6 downto 0); 
        elsif u_out_adr = multiply2(M_vec) then
            in_data <= U_out_data_out;
            send_output_enable <= '0';
        else
            in_data <= U_out_data_out;
            U_out_address <= u_out_adr;
            U_out_wr <= '0';
            U_out_rd <= '1';
            adr_temp := std_logic_vector(unsigned(u_out_adr) + 1); 
            u_out_adr <= adr_temp(6 downto 0); 
        end if;
    end procedure;

    --sends U_0 on output bus cycle by cycle
    procedure send_u_0 is
    begin
        if u_0_adr = "0000000" then
            U_0_address <= u_0_adr;
            U_0_wr <= '0';
            U_0_rd <= '1';
            adr_temp := std_logic_vector(unsigned(u_0_adr) + 1); 
            u_0_adr <= adr_temp(6 downto 0); 
        elsif u_0_adr = multiply2(M_vec) then
            in_data <= U_0_data_out;
            send_u_0_enable <= '0';
        else
            in_data <= U_0_data_out;
            U_0_address <= u_0_adr;
            U_0_wr <= '0';
            U_0_rd <= '1';
            adr_temp := std_logic_vector(unsigned(u_0_adr) + 1); 
            u_0_adr <= adr_temp(6 downto 0); 
        end if;
    end procedure;

    --sends U_s on output bus cycle by cycle
    procedure send_u_s is
    begin
        if u_low_adr = "0000000" then
            U_s_address <= u_low_adr;
            U_s_wr <= '0';
            U_s_rd <= '1';
            adr_temp := std_logic_vector(unsigned(u_low_adr) + 1); 
            u_low_adr <= adr_temp(6 downto 0);
        elsif u_low_adr = multiply2(M_vec) then
            in_data <= U_s_data_out;
            send_u_s_enable <= '0';
        else
            in_data <= U_s_data_out;
            U_s_address <= u_low_adr;
            U_s_wr <= '0';
            U_s_rd <= '1';
            adr_temp := std_logic_vector(unsigned(u_low_adr) + 1); 
            u_low_adr <= adr_temp(6 downto 0);
        end if;
    end procedure;

    --reads U0 entry
    procedure read_u0 is
    begin
        if u_0_high = '0' then
            U_0_address <= u_0_adr;
            U_0_wr <= '0';
            U_0_rd <= '1';
            u_0_temp(MAX_LENGTH-1 downto 32) <= U_0_data_out;
            u_0_high <= '1';
            adr_temp := std_logic_vector(unsigned(u_0_adr) + 1);
            u_0_adr <= adr_temp(6 downto 0); 
        else
            U_0_address <= u_0_adr;
            U_0_wr <= '0';
            U_0_rd <= '1';
            u_0_temp(31 downto 0) <= U_0_data_out;
            u_0_high <= '0';
            adr_temp := std_logic_vector(unsigned(u_0_adr) + 1);
            u_0_adr <= adr_temp(6 downto 0);
            read_u_0 <= '0';
        end if;
    end procedure; 

    --reads low Us entry
    procedure read_low_us is
    begin
        if u_s_low_high = '0' then
            U_s_address <= u_low_adr;
            U_s_wr <= '0';
            U_s_rd <= '1';
            u_low_temp(MAX_LENGTH-1 downto 32) <= U_s_data_out;
            u_s_low_high <= '1';
            adr_temp := std_logic_vector(unsigned(u_low_adr) + 1);
            u_low_adr <= adr_temp(8 downto 0); 
        else
            U_s_address <= u_low_adr;
            U_s_wr <= '0';
            U_s_rd <= '1';
            u_low_temp(31 downto 0) <= U_s_data_out;
            u_s_low_high <= '0';
            adr_temp := std_logic_vector(unsigned(u_low_adr) + 1);
            u_low_adr <= adr_temp(8 downto 0); 
            read_u_s_low <= '0';
        end if;
    end procedure; 

    --reads high Us entry
    procedure read_high_us is
    begin
        if u_s_high_high = '0' then
            U_s_address <= u_high_adr;
            U_s_wr <= '0';
            U_s_rd <= '1';
            u_high_temp(MAX_LENGTH-1 downto 32) <= U_s_data_out;
            u_s_high_high <= '1';
            adr_temp := std_logic_vector(unsigned(u_high_adr) + 1);
            u_high_adr <= adr_temp(8 downto 0);
        else
            U_s_address <= u_high_adr;
            U_s_wr <= '0';
            U_s_rd <= '1';
            u_high_temp(31 downto 0) <= U_s_data_out;
            u_s_high_high <= '0';
            adr_temp := std_logic_vector(unsigned(u_high_adr) + 1);
            u_high_adr <= adr_temp(8 downto 0);
            read_u_s_high <= '0';
        end if;
    end procedure; 

    --reads Uout entry
    procedure read_uout is
    begin
        if u_out_high = '0' then
            U_out_address <= u_out_adr;
            U_out_wr <= '0';
            U_out_rd <= '1';
            u_out_temp(MAX_LENGTH-1 downto 32) <= U_out_data_out;
            u_out_high <= '1';
            adr_temp := std_logic_vector(unsigned(u_out_adr) + 1); 
            u_out_adr <= adr_temp(6 downto 0); 
        else
            U_out_address <= u_out_adr;
            U_out_wr <= '0';
            U_out_rd <= '1';
            u_out_temp(31 downto 0) <= U_out_data_out;
            u_out_high <= '0';
            adr_temp := std_logic_vector(unsigned(u_out_adr) + 1); 
            u_out_adr <= adr_temp(6 downto 0); 
            read_u_out <= '0';
        end if;    
    end procedure; 

    --writes Uout entry
    procedure write_uout is
    begin
        if u_out_high = '0' then
            U_out_address <= u_out_adr;
            U_out_data_in <= u_out_result(MAX_LENGTH-1 downto 32);
            U_out_rd <= '0';
            U_out_wr <= '1';
            u_out_high <= '1';
            adr_temp := std_logic_vector(unsigned(u_out_adr) + 1); 
            u_out_adr <= adr_temp(6 downto 0);  
        else
            U_out_address <= u_out_adr;
            U_out_data_in <= u_out_result(31 downto 0);
            U_out_rd <= '0';
            U_out_wr <= '1';
            u_out_high <= '0';
            adr_temp := std_logic_vector(unsigned(u_out_adr) + 1); 
            u_out_adr <= adr_temp(6 downto 0); 
            write_u_out <= '0';
        end if;
    end procedure;

    --main process implementation
    begin
        --SYSTEM RESET
        if rst = '1' then
            --port signals
            interrupt <= '0';
            error_success <= '1';
            in_data <= (others => 'Z');
            interp_done_op <= (others => 'Z');
            --time signals
            h_new <= (others => '0');
            --fpu signals
            fpu_mul_1_in_1 <= (others => '0');
            fpu_mul_1_in_2 <= (others => '0');
            enable_mul_1 <= '0';
            fpu_div_1_in_1 <= (others => '0');
            fpu_div_1_in_2 <= (others => '0');
            enable_div_1 <= '0';
            fpu_add_1_in_1 <= (others => '0');
            fpu_add_1_in_2 <= (others => '0');
            enable_add_1 <= '0';
            fpu_sub_1_in_1 <= (others => '0');
            fpu_sub_1_in_2 <= (others => '0');
            enable_sub_1 <= '0';
            fpu_sub_2_in_1 <= (others => '0');
            fpu_sub_2_in_2 <= (others => '0');
            enable_sub_2 <= '0';
            --memory signals
            U_0_rd <= '0';
            U_0_wr <= '0';
            U_0_address <= (others => '0');
            U_0_data_in <= (others => '0');
            U_s_rd <= '0';
            U_s_wr <= '0';
            U_s_address <= (others => '0');
            U_s_data_in <= (others => '0');
            U_out_rd <= '0';
            U_out_wr <= '0';
            U_out_address <= (others => '0');
            U_out_data_in <= (others => '0');
            --main fsm signals
            interp_state <= "1111";
            t_low <= (others => '0');
            t_high <= (others => '0');
            t_const <= (others => '0');
            u_low_adr <= (others => '0');
            u_high_adr <= (others => '0');
            u_0_adr <= (others => '0'); 
            u_out_adr <= (others => '0'); 
            u_0_temp <= (others => '0'); 
            u_low_temp <= (others => '0'); 
            u_high_temp <= (others => '0');
            u_out_temp <= (others => '0');
            u_out_result <= (others => '0'); 
            --other processes signals
            range_finder_enable <= '0';
            is_stored <= '0';
            send_output_enable <= '0';
            send_u_0_enable <= '0';
            send_u_s_enable <= '0';
            read_u_0 <= '0';
            u_0_high <= '0';
            read_u_s_low <= '0';
            u_s_low_high <= '0';
            read_u_s_high <= '0';
            u_s_high_high <= '0';
            read_u_out <= '0';
            write_u_out <= '0';
            u_out_high <= '0';
        
        --ERROR HANDLING    
        elsif rising_edge(clk) and (err_mul_1 = '1' or err_div_1 = '1' or err_add_1 = '1' or err_sub_1 = '1' or err_sub_2 = '1') then
            interrupt <= '1';
            error_success <= '0';
        
        --DATALOADER
        elsif rising_edge(clk) and rst = '0' and (in_state = STATE_LOAD or in_state = STATE_WAIT) then
            --switch main FSM to ready state
            if interp_state = "1111" then
                interp_state <= "0000";
                interrupt <= '0';
                error_success <= '0';
                interp_done_op <= "00";
            end if;
            --read header data
            if adr = MM_HDR_0 then
                N_vec(5 downto 0) <= in_data(31 downto 26);
                M_vec(5 downto 0) <= in_data(25 downto 20);
                fixed_or_var <= in_data(19);
                mode_sig <= in_data(18 downto 17);
                t_size <= in_data(16 downto 14);
            --read time step (h)
            elsif adr = MM_H_0 then
                h_step(MAX_LENGTH-1 downto 32) <= in_data;
            elsif adr = MM_H_1 then
                h_step(31 downto 0) <= in_data;
            --read U_0
            elsif adr >= MM_U0_0 and adr <= MM_U0_1 then
                U_0_data_in <= in_data;
                U_0_wr <= '1';
                -- shift adr from [MM_U0_0:MM_U0_1] to [0:MM_U0_1-MM_U0_0]
                adr_temp := std_logic_vector(unsigned(adr) - unsigned(MM_U0_0));
                U_0_address <= adr_temp(6 downto 0);     
            --read output times           
            elsif adr >= MM_T_0 and adr <= MM_T_1 then
                if adr = MM_T_0 then
                    t_count <= 0;
                end if;
                t_count <= t_count + 1;
                if t_count = 1 then
                    out_time_1(MAX_LENGTH-1 downto 32) <= in_data;
                elsif t_count = 2 then
                    out_time_1(31 downto 0) <= in_data;
                elsif t_count = 3 then
                    out_time_2(MAX_LENGTH-1 downto 32) <= in_data;
                elsif t_count = 4 then
                    out_time_2(31 downto 0) <= in_data;
                elsif t_count = 5 then
                    out_time_3(MAX_LENGTH-1 downto 32) <= in_data;
                elsif t_count = 6 then
                    out_time_3(31 downto 0) <= in_data;
                elsif t_count = 7 then
                    out_time_4(MAX_LENGTH-1 downto 32) <= in_data;
                elsif t_count = 8 then
                    out_time_4(31 downto 0) <= in_data;
                elsif t_count = 9 then
                    out_time_5(MAX_LENGTH-1 downto 32) <= in_data;
                elsif t_count = 10 then
                    out_time_5(31 downto 0) <= in_data;
                end if;    
            --read U_s
            elsif adr >= MM_U_S_0 and adr <= MM_U_S_1 then
                U_s_data_in <= in_data;
                U_s_wr <= '1';
                -- shift adr from [MM_U_S_0:MM_U_S_1] to [0:MM_U_S_1-MM_U_S_0]
                adr_temp := std_logic_vector(unsigned(adr) - unsigned(MM_U_S_0));
                U_s_address <= adr_temp(8 downto 0);
            end if;
        
        --TIMESTEP HIGHER PART UPDATE
        elsif rising_edge(clk) and rst = '0' and adr = MM_H_ADA_0 then
                h_step(MAX_LENGTH-1 downto 32) <= in_data;
        --TIMESTEP LOWER PART UPDATE
        elsif adr = MM_H_ADA_1 then
                h_step(31 downto 0) <= in_data;
        
        --MAIN FSM DRIVER
        elsif rising_edge(clk) and rst = '0' and in_state = STATE_PROC then
            case interp_state is
                when "0000" => 
                    --check input address
                    --read lower part of h_new
                    if adr = MM_H_NEW_0 and send_output_enable = '0' and send_u_0_enable = '0' and send_u_s_enable = '0' then
                        M <= to_int(M_vec);
                        u_out_adr <= (others => '0');
                        h_new(MAX_LENGTH-1 downto 32) <= in_data;
                        interp_state <= "0001";
                    end if;
                when "0001" =>
                    --check input address
                    --read higher part of h_new
                    --start range finder process
                    if adr = MM_H_NEW_1 then
                        h_new(31 downto 0) <= in_data;
                        range_finder_enable <= '1';
                        range_finder;
                        interp_state <= "0010";
                    end if;
                when "0010" =>
                    --check range finder completion
                    --subtract Tz-Tn and Tk-Tn
                    if range_finder_enable = '0' then
                        if is_stored = '0' then
                            fpu_sub_1_in_1 <= t_high;
                            fpu_sub_1_in_2 <= t_low;
                            enable_sub_1 <= '1';
                            fpu_sub_2_in_1 <= h_new;
                            fpu_sub_2_in_2 <= t_low;
                            enable_sub_2 <= '1';
                            interp_state <= "0011";
                        elsif is_stored = '1' and h_new = X"0000" then
                            if out_from = '0' then
                                interp_done_op <= "01";
                                send_u_0_enable <= '1';
                                interp_state <= "0000";
                            else
                                interp_done_op <= "01";
                                send_u_s_enable <= '1';
                                interp_state <= "0000";
                            end if;
                        elsif is_stored = '1' then
                            interp_done_op <= "01";
                            send_u_s_enable <= '1';
                            interp_state <= "0000";
                        end if;
                    end if;
                when "0011" =>
                    --check subtraction completion
                    --divide the resultant Ts
                    if done_sub_1 = '1' and done_sub_2 = '1' then
                        fpu_div_1_in_1 <= fpu_sub_2_out;
                        fpu_div_1_in_2 <= fpu_sub_1_out;
                        enable_div_1 <= '1';
                        interp_state <= "0100";
                    end if;
                when "0100" =>
                    --check division completion
                    --read lower U
                    if done_div_1 = '1' then
                        t_const <= fpu_div_1_out;
                        read_u_s_low <= '1';
                        interp_state <= "0101";
                    end if;
                when "0101" =>
                    --check read completion
                    --read higher U
                    if read_u_s_low = '0' then
                        read_u_s_high <= '1';
                        interp_state <= "0110";
                    end if;
                when "0110" =>
                    --check read completion
                    --subtract two Us
                    if read_u_s_high = '0' then
                        fpu_sub_1_in_1 <= u_high_temp;
                        fpu_sub_1_in_2 <= u_low_temp;
                        enable_sub_1 <= '1';
                        interp_state <= "0111";
                    end if;
                when "0111" =>
                    --check subtraction completion
                    --multiply resultant T with subtraction result
                    if done_sub_1 = '1' then
                        fpu_mul_1_in_1 <= fpu_sub_1_out;
                        fpu_mul_1_in_2 <= t_const;
                        enable_mul_1 <= '1';
                        interp_state <= "1000";
                    end if;
                when "1000" =>
                    --check multiplication completion
                    --add multiplication result to U low
                    if done_mul_1 = '1' then
                        fpu_add_1_in_1 <= fpu_mul_1_out;
                        fpu_add_1_in_2 <= u_low_temp;
                        enable_add_1 <= '1';
                        interp_state <= "1001";
                    end if;
                when "1001" =>
                    --check addition completion
                    --write current U out
                    --decrement M counter
                    if done_add_1 = '1' then
                        u_out_result <= fpu_add_1_out;
                        write_u_out <= '1';
                        M <= M - 1;
                        interp_state <= "1010";
                    end if;
                when "1010" =>
                    --check Uout write completion
                    --check end of loop
                    --add time step to received time to check outut points
                    if write_u_out = '0' then
                        if M = 0 then
                            u_out_adr <= (others => '0');
                            fpu_add_1_in_1 <= h_step;
                            fpu_add_1_in_2 <= h_new;
                            enable_add_1 <= '1';
                            interp_state <= "1011";
                        else
                            interp_state <= "0100";
                        end if;
                    end if;
                when "1011" =>
                    --check addition comletion
                    --generate corresponding output signal
                    if done_add_1 = '1' then
                        if fpu_add_1_out = t_high and t_high = out_time_5 then
                            interp_done_op <= "11";
                            interrupt <= '0';
                            error_success <= '1';
                            send_output_enable <= '1';
                            interp_state <= "1111";
                        elsif fpu_add_1_out = t_high then
                            interp_done_op <= "10";
                            send_output_enable <= '1';
                            interp_state <= "0000";
                        else 
                            interp_done_op <= "01";
                            send_output_enable <= '1';
                            interp_state <= "0000";
                        end if;
                    end if;
                when others =>
                    --NOP
                    null;
            end case;
        end if;
    end process ;
end architecture;