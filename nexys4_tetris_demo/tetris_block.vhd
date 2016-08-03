library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;
use     ieee.math_real          .all;

use     work.definitions        .all;



entity tetris_block is
	port
	(
		clock_i						: in	std_logic;
		reset_i						: in	std_logic;

		row_elim_data_o				: out	std_logic_vector(4 downto 0);
		tetrimino_shape_o			: out	tetrimino_shape_type;
		block_row_i					: in	block_storage_row_type;
		block_column_i				: in	block_storage_column_type;

		screen_finished_render_i	: in	std_logic;
		active_operation_i			: in	active_tetrimino_operations;
		active_operation_ack_o		: out	std_logic;

		score_count_o				: out	score_count_type
	);
end tetris_block;



architecture Behavioral of tetris_block is

	constant ram_width : integer := tetris.row.width + tetris.column.width;
	constant ram_size  : integer := 2 ** (ram_width);
	-------------------------------------------------------
	----------------- Tetris Active Data ------------------
	-------------------------------------------------------
	-- number_of_rows*number_of_columns for storing block descriptors
	-- of type tetrimino_shape_type + wasted space (if the sizes are not a power of two).
	type tetrimino_block_storage_type is array (0 to ram_size - 1) of tetrimino_shape_type;
	signal RAM : tetrimino_block_storage_type := (others => TETRIMINO_SHAPE_NONE);

	type ram_access_mux_enum is
	(
		MUXSEL_RENDER,
		MUXSEL_ROW_ELIM,
		MUXSEL_ACTIVE_ELEMENT
	);
	signal ram_access_mux					: ram_access_mux_enum;

	signal ram_write_enable					: std_logic;
	signal ram_write_address				: std_logic_vector (ram_width - 1 downto 0);
	signal ram_write_data					: tetrimino_shape_type;

	signal ram_read_address					: std_logic_vector (ram_width - 1 downto 0);
	signal ram_read_data					: tetrimino_shape_type;


	type fsm_states is
	(
		state_wait_for_initial_input,
		state_confirm_start,
		state_start,
		-- removes full rows
		state_full_row_elim,
		state_full_row_elim_wait,
		-- move down
		state_active_element_MD,
		state_active_element_MD_wait,
		-- user input
		state_active_element_input,
		state_active_element_input_wait,
		state_active_element_input_ack
	);
	signal state, next_state				: fsm_states := state_wait_for_initial_input;

	constant refresh_count_top				: integer := 59; --255;
	constant refresh_count_width			: integer := integer(CEIL(LOG2(real(refresh_count_top))));
	signal refresh_count_at_top				: std_logic;

	signal row_elim_read_row				: block_storage_row_type;
	signal row_elim_read_column				: block_storage_column_type;
	signal row_elim_write_data				: tetrimino_shape_type;
	signal row_elim_write_enable			: std_logic;
	signal row_elim_write_row				: block_storage_row_type;
	signal row_elim_write_column			: block_storage_column_type;

	signal row_elim_start					: std_logic;
	signal row_elim_ready					: std_logic;

	signal active_write_data				: tetrimino_shape_type;
	signal active_write_enable				: std_logic;
	signal active_read_row					: block_storage_row_type;
	signal active_read_column				: block_storage_column_type;
	signal active_write_row					: block_storage_row_type;
	signal active_write_column				: block_storage_column_type;

	signal active_tetrimino_shape			: tetrimino_shape_type;
	type active_tetrimino_command_mux_enum is
	(
		ATC_DISABLED,
		ATC_MOVE_DOWN,
		ATC_USER_INPUT
	);
	signal active_tetrimino_command_mux		: active_tetrimino_command_mux_enum;
	signal active_operation					: active_tetrimino_operations;

	signal active_start						: std_logic;
	signal active_ready						: std_logic;

	signal game_start						: std_logic;
	signal game_over						: std_logic;

