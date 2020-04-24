library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpu_adder is
    port (
        mode    : in std_logic_vector(1 downto 0);
        clk     : in std_logic;
        rst     : in std_logic;
        enbl    : in std_logic;
        add_sub : in std_logic; -- add = 0, sub = 1
        in_a    : in std_logic_vector(63 downto 0);
        in_b    : in std_logic_vector(63 downto 0);

        out_c   : out std_logic_vector(63 downto 0);
        done    : out std_logic;
        err     : out std_logic;
        zero    : out std_logic;
        posv    : out std_logic
    );
end entity;

-- Adder implementation with operators
-- Used by other components temporarily until other algos architectures are done
architecture with_operators of fpu_adder is
    signal in_b_signal               : std_logic_vector(63 downto 0);
    signal out_c_signal              : std_logic_vector(63 downto 0);
    signal zero_signal, error_signal : std_logic;
    function CheckZero (F            : in std_logic_vector)
        return std_logic is
        variable Zero : std_logic := '0';
    begin
        for i in 0 to 63 loop
            Zero := Zero or F(i);
        end loop;
        return Zero;
    end function CheckZero;
begin
    process (in_a, in_b, rst, enbl, out_c_signal, error_signal, zero_signal)
    begin
        if (rst = '1') then
            zero_signal  <= '1';
            posv         <= '0'; -- reset signal
            error_signal <= '0';
            out_c_signal <= (others => '0');
        elsif (enbl = '1' and rst = '0') then
            if add_sub = '1' then
                in_b_signal <= std_logic_vector(unsigned(not(in_b)) + 1);
            else
                in_b_signal <= in_b;
            end if;
            out_c_signal <= std_logic_vector(signed(in_a) + signed(in_b_signal));
            zero_signal  <= (not CheckZero(out_c_signal));
            posv         <= (not out_c_signal(63)) and (not zero_signal);
            error_signal <= ((not(in_a(63)) and not(in_b_signal(63)) and out_c_signal(63)) or ((in_a(63)) and (in_b_signal(63)) and not(out_c_signal(63))));
        end if;
        err   <= error_signal;
        zero  <= zero_signal;
        out_c <= out_c_signal;
        done  <= enbl or rst;
    end process;
end architecture;

architecture first_algo of fpu_adder is --Carry look ahead adder
    component cla_16_bit_adder is
        port (
            in_a      : in std_logic_vector(15 downto 0);
            in_b      : in std_logic_vector(15 downto 0);
            carry_in  : in std_logic;
            sum       : out std_logic_vector(15 downto 0);
            carry_out : out std_logic
        );
    end component;
    signal in_a_signal               : std_logic_vector(63 downto 0);
    signal in_b_signal               : std_logic_vector(63 downto 0);
    signal sum_signal, out_c_signal  : std_logic_vector(63 downto 0);
    signal carry_signal              : std_logic_vector(3 downto 1);
    signal zero_signal, error_signal : std_logic;
    signal dummy                     : std_logic;
    signal input_carry               : std_logic := '0';

    function CheckZero (F            : in std_logic_vector)
        return std_logic is
        variable Zero : std_logic := '0';
    begin
        for i in 0 to 63 loop
            Zero := Zero or F(i);
        end loop;
        return Zero;
    end function CheckZero;

