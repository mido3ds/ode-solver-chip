library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity solver_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of solver_tb is
    constant CLK_FREQ     : integer   := 100e6; -- 100 MHz
    constant CLK_PERD     : time      := 1000 ms / CLK_FREQ;

    signal clk            : std_logic := '0';

    signal in_state       : std_logic_vector(1 downto 0);
    signal rst            : std_logic;
    signal interp_done_op : std_logic_vector(1 downto 0);

    signal in_data        : std_logic_vector(31 downto 0);

    signal adr            : std_logic_vector(15 downto 0);
    signal interrupt      : std_logic;
    signal error_success  : std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    solver : entity work.solver
        port map(
            in_state       => in_state,
            clk            => clk,
            rst            => rst,
            interp_done_op => interp_done_op,
            in_data        => in_data,
            adr            => adr,
            interrupt      => interrupt,
            error_success  => error_success
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        rst <= '1';
        wait for 1 ps;
        rst <= '0';

        if run("name_this_test_case") then
            -- TODO
            in_state <= "00";
            in_data  <= (others => '0');
            adr      <= (others => '0');
            wait for 10 * CLK_PERD;
        end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;