library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fpu_adder is
    port (
        mode: in std_logic_vector(1 downto 0);
        clk: in std_logic;
        rst: in std_logic;
        enbl: in std_logic;
        add_sub: in std_logic; -- add = 0, sub = 1
        in_a: in std_logic_vector(15 downto 0);
        in_b: in std_logic_vector(15 downto 0);

        out_c: out std_logic_vector(15 downto 0);
        done: out std_logic;
        err: out std_logic;
        zero: out std_logic;
        posv: out std_logic
    );
end entity; 

-- Adder implementation with operators
-- Used by other components temporarily until other algos architectures are done
architecture with_operators of fpu_adder is
    signal in_b_signal  : std_logic_vector(15 downto 0);
    signal out_c_signal :  std_logic_vector(15 downto 0);
    signal zero_signal,error_signal :  std_logic;
    function CheckZero (F: in std_logic_vector)
        return std_logic is
        variable Zero : std_logic := '0';
        begin
        for i in 0 to 15 loop
            Zero := Zero or F(i);
        end loop;
        return Zero;
    end function CheckZero;
begin
-- TODO: copy phase-1 multiplier here and adjust the ports names to match this interface
    PROCESS(in_a,in_b,rst,enbl,out_c_signal,error_signal,zero_signal)
    begin
        if(rst = '1') then
            zero_signal <= '1';
            posv <= '0';                                                                                        -- reset signal
            error_signal <= '0';
            out_c_signal<=(others => '0');
        elsif(enbl = '1' and rst = '0') then
            if add_sub = '1' then
                in_b_signal<= std_logic_vector(unsigned(not(in_b)) + 1);
            else
                in_b_signal<=in_b;
            end if;
            out_c_signal<=std_logic_vector(signed(in_a)+signed(in_b_signal));
            zero_signal<= (not CheckZero(out_c_signal));
            posv<= (not out_c_signal(15))and (not zero_signal);
            error_signal<=((not(in_a(15)) and not(in_b_signal(15)) and out_c_signal(15))or((in_a(15)) and (in_b_signal(15)) and not(out_c_signal(15))));    
        end if;
        err<=error_signal;
        zero <= zero_signal;
        out_c<=out_c_signal;
        done<=enbl or rst;
    end PROCESS;
end architecture;

architecture first_algo of fpu_adder is --Carry look ahead adder
-- TODO: implement first algo
    COMPONENT cla_16_bit_adder is
        PORT
            (   
            in_a      :  IN   STD_LOGIC_VECTOR(15 DOWNTO 0);
            in_b      :  IN   STD_LOGIC_VECTOR(15 DOWNTO 0);
            carry_in  :  IN   STD_LOGIC;
            sum       :  OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
            carry_out :  OUT  STD_LOGIC
            );
    END COMPONENT;
    SIGNAL    in_a_signal  :    STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL    in_b_signal  :    STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL    sum_signal,out_c_signal  :    STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL    carry_signal  :    STD_LOGIC;
    signal zero_signal,error_signal :  std_logic;
    signal dummy : STD_LOGIC;
    signal input_carry : STD_LOGIC := '0';

    function CheckZero (F: in std_logic_vector)
    return std_logic is
    variable Zero : std_logic := '0';
    begin
    for i in 0 to 15 loop
        Zero := Zero or F(i);
    end loop;
    return Zero;
    end function CheckZero;

    BEGIN
    u1:cla_16_bit_adder port map (in_a=>in_a_signal,in_b=>in_b_signal,carry_in=>input_carry,sum=>sum_signal
    ,carry_out=>carry_signal);
    
    PROCESS(in_a,in_b,rst,enbl,sum_signal,out_c_signal,error_signal,zero_signal,in_b_signal)
    begin
        if(rst = '1') then																					-- reset signal
            error_signal <= '0';
            zero_signal <= '1';
            posv <= '0';
        elsif(enbl = '1'and rst= '0' ) then
            if add_sub = '1' then
                in_b_signal<= std_logic_vector(unsigned(not(in_b)) + 1);
            else
                in_b_signal<=in_b;
            end if;
            in_a_signal<=in_a;	
            out_c_signal<=sum_signal;
            zero_signal<=(not CheckZero(out_c_signal));
            error_signal<=((not(in_a(15)) and not(in_b_signal(15)) and out_c_signal(15))or((in_a(15)) and (in_b_signal(15)) and not(out_c_signal(15))));
            posv<= (not out_c_signal(15))and (not zero_signal);
        end if;
        zero<=zero_signal;
        err<=error_signal;
        out_c<=out_c_signal;
        done<=enbl or rst;
    end Process;
end architecture;

architecture sec_algo of fpu_adder is --Carry select
-- TODO: implement second algo
    component full_adder is
        Port
            (A : in STD_LOGIC;
            B : in STD_LOGIC;
            Cin : in STD_LOGIC;
            S : out STD_LOGIC;
            Cout : out STD_LOGIC);
    end component;
    
    component mux2_1
        port
            (A,B : in STD_LOGIC;
            Sel: in STD_LOGIC;
            Z: out STD_LOGIC);
    end component;
    
    signal A,B,C0,C1: STD_LOGIC_VECTOR( 15 DOWNTO 0);
    SIGNAL in_b_signal,sum_signal,out_c_signal  :    STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal zero_signal,error_signal :  std_logic;
    signal dummy : STD_LOGIC;

    function CheckZero (F: in std_logic_vector)
        return std_logic is
        variable Zero : std_logic := '0';
        begin
        for i in 0 to 15 loop
            Zero := Zero or F(i);
        end loop;
        return Zero;
    end function CheckZero;

    begin
        
        FA1: full_adder PORT MAP(in_a(0),in_b_signal(0),'0',A(0),C0(0));
        GEN_ADDER_CARRY_0: 
        for i in 1 to 15 generate
            ADDER_0 : full_adder port map (in_a(i),in_b_signal(i),C0(i-1),A(i),C0(i));
        end generate ;

        FA2: full_adder PORT MAP(in_a(0),in_b_signal(0),'1',B(0),C1(0));
        GEN_ADDER_CARRY_1: 
        for i in 1 to 15 generate
            ADDER_1 : full_adder port map (in_a(i),in_b_signal(i),C1(i-1),B(i),C1(i));
        end generate ;
    
        GEN_MUX: 
        for i in 0 to 15 generate
            MUX1: mux2_1 PORT MAP(A(i),B(i),'0',sum_signal(i));
        end generate ;
        MUX: mux2_1 PORT MAP(C0(15),C1(15),'0',dummy);

        PROCESS(in_a,in_b,rst,enbl,zero_signal,error_signal,sum_signal,in_b_signal,out_c_signal)
        begin
            if(rst = '1') then
                zero_signal <= '1';
                posv <= '0';																					-- reset signal
                error_signal <= '0';
                out_c<= (others=>'0');
            elsif(enbl = '1' and rst ='0' ) then
                if add_sub = '1' then
                    in_b_signal<= std_logic_vector(unsigned(not(in_b)) + 1);
                else
                    in_b_signal<=in_b;
                end if;
                out_c_signal<=sum_signal;	
                zero_signal<=(not CheckZero(out_c_signal));
                posv<= (not out_c_signal(15))and (not zero_signal);
                error_signal<=((not(in_a(15)) and not(in_b_signal(15)) and out_c_signal(15))or((in_a(15)) and (in_b_signal(15)) and not(out_c_signal(15))));
            end if;
            zero<=zero_signal;
            err<=error_signal;
            out_c<=out_c_signal;
            done<=enbl or rst;
    end Process;
end architecture;