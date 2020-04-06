library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
    generic (WORD_LENGTH, NUM_WORDS: integer);

    port (
        clk, rd, wr: in std_logic;
        address, data_in: in std_logic_vector(15 downto 0);

        data_out: out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of ram is
    type DataType is array(0 to NUM_WORDS-1) of std_logic_vector(WORD_LENGTH-1 downto 0);
    signal data: DataType;

    -- for debugging, as ghdl doenst dump `DataType` signals
    signal dbg_data_in, dbg_data_out: std_logic_vector(WORD_LENGTH-1 downto 0);
begin
    process (clk, data_in, rd, address)
    begin
        if clk = '1' and rd = '1' then  
            data_out <= data(to_integer(unsigned(address)));
            dbg_data_out <= data(to_integer(unsigned(address)));
        else 
            data_out <= (others => 'Z');
        end if;
    end process;

    process (clk, data_in, wr, address)
    begin   
        if clk = '1' and wr = '1' then  
            data(to_integer(unsigned(address))) <= data_in;
            dbg_data_in <= data_in;
        end if;
    end process;
end architecture;
