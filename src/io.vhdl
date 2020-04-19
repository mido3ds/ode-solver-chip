library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity io is
    port (
        in_state      : in std_logic_vector(1 downto 0);
        clk           : in std_logic;
        rst           : in std_logic;

        cpu_data      : inout std_logic_vector(31 downto 0);
        in_data       : inout std_logic_vector(31 downto 0);

        adr           : out std_logic_vector(15 downto 0);
        interrupt     : out std_logic;
        error_success : out std_logic
    );
end entity;

architecture rtl of io is
    -- decompressor
    signal dcm_out_data  : std_logic_vector(in_data'range);
    signal dcm_out_ready : std_logic;
begin
    decompressor : entity work.decompressor
        port map(
            in_data   => cpu_data,
            rst       => rst,
            enbl_in   => to_std_logic(in_state = STATE_LOAD),
            clk       => clk,
            out_data  => dcm_out_data,
            out_ready => dcm_out_ready
        );

    process (clk, rst)
    begin
        if rst = '1' then
            interrupt     <= '0';
            error_success <= '0';
            adr           <= (others => 'Z');
            cpu_data      <= (others => 'Z');
            in_data       <= (others => 'Z');
        elsif rising_edge(clk) then
            case(in_state) is
                when STATE_LOAD =>
                null; -- TODO: load logic

                when STATE_WAIT =>
                null; -- TODO: wait logic

                when STATE_OUT =>
                null; -- TODO: output logic

                when others        =>
                -- in other states, we don't intervent in the internal bus
                in_data <= (others => 'Z');
                adr     <= (others => 'Z');
            end case;
        end if;
    end process;
end architecture;