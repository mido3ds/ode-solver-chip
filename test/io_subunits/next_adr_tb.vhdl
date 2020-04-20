library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity next_adr_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of next_adr_tb is
    constant CLK_FREQ      : integer   := 100e6; -- 100 MHz
    constant CLK_PERD      : time      := 1000 ms / CLK_FREQ;

    signal clk             : std_logic := '0';

    signal in_data         : std_logic_vector(31 downto 0);
    signal enbl, rst, done : std_logic;
    signal out_adr         : std_logic_vector(15 downto 0);

    signal state           : std_logic_vector(3 downto 0);
    constant STATE_START   : std_logic_vector(state'range) := x"0";
    constant STATE_HDR     : std_logic_vector(state'range) := x"1";
    constant STATE_H_ERR   : std_logic_vector(state'range) := x"2";
    constant STATE_A       : std_logic_vector(state'range) := x"3";
    constant STATE_B       : std_logic_vector(state'range) := x"4";
    constant STATE_X       : std_logic_vector(state'range) := x"5";
    constant STATE_U0      : std_logic_vector(state'range) := x"6";
    constant STATE_T       : std_logic_vector(state'range) := x"7";
    constant STATE_US      : std_logic_vector(state'range) := x"8";
    constant STATE_DONE    : std_logic_vector(state'range) := x"9";

    alias hdr_n is in_data(31 downto 26);
    alias hdr_m is in_data(25 downto 20);
    alias hdr_mode is in_data(19);
    alias hdr_fpu_precision is in_data(18 downto 17);
    alias hdr_tsize is in_data(16 downto 14);
begin
    clk <= not clk after CLK_PERD / 2;

    nau : entity work.next_adr
        port map(
            in_data    => in_data,
            enbl       => enbl,
            clk        => clk,
            rst        => rst,
            out_adr    => out_adr,
            state_test => state,
            done       => done
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        rst <= '1';
        wait for 1 ps;
        rst <= '0';

        if run("state_start") then
            enbl <= '0';
            check_equal(state, to_vec(STATE_START, state'length), "state");
            check_equal(out_adr, to_vec('1', out_adr'length), "out_adr");
            check_equal(done, '0', "done");
            wait for CLK_PERD;
            check_equal(state, to_vec(STATE_START, state'length), "state");
            check_equal(out_adr, to_vec('1', out_adr'length), "out_adr");
            check_equal(done, '0', "done");
        end if;

        if run("first_enable") then
            enbl <= '1';
            wait for CLK_PERD;
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
        end if;

        if run("iterate_to_a") then
            hdr_fpu_precision <= FPU_MODE_F64;

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_A_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_A, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_a_then_rst") then
            hdr_fpu_precision <= FPU_MODE_F64;

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_A_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_A, state'length), "state");
            check_equal(done, '0', "done");

            rst <= '1';
            wait for 1 ps;
            rst <= '0';
            check_equal(out_adr, to_vec('1', out_adr'length), "out_adr");
            check_equal(done, '0', "done");
            check_equal(state, to_vec(STATE_START, state'length), "state");
        end if;

        if run("iterate_to_a_f16") then
            hdr_fpu_precision <= FPU_MODE_FXD;

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(1, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
            check_equal(done, '0', "done");

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(3, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
            check_equal(done, '0', "done");

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_A_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_A, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_a_f32") then
            hdr_fpu_precision <= FPU_MODE_F32;

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(1, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
            check_equal(done, '0', "done");

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(3, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
            check_equal(done, '0', "done");

            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_A_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_A, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_b") then
            hdr_fpu_precision <= FPU_MODE_F64;
            hdr_n             <= to_vec(3, hdr_n'length);

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_A_0) to to_int(MM_A_0) + 3 * 3 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_A, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, MM_B_0, "out_adr");
            check_equal(state, to_vec(STATE_B, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_x") then
            hdr_fpu_precision <= FPU_MODE_F64;
            hdr_n             <= to_vec(4, hdr_n'length);
            hdr_m             <= to_vec(2, hdr_m'length);

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_A_0) to to_int(MM_A_0) + 4 * 4 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_A, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_B_0) to to_int(MM_B_0) + 4 * 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_B, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, MM_X_0, "out_adr");
            check_equal(state, to_vec(STATE_X, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_u0") then
            hdr_fpu_precision <= FPU_MODE_F64;
            hdr_n             <= to_vec(4, hdr_n'length);
            hdr_m             <= to_vec(2, hdr_m'length);

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_A_0) to to_int(MM_A_0) + 4 * 4 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_A, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_B_0) to to_int(MM_B_0) + 4 * 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_B, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_X_0) to to_int(MM_X_0) + 4 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_X, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, MM_U0_0, "out_adr");
            check_equal(state, to_vec(STATE_U0, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_t") then
            hdr_fpu_precision <= FPU_MODE_F64;
            hdr_n             <= to_vec(10, hdr_n'length);
            hdr_m             <= to_vec(2, hdr_m'length);
            hdr_tsize         <= to_vec(3, hdr_tsize'length);

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_A_0) to to_int(MM_A_0) + 10 * 10 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_A, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_B_0) to to_int(MM_B_0) + 10 * 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_B, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_X_0) to to_int(MM_X_0) + 10 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_X, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_U0_0) to to_int(MM_U0_0) + 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_U0, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, MM_T_0, "out_adr");
            check_equal(state, to_vec(STATE_T, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_us") then
            hdr_fpu_precision <= FPU_MODE_F64;
            hdr_n             <= to_vec(10, hdr_n'length);
            hdr_m             <= to_vec(2, hdr_m'length);
            hdr_tsize         <= to_vec(3, hdr_tsize'length);

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_A_0) to to_int(MM_A_0) + 10 * 10 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_A, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_B_0) to to_int(MM_B_0) + 10 * 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_B, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_X_0) to to_int(MM_X_0) + 10 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_X, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_U0_0) to to_int(MM_U0_0) + 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_U0, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_T_0) to to_int(MM_T_0) + 3 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_T, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            wait for CLK_PERD;
            check_equal(out_adr, MM_U_S_0, "out_adr");
            check_equal(state, to_vec(STATE_US, state'length), "state");
            check_equal(done, '0', "done");
        end if;

        if run("iterate_to_done") then
            hdr_fpu_precision <= FPU_MODE_F64;
            hdr_n             <= to_vec(10, hdr_n'length);
            hdr_m             <= to_vec(2, hdr_m'length);
            hdr_tsize         <= to_vec(3, hdr_tsize'length);

            enbl              <= '1';
            wait for CLK_PERD;
            check_equal(out_adr, to_vec(MM_HDR_0, out_adr'length), "out_adr");
            check_equal(state, to_vec(STATE_HDR, state'length), "state");
            check_equal(done, '0', "done");

            for i in 1 to 4 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_H_ERR, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_A_0) to to_int(MM_A_0) + 10 * 10 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_A, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_B_0) to to_int(MM_B_0) + 10 * 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_B, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_X_0) to to_int(MM_X_0) + 10 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_X, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_U0_0) to to_int(MM_U0_0) + 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_U0, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_T_0) to to_int(MM_T_0) + 3 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_T, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            for i in to_int(MM_U_S_0) to to_int(MM_U_S_0) + 3 * 2 * 2 - 1 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec(i, out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_US, state'length), "state");
                check_equal(done, '0', "done");
            end loop;

            -- arbitray number of iterations to make sure i stopped at done
            for i in 0 to 5 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec('Z', out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_DONE, state'length), "state");
                check_equal(done, '1', "done");
            end loop;

            -- event without enable 
            enbl <= '0';
            for i in 0 to 5 loop
                wait for CLK_PERD;
                check_equal(out_adr, to_vec('Z', out_adr'length), "out_adr");
                check_equal(state, to_vec(STATE_DONE, state'length), "state");
                check_equal(done, '1', "done");
            end loop;

            -- reset
            rst <= '1';
            wait for 1 ps;
            rst <= '0';
            check_equal(out_adr, to_vec('1', out_adr'length), "out_adr");
            check_equal(done, '0', "done");
            check_equal(state, to_vec(STATE_START, state'length), "state");
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;