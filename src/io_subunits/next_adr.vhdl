library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity next_adr is
    port (
        in_data : in std_logic_vector(31 downto 0);
        enbl    : in std_logic;
        clk     : in std_logic;
        rst     : in std_logic;

        out_adr : out std_logic_vector(15 downto 0);
        done    : out std_logic
    );
end entity;

architecture rtl of next_adr is
    -- states
    signal state             : std_logic_vector(3 downto 0);
    ---- idle: reset state, out x"FFFF", next hdr(x"0000")
    constant STATE_START     : std_logic_vector(state'range) := x"0";
    ---- hdr: calculate dimensions, next h(x"0001")
    constant STATE_HDR_H_ERR : std_logic_vector(state'range) := x"1";
    ---- a: out (x"0005",x"138C"], next b(x"138D")
    constant STATE_A         : std_logic_vector(state'range) := x"4";
    ---- b: out (x"138D",x"2714"], next x(x"2715")
    constant STATE_B         : std_logic_vector(state'range) := x"5";
    ---- x: out (x"2715",x"296C"], next u0(x"296D")
    constant STATE_X         : std_logic_vector(state'range) := x"6";
    ---- u0: out (x"296D",x"29D0"], next t(x"29D1")
    constant STATE_U0        : std_logic_vector(state'range) := x"7";
    ---- t: out (x"29D1",x"29D7"], next us(x"29DB")
    constant STATE_T         : std_logic_vector(state'range) := x"8";
    ---- us: out (x"29DB",x"2BCB"]
    constant STATE_US        : std_logic_vector(state'range) := x"9";
    ---- done: out Z
    constant STATE_DONE      : std_logic_vector(state'range) := x"A";

    signal cur_adr           : std_logic_vector(out_adr'range);
    signal new_adr           : std_logic_vector(out_adr'range);

    -- header parts
    signal header            : std_logic_vector(31 downto 0);
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

    -- tmp outputs
    signal hdr_n_square                  : std_logic_vector(hdr_n'range);
    signal hdr_n_m                       : std_logic_vector(hdr_n'range);
    signal hdr_tsize_m                   : std_logic_vector(hdr_n'range);

    function get_increment_size(fpu_mode : std_logic_vector) return std_logic_vector is
    begin
        if fpu_mode = FPU_MODE_FXD or fpu_mode = FPU_MODE_F32 then
            return to_vec(2, 2);
        end if;

        return to_vec(1, 2);
    end function;
begin
    out_adr <= cur_adr;

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
    max_a_adr_mul : entity work.int_multiplier
        generic map(N => hdr_n'length, M => hdr_n'length)
        port map(
            a    => hdr_n,
            b    => hdr_n,
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
    max_b_adr_mul : entity work.int_multiplier
        generic map(N => hdr_n'length, M => hdr_m'length)
        port map(
            a    => hdr_n,
            b    => hdr_m,
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
        generic map(N => hdr_m'length, M => hdr_tsize'length)
        port map(
            a    => hdr_m,
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
            case(state) is
                when STATE_START =>
                cur_adr <= MM_HDR_0;
                state   <= STATE_HDR_H_ERR;
                header  <= in_data;

                when STATE_HDR_H_ERR =>
                cur_adr <= new_adr;

                if new_adr = MM_A_0 then
                    cur_adr <= MM_A_0;
                    state   <= STATE_A;
                end if;

                when STATE_A =>
                cur_adr <= new_adr;

                if new_adr = max_a_adr then
                    cur_adr <= MM_B_0;
                    state   <= STATE_B;
                end if;

                when STATE_B =>
                cur_adr <= new_adr;

                if new_adr = max_b_adr then
                    cur_adr <= MM_X_0;
                    state   <= STATE_X;
                end if;

                when STATE_X =>
                cur_adr <= new_adr;

                if new_adr = max_x_adr then
                    cur_adr <= MM_U0_0;
                    state   <= STATE_U0;
                end if;

                when STATE_U0 =>
                cur_adr <= new_adr;

                if new_adr = max_u0_adr then
                    cur_adr <= MM_T_0;
                    state   <= STATE_T;
                end if;

                when STATE_T =>
                cur_adr <= new_adr;

                if new_adr = max_t_adr then
                    cur_adr <= MM_U_S_0;
                    state   <= STATE_US;
                end if;

                when STATE_US =>
                cur_adr <= new_adr;

                if new_adr = max_us_adr then
                    done    <= '1';
                    cur_adr <= (others => 'Z');
                    state   <= STATE_DONE;
                end if;

                when others =>
                done    <= '1';
                cur_adr <= (others => 'Z');
            end case;
        end if;
    end process;
end architecture;