begin

	Inst_score_counter: entity work.counter
	generic map         ( width => score_count_width )
	port map
	(
		clock_i         => clock_i,
		reset_i         => game_start,
		count_enable_i  => active_write_enable, -- temporary?
		count_o         => score_count_o
	);

	-- determine what goes out on screen
	with active_tetrimino_shape	select tetrimino_shape_o <=
		ram_read_data				when TETRIMINO_SHAPE_NONE,
		active_tetrimino_shape		when others;

	-------------------------------------------------------
	--------------- logic for RAM for blocks --------------
	-------------------------------------------------------

	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if ram_write_enable = '1' then
				RAM (conv_integer(ram_write_address)) <= ram_write_data;
			end if;
		end if;
	end process;

	ram_read_data								<= RAM (conv_integer(ram_read_address));

	-- figure out who has access to it
	with ram_access_mux							select ram_write_data <=
		TETRIMINO_SHAPE_NONE						when MUXSEL_RENDER,
		row_elim_write_data							when MUXSEL_ROW_ELIM,
		active_write_data							when MUXSEL_ACTIVE_ELEMENT,
		TETRIMINO_SHAPE_NONE						when others;

	with ram_access_mux							select ram_write_address <=
		"00000"            & "0000"					when MUXSEL_RENDER,
		row_elim_write_row & row_elim_write_column	when MUXSEL_ROW_ELIM,
		active_write_row   & active_write_column	when MUXSEL_ACTIVE_ELEMENT,
		"00000"            & "0000"					when others;

	with ram_access_mux							select ram_write_enable <=
		'0'											when MUXSEL_RENDER,
		row_elim_write_enable						when MUXSEL_ROW_ELIM,
		active_write_enable							when MUXSEL_ACTIVE_ELEMENT,
		'0'											when others;

	with ram_access_mux							select ram_read_address <=
		block_row_i       & block_column_i			when MUXSEL_RENDER,
		row_elim_read_row & row_elim_read_column	when MUXSEL_ROW_ELIM,
		active_read_row   & active_read_column		when MUXSEL_ACTIVE_ELEMENT,
		"00000"           & "0000"					when others;


	-------------------------------------------------------
	--------------------- sub modules ---------------------
	-------------------------------------------------------

	Inst_tetris_row_elim:					entity work.tetris_row_elim
	port map
	(
		clock_i								=> clock_i,
		reset_i								=> reset_i,

		-- communication with main RAM
		block_o								=> row_elim_write_data,
		block_i								=> ram_read_data,
		block_write_enable_o				=> row_elim_write_enable,
		block_read_row_o					=> row_elim_read_row,
		block_read_column_o					=> row_elim_read_column,
		block_write_row_o					=> row_elim_write_row,
		block_write_column_o				=> row_elim_write_column,

		row_elim_address_i					=> block_row_i,
		row_elim_data_o						=> row_elim_data_o,

		fsm_start_i							=> row_elim_start,
		fsm_ready_o							=> row_elim_ready
	);

	Inst_active_element:					entity work.tetris_active_element
	port map
	(
		clock_i								=> clock_i,
		reset_i								=> reset_i,

		-- communication with main RAM
		block_o								=> active_write_data,
		block_i								=> ram_read_data,
		block_write_enable_o				=> active_write_enable,
		block_read_row_o					=> active_read_row,
		block_read_column_o					=> active_read_column,
		block_write_row_o					=> active_write_row,
		block_write_column_o				=> active_write_column,

		-- readout for drawing of active element
		active_data_o						=> active_tetrimino_shape,
		active_row_i						=> block_row_i,
		active_column_i						=> block_column_i,

		-- communication with the main finite state machine
		operation_i							=> active_operation,
		fsm_start_i							=> active_start,
		fsm_ready_o							=> active_ready,
		fsm_game_over_o						=> game_over
	);

	with active_tetrimino_command_mux select active_operation <=
		ATO_NONE						when ATC_DISABLED,
		ATO_MOVE_DOWN					when ATC_MOVE_DOWN,
		active_operation_i				when ATC_USER_INPUT;

	-------------------------------------------------------
	-------------- support counters for FSM ---------------
	-------------------------------------------------------

	Inst_refresh_counter:	entity work.counter_until
	generic map				(width => refresh_count_width)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> screen_finished_render_i,
		reset_when_i		=> std_logic_vector (to_unsigned (refresh_count_top, refresh_count_width)),
		reset_value_i		=> std_logic_vector (to_unsigned (0,                 refresh_count_width)),
		count_o				=> open,
		count_at_top_o		=> refresh_count_at_top,
		overflow_o			=> open
	);

	-------------------------------------------------------
	------------------------- FSM -------------------------
	-------------------------------------------------------

	-- FSM state change process
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				state <= state_wait_for_initial_input;
			else
				state <= next_state;
			end if;
		end if;
	end process;

	-- FSM output
	process (state)
	begin

		ram_access_mux							<= MUXSEL_RENDER;

		row_elim_start							<= '0';
		active_start							<= '0';
		active_tetrimino_command_mux			<= ATC_DISABLED;
		active_operation_ack_o					<= '0';

		game_start								<= '0';

		case state is
		when state_wait_for_initial_input =>
			null;
		when state_confirm_start =>
			game_start							<= '1';
			-- clear key press
			active_operation_ack_o				<= '1';
		when state_start =>
			ram_access_mux						<= MUXSEL_RENDER;

		when state_full_row_elim =>
			row_elim_start						<= '1';
			ram_access_mux						<= MUXSEL_ROW_ELIM;
		when state_full_row_elim_wait =>
			ram_access_mux						<= MUXSEL_ROW_ELIM;

		when state_active_element_MD =>
			active_start						<= '1';
			ram_access_mux						<= MUXSEL_ACTIVE_ELEMENT;
			active_tetrimino_command_mux		<= ATC_MOVE_DOWN;
		when state_active_element_MD_wait =>
			ram_access_mux						<= MUXSEL_ACTIVE_ELEMENT;
			active_tetrimino_command_mux		<= ATC_MOVE_DOWN;

		when state_active_element_input =>
			active_start						<= '1';
			ram_access_mux						<= MUXSEL_ACTIVE_ELEMENT;
			active_tetrimino_command_mux		<= ATC_USER_INPUT;
		when state_active_element_input_wait =>
			ram_access_mux						<= MUXSEL_ACTIVE_ELEMENT;
			active_tetrimino_command_mux		<= ATC_USER_INPUT;
		when state_active_element_input_ack =>
			active_operation_ack_o				<= '1';

		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process
	(
		state,
		screen_finished_render_i, refresh_count_at_top,
		row_elim_ready,	active_ready,
		active_operation_i, game_over
	)
	begin
		next_state	<= state;

		case state is
		when state_wait_for_initial_input =>
			if active_operation_i /= ATO_NONE then
				next_state <= state_confirm_start;
			end if;
		when state_confirm_start =>
			next_state <= state_start;

		when state_start =>
			-- active only one clock
			if screen_finished_render_i = '1' then
			--refresh_count_overflow = '1' then
				next_state <= state_full_row_elim;
			end if;

		when state_full_row_elim =>
			next_state <= state_full_row_elim_wait;
		when state_full_row_elim_wait =>
			if row_elim_ready = '1' then
				if refresh_count_at_top = '1' then
					next_state <= state_active_element_MD;
				else
					next_state <= state_active_element_input;
				end if;
			end if;

		when state_active_element_MD =>
			next_state <= state_active_element_MD_wait;
		when state_active_element_MD_wait =>
			if active_ready = '1' then
				if game_over = '1' then
					next_state <= state_wait_for_initial_input;
				else
					next_state <= state_active_element_input;
				end if;
			end if;

		when state_active_element_input =>
			next_state <= state_active_element_input_wait;
		when state_active_element_input_wait =>
			if active_ready = '1' then
				next_state <= state_active_element_input_ack;
			end if;
		when state_active_element_input_ack =>
			next_state <= state_start;

		when others =>
			next_state <= state_start;
		end case;

	end process;


end Behavioral;
