library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
Entity adder_fixed_scale is
End Entity;

Architecture testing of adder_fixed_scale  is
    component Adder is
        port(
    A,B:in std_logic_vector(15 downto 0);
    F:out std_logic_vector(15 downto 0);
    OverFlowFlag:out std_logic);
    end component;
    signal A,B,F :std_logic_vector(15 downto 0);
    signal OverFlowSignal:std_logic;
    begin
        DUT: Adder port map(A=>A,B=>B,F=>F,OverFlowFlag=>OverFlowSignal);
        process
        begin
        A <= ("0000000000110100");
        B <= ("0000000000101100");
        wait for 10 ns;
        assert(F="0000000001100000");
        report "Test Passed 1: passed";

        A <= ("1111111111101110");
        B <= ("0000000000111000");
        wait for 10 ns;
        assert(F="0000000000100110") ;
        report "Test Passed 2: passed";

        A <= ("0000000000001000");
        B <= ("0000000000000010");
        wait for 10 ns;
        assert(F="0000000000001010") ;
        report "Test Passed 3: passed";

        A <= ("0000000010101100");
        B <= ("1111111100111100");
        wait for 10 ns;
        assert(F="1111111111101000") ;
        report "Test Passed 4: passed";

        A <= ("0000000101000010");
        B <= ("1111111010111110");
        wait for 10 ns;
        assert(F="0000000000000000") ;
        report "Test Passed 5: passed";

        A <= ("1111111110101110");
        B <= ("1111111111000100");
        wait for 10 ns;
        assert(F="1111111101110010") ;
        report "Test Passed 6: passed";
        
        A <= ("1000000000000001");
        B <= ("1111111111110000");
        wait for 10 ns;
        assert(OverFlowSignal='1') ;
        report "Test Passed 7: passed";

        A <= ("0111111111111111");
        B <= ("0111111111111111");
        wait for 10 ns;
        assert(OverFlowSignal='1') ;
        report "Test Passed 8: passed";

        wait;
        end process;

end Architecture;