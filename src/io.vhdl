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
    signal dcm_out_data      : std_logic_vector(in_data'range);
    signal dcm_out_ready     : std_logic;
    signal dcm_enbl_in       : std_logic;
    signal dcm_interrupt     : std_logic;
    signal dcm_state_wait    : std_logic;
    signal dcm_error_success : std_logic;

    -- next adr
    signal nau_out_adr       : std_logic_vector(adr'range);
    signal nau_done          : std_logic;
begin
    dcm_enbl_in    <= to_std_logic(in_state = STATE_LOAD);
    dcm_state_wait <= to_std_logic(in_state = STATE_WAIT);

    decompressor : entity work.decompressor
        port map(
            in_data       => cpu_data,
            rst           => rst,
            enbl_in       => dcm_enbl_in,
            clk           => clk,
            out_data      => dcm_out_data,
            out_ready     => dcm_out_ready,
            error_success => dcm_error_success,
            state_wait    => dcm_state_wait
        );

    nau : entity work.next_adr
        port map(
            in_data => dcm_out_data,
            enbl    => dcm_out_ready,
            clk     => clk,
            rst     => rst,
            out_adr => nau_out_adr,
            done    => nau_done
        );

    process (clk, rst, in_state, nau_out_adr, dcm_out_data, dcm_error_success, nau_done, dcm_error_success, in_data)
    begin
        -- reset or change in state
        if rst = '1' or in_state'event then
            interrupt     <= '0';
            error_success <= '1';

            -- put Z on read-only busses to avoid conflicts with writers
            case in_state is
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

        if rst = '0' then
            case in_state is
                when STATE_LOAD | STATE_WAIT =>
                    adr <= nau_out_adr;
                    if falling_edge(clk) then
                        in_data <= dcm_out_data;
                    end if;
                    error_success <= dcm_error_success;
                    interrupt     <= nau_done or to_std_logic(dcm_error_success = '0');

                when STATE_OUT =>
                    cpu_data <= in_data;

                when others => null;
            end case;
        end if;
    end process;
end architecture;