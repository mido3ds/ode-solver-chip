library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity next_adr is
    port (
        in_data  : in std_logic_vector(31 downto 0);
        in_ready : in std_logic;
        clk      : in std_logic;
        rst      : in std_logic;

        out_adr  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of next_adr is
begin
    -- TODO
end architecture;