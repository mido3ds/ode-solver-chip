library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity solver is
    port (
        --state signal sent from CPU
        in_state: in std_logic_vector(1 downto 0);
        clk: in std_logic;
        rst: in std_logic;
        --signals sent from interpolator
        --done: Un+1 is done and at the bus right now
        --o/p point: the upcoming U will be an output point
        interp_done_op: in std_logic_vector(1 downto 0);


        in_data: inout std_logic_vector(31 downto 0);
        adr: inout std_logic_vector(15 downto 0);
        
        interrupt: out std_logic;
        error_success: out std_logic
    );
end entity; 

architecture rtl of solver is
begin
-- TODO
end architecture;
