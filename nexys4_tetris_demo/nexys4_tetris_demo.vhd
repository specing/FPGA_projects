library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;

use     work.definitions        .all;



entity nexys4_tetris_demo is
	generic
	(
		row_width			: integer := 10;
		column_width		: integer := 10;

		num_of_buttons		: integer := 4
	);
	port
	(
		clock_i				: in	std_logic;
		reset_low_i			: in	std_logic;

		hsync_o				: out	std_logic;
		vsync_o				: out	std_logic;
		vga_red_o			: out	std_logic_vector(vga_red_width   - 1 downto 0);
		vga_green_o			: out	std_logic_vector(vga_green_width - 1 downto 0);
		vga_blue_o			: out	std_logic_vector(vga_blue_width  - 1 downto 0);

		switches_i			: in	std_logic_vector(15 downto 0);
		btnL_i				: in	std_logic;
		btnR_i				: in	std_logic;
		btnU_i				: in	std_logic;
		btnD_i				: in	std_logic;

		led_o				: out	std_logic_vector(15 downto 0);
		anode_o				: out	std_logic_vector(7 downto 0);
		cathode_o			: out	std_logic_vector(6 downto 0)
	);
end nexys4_tetris_demo;



architecture Behavioral of nexys4_tetris_demo is

	signal reset_i					: std_logic;
	signal tetrimino_operation		: active_tetrimino_operations;
	signal tetrimino_operation_ack	: std_logic;

	-- vga signals
	signal vga_pixel_clock			: std_logic;

	signal led						: std_logic_vector(15 downto 0);
	signal pwm_count				: std_logic;

	signal button_left			: std_logic;
	signal button_right			: std_logic;
	signal button_up			: std_logic;
	signal button_down			: std_logic;

begin
	-- board reset is active low
	reset_i					<= not reset_low_i;

	-------------------------------------------------------
	------------------------ INPUT ------------------------
	-------------------------------------------------------

	INPUT_LOGIC: block
		signal buttons_joined		: std_logic_vector(3 downto 0);
		signal buttons				: std_logic_vector(3 downto 0);

		type state_type is
		(
			state_start,
			state_left,
			state_right,
			state_up,
			state_down
		--	state_wait_for_ack
		);
		signal state, next_state	: state_type := state_start;


		signal button_left_ack		: std_logic;
		signal button_right_ack		: std_logic;
		signal button_up_ack		: std_logic;
		signal button_down_ack		: std_logic;
		signal buttons_ack_joined	: std_logic_vector(3 downto 0);

	begin

		buttons_joined			<= btnL_i & btnR_i & btnU_i & btnD_i;
		buttons_ack_joined		<= button_left_ack & button_right_ack & button_up_ack & button_down_ack;
		-- sync & rising edge detectors on input buttons
		Inst_button_input:		entity work.button_input
		generic map				( num_of_buttons => 4 )
		port map
		(
			clock_i				=> clock_i,
			reset_i				=> reset_i,
			buttons_i			=> buttons_joined,
			buttons_ack_i		=> buttons_ack_joined,
			buttons_o			=> buttons
		);

		button_left				<= buttons(3);
		button_right			<= buttons(2);
		button_up				<= buttons(1);
		button_down				<= buttons(0);

		-- FSM state change
		process (clock_i)
		begin
			if rising_edge (clock_i) then
				if reset_i = '1' then
					state <= state_start;
				else
					state <= next_state;
				end if;
			end if;
		end process;

		-- FSM output
		process (state)
		begin
			button_left_ack				<= '0';
			button_right_ack			<= '0';
			button_up_ack				<= '0';
			button_down_ack				<= '0';
			tetrimino_operation			<= ATO_NONE;

			case state is
			when state_start =>
				null;
			when state_left =>
			--	tetrimino_operation		<= ATO_MOVE_LEFT;
				tetrimino_operation		<= ATO_MOVE_DOWN;
				button_left_ack			<= '1';
			when state_right =>
				tetrimino_operation		<= ATO_MOVE_RIGHT;
				button_right_ack		<= '1';
			when state_up =>
				tetrimino_operation		<= ATO_ROTATE_CLOCKWISE;
				button_up_ack			<= '1';
			when state_down =>
				tetrimino_operation		<= ATO_ROTATE_COUNTER_CLOCKWISE;
				button_down_ack			<= '1';
			end case;
		end process;

		-- FSM next state
		process
		(
			state, tetrimino_operation_ack,
			button_left, button_right, button_up, button_down
		)
		begin
			next_state <= state;

			case state is
			when state_start =>
				if button_left = '1' then
					next_state <= state_left;
				elsif button_right = '1' then
					next_state <= state_right;
				elsif button_up = '1' then
					next_state <= state_up;
				elsif button_down = '1' then
					next_state <= state_down;
				else
					next_state <= state_start;
				end if;
			when state_left =>
				if tetrimino_operation_ack = '1' then
					next_state <= state_start;
				end if;
			when state_right =>
				if tetrimino_operation_ack = '1' then
					next_state <= state_start;
				end if;
			when state_up =>
				if tetrimino_operation_ack = '1' then
					next_state <= state_start;
				end if;
			when state_down =>
				if tetrimino_operation_ack = '1' then
					next_state <= state_start;
				end if;
			end case;
		end process;

	end block;

	-------------------------------------------------------
	----------------------- SCREEN ------------------------
	-------------------------------------------------------
	-- prescale the main clock to obtain the "pixel clock"
	-- /4 for nexys 4
	Inst_counter_pixelclockprescale: entity work.counter_until
	generic map				(width => 2)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> '1',
		reset_when_i		=> "11",
		reset_value_i		=> "00",
		count_o				=> open,
		count_at_top_o		=> open,
		overflow_o			=> vga_pixel_clock
	);

	Inst_tetris:				entity work.tetris
	port map
	(
		clock_i					=> clock_i,
		reset_i					=> reset_i,

		vga_pixel_clock_i		=> vga_pixel_clock,
		hsync_o					=> hsync_o,
		vsync_o					=> vsync_o,
		vga_red_o				=> vga_red_o,
		vga_green_o				=> vga_green_o,
		vga_blue_o				=> vga_blue_o,

		active_operation_i		=> tetrimino_operation,
		active_operation_ack_o	=> tetrimino_operation_ack
	);

	-- dim LEDs

	process(clock_i)
	begin
		if rising_edge (clock_i) then
			pwm_count <= not pwm_count;
		end if;
	end process;

	with pwm_count select led_o <=
		led				when '0',
		(others => '0')	when others;

	-- assign debug signals

	anode_o					<= (others => '1');
	cathode_o				<= (others => '0');

	-- silence warnings
	led(15 downto 4)		<= switches_i (15 downto 4);
	led(0) <= button_left;
	led(1) <= button_right;
	led(2) <= button_up;
	led(3) <= button_down;


end Behavioral;
