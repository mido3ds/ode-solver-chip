library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity solver_tb is
    generic (runner_cfg : string);
end entity;

architecture tb of solver_tb is
    constant CLK_FREQ    : integer   := 100e6; -- 100 MHz
    constant CLK_PERD    : time      := 1000 ms / CLK_FREQ;

    signal clk           : std_logic := '0';

    signal in_state      : std_logic_vector(1 downto 0);
    signal rst           : std_logic;
    signal interp_done   : std_logic_vector(1 downto 0);

    signal in_data       : std_logic_vector(31 downto 0);

    signal adr           : std_logic_vector(15 downto 0);
    signal interrupt     : std_logic;
    signal error_success : std_logic;
begin
    solver : entity work.solver(rtl)
        port map(
            in_state      => in_state,
            clk           => clk,
            rst           => rst,
            interp_done_op   => interp_done,
            in_data       => in_data,
            adr           => adr,
            interrupt     => interrupt,
            error_success => error_success
        );

        generateClock : process (clk)
        begin 
            clk <= not clk after CLK_PERD/2; 
        end process;
        process
            begin
                -- Reset all signal and stats
                rst <=('1');
                wait for CLK_PERD;

                -- Intialize Header

                -- disable rst signal
                rst <=('0'); 
                -- define load in  in_state
                in_state <=("00");
                
                -- Enter address of header structure 
                adr <= std_logic_vector(to_unsigned(16#0000#,16));
                -- Enter Header Strucutre
                in_data(31 downto 26) <= ("110010");-- Dimension of X equal 50
                in_data(25 downto 20) <= ("110010");-- Dimension of U equal 50
                in_data(19) <= ('0'); -- Choose fixed method (Forward Eular)
                in_data(18 downto 17) <=("00"); -- Choose Fixed point precision
                in_data(16 downto 14) <=("001"); -- Count = 1
                in_data(13 downto 0) <=(others=>'0'); -- Not Used
                wait for CLK_PERD;
                
                -- Initialzie h
                adr <= std_logic_vector(to_unsigned(16#0001#,16));
                in_data <= std_logic_vector(to_unsigned(16#0001#,16));
                wait for CLK_PERD;

                -- Initalize Matrix A
                adr <= std_logic_vector(to_unsigned(16#0005#,16));
                for i in 0 to 49 loop -- for every row  
                    for j in 0 to 49 loop -- for every element in each row
                        in_data(31 downto 16) <= (others =>'0');
                        in_data(15 downto 0) <= std_logic_vector(to_unsigned(16#0006#,16));
                        wait for CLK_PERD;
                    end loop;
                end loop;

                -- Initialize Matrix B
                adr <= std_logic_vector(to_unsigned(16#138D#,16));
                for i in 0 to 49 loop -- for every row  
                    for j in 0 to 49 loop -- for every element in each row
                        in_data(31 downto 16) <= (others =>'0');
                        in_data(15 downto 0) <= std_logic_vector(to_unsigned(10#3#,16));
                        wait for CLK_PERD;
                    end loop;
                end loop;

                -- Initialize U
                adr <= std_logic_vector(to_unsigned(16#296D#,16));
                for i in 0 to 49 loop
                    in_data(31 downto 0) <=(others =>'0');
                    in_data(15 downto 0) <= std_logic_vector(to_unsigned(10#5#,16));
                    wait for CLK_PERD;
                end loop;

                -- Initialize X
                adr <= std_logic_vector(to_unsigned(16#2715#,16));
                for i in 0 to 49 loop
                    in_data(31 downto 0) <=(others =>'0');
                    in_data(15 downto 0) <= std_logic_vector(to_unsigned(10#2#,16));
                    wait for CLK_PERD;
                end loop;

                -- define U state in interp_done
                interp_done <= ("10");


                --Check output
                for i in 0 to 49 loop
                    assert(in_data=std_logic_vector(to_unsigned(10#1352#,16)));
                    wait for CLK_PERD;
                end loop;

            end process;
end architecture;