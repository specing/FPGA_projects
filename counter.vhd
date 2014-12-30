library	IEEE;
use		IEEE. std_logic_1164	. all;
use		IEEE. std_logic_ARITH	. all;
use		IEEE. std_logic_UNSIGNED. all;



entity counter is
	generic
	(
		width			: integer := 8
	);
	Port
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;
		count_enable_i	: in	std_logic;
		count_o			: out	std_logic_vector(width - 1 downto 0)
	);
end counter;



architecture Behavioral of counter is

	signal count		: std_logic_vector(width - 1 downto 0);

begin

	count_o				<= count;

	process (clock_i)
	begin
		if clock_i'event and clock_i = '1' then
			if reset_i = '1' then
				count <= (others => '0');
			else
				if count_enable_i = '1' then
					count <= count + '1';
				end if;
			end if ;
		end if ;
	end process;

end Behavioral;
