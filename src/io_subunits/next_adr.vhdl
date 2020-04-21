library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity next_adr is
    port (
        in_data    : in std_logic_vector(31 downto 0);
        enbl       : in std_logic;
        clk        : in std_logic;
        rst        : in std_logic;

        out_adr    : out std_logic_vector(15 downto 0);
        done       : out std_logic;

        -- for testing
        state_test : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of next_adr is
    -- states
    signal state         : std_logic_vector(3 downto 0);
    constant STATE_START : std_logic_vector(state'range) := x"0";
    constant STATE_HDR   : std_logic_vector(state'range) := x"1";
    constant STATE_H_ERR : std_logic_vector(state'range) := x"2";
    constant STATE_A     : std_logic_vector(state'range) := x"3";
    constant STATE_B     : std_logic_vector(state'range) := x"4";
    constant STATE_X     : std_logic_vector(state'range) := x"5";
    constant STATE_U0    : std_logic_vector(state'range) := x"6";
    constant STATE_T     : std_logic_vector(state'range) := x"7";
    constant STATE_US    : std_logic_vector(state'range) := x"8";
    constant STATE_DONE  : std_logic_vector(state'range) := x"9";

    signal cur_adr       : std_logic_vector(out_adr'range);
    signal new_adr       : std_logic_vector(out_adr'range);

    -- header parts
    signal header        : std_logic_vector(31 downto 0);
    alias hdr_n is header(31 downto 26);
    alias hdr_m is header(25 downto 20);
    alias hdr_mode is header(19);
    alias hdr_fpu_precision is header(18 downto 17);
    alias hdr_tsize is header(16 downto 14);

    -- boundries
    signal max_a_adr                     : std_logic_vector(out_adr'range);
    signal max_b_adr                     : std_logic_vector(out_adr'range);
    signal max_x_adr                     : std_logic_vector(out_adr'range);
    signal max_u0_adr                    : std_logic_vector(out_adr'range);
    signal max_t_adr                     : std_logic_vector(out_adr'range);
    signal max_us_adr                    : std_logic_vector(out_adr'range);

    -- tmp inputs
    signal hdr_n_with_padding            : std_logic_vector(out_adr'range);
    signal hdr_m_with_padding            : std_logic_vector(out_adr'range);

    -- tmp outputs
    signal hdr_n_square                  : std_logic_vector(out_adr'range);
    signal hdr_n_m                       : std_logic_vector(out_adr'range);
    signal hdr_tsize_m                   : std_logic_vector(out_adr'range);

    function get_increment_size(fpu_mode : std_logic_vector) return std_logic_vector is
    begin
        if fpu_mode = FPU_MODE_FXD or fpu_mode = FPU_MODE_F32 then
            return to_vec(2, 2);
        end if;

        return to_vec(1, 2);
    end function;
begin
    state_test <= state;
    out_adr    <= cur_adr;

    iterator : entity work.int_adder
        generic map(N => cur_adr'length, M => 2)
        port map(
            a    => cur_adr,
            b    => get_increment_size(hdr_fpu_precision),
            cin  => '0',
            enbl => '1',
            c    => new_adr
        );

    -- max_a_adr
    hdr_n_with_padding <= "0000000000" & hdr_n;

    max_a_adr_mul : entity work.int_multiplier
        generic map(N => hdr_n_with_padding'length, M => hdr_n_with_padding'length)
        port map(
            a    => hdr_n_with_padding,
            b    => hdr_n_with_padding,
            enbl => '1',
            c    => hdr_n_square
        );

    max_a_adr_add : entity work.int_adder
        generic map(N => MM_A_0'length, M => hdr_n_square'length)
        port map(
            a    => MM_A_0,
            b    => multiply2(hdr_n_square),
            cin  => '0',
            enbl => '1',
            c    => max_a_adr
        );

    -- max_b_adr
    hdr_m_with_padding <= "0000000000" & hdr_m;

    max_b_adr_mul : entity work.int_multiplier
        generic map(N => hdr_n_with_padding'length, M => hdr_m_with_padding'length)
        port map(
            a    => hdr_n_with_padding,
            b    => hdr_m_with_padding,
            enbl => '1',
            c    => hdr_n_m
        );

    max_b_adr_add : entity work.int_adder
        generic map(N => MM_B_0'length, M => hdr_n_m'length)
        port map(
            a    => MM_B_0,
            b    => multiply2(hdr_n_m),
            cin  => '0',
            enbl => '1',
            c    => max_b_adr
        );

    -- max_x_adr
    max_x_adr_add : entity work.int_adder
        generic map(N => MM_X_0'length, M => hdr_n'length)
        port map(
            a    => MM_X_0,
            b    => multiply2(hdr_n),
            cin  => '0',
            enbl => '1',
            c    => max_x_adr
        );

    -- max_u0_adr
    max_u0_adr_add : entity work.int_adder
        generic map(N => MM_U0_0'length, M => hdr_m'length)
        port map(
            a    => MM_U0_0,
            b    => multiply2(hdr_m),
            cin  => '0',
            enbl => '1',
            c    => max_u0_adr
        );

    -- max_us_adr
    max_us_adr_mul : entity work.int_multiplier
        generic map(N => hdr_m_with_padding'length, M => hdr_tsize'length)
        port map(
            a    => hdr_m_with_padding,
            b    => hdr_tsize,
            enbl => '1',
            c    => hdr_tsize_m
        );

    max_us_adr_add : entity work.int_adder
        generic map(N => MM_U_S_0'length, M => hdr_tsize_m'length)
        port map(
            a    => MM_U_S_0,
            b    => multiply2(hdr_tsize_m),
            cin  => '0',
            enbl => '1',
            c    => max_us_adr
        );

    -- max_t_adr
    max_t_adr_add : entity work.int_adder
        generic map(N => MM_T_0'length, M => hdr_tsize'length)
        port map(
            a    => MM_T_0,
            b    => multiply2(hdr_tsize),
            cin  => '0',
            enbl => '1',
            c    => max_t_adr
        );

    process (clk, rst, state)
    begin
        if rst = '1' then
            state   <= STATE_START;
            done    <= '0';
            cur_adr <= (others => '1');
        elsif rising_edge(clk) and enbl = '1' then
            case state is
                when STATE_START =>
                    -- start: next hdr(MM_HDR_0) + calculate max_*
                    cur_adr <= MM_HDR_0;
                    state   <= STATE_HDR;
                    header  <= in_data;

                when STATE_HDR =>
                    -- hdr: next h_err(MM_H_0)
                    cur_adr <= MM_H_0;
                    state   <= STATE_H_ERR;

                when STATE_H_ERR =>
                    -- h_err: out (MM_H_0, x"0004"], next a(MM_A_0)
                    cur_adr <= new_adr;

                    if new_adr = MM_A_0 then
                        cur_adr <= MM_A_0;
                        state   <= STATE_A;
                    end if;

                when STATE_A =>
                    -- a: out (MM_A_0,max_a_adr], next b(MM_B_0)
                    cur_adr <= new_adr;

                    if new_adr = max_a_adr then
                        cur_adr <= MM_B_0;
                        state   <= STATE_B;
                    end if;

                when STATE_B =>
                    -- b: out (MM_B_0,max_b_adr], next x(MM_X_0)
                    cur_adr <= new_adr;

                    if new_adr = max_b_adr then
                        cur_adr <= MM_X_0;
                        state   <= STATE_X;
                    end if;

                when STATE_X =>
                    -- x: out (MM_X_0,max_x_adr], next u0(MM_U0_0)
                    cur_adr <= new_adr;

                    if new_adr = max_x_adr then
                        cur_adr <= MM_U0_0;
                        state   <= STATE_U0;
                    end if;

                when STATE_U0 =>
                    -- u0: out (MM_U0_0,max_u0_adr], next t(MM_T_0)
                    cur_adr <= new_adr;

                    if new_adr = max_u0_adr then
                        cur_adr <= MM_T_0;
                        state   <= STATE_T;
                    end if;

                when STATE_T =>
                    -- t: out (MM_T_0,max_t_adr], next us(MM_U_S_0)
                    cur_adr <= new_adr;

                    if new_adr = max_t_adr then
                        cur_adr <= MM_U_S_0;
                        state   <= STATE_US;
                    end if;

                when STATE_US =>
                    -- us: out (MM_U_S_0,maxu_us_adr], next done(Z)
                    cur_adr <= new_adr;

                    if new_adr = max_us_adr then
                        done    <= '1';
                        cur_adr <= (others => 'Z');
                        state   <= STATE_DONE;
                    end if;

                when STATE_DONE =>
                    -- done: out Z
                    done    <= '1';
                    cur_adr <= (others => 'Z');

                when others        =>
                    assert false report "invalid state" severity failure;
            end case;
        end if;
    end process;
end architecture;