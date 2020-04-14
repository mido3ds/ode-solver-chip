library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpu_adder is
    port (
        mode    : in std_logic_vector(1 downto 0);
        clk     : in std_logic;
        rst     : in std_logic;
        enbl    : in std_logic;
        add_sub : in std_logic; -- add = 0, sub = 1
        in_a    : in std_logic_vector(63 downto 0);
        in_b    : in std_logic_vector(63 downto 0);

        out_c   : out std_logic_vector(63 downto 0);
        done    : out std_logic;
        err     : out std_logic;
        zero    : out std_logic;
        posv    : out std_logic
    );
end entity;

-- Adder implementation with operators
-- Used by other components temporarily until other algos architectures are done
architecture with_operators of fpu_adder is
begin
    -- TODO: copy phase-1 multiplier here and adjust the ports names to match this interface
end architecture;

architecture first_algo of fpu_adder is
begin
    -- TODO: implement first algo
end architecture;

architecture sec_algo of fpu_adder is
begin
    -- TODO: implement second algo
end architecture;