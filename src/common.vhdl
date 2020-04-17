library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.address_pkg.all;

package common is
    -- operations of fpu
    constant FPU_OP_ADD         : std_logic_vector(1 downto 0)  := "00";
    constant FPU_OP_SUB         : std_logic_vector(1 downto 0)  := "01";
    constant FPU_OP_MUL         : std_logic_vector(1 downto 0)  := "10";
    constant FPU_OP_DIV         : std_logic_vector(1 downto 0)  := "11";

    -- modes of fpu
    constant FPU_MODE_FXD       : std_logic_vector(1 downto 0)  := "00";
    constant FPU_MODE_F64       : std_logic_vector(1 downto 0)  := "01";
    constant FPU_MODE_F32       : std_logic_vector(1 downto 0)  := "10";

    -- major states
    constant STATE_LOAD         : std_logic_vector(1 downto 0)  := "00";
    constant STATE_WAIT         : std_logic_vector(1 downto 0)  := "01";
    constant STATE_PROC         : std_logic_vector(1 downto 0)  := "10";
    constant STATE_OUT          : std_logic_vector(1 downto 0)  := "11";

    -- operations constants
    constant FIXED_SCALE_FACTOR : integer                       := 7;

    -- memory mapping address ranges
    --- MM_*_0 is the beginning of a range (inclusive)
    --- MM_*_1 is the end of a range (inclusive)
    constant MM_HDR_0           : std_logic_vector(15 downto 0) := X"0000";
    constant MM_HDR_1           : std_logic_vector(15 downto 0) := other_adr(MM_HDR_0, 1);

    constant MM_H_0             : std_logic_vector(15 downto 0) := X"0001";
    constant MM_H_1             : std_logic_vector(15 downto 0) := other_adr(MM_H_0, 2);

    constant MM_ERR_0           : std_logic_vector(15 downto 0) := X"0003";
    constant MM_ERR_1           : std_logic_vector(15 downto 0) := other_adr(MM_ERR_0, 2);

    constant MM_A_0             : std_logic_vector(15 downto 0) := X"0005";
    constant MM_A_1             : std_logic_vector(15 downto 0) := other_adr(MM_A_0, 5000);

    constant MM_B_0             : std_logic_vector(15 downto 0) := X"138D";
    constant MM_B_1             : std_logic_vector(15 downto 0) := other_adr(MM_B_0, 5000);

    constant MM_X_0             : std_logic_vector(15 downto 0) := X"2715";
    constant MM_X_1             : std_logic_vector(15 downto 0) := other_adr(MM_X_0, 100);

    constant MM_X_OUT_0         : std_logic_vector(15 downto 0) := X"2779";
    constant MM_X_OUT_1         : std_logic_vector(15 downto 0) := other_adr(MM_X_OUT_0, 500);

    constant MM_U0_0            : std_logic_vector(15 downto 0) := X"296D";
    constant MM_U0_1            : std_logic_vector(15 downto 0) := other_adr(MM_U0_0, 100);

    constant MM_T_0             : std_logic_vector(15 downto 0) := X"29D1";
    constant MM_T_1             : std_logic_vector(15 downto 0) := other_adr(MM_T_0, 10);

    constant MM_U_S_0           : std_logic_vector(15 downto 0) := X"29D8";
    constant MM_U_S_1           : std_logic_vector(15 downto 0) := other_adr(MM_U_S_0, 500);

    constant MM_U_INT_0         : std_logic_vector(15 downto 0) := X"2BCF";
    constant MM_U_INT_1         : std_logic_vector(15 downto 0) := other_adr(MM_U_INT_0, 100);

    constant MM_H_NEW_0         : std_logic_vector(15 downto 0) := X"2C33";
    constant MM_H_NEW_1         : std_logic_vector(15 downto 0) := other_adr(MM_H_NEW_0, 2);

    function to_vec(i : integer; size : integer                 := 16) return std_logic_vector;
    function to_vec(i : std_logic; size : integer               := 16) return std_logic_vector;
    function to_vec(i : std_logic_vector; size : integer        := 16) return std_logic_vector;
    function to_vec(i : unsigned; size : integer                := 16) return std_logic_vector;

    function to_int(i           : std_logic_vector) return integer;
    function to_int(i           : unsigned) return integer;

    function to_str(a           : std_logic_vector) return string;
    function to_str(a           : unsigned) return string;
    function to_str(a           : integer) return string;
end package;

package body common is
    function to_vec(i : integer; size : integer := 16) return std_logic_vector is
        variable tmp : unsigned(size - 1 downto 0);
    begin
        if i < 0 then
            tmp := to_unsigned(-i, size);
            tmp := not tmp;
            tmp := tmp + 1;
        else
            tmp := to_unsigned(i, size);
        end if;

        return std_logic_vector(tmp);
    end function;

    function to_vec(i : std_logic; size : integer := 16) return std_logic_vector is
        variable v : std_logic_vector(size - 1 downto 0);
    begin
        v := (others => i);
        return v;
    end function;

    function to_vec(i : std_logic_vector; size : integer := 16) return std_logic_vector is
        variable v : std_logic_vector(size - 1 downto 0)     := i;
    begin
        return v;
    end function;

    function to_vec(i : unsigned; size : integer := 16) return std_logic_vector is
    begin
        return std_logic_vector(i);
    end function;

    function to_str(a : std_logic_vector) return string is
        variable b        : string (1 to a'length) := (others => NUL);
        variable stri     : integer                := 1;
    begin
        for i in a'range loop
            b(stri) := std_logic'image(a((i)))(2);
            stri    := stri + 1;
        end loop;

        return b;
    end function;

    function to_str(a : unsigned) return string is
    begin
        return to_str(std_logic_vector(a));
    end function;

    function to_str(a : integer) return string is
    begin
        return integer'image(a);
    end function;

    function to_int(i : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(i));
    end function;

    function to_int(i : unsigned) return integer is
    begin
        return to_integer(i);
    end function;
end package body;