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
        -- wr: write to ram through data_in
        -- rd: read from ram to data_out
        clk, rd, wr : in std_logic;
        -- rst: async 0 parallel load to all latches
        rst         : in std_logic;
        data_in     : in std_logic_vector(WORD_LENGTH - 1 downto 0);
        address     : in std_logic_vector(ADR_LENGTH - 1 downto 0);
        data_out    : out std_logic_vector(WORD_LENGTH - 1 downto 0)
    );
end entity;

-- both wr and rd are in falling edge
architecture rtl of ram is
    type DataType is array(0 to NUM_WORDS - 1) of std_logic_vector(data_in'range);
    signal data : DataType;
begin
    process (clk, rd, wr, address, data_in, rst)
    begin
        if rst = '1' then
            for i in data'range loop
                data(i) <= to_vec(0, data(i)'length);
            end loop;
        elsif falling_edge(clk) then
            if rd = '1' then
                data_out <= data(to_int(address));
            end if;

            if wr = '1' then
                data(to_int(address)) <= data_in;
            end if;
        end if;
    end process;
end architecture;