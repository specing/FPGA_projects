-- generates a clock_i period pulse when a button is pressed
library ieee;
use     ieee.std_logic_1164    .all;
use     ieee.std_logic_unsigned.all;



entity button_input is
	generic
	(
		num_of_buttons		: integer := 1
	);
	port
	(
		clock_i				: in	std_logic;
		reset_i				: in	std_logic;

		buttons_i			: in	std_logic_vector(num_of_buttons - 1 downto 0);
		buttons_ack_i		: in	std_logic_vector(num_of_buttons - 1 downto 0);
		buttons_o			: out	std_logic_vector(num_of_buttons - 1 downto 0)
	);
end button_input;



architecture Behavioral of button_input is

	signal buttons_sync		: std_logic_vector(num_of_buttons - 1 downto 0);

begin

	-- sync to clock
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				buttons_sync <= (others => '0');
			else
				buttons_sync <= buttons_i;
			end if;
		end if;
	end process;

	-- generate RED
	detectors:
	for index in 0 to num_of_buttons - 1 generate
		signal button_pulse : std_logic;
	begin
		buttons_o(index) <= button_pulse;

		-- rising edge detectors on synced input buttons
		Inst_RED:			entity work.rising_edge_detector
		port map
		(
			clock_i			=> clock_i,
			reset_i			=> reset_i,
			input_i			=> buttons_sync(index),
			input_ack_i		=> buttons_ack_i(index),
			output_o		=> button_pulse
		);

	end generate;

end Behavioral;
