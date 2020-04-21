library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity ram_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of ram_tb is
    constant CLK_FREQ                 : integer   := 100e6; -- 100 MHz
    constant CLK_PERD                 : time      := 1000 ms / CLK_FREQ;

    signal clk                        : std_logic := '0';

    signal rd, wr, rst                : std_logic;
    signal address, data_in, data_out : std_logic_vector(15 downto 0);
begin
    clk <= not clk after CLK_PERD / 2;

    ram : entity work.ram
        generic map(WORD_LENGTH => 16, ADR_LENGTH => 16, NUM_WORDS => 4 * 1024)
        port map(
            rd => rd, wr => wr, address => address, clk => clk, rst => rst,
            data_in => data_in, data_out => data_out
        );

    main : process
        constant input_case  : std_logic_vector(15 downto 0) := x"A59F";
        constant input_case2 : std_logic_vector(15 downto 0) := x"5fff";
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        info("reset");
        wr      <= '0';
        rd      <= '0';
        rst     <= '0';
        address <= x"0000";
        data_in <= x"0000";
        wait for CLK_PERD;

        if run("one_word") then
            wr      <= '1';
            rd      <= '0';
            address <= x"0000";
            data_in <= input_case;
            wait for CLK_PERD;

            wr      <= '0';
            rd      <= '1';
            address <= x"0000";
            wait for CLK_PERD;
            check_equal(data_out, input_case, "data_out is input_case");
        end if;

        if run("two_words") then
            wr      <= '1';
            rd      <= '0';
            address <= x"0000";
            data_in <= input_case;
            wait for CLK_PERD;
            wr      <= '1';
            rd      <= '0';
            address <= x"0001";
            data_in <= input_case2;
            wait for CLK_PERD;

            wr      <= '0';
            rd      <= '1';
            address <= x"0000";
            wait for CLK_PERD;
            check_equal(data_out, input_case, "data_out is input_case");
            wr      <= '0';
            rd      <= '1';
            address <= x"0001";
            wait for CLK_PERD;
            check_equal(data_out, input_case2, "data_out is input_case2");
        end if;

        if run("all_zeroes") then
            info("zeroing ram");
            for i in 0 to 4 * 1024 - 1 loop
                wr      <= '1';
                rd      <= '0';
                address <= std_logic_vector(to_unsigned(i, 16));
                data_in <= x"0000";
                wait for CLK_PERD;
            end loop;

            info("testing all ram is zeroed");
            for i in 0 to 4 * 1024 - 1 loop
                wr      <= '0';
                rd      <= '1';
                address <= std_logic_vector(to_unsigned(i, 16));
                wait for CLK_PERD;
                check_equal(data_out, std_logic_vector(to_unsigned(0, 16)), "data_out is zero");
            end loop;
        end if;

        if run("rst") then
            wr      <= '1';
            rd      <= '0';
            address <= x"0000";
            data_in <= input_case;
            wait for CLK_PERD;
            wr      <= '1';
            rd      <= '0';
            address <= x"0001";
            data_in <= input_case2;
            wait for CLK_PERD;

            wr      <= '0';
            rd      <= '1';
            address <= x"0000";
            wait for CLK_PERD;
            check_equal(data_out, input_case, "data_out is input_case");
            wr      <= '0';
            rd      <= '1';
            address <= x"0001";
            wait for CLK_PERD;
            check_equal(data_out, input_case2, "data_out is input_case2");

            rst <= '1';
            wait for 1 ps;
            rst <= '0';

            info("testing all ram is zeroed");
            for i in 0 to 4 * 1024 - 1 loop
                wr      <= '0';
                rd      <= '1';
                address <= std_logic_vector(to_unsigned(i, 16));
                wait for CLK_PERD;
                check_equal(data_out, std_logic_vector(to_unsigned(0, 16)), "data_out is zero");
            end loop;
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;