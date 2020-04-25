library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package address_pkg is
    function other_adr(a : std_logic_vector; size : integer) return std_logic_vector;
end package;

package body address_pkg is
    function other_adr(a : std_logic_vector; size : integer) return std_logic_vector is
    begin
        return std_logic_vector(unsigned(a) + size - 1);
    end function;
end package body;