library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity range_extractor is
    port (
        in_a         : in std_logic_vector(6 downto 0);
        in_size      : in std_logic_vector(2 downto 0);

        out_a, out_b : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of range_extractor is
    signal temp_out_a : std_logic_vector(out_a'range);
begin
    inc : entity work.incrementor
        generic map(N => 7)
        port map(
            a    => in_a,
            enbl => '1',
            c    => temp_out_a
        );

    add : entity work.int_adder
        generic map(N => 7, M => 3)
        port map(
            a    => temp_out_a,
            b    => in_size,
            cin  => '0',
            enbl => '1',
            c    => out_b
        );

    out_a <= temp_out_a;
end architecture;