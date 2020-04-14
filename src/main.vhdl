library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
    port (
        in_state      : in std_logic_vector(1 downto 0);
        clk           : in std_logic;
        rst           : in std_logic;

        cpu_data      : inout std_logic_vector(31 downto 0);

        interrupt     : out std_logic;
        error_success : out std_logic
    );
end entity;

architecture rtl of main is
    signal in_data                                       : std_logic_vector(31 downto 0);
    signal interp_done                                   : std_logic;
    signal adr                                           : std_logic_vector(15 downto 0);
    signal io_interr, solver_interr, interp_interr       : std_logic;
    signal io_err_sucs, solver_err_sucs, interp_err_sucs : std_logic;
begin
    io : entity work.io
        port map(
            in_state      => in_state,
            clk           => clk,
            rst           => rst,
            in_data       => in_data,
            cpu_data      => cpu_data,
            interrupt     => io_interr,
            error_success => io_err_sucs
        );

    solver : entity work.solver
        port map(
            in_state      => in_state,
            clk           => clk,
            rst           => rst,
            interp_done   => interp_done,
            in_data       => in_data,
            adr           => adr,
            interrupt     => solver_interr,
            error_success => solver_err_sucs
        );

    interp : entity work.interp
        port map(
            in_state      => in_state,
            clk           => clk,
            rst           => rst,
            interp_done   => interp_done,
            in_data       => in_data,
            adr           => adr,
            interrupt     => interp_interr,
            error_success => interp_err_sucs
        );

    interrupt     <= io_interr or solver_interr or interp_interr;
    error_success <= io_err_sucs and solver_err_sucs and interp_err_sucs;
end architecture;