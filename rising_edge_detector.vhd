library ieee;
use     ieee.std_logic_1164.all;



entity rising_edge_detector is
	port
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;
		input_i			: in	std_logic;
		input_ack_i		: in	std_logic;
		output_o		: out	std_logic
	);
end rising_edge_detector;



architecture Behavioral of rising_edge_detector is

	type state_type is
	(
		state_waiting_for_rising_edge,
		state_rising_edge,
		state_waiting_for_zero
	);

	signal state, next_state : state_type;

	signal output	: std_logic;
	signal input	: std_logic;

begin

	output_o		<= output;
	input			<= input_i;


	-- FSM state change
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				state <= state_waiting_for_rising_edge;
			else
				state <= next_state;
			end if;
		end if;
	end process;

	-- FSM output
	process (state)
	begin
		case (state) is
		when state_waiting_for_rising_edge	=> output <= '0';
		when state_rising_edge				=> output <= '1';
		when state_waiting_for_zero			=> output <= '0';
		when others							=> output <= '0';
		end case;
	end process;

	-- FSM next state
	process (state, input, input_ack_i)
	begin
		--declare default state for next_state to avoid latches
		next_state <= state;


		case (state) is

		when state_waiting_for_rising_edge =>

			if input = '1' then
				next_state <= state_rising_edge;
			end if;

		when state_rising_edge =>

			if input_ack_i = '1' then
				next_state <= state_waiting_for_zero;
			end if;

		when state_waiting_for_zero =>

			if input = '0' then
				next_state <= state_waiting_for_rising_edge;
			end if;

		when others =>

			next_state <= state_waiting_for_rising_edge;

		end case;
	end process;

end Behavioral;
