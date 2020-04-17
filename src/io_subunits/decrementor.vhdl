library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decrementor is
    generic (N : integer := 7);

    port (
        a : in std_logic_vector(N - 1 downto 0);
        c : out std_logic_vector(N - 1 downto 0)
    );
end entity;

architecture rtl of decrementor is
    signal adder_carrys : std_logic_vector(N downto 0);
    constant neg_one    : std_logic_vector(a'range) := (others => '1');
begin
    full_adder_0 : for i in 0 to N - 1 generate
        full_adder_0_i : entity work.full_adder
            port map(
                a => a(i), b => neg_one(i), cin => adder_carrys(i),
                cout => adder_carrys(i + 1), f => c(i)
            );
    end generate;

    -- cin
    adder_carrys(0) <= '0';
end architecture;