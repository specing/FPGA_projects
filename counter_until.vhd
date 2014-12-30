library IEEE;
use		IEEE.std_logic_1164.	all;
use		IEEE.std_logic_ARITH.	all;
use		IEEE.std_logic_UNSIGNED.all;



entity counter_until is
	Generic
	(
		width				: integer := 10
	);
	Port
	(
		clock_i				: in	std_logic;
		reset_i				: in	std_logic;
		count_enable_i		: in	std_logic;
		reset_when_i		: in	std_logic_vector (width - 1 downto 0);
		count_o				: out	std_logic_vector (width - 1 downto 0);
		overflow_o			: out	std_logic
	);
end counter_until;



architecture Behavioral of counter_until is

	COMPONENT comparator
	GENERIC(
		width				: integer := width
	);
	PORT(
		a_i					: in	std_logic_vector(width - 1 downto 0);
		b_i					: in	std_logic_vector(width - 1 downto 0);
		eq_o				: out	std_logic
	);
	END COMPONENT;



	signal count			: std_logic_vector(width - 1 downto 0);
	signal reset			: std_logic;
	signal count_reset		: std_logic;

begin
	reset			<= reset_i or count_reset;

	count_o			<= count;
	overflow_o		<= count_reset;


	process(clock_i)
	begin
		if clock_i'event and clock_i = '1' then
			if reset = '1' then
				count <= (others => '0');
			else
				if count_enable_i = '1' then
					count <= count + '1';
				end if;
			end if ;
		end if ;
	end process;


	Inst_comparator: comparator
	GENERIC MAP ( width => width )
	PORT MAP
	(
		a_i		=> count,
		b_i		=> reset_when_i,
		eq_o	=> count_reset
	);

end Behavioral;
