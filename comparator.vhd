library IEEE;
use		IEEE.std_logic_1164.all;



entity comparator is
	generic
	(
		width			: integer := 9
	);
	Port
	(
		a_i				: in	std_logic_vector (width - 1 downto 0);
		b_i				: in	std_logic_vector (width - 1 downto 0);
		eq_o			: out	std_logic
	);
end comparator;



architecture Behavioral of comparator is

begin

	process (a_i, b_i)
	begin
		if a_i = b_i then
			eq_o <= '1';
		else
			eq_o <= '0';
		end if;
	end process;

end Behavioral;
