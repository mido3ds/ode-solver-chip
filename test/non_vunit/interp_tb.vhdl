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

	signal in_state, interp_done_op      : std_logic_vector(1 downto 0);
	signal clk                           : std_logic := '1';
	signal rst, interrupt, error_success : std_logic;
	signal adr                           : std_logic_vector(15 downto 0);
	signal in_data                       : std_logic_vector(31 downto 0);
	constant CLKPERIOD                   : time := 100 ps;

	type list is array(0 to 4) of std_logic_vector(63 downto 0);
	signal Uout : list := (others => (others => 'Z'));
begin
	interp1 : interp port map(
		in_state       => in_state,
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
		variable current_adr : std_logic_vector(15 downto 0);
	begin
		rst <= '1';
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait for CLKPERIOD*2;
		
		
		rst      <= '0';
		in_state <= "00";

		-- load header	(sure)
		adr      <= x"0000";
		in_data  <= "00010100010100010100000000000000"; -- n=5 , m=5 , fixed_step , fixed_point , 5 time steps
		wait for CLKPERIOD;
		
		-- load Hstep	(sure)
		adr     <= x"0001";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		adr     <= x"0002";
		in_data <= x"00000040";	-- 0.5
		wait for CLKPERIOD;
		-- load U0		(sure)
		current_adr := x"296D";
		U0 : for i in 0 to 4 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
		end loop U0;

		-- load Ts		(sure)

		--T1 
		adr     <= x"29D1";
		in_data <= x"00000000"; 
		wait for CLKPERIOD;
		adr     <= x"29D2";
		in_data <= x"00000080";	-- 1
		wait for CLKPERIOD;

		--T2
		adr     <= x"29D3";
		in_data <= x"00000000"; 
		wait for CLKPERIOD;
		adr     <= x"29D4";
		in_data <= x"00000180";	-- 3
		wait for CLKPERIOD;

		--T3
		adr     <= x"29D5";
		in_data <= x"00000000";
		wait for CLKPERIOD;
		adr     <= x"29D6";
		in_data <= x"00000280";	-- 5
		wait for CLKPERIOD;

		--T4
		adr     <= x"29D7";
		in_data <= x"00000000"; 
		wait for CLKPERIOD;
		adr     <= x"29D8";
		in_data <= x"00000380";	-- 7
		wait for CLKPERIOD;

		--T5
		adr     <= x"29D9";
		in_data <= x"00000000"; 
		wait for CLKPERIOD;
		adr     <= x"29DA";
		in_data <= x"00000480";	-- 9
		wait for CLKPERIOD;

		-- load Us
		current_adr := x"29DB";
		U11 : for i in 0 to 2 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U11;
		U12 : for i in 0 to 1 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000780"; -- 15
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U12;
		
		current_adr := x"2A3F";
		U21 : for i in 0 to 2 loop
			adr     <= current_adr;
			in_data <= x"00000000"; 
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00003F80";	-- 127
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U21;
		U22 : for i in 0 to 1 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U22;
		
		current_adr := x"2AA3";
		U31 : for i in 0 to 2 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U31;
		U32 : for i in 0 to 1 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000780"; -- 15
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U32;
	
		current_adr := x"2B07";
		U41 : for i in 0 to 2 loop
			adr     <= current_adr;
			in_data <= x"00000000"; 
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00003F80";	-- 127
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U41;
		U42 : for i in 0 to 1 loop
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"00000000";
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U42;
		
		current_adr := x"2B6B";
		U51 : for i in 0 to 2 loop
			adr     <= current_adr;
			in_data <= x"FFFFFFFF"; 
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"FFFA2400";	-- -3000
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
		end loop U51;
		U52 : for i in 0 to 1 loop
			adr     <= current_adr;
			in_data <= x"FFFFFFFF"; 
			wait for CLKPERIOD;
			current_adr := current_adr + 1;
			adr     <= current_adr;
			in_data <= x"FFFE7000";	-- -800
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
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000100";	-- 2
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS11 : for i in 0 to 2 loop	-- 63.5
			assert(Uout(i) = x"0000000000001FC0" and interp_done_op = "01" and interrupt = '0') report "wrong output in test 1" severity error;
		end loop ANS11;
		ANS12 : for i in 3 to 4 loop	-- 7.5
			assert(Uout(i) = x"00000000000003C0" and interp_done_op = "01" and interrupt = '0') report "wrong output in test 1" severity error;
		end loop ANS12;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;


		-- test with intermediate time step 2.5
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000140";	-- 2.5
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV2 : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV2;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS21 : for i in 0 to 2 loop	-- 95.25
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 2" severity error;
		end loop ANS21;
		ANS22 : for i in 3 to 4 loop	-- 3.75
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 2" severity error;
		end loop ANS22;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;

		-- test with intermediate time step 2.5
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000140";	-- 2.5
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV4 : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV4;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS41 : for i in 0 to 2 loop	-- 95.25
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 3" severity error;
		end loop ANS41;
		ANS42 : for i in 3 to 4 loop	-- 3.75
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 3" severity error;
		end loop ANS42;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;

		-- test with intermediate time step 0.5
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000040";	-- 0.5
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV5 : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV5;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS51 : for i in 0 to 2 loop	-- 0
			assert(Uout(i) = x"0000000000000000" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 4" severity error;
		end loop ANS51;
		ANS52 : for i in 3 to 4 loop	-- 7.5
			assert(Uout(i) = x"00000000000003C0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 4" severity error;
		end loop ANS52;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;

		-- test with intermediate time step 4.5
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000240";	-- 4.5
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV6 : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV6;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS61 : for i in 0 to 2 loop	-- 31.75
			assert(Uout(i) = x"0000000000000FE0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 5" severity error;
		end loop ANS61;
		ANS62 : for i in 3 to 4 loop	-- 11.25
			assert(Uout(i) = x"00000000000005A0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 5" severity error;
		end loop ANS62;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;

		-- test with intermediate time step 6.5
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000340";	-- 6.5
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV7 : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV7;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS71 : for i in 0 to 2 loop	-- 95.25
			assert(Uout(i) = x"0000000000002FA0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 6" severity error;
		end loop ANS71;
		ANS72 : for i in 3 to 4 loop	-- 3.75
			assert(Uout(i) = x"00000000000001E0" and interp_done_op = "10" and interrupt = '0') report "wrong output in test 6" severity error;
		end loop ANS72;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;

		-- test with intermediate time step 8.5
		current_adr := x"29DB";
		in_state <= "10";
		adr     <= x"2C33";
		in_data <= x"00000000";	
		wait for CLKPERIOD;
		adr     <= x"2C34";
		in_data <= x"00000440";	-- 8.5
		wait for CLKPERIOD;
		-- data has been inserted. just wait until it computes the answer
		adr <= (others => 'Z');
		in_data <= (others => 'Z');
		wait until (interp_done_op = "01" or interp_done_op = "10" or interp_done_op = "11");
		wait for CLKPERIOD;
		--------------------------------------------------------------------------wait--------------------------------------------------------
		RECV8 : for i in 0 to 4 loop
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(63 downto 32) <= in_data;
			current_adr := current_adr + 1;
			adr <= current_adr;
			in_data <= (others => 'Z');
			wait for CLKPERIOD;
			Uout(i)(31 downto 0) <= in_data;
			current_adr := current_adr + 1;
		end loop RECV8;
		
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;
		
		ANS81 : for i in 0 to 2 loop	-- -2218.25
			assert(Uout(i) = x"FFFFFFFFFFFBAB20" and interp_done_op = "11" and interrupt = '0') report "wrong output in test 7" severity error;
		end loop ANS81;
		ANS82 : for i in 3 to 4 loop	-- -600
			assert(Uout(i) = x"FFFFFFFFFFFED400" and interp_done_op = "11" and interrupt = '0') report "wrong output in test 7" severity error;
		end loop ANS82;
		-----------------------------------------------------------------check and assert here-------------------------------------------------
		in_data <= (others => 'Z');
		adr <= (others => 'Z');
		wait for CLKPERIOD;

		wait;
	end process;
end arch;