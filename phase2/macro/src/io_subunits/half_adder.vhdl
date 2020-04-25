library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

entity half_adder is
    port (
        a, b    : in std_logic;
        cout, f : out std_logic
    );
end entity;

architecture rtl of half_adder is
begin
    f    <= a xor b;
    cout <= a and b;
end architecture;