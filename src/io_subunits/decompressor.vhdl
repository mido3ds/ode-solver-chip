library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity decompressor is
    port (
        in_data   : in std_logic_vector(31 downto 0);
        rst       : in std_logic;
        enbl      : in std_logic;
        clk       : in std_logic;

        out_ready : out std_logic;
        out_data  : out std_logic_vector(31 downto 0);

        -- for testing and debugging 
        buf_dbg   : out std_logic_vector(128 - 1 downto 0)
    );
end entity;

architecture rtl of decompressor is
    -- buffer
    signal buf                          : std_logic_vector(128 - 1 downto 0);

    -- index of current bit in buffer to fill (if 0 -> put first bit in 0)
    signal buf_fill_i                   : std_logic_vector(6 downto 0);

    -- index of next buffer part to flush, either 0,32,64
    --- if 32 -> will flush from 32 to 63
    signal buf_flush_i, buf_flush_i_inv : std_logic_vector(6 downto 0);
    -- buf_flush_i_inc=buf_flush_i+32
    signal buf_flush_i_inc              : std_logic_vector(6 downto 0);

    -- buf_fill_flush_diff = buf_fill_i - buf_flush_i
    signal buf_fill_flush_diff          : std_logic_vector(6 downto 0);

    signal buf_is_empty                 : std_logic;

    -- range extractors
    type vecs_8x7 is array(0 to 7) of std_logic_vector(6 downto 0);
    signal out_bs, out_as : vecs_8x7;

    function get_size(i : integer; in_data : std_logic_vector) return std_logic_vector is
    begin
        return flip(flip(in_data)(i * 4 + 2 downto i * 4));
    end function;

    function get_bit(i : integer; in_data : std_logic_vector) return std_logic is
    begin
        return flip(in_data)(i * 4 + 3);
    end function;
begin
    range_extr_0 : entity work.range_extractor
        port map(
            -- inputs
            in_a    => buf_fill_i,
            in_size => flip(flip(in_data)(2 downto 0)),
            -- outputs
            out_a   => out_as(0),
            out_b   => out_bs(0)
        );

    ranges : for i in 1 to 7 generate
        range_extr_i : entity work.range_extractor
            port map(
                -- inputs
                in_a    => out_bs(i - 1),
                in_size => get_size(i, in_data),
                -- outputs
                out_a   => out_as(i),
                out_b   => out_bs(i)
            );
    end generate;

    buf_flush_i_adder : entity work.int_adder
        generic map(N => buf_flush_i'length, M => 6)
        port map(
            a    => buf_flush_i,
            b    => to_vec(32, 6),
            cin  => '0',
            enbl => '1',
            c    => buf_flush_i_inc
        );

    -- avoid a bug in ghdl
    buf_flush_i_inv <= not buf_flush_i;

    -- buf_fill_flush_diff = buf_fill_i - buf_flush_i
    fill_flush_diff_subtractor : entity work.int_adder
        generic map(N => buf_fill_i'length, M => buf_flush_i'length)
        port map(
            a    => buf_fill_i,
            b    => buf_flush_i_inv,
            cin  => '1',
            enbl => '1',
            c    => buf_fill_flush_diff
        );

    buf_dbg <= buf;

    process (enbl, clk, rst)
        procedure fill_buffer is
        begin
            --- foreach range pair
            for i in 0 to out_as'length - 1 loop
                --- foreach bit in buffer
                for j in 0 to buf'length - 1 loop
                    --- is the sec range >= first range ?
                    if to_int(out_bs(i)) >= to_int(out_as(i)) then
                        --- foreach 
                        if (j >= to_int(out_as(i)) and j <= to_int(out_bs(i))) then
                            null; -- dummy line so the reformatter tool ignores the following one
                            buf(j) <= get_bit(i, in_data);
                        end if;
                    else
                        if (j <= to_int(out_bs(i)) or j >= to_int(out_as(i))) then
                            null; -- dummy line so the reformatter tool ignores the following one
                            buf(j) <= get_bit(i, in_data);
                        end if;
                    end if;
                end loop;
            end loop;

            buf_is_empty <= '0';

            -- increment buf_fil_i
            buf_fill_i   <= out_bs(7);
        end procedure;

        procedure flush_buffer is
        begin
            if buf_is_empty = '0' and ((to_int(buf_fill_i) > to_int(buf_flush_i) and to_int(buf_fill_flush_diff) >= 31)
                or to_int(buf_fill_i) < to_int(buf_flush_i)) then
                if to_int(buf_flush_i) = 0 then
                    out_data <= flip(buf(32 - 1 downto 0));
                elsif to_int(buf_flush_i) = 32 then
                    out_data <= flip(buf(64 - 1 downto 32));
                elsif to_int(buf_flush_i) = 64 then
                    out_data <= flip(buf(96 - 1 downto 64));
                else
                    out_data <= flip(buf(128 - 1 downto 96));
                end if;

                -- increment buf_flush_i
                buf_flush_i <= buf_flush_i_inc;

                out_ready   <= '1';
            else
                out_ready <= '0';
            end if;
        end procedure;
    begin
        if enbl = '0' then
            out_data  <= (others => 'Z');
            out_ready <= '0';
        end if;

        if rst = '1' then
            buf_fill_i   <= (others => '1');
            buf_flush_i  <= (others => '0');
            buf_is_empty <= '1';
            out_ready    <= '0';
        elsif rising_edge(clk) and enbl = '1' then
            fill_buffer;
            flush_buffer;
        end if;
    end process;
end architecture;