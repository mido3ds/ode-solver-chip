library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

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
    signal state          : std_logic_vector(1 downto 0);

    constant STATE_NO_HDR : std_logic_vector(state'range) := to_vec(0, state'length);
begin
    process (clk, rst)
    begin
        if rst = '1' then
            -- TODO
        elsif rising_edge(clk) then
            -- TODO
        end if;
    end process;
end architecture;