begin
    u1 : cla_16_bit_adder port map(
        in_a => in_a_signal(15 downto 0), in_b => in_b_signal(15 downto 0), carry_in => input_carry, sum => sum_signal(15 downto 0)
        , carry_out => carry_signal(1));
    u2 : cla_16_bit_adder port map(
        in_a => in_a_signal(31 downto 16), in_b => in_b_signal(31 downto 16), carry_in => carry_signal(1), sum => sum_signal(31 downto 16)
        , carry_out => carry_signal(2));
    u3 : cla_16_bit_adder port map(
        in_a => in_a_signal(47 downto 32), in_b => in_b_signal(47 downto 32), carry_in => carry_signal(2), sum => sum_signal(47 downto 32)
        , carry_out => carry_signal(3));
    u4 : cla_16_bit_adder port map(
        in_a => in_a_signal(63 downto 48), in_b => in_b_signal(63 downto 48), carry_in => carry_signal(3), sum => sum_signal(63 downto 48)
        , carry_out => dummy);

    process (in_a, in_b, rst, enbl, sum_signal, out_c_signal, error_signal, zero_signal, in_b_signal)
    begin
        if (rst = '1') then -- reset signal
            error_signal <= '0';
            zero_signal  <= '1';
            posv         <= '0';
        elsif (enbl = '1'and rst = '0') then
            if add_sub = '1' then
                in_b_signal <= std_logic_vector(unsigned(not(in_b)) + 1);
            else
                in_b_signal <= in_b;
            end if;
            in_a_signal  <= in_a;
            out_c_signal <= sum_signal;
            zero_signal  <= (not CheckZero(out_c_signal));
            error_signal <= ((not(in_a(63)) and not(in_b_signal(63)) and out_c_signal(63)) or ((in_a(63)) and (in_b_signal(63)) and not(out_c_signal(63))));
            posv         <= (not out_c_signal(63)) and (not zero_signal);
        end if;
        zero  <= zero_signal;
        err   <= error_signal;
        out_c <= out_c_signal;
        done  <= enbl or rst;
    end process;
end architecture;

architecture sec_algo of fpu_adder is --Carry select
    component full_adder is
        port (
            a    : in std_logic;
            b    : in std_logic;
            cin  : in std_logic;
            f    : out std_logic;
            cout : out std_logic);
    end component;

    component mux2_1
        port (
            A, B : in std_logic;
            Sel  : in std_logic;
            Z    : out std_logic);
    end component;

    signal A, B, C0, C1                          : std_logic_vector(63 downto 0);
    signal in_b_signal, sum_signal, out_c_signal : std_logic_vector(63 downto 0);
    signal zero_signal, error_signal             : std_logic;
    signal dummy                                 : std_logic;

    function CheckZero (F                        : in std_logic_vector)
        return std_logic is
        variable Zero : std_logic := '0';
    begin
        for i in 0 to 63 loop
            Zero := Zero or F(i);
        end loop;
        return Zero;
    end function CheckZero;
begin
    FA1 : full_adder port map(in_a(0), in_b_signal(0), '0', A(0), C0(0));
    GEN_ADDER_CARRY_0 :
    for i in 1 to 63 generate
        ADDER_0 : full_adder port map(in_a(i), in_b_signal(i), C0(i - 1), A(i), C0(i));
    end generate;

    FA2 : full_adder port map(in_a(0), in_b_signal(0), '1', B(0), C1(0));
    GEN_ADDER_CARRY_1 :
    for i in 1 to 63 generate
        ADDER_1 : full_adder port map(in_a(i), in_b_signal(i), C1(i - 1), B(i), C1(i));
    end generate;

    GEN_MUX :
    for i in 0 to 63 generate
        MUX1 : mux2_1 port map(A(i), B(i), '0', sum_signal(i));
    end generate;
    MUX : mux2_1 port map(C0(63), C1(63), '0', dummy);

    process (in_a, in_b, rst, enbl, zero_signal, error_signal, sum_signal, in_b_signal, out_c_signal)
    begin
        if (rst = '1') then
            zero_signal  <= '1';
            posv         <= '0'; -- reset signal
            error_signal <= '0';
            out_c        <= (others => '0');
        elsif (enbl = '1' and rst = '0') then
            if add_sub = '1' then
                in_b_signal <= std_logic_vector(unsigned(not(in_b)) + 1);
            else
                in_b_signal <= in_b;
            end if;
            out_c_signal <= sum_signal;
            zero_signal  <= (not CheckZero(out_c_signal));
            posv         <= (not out_c_signal(63)) and (not zero_signal);
            error_signal <= ((not(in_a(63)) and not(in_b_signal(63)) and out_c_signal(63)) or ((in_a(63)) and (in_b_signal(63)) and not(out_c_signal(63))));
        end if;
        zero  <= zero_signal;
        err   <= error_signal;
        out_c <= out_c_signal;
        done  <= enbl or rst;
    end process;
end architecture;