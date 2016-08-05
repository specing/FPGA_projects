library IEEE;
use		IEEE.std_logic_1164.all;



entity flip_flop_d is
	Generic
	(
		reset_value		: std_logic := '0'
	);
	Port
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;
		d_i				: in	std_logic;
		q_o				: out	std_logic
	);
end flip_flop_d;



architecture Behavioral of flip_flop_d is

begin

	process (clock_i)
	begin
		if clock_i'event and clock_i = '1' then
			if reset_i = '1' then
				q_o <= reset_value;
			else
				q_o	<= d_i;
			end if;
		end if;
	end process;

end Behavioral;
