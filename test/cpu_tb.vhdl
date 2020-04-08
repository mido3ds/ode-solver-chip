library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity cpu_tb is
    generic (runner_cfg: string);
end entity; 

architecture tb of cpu_tb is
    constant CLK_FREQ: integer := 100e6; -- 100 MHz
    constant CLK_PERD: time    := 1000 ms / CLK_FREQ;

    signal clk: std_logic := '0';

    signal in_state: std_logic_vector(1 downto 0);
    signal rst: std_logic := '0';

    signal cpu_data: std_logic_vector(31 downto 0);
    
    signal interrupt: std_logic;
    signal error_success: std_logic;
begin
    clk <= not clk after CLK_PERD / 2;

    main: entity work.main port map (
        clk => clk, 
        in_state => in_state,
        rst => rst, 
        cpu_data => cpu_data, 
        interrupt => interrupt, 
        error_success => error_success
    );

    process
        procedure read_input is
            constant file_path: string := "input/" & running_test_case & ".in";
            file file_handler : text open read_mode is file_path;

            variable row      : line;
            variable data     : std_logic_vector(31 downto 0);
            variable i        : integer := 1;
        begin
            info("reading: " & file_path);

            in_state <= STATE_LOAD;
            wait until rising_edge(clk);

            while not endfile(file_handler) loop
                readline(file_handler, row);
                read(row, data);

                cpu_data <= data;
                wait until rising_edge(clk);

                info("done line " & integer'image(i));
                i := i + 1;
            end loop;

            info("done reading " & file_path & " with " & integer'image(i) & " lines");
            file_close(file_handler);
        end procedure;

        procedure wait_io is
        begin
            in_state <= STATE_WAIT;
            wait until rising_edge(clk);

            info("waiting for io interrupt");

            -- TODO
            -- wait until interrupt = '1';
            -- check_equal(error_success, '1', "io had error in reading", failure);

            info("done waiting");
        end procedure;

        procedure wait_proc is
        begin
            in_state <= STATE_PROC;
            wait until rising_edge(clk);

            info("waiting for interrupt");

            -- TODO
            -- wait until interrupt = '1';
            -- check_equal(error_success, '1', "solver/interpolator had error during processing", failure);

            info("done waiting");
        end procedure;

        procedure write_output is
            constant file_path: string := "out/" & running_test_case & ".out";
            file file_handler : text open write_mode is file_path;

            variable row      : line;
            variable data     : std_logic_vector(31 downto 0);
            variable i        : integer := 1;
        begin
            in_state <= STATE_OUT;
            wait until rising_edge(clk);

            info("writing output to file: " & file_path);

            while interrupt /= '1' loop
                data := cpu_data;
                write(row, data);
                writeline(file_handler, row);

                wait until rising_edge(clk);

                info("wrote line " & integer'image(i));
                i := i+1;
                
                -- TODO: this is just for demonstration
                if i > 10 then
                    exit;
                end if;
            end loop;

            info("done writing " & file_path & " with " & integer'image(i) & " lines");
            file_close(file_handler);
        end procedure;

        procedure run_cpu is
        begin
            info(
                "running test_case: " & running_test_case &
                " input: input/" & running_test_case & ".in" &
                " output: out/" & running_test_case & ".out"
            );

            read_input;
            wait_io;
            wait_proc;
            write_output;
        end procedure;
    begin
        test_runner_setup(runner, runner_cfg);
        set_stop_level(failure);

        if run("sample-f16") then run_cpu; end if;
        if run("sample-f32") then run_cpu; end if;
        if run("sample-f64") then run_cpu; end if;

        wait for CLK_PERD/2;
        test_runner_cleanup(runner);
        wait;
    end process;
end architecture;
