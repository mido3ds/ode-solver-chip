library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity incrementer is
    generic (N : integer := 7);

    port (
        a : in std_logic_vector(N - 1 downto 0);
        c : out std_logic_vector(N - 1 downto 0)
    );
end entity;

architecture rtl of incrementer is
    signal adder_carrys : std_logic_vector(N downto 0);
begin
    half_adder_0 : for i in 0 to N - 1 generate
        half_adder_0_i : entity work.half_adder
            port map(
                a => a(i), b => adder_carrys(i),
                cout => adder_carrys(i + 1), f => c(i)
            );
    end generate;

    -- cin
    adder_carrys(0) <= '1';
end architecture;