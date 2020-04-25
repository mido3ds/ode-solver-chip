library ieee;
use ieee.std_logic_1164.all;

entity cla_16_bit_adder is
    port (
        in_a      : in std_logic_vector(15 downto 0);
        in_b      : in std_logic_vector(15 downto 0);
        carry_in  : in std_logic;
        sum       : out std_logic_vector(15 downto 0);
        carry_out : out std_logic
    );
end entity;

architecture rtl of cla_16_bit_adder is
    signal h_sum             : std_logic_vector(15 downto 0);
    signal carry_generate    : std_logic_vector(15 downto 0);
    signal carry_propagate   : std_logic_vector(15 downto 0);
    signal carry_in_internal : std_logic_vector(15 downto 1);
begin
    h_sum           <= in_a xor in_b;
    carry_generate  <= in_a and in_b;
    carry_propagate <= in_a xor in_b;
    process (carry_generate, carry_propagate, carry_in_internal,carry_in)
    begin
        carry_in_internal(1) <= carry_generate(0) or (carry_propagate(0) and carry_in);
        inst : for i in 1 to 14 loop
            carry_in_internal(i + 1) <= carry_generate(i) or (carry_propagate(i) and carry_in_internal(i));
        end loop;
        carry_out <= carry_generate(15) or (carry_propagate(15) and carry_in_internal(15));
    end process;

    sum(0)           <= h_sum(0) xor carry_in;
    sum(15 downto 1) <= h_sum(15 downto 1) xor carry_in_internal(15 downto 1);
end architecture;
