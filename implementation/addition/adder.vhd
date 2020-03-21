library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_signed.all;
entity Adder is 
port(
    A,B:in std_logic_vector(15 downto 0);
    F:out std_logic_vector(15 downto 0);
    OverFlowFlag:out std_logic);
end entity;
architecture Arch of Adder is
signal F_Signal:std_logic_vector(15 downto 0);
begin
F_Signal<= std_logic_vector(signed(A) + signed(B));
OverFlowFlag<=((not(A(15)) and not(B(15)) and F_Signal(15))or((A(15)) and (B(15)) and not(F_Signal(15))));
F<=F_Signal;
end architecture Arch;

