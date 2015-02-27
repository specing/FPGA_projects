library	ieee;
use		ieee.std_logic_1164.all;



entity generic_register is
	generic
	(
		reset_value		: std_logic_vector := (others => '0')
	);
	port
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;
		clock_enable_i	: in	std_logic;
		data_i			: in	std_logic_vector;
		data_o			: out	std_logic_vector
	);
end generic_register;



architecture Behavioral of generic_register is

begin

	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				data_o <= reset_value;
			elsif clock_enable_i = '1' then
				data_o <= data_i;
			end if;
		end if;
	end process;

end Behavioral;
