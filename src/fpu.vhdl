library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpu is
    port (
        operation: in std_logic_vector(1 downto 0);
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

architecture rtl of fpu is
begin
    -- TODO

    adder: entity work.fpu_adder port map (
        clk => clk, 
        operation => operation,
        rst => rst, 
        enbl => enbl, 
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => err, 
        zero => zero, 
        posv => posv
    );

    multiplier: entity work.fpu_multiplier port map (
        clk => clk, 
        operation => operation,
        rst => rst, 
        enbl => enbl, 
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => err, 
        zero => zero, 
        posv => posv
    );

    divider: entity work.fpu_divider port map (
        clk => clk, 
        operation => operation,
        rst => rst, 
        enbl => enbl, 
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => err, 
        zero => zero, 
        posv => posv
    );

end architecture;
