library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_n_m is
    -- N <= M
    generic (
        N : integer := 7;
        M : integer := 3
    );

    port (
        a : in std_logic_vector(N - 1 downto 0);
        b : in std_logic_vector(M - 1 downto 0);
        c : out std_logic_vector(N - 1 downto 0)
    );
end entity;

architecture rtl of adder_n_m is
    signal adder_b      : std_logic_vector(N - 1 downto 0);
    signal adder_carrys : std_logic_vector(N downto 0);
begin
    full_adder_0 : for i in 0 to N - 1 generate
        full_adder_0_i : entity work.full_adder
            port map(
                a => a(i), b => adder_b(i), cin => adder_carrys(i),
                cout => adder_carrys(i + 1), f => c(i)
            );
    end generate;

    adder_b(M - 1 downto 0) <= b;
    adder_b(N - 1 downto 3) <= (others => '0');

    -- cin
    adder_carrys(0)         <= '0';
end architecture;