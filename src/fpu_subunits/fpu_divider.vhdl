library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpu_divider is
    port (
        mode: in std_logic_vector(1 downto 0);
        clk: in std_logic;
        rst: in std_logic;
        enbl: in std_logic;
        in_a: in std_logic_vector(63 downto 0);
        in_b: in std_logic_vector(63 downto 0);

        out_c: out std_logic_vector(63 downto 0);
        done: out std_logic;
        err: out std_logic;
        zero: out std_logic;
        posv: out std_logic
    );
end entity; 

architecture rtl of fpu_divider is
begin
-- TODO
end architecture;
