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
    signal incremented_a : std_logic_vector(out_a'range);
begin
    inc : entity work.incrementor
        generic map(N => 7)
        port map(
            a => in_a,
            c => incremented_a
        );

    add : entity work.adder_n_m
        generic map(N => 7, M => 3)
        port map(
            a => incremented_a,
            b => in_size,
            c => out_b
        );

    out_a <= incremented_a;
end architecture;