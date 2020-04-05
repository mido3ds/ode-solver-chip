library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

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
    signal add_enbl, add_sub, mul_enbl, div_enbl : std_logic := '0';
    signal add_zero, mul_zero, div_zero : std_logic;
    signal add_posv, mul_posv, div_posv : std_logic;
    signal add_err, mul_err, div_err : std_logic;
begin
    adder: entity work.fpu_adder port map (
        clk => clk, 
        mode => mode,
        rst => rst, 
        enbl => add_enbl, 
        add_sub => add_sub,
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => add_err, 
        zero => add_zero, 
        posv => add_posv
    );

    add_enbl <= '1' when (operation = FPU_OP_ADD or operation = FPU_OP_SUB) else '0';
    add_sub <= '1' when (operation = FPU_OP_SUB) else '0';

    multiplier: entity work.fpu_multiplier port map (
        clk => clk, 
        mode => mode,
        rst => rst, 
        enbl => mul_enbl, 
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => mul_err, 
        zero => mul_zero, 
        posv => mul_posv
    );

    mul_enbl <= '1' when (operation = FPU_OP_MUL) else '0';

    divider: entity work.fpu_divider port map (
        clk => clk, 
        mode => mode,
        rst => rst, 
        enbl => div_enbl, 
        in_a => in_a, 
        in_b => in_b, 
        out_c => out_c, 
        done => done, 
        err => div_err, 
        zero => div_zero, 
        posv => div_posv
    );

    div_enbl <= '1' when (operation = FPU_OP_DIV) else '0';

    zero <= add_zero when (add_enbl = '1')
        else mul_zero when (mul_enbl = '1')
        else div_zero;
    
    posv <= add_posv when (add_enbl = '1')
        else mul_posv when (mul_enbl = '1')
        else div_posv;

    err <= add_err or mul_err or div_err;
end architecture;
