library ieee;
use     ieee.std_logic_1164.all;



entity ps2_controller is
	port
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;

		ps2_data_i		: in	std_logic;
		ps2_clock_i		: in	std_logic;

		data_o			: out	std_logic_vector(7 downto 0);
		data_ready_o	: out	std_logic;

		-- debug
		state_o			: out	std_logic_vector(3 downto 0);
		pulse_o			: out	std_logic
	);
end ps2_controller;



architecture behavioral of ps2_controller is

	type state_type is
	(
		state_idle,
--		state_start,
		state_b0,
		state_b1,
		state_b2,
		state_b3,
		state_b4,
		state_b5,
		state_b6,
		state_b7,
		state_parity,
		state_stop
	);

	signal state, next_state	: state_type;
	--Declare internal signals for all outputs of the state-machine

	signal sync_ps2_clock		: std_logic;
	signal sync_ps2_clock_low	: std_logic;
	signal sync_ps2_data		: std_logic;

	signal shift_register       : std_logic_vector (7 downto 0) -- 8 bit (no parity)
	                            := (others => '0');
	signal shift_register_enable: std_logic;
	signal data_ready			: std_logic;

begin

	data_o						<= shift_register;
	data_ready_o				<= data_ready;

	-- Sync both inputs
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				sync_ps2_clock	<= '1';
				sync_ps2_data	<= '1';
			else
				sync_ps2_clock	<= ps2_clock_i;
				sync_ps2_data	<= ps2_data_i;
			end if;
		end if;
	end process;

	-- negative edge detection KBD CLOCK
	Inst_falling_edge_detector_clock: entity work.falling_edge_detector
	port map
	(
		clock_i		=> clock_i,
		reset_i		=> reset_i,
		input_i		=> sync_ps2_clock,
		output_o	=> sync_ps2_clock_low
	);


	-- shift register
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				shift_register <= (others => '0');
			else
				if shift_register_enable = '1' and sync_ps2_clock_low = '1' then
					shift_register (6 downto 0)		<= shift_register(7 downto 1);
					shift_register (7)				<= sync_ps2_data;
				end if;
			end if;
		end if;
	end process;




	--Insert the following in the architecture after the begin keyword
	SYNC_PROC: process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				state <= state_idle;
			else
				if sync_ps2_clock_low = '1' then
					state <= next_state;
				end if;
			end if;
		end if;
	end process;


	--MOORE State-Machine - Outputs based on state only
	OUTPUT_DECODE: process (state)
	begin
		data_ready					<= '0';
		shift_register_enable		<= '0';
		-- insert statements to decode internal output signals
		-- below is simple example
		case state is
		when state_idle =>
			data_ready				<= '0';
--		when state_start =>
--			shift_register_enable	<= '0';

		when state_b0 =>
			shift_register_enable	<= '1';
		when state_b1 =>
			shift_register_enable	<= '1';
		when state_b2 =>
			shift_register_enable	<= '1';
		when state_b3 =>
			shift_register_enable	<= '1';
		when state_b4 =>
			shift_register_enable	<= '1';
		when state_b5 =>
			shift_register_enable	<= '1';
		when state_b6 =>
			shift_register_enable	<= '1';
		when state_b7 =>
			shift_register_enable	<= '1';

		when state_parity =>
			data_ready				<= '1';
		when state_stop =>
			data_ready				<= '0';
		when others =>
			data_ready				<= '0';
		end case;
	end process;


	NEXT_STATE_DECODE: process (state, sync_ps2_data)
	begin
		-- declare default state for next_state to avoid latches
		next_state <= state;  --default is to stay in current state
		-- insert statements to decode next_state
		-- below is a simple example
		case state is
		when state_idle =>
			if sync_ps2_data = '0' then
				next_state <= state_b0;
			else
				next_state <= state_idle;
			end if;
--		when state_start =>
--			if sync_ps2_data = '0' then
--				next_state <= state_b0;
--			else
--				next_state <= state_idle;
--			end if;
		when state_b0 =>
			next_state <= state_b1;
		when state_b1 =>
			next_state <= state_b2;
		when state_b2 =>
			next_state <= state_b3;
		when state_b3 =>
			next_state <= state_b4;
		when state_b4 =>
			next_state <= state_b5;
		when state_b5 =>
			next_state <= state_b6;
		when state_b6 =>
			next_state <= state_b7;
		when state_b7 =>
			next_state <= state_parity;
		when state_parity =>
			next_state <= state_stop;
		when state_stop =>
			next_state <= state_idle;
		when others =>
			next_state <= state_idle;
		end case;
	end process;

	-- debug part
	--pulse_o					<= shift_register_enable and sync_ps2_clock_low;
	pulse_o						<= sync_ps2_clock;

	with state select state_o <=
		"0000" when state_idle,
		"0010" when state_b0,
		"0011" when state_b1,
		"0100" when state_b2,
		"0101" when state_b3,
		"0110" when state_b4,
		"0111" when state_b5,
		"1000" when state_b6,
		"1001" when state_b7,
		"1010" when state_parity,
		"1011" when state_stop,
		"1111" when others;

end behavioral;
