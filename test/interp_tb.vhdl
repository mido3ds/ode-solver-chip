library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity interp_tb is
end entity;

architecture arch of interp_tb is
component interp is
    generic (
        WORD_LENGTH : integer := 32;
        ADDR_LENGTH : integer := 16;
        MAX_LENGTH  : integer := 64
    );

    port (
        in_state       : in std_logic_vector(1 downto 0); --state signal sent from CPU
        clk            : in std_logic;
        rst            : in std_logic;
        adr            : in std_logic_vector(ADDR_LENGTH - 1 downto 0);
        in_data        : inout std_logic_vector(WORD_LENGTH - 1 downto 0);
        interp_done_op : out std_logic_vector(1 downto 0);
        interrupt      : out std_logic;
        error_success  : out std_logic
    );
end component;

signal in_state , interp_done_op : std_logic_vector(1 downto 0);
signal clk : std_logic := '1';
signal rst , interrupt , error_success : std_logic;
signal adr : std_logic_vector(15 downto 0);
signal in_data : std_logic_vector(31 downto 0);
constant CLKPERIOD : time := 100 ps;

signal timeout : std_Logic;

type list is array(0 to 4) of std_logic_vector(63 downto 0);
signal Uout : list := (others => (others => 'Z'));
begin
	interp1 : interp port map( in_state       => in_state,
										clk            => clk,
										rst            => rst,
										adr            => adr,
										in_data        => in_data,
										interp_done_op => interp_done_op,
										interrupt      => interrupt,
										error_success  => error_success);
			
	process
    begin
        clk <= not clk;
        wait for CLKPERIOD/2;
    end process;
	
	process
	begin 
		timeout <= '0';
		wait for CLKPERIOD*500;
	end process;
	process
	Variable current_adr : std_logic_vector(15 downto 0);
	begin
		rst <= '0';
		in_state <= "00";
		
		-- load header
		adr <= x"0000";
		in_data <= "00010100010100010100000000000000";	-- n=5 , m=5 , fixed_step , fixed_point , 5 time steps
		wait for CLKPERIOD;
		-- load Hstep
		adr <= x"0001";
		in_data <= x"00000040";
		wait for CLKPERIOD;
		adr <= x"0002";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		-- load U0
		current_adr := x"296D";
		U0 : for i in 0 to 4 loop 
			adr <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1; 
			adr <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
		end loop U0;
		
		-- load Ts
		
		--T1 
		adr <= x"29D1";
		in_data <= x"00000080";		-- 1
		wait for CLKPERIOD;
		adr <= x"29D2";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		--T2
		adr <= x"29D3";
		in_data <= x"00000180";		-- 3
		wait for CLKPERIOD;
		adr <= x"29D4";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		--T3
		adr <= x"29D5";
		in_data <= x"00000280";		-- 5
		wait for CLKPERIOD;
		adr <= x"29D6";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		--T4
		adr <= x"29D7";
		in_data <= x"00000380";		-- 7
		wait for CLKPERIOD;
		adr <= x"29D8";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		--T5
		adr <= x"29D9";
		in_data <= x"00000480";		-- 9
		wait for CLKPERIOD;
		adr <= x"29DA";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- load Us
		current_adr := x"29DB";
		U14: for j in 0 to 1 loop
			U11 : for i in 0 to 2 loop 
				adr <= current_adr;
				in_data <= x"00000000";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
				adr <= current_adr;
				in_data <= x"00000000";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
			end loop U11;
			U12 : for i in 0 to 1 loop 
				adr <= current_adr;
				in_data <= x"00000780";			-- 15
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
				adr <= current_adr;
				in_data <= x"00000000";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
			end loop U12;
			
			U21 : for i in 0 to 2 loop 
				adr <= current_adr;
				in_data <= x"00007F80";			-- 127
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
				adr <= current_adr;
				in_data <= x"00000000";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
			end loop U21;
			U22 : for i in 0 to 1 loop 
				adr <= current_adr;
				in_data <= x"00000000";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
				adr <= current_adr;
				in_data <= x"00000000";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
			end loop U22;
		end loop U14;
		U51 : for i in 0 to 2 loop 
				adr <= current_adr;
				in_data <= x"FFFA2400";			-- -3000
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
				adr <= current_adr;
				in_data <= x"FFFFFFFF";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
		end loop U51;
		U52 : for i in 0 to 1 loop 
				adr <= current_adr;
				in_data <= x"FFFE7000";			-- -800
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
				adr <= current_adr;
				in_data <= x"FFFFFFFF";
				wait for CLKPERIOD;
				current_adr := current_adr + 1;
		end loop U52;
		
		
		-- summary 
		-- at T = 1 -> Us are 3 equal values of 0 then 2 equal values of 15
		-- at T = 3 -> Us are 3 equal values of 127 then 2 equal values of 0
		-- at T = 5 -> Us are 3 equal values of 0 then 2 equal values of 15
		-- at T = 7 -> Us are 3 equal values of 127 then 2 equal values of 0
		-- at T = 9 -> Us are 3 equal values of -3000 then 2 equal numbers of -800 
		
		-- start cases 
		
		-- test with intermediate time step 2
		adr <= x"2C33";
		in_data <= x"00000100";
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV;
		ANS11 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000001FC0" and interp_done_op = "01" and interrupt = '0') report "wrong output in test 1" severity error;
		end loop ANS11;
		ANS12 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000003C0" and interp_done_op = "01" and interrupt = '0') report "wrong output in test 1" severity error;
		end loop ANS12;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		
		-- test with intermediate time step 2.5
		adr <= x"2C33";
		in_data <= x"00000140";		-- 2.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV2 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV2;
		ANS21 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 2" severity error;
		end loop ANS21;
		ANS22 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 2" severity error;
		end loop ANS22;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		
		-- test with intermediate time step 5
		adr <= x"2C33";
		in_data <= x"00000280";		-- 5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV3 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV3;
		ANS31 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000000000" and interp_done_op = "01" and interrupt = '0') report "wrong output in test 3" severity error;
		end loop ANS31;
		ANS32 : for i in 3 to 4 loop
			assert(Uout(i) = x"0000000000000780" and interp_done_op = "01" and interrupt = '0') report "wrong output in test 3" severity error;
		end loop ANS32;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		-- test with intermediate time step 2.5
		adr <= x"2C33";
		in_data <= x"00000140";		-- 2.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV4 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV4;
		ANS41 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 4" severity error;
		end loop ANS41;
		ANS42 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 4" severity error;
		end loop ANS42;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		-- test with intermediate time step 0.5
		adr <= x"2C33";
		in_data <= x"00000040";		-- 0.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV5 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV5;
		ANS51 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000000000" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 5" severity error;
		end loop ANS51;
		ANS52 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000003C0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 5" severity error;
		end loop ANS52;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		-- test with intermediate time step 4.5
		adr <= x"2C33";
		in_data <= x"00000240";		-- 4.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV6 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV6;
		ANS61 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000000FE0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 6" severity error;
		end loop ANS61;
		ANS62 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000005A0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 6" severity error;
		end loop ANS62;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		-- test with intermediate time step 6.5
		adr <= x"2C33";
		in_data <= x"00000340";		-- 6.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV7 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV7;
		ANS71 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 7" severity error;
		end loop ANS71;
		ANS72 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 7" severity error;
		end loop ANS72;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		-- test with intermediate time step 0.5
		adr <= x"2C33";
		in_data <= x"00000440";		-- 8.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV8 : for i in 0 to 5 loop
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			wait for CLKPERIOD;
			Uout(i)(31 downto 0)  <= in_data;
			current_adr := current_adr + 1;
		end loop RECV8;
		ANS81 : for i in 0 to 2 loop
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "11" and interrupt = '0') report "wrong output in test 8" severity error;
		end loop ANS81;
		ANS82 : for i in 3 to 4 loop
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "11" and interrupt = '0') report "wrong output in test 8" severity error;
		end loop ANS82;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		-- test with intermediate time step 11
		adr <= x"2C33";
		in_data <= x"00000580";		-- 8.5
		wait for CLKPERIOD;
		adr <= x"2C34";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		
		-- data has been inserted. just wait until it computes the answer
		current_adr := x"29DB";
		in_state <= "10";
		wait on timeout until timeout = '1';
		--------------------------------------------------------------------------wait--------------------------------------------------------
		assert(interrupt = '1' and error_success = '0') report "error with invalid address in test 9" severity error;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		
		
		--test rst
		rst <= '1';
		wait for CLKPERIOD;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
	end process;
end arch;