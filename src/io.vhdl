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

    -- next adr
    signal nau_out_adr   : std_logic_vector(adr'range);
    signal nau_done      : std_logic;
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

    nau : entity work.next_adr
        port map(
            in_data  => dcm_out_data,
            in_ready => dcm_out_ready,
            clk      => clk,
            rst      => rst,
            out_adr  => nau_out_adr,
            done     => nau_done
        );

    process (clk, rst, in_state)
    begin
        if rst = '1' then
            interrupt     <= '0';
            error_success <= '0';
        elsif rising_edge(clk) then
            case(in_state) is
                when STATE_LOAD | STATE_WAIT =>
                adr     <= nau_out_adr;
                in_data <= dcm_out_data;

                if nau_done = '1' then
                    interrupt <= '1';
                end if;

                when STATE_OUT =>
                cpu_data <= in_data;

                when others => null;
            end case;
        end if;

        -- change in state
        if in_state'event then
            interrupt <= '0';

            -- put Z on read-only busses to avoid conflicts with writers
            case(in_state) is
                when STATE_LOAD | STATE_WAIT =>
                cpu_data <= (others          => 'Z');

                when STATE_OUT               =>
                in_data <= (others           => 'Z');
                adr     <= (others           => 'Z');

                when others                  =>
                cpu_data <= (others          => 'Z');
                in_data  <= (others          => 'Z');
                adr      <= (others          => 'Z');
            end case;
        end if;
    end process;
end architecture;