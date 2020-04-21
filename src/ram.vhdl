library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity ram is
    --NUM_WORDS: maximum number (and no more) of words you want the ram to hold.
    --ADR_LENGTH: number of adress bits, ADR_LENGTH <= ceil(log2(NUM_WORDS)).
    --WORD_LENGTH: number of bits of data bus and the word stored in one address in ram.
    generic (NUM_WORDS, WORD_LENGTH, ADR_LENGTH : integer);

    port (
        clk, rd, wr : in std_logic;
        rst         : in std_logic;
        data_in     : in std_logic_vector(WORD_LENGTH - 1 downto 0);
        address     : in std_logic_vector(ADR_LENGTH - 1 downto 0);
        data_out    : out std_logic_vector(WORD_LENGTH - 1 downto 0)
    );
end entity;

architecture rtl of ram is
    type DataType is array(0 to NUM_WORDS - 1) of std_logic_vector(data_in'range);
    signal data                      : DataType;

    -- for debugging, as ghdl doenst dump `DataType` signals
    signal dbg_data_in, dbg_data_out : std_logic_vector(data_in'range);
begin
    process (clk, rd, address, data_in, rst)
    begin
        if rst = '1' then
            for i in data'range loop
                data(i) <= to_vec(0, data(i)'length);
            end loop;
        elsif clk = '1' and wr = '1' then
            data(to_integer(unsigned(address))) <= data_in;
            dbg_data_in                         <= data_in;
        elsif clk = '1' and rd = '1' then
            data_out     <= data(to_integer(unsigned(address)));
            dbg_data_out <= data(to_integer(unsigned(address)));
        end if;
    end process;
end architecture;