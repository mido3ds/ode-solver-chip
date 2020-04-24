library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpu_divider is
	port (
		mode  : in std_logic_vector(1 downto 0);
		clk   : in std_logic;
		rst   : in std_logic;
		enbl  : in std_logic;
		in_a  : in std_logic_vector(63 downto 0);
		in_b  : in std_logic_vector(63 downto 0);

		out_c : out std_logic_vector(63 downto 0);
		done  : out std_logic;
		err   : out std_logic;
		zero  : out std_logic;
		posv  : out std_logic
	);
end entity;

-- Divider implementation with operators
architecture with_operators of fpu_divider is
	constant scale_factor : integer := 7;  -- fixed scale factor
	constant size         : integer := 16; -- operands' size
	signal Q              : std_logic_vector(size - 1 downto 0);
	signal F              : std_logic_vector(scale_factor - 1 downto 0);
begin
	process (in_a, in_b, clk)
		variable zero_flag, posv_flag, ovfl_flag, divide_by_zero_error, ready : std_logic;
		variable quotient                                                     : std_logic_vector(size + scale_factor - 1 downto 0);
		variable a, b, out64                                                  : std_logic_vector(4 * size - 1 downto 0);
		variable out_neg                                                      : std_logic_vector(4 * size - 1 downto 0);
	begin
		a         := std_logic_vector(abs(signed(in_a)) sll scale_factor);
		b         := std_logic_vector(abs(signed(in_b)));
		quotient  := (others => '0');
		out64     := (others => '0');
		zero_flag := '0';
		posv_flag := '0';
		ovfl_flag := '0';
		ready     := '0';

		if (rst = '1') then -- reset signal
			divide_by_zero_error := '0';
		elsif (enbl = '1' and rising_edge(clk)) then -- enabled 

			-- divide by zero flag 
			if (unsigned(in_b) = 0) then
				divide_by_zero_error := '1';
			else
				quotient := std_logic_vector(unsigned(a(size + scale_factor - 1 downto 0)) / unsigned(b(size + scale_factor - 1 downto 0)));
			end if;
			-- Overflow check
			if (quotient(22) = '1' or quotient(21) = '1' or quotient(20) = '1' or quotient(19) = '1'
				or quotient(18) = '1' or quotient(17) = '1' or quotient(16) = '1') then
				ovfl_flag := '1';
			end if;
			out64(size - 1 downto 0) := quotient(size - 1 downto 0);
			-- Sign check
			if (in_a(size - 1) = '1' xor in_b(size - 1) = '1') then
				out_neg := std_logic_vector(unsigned(not out64) + 1);
				out64   := out_neg;
			end if;
			-- zero flag 
			if (unsigned(out64(size + scale_factor - 1 downto scale_factor)) = 0 and divide_by_zero_error = '0') then
				zero_flag := '1';
			end if;

			-- positive flag
			posv_flag := not out64(size - 1) and not zero_flag and not divide_by_zero_error;
			ready     := '1';
		end if;
		err   <= divide_by_zero_error or ovfl_flag;
		zero  <= zero_flag;
		posv  <= posv_flag;
		done  <= ready;
		out_c <= out64;
	end process;
end architecture;

architecture first_algo of fpu_divider is
	constant scale_factor : integer := 7;  -- fixed scale factor
	constant size         : integer := 16; -- operands' size

	-- FSM states
	type state_type is (idle, shift, op);

	signal state, state_next                                         : state_type;
	signal z, z_next, quotient, a, b                                 : std_logic_vector(4 * size - 1 downto 0);
	signal out64, out_neg, test                                      : std_logic_vector(4 * size - 1 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
	signal i, i_next                                                 : integer;
	signal zero_flag, posv_flag, ovfl_flag, div_by_zero, ready, temp : std_logic := '0';

	-- The subtraction
	signal operation, enbl_add                                       : std_logic := '1';
	signal sub                                                       : std_logic_vector(4 * size - 1 downto 0);

	component fpu_adder is
		port (
			mode    : in std_logic_vector(1 downto 0);
			clk     : in std_logic;
			rst     : in std_logic;
			enbl    : in std_logic;
			add_sub : in std_logic; -- add = 0, sub = 1
			in_a    : in std_logic_vector(63 downto 0);
			in_b    : in std_logic_vector(63 downto 0);

			out_c   : out std_logic_vector(63 downto 0);
			done    : out std_logic;
			err     : out std_logic;
			zero    : out std_logic;
			posv    : out std_logic
		);
	end component;

begin
	a <= std_logic_vector(abs(signed(in_a)) sll scale_factor);
	b <= std_logic_vector(abs(signed(in_b)));
	process (clk, rst)
	begin
		if (rst = '1') then
			state <= idle;
		elsif (clk'event) then
			state <= state_next;
		end if;
	end process;

	--FSM next state calculation
	process (state, enbl, i_next)
	begin
		case state is
			when idle =>
				if (enbl = '1') then
					state_next <= shift;
				else
					state_next <= idle;
				end if;

			when shift =>
				state_next <= op;

			when op =>
				if (i_next = 23) then
					state_next <= idle;
				else
					state_next <= shift;
				end if;

		end case;
	end process;

	--counter
	process (clk, rst)
	begin
		if (rst = '1') then
			i <= 0;
		elsif (clk'event) then
			i <= i_next;
		end if;
	end process;

	process (state, i)
	begin
		case state is
			when idle =>
				i_next <= 0;
			when shift =>
				i_next <= i;
			when op =>
				i_next <= i + 1;
		end case;
	end process;
	process (clk, rst)
	begin
		if (rst = '1') then
			z <= (others => '0');
		elsif (clk'event) then
			z <= z_next;
		end if;
	end process;

	process (state, a, b, z, sub)
	begin

		case state is
			when idle =>
				z_next   <= z(4 * size - 2 downto 0) & a(size + scale_factor - 1);
				quotient <= (others => '0');
			when shift          =>
				z_next <= z(4 * size - 2 downto 0) & a(size + scale_factor - i - 1);
			when op =>
				if (z < b) then
					z_next                                <= z;
					quotient(size + scale_factor - i - 1) <= '0';
				else
					z_next                                <= sub;
					quotient(size + scale_factor - i - 1) <= '1';
				end if;
		end case;
	end process;

	subtractor : entity work.fpu_adder (sec_algo) port map(mode => mode, clk => clk, rst => rst, enbl => enbl_add, add_sub => operation, in_a => z, in_b => b, out_c => sub);
	out_neg <= std_logic_vector(unsigned (not (quotient)) + 1);

	--output and control signals
	out64   <= out_neg when ((i_next = 23) and (in_a(size - 1) = '1' xor in_b(size - 1) = '1')) else
		quotient when (i_next = 23) else
		"0000000000000000000000000000000000000000000000000000000000000000";
	out_c       <= out64;

	div_by_zero <= '1' when (in_b = "0000000000000000000000000000000000000000000000000000000000000000") else '0';
	ovfl_flag   <= '1' when ((i_next = 23) and (quotient(22) = '1' or quotient(21) = '1' or quotient(20) = '1' or quotient(19) = '1'
		or quotient(18) = '1' or quotient(17) = '1' or quotient(16) = '1')) else '0';
	zero <= '1' when (i_next = 23 and unsigned(out64) = 0) else '0';
	posv <= '1' when (i_next = 23 and out64(size - 1) = '0' and unsigned(out64) /= 0) else '0';
	done <= '1' when (i_next = 23) else '0';
	err  <= div_by_zero or ovfl_flag;
end architecture;