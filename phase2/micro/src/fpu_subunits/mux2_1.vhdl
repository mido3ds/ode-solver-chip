library ieee;
use ieee.std_logic_1164.all;

entity mux2_1 is
    port (
        A, B : in std_logic;
        Sel  : in std_logic;
        Z    : out std_logic
    );
end entity;

architecture rtl of mux2_1 is
begin
    process (A, B, Sel)
    begin
        if Sel = '0' then
            Z <= A;
        else
            Z <= B;
        end if;
    end process;
end architecture;