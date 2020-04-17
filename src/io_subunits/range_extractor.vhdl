library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity range_extractor is
    port (
        in_a, in_lastsize      : in std_logic_vector(6 downto 0);
        in_size                : in std_logic_vector(2 downto 0);

        out_a, out_b, out_size : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of range_extractor is
    signal temp_out_a : std_logic_vector(out_a'range);
begin
    inc : entity work.incrementor
        generic map(N => 7)
        port map(
            a => in_a,
            c => temp_out_a
        );

    add : entity work.adder_n_m
        generic map(N => 7, M => 3)
        port map(
            a   => temp_out_a,
            b   => in_size,
            cin => '0',
            c   => out_b
        );

    size_adder : entity work.adder_n_m
        generic map(N => 7, M => 3)
        port map(
            a   => in_lastsize,
            b   => in_size,
            cin => '1',
            c   => out_size
        );

    out_a <= temp_out_a;
end architecture;