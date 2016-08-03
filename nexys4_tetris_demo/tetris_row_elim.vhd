library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;
use     ieee.math_real          .all;

use     work.definitions        .all;



entity tetris_row_elim is
	port
	(
		clock_i						: in	std_logic;
		reset_i						: in	std_logic;

		-- communication with main RAM
		block_o						: out	tetrimino_shape_type;
		block_i						: in	tetrimino_shape_type;
		block_write_enable_o		: out	std_logic;
		block_read_row_o			: out	block_storage_row_type;
		block_read_column_o			: out	block_storage_column_type;
		block_write_row_o			: out	block_storage_row_type;
		block_write_column_o		: out	block_storage_column_type;

		row_elim_address_i			: in	std_logic_vector(4 downto 0);
		row_elim_data_o				: out	std_logic_vector(4 downto 0);
		fsm_start_i					: in	std_logic;
		fsm_ready_o					: out	std_logic
	);
end tetris_row_elim;



architecture Behavioral of tetris_row_elim is

	-- block descriptor
	constant row_elim_width				: integer := 5;

	type ram_write_data_mux_enum is (
		MUXSEL_MOVE_DOWN,
		MUXSEL_ZERO
	);
	signal ram_write_data_mux			: ram_write_data_mux_enum;

	type fsm_states is
	(
		state_start,

		state_check_block,
		state_check_block_increment_column,
		state_check_block_increment_column_til_end,
		state_increment_row_elim,
		state_check_block_decrement_row,

		state_check_row,
		state_check_row_decrement_row,

		state_pre_decrement_row,
		state_move_block_down,
		state_decrement_row,

		state_zero_upper_row
	);
	signal state, next_state			: fsm_states := state_start;

	signal row_count_enable				: std_logic;
	signal row_count                    : tetris.row.object;
	signal row_count_old                : tetris.row.object;
	signal row_count_at_top				: std_logic;

	signal column_count_enable			: std_logic;
	signal column_count                 : tetris.column.object;
	signal column_count_at_top			: std_logic;

	type ram_row_elim_type is array (0 to (2 ** tetris.row.width) - 1) of std_logic_vector (0 to row_elim_width - 1);
	signal RAM_ROW_ELIM					: ram_row_elim_type := (others => (others => '0'));

	type row_elim_mode_enum is
	(
		MUXSEL_ROW_ELIM_RENDER,
		MUXSEL_ROW_ELIM_INCREMENT,
		MUXSEL_ROW_ELIM_MOVE_DOWN,
		MUXSEL_ROW_ELIM_ZERO
	);
	signal row_elim_mode				: row_elim_mode_enum;

	signal row_elim_read_address        : tetris.row.object;
	signal row_elim_read_data			: std_logic_vector (4 downto 0);

	signal row_elim_write_enable		: std_logic;
	signal row_elim_write_address       : tetris.row.object;
	signal row_elim_write_data			: std_logic_vector (4 downto 0);

begin
	block_write_row_o					<= row_count_old;
	block_write_column_o				<= column_count;
	block_read_row_o					<= row_count;
	block_read_column_o					<= column_count;

	-------------------------------------------------------
	---------- logic for RAM for line elimination ---------
	-------------------------------------------------------
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if row_elim_write_enable = '1' then
				RAM_ROW_ELIM (conv_integer(row_elim_write_address)) <= row_elim_write_data;
			end if;
		end if;
	end process;

	row_elim_read_data			<= RAM_ROW_ELIM (conv_integer(row_elim_read_address));
	row_elim_data_o				<= row_elim_read_data;

	with row_elim_mode			select row_elim_write_data <=
		"00000"						when MUXSEL_ROW_ELIM_RENDER, -- N/A
		row_elim_read_data + '1'	when MUXSEL_ROW_ELIM_INCREMENT,
		row_elim_read_data			when MUXSEL_ROW_ELIM_MOVE_DOWN,
		"00000"						when MUXSEL_ROW_ELIM_ZERO,
		"00000"						when others;

	with row_elim_mode			select row_elim_write_address <=
		"00000"						when MUXSEL_ROW_ELIM_RENDER, -- N/A
		row_count					when MUXSEL_ROW_ELIM_INCREMENT,
		row_count_old				when MUXSEL_ROW_ELIM_MOVE_DOWN,
		row_count_old				when MUXSEL_ROW_ELIM_ZERO,
		"00000"						when others;

	with row_elim_mode			select row_elim_read_address <=
		row_elim_address_i			when MUXSEL_ROW_ELIM_RENDER,
		row_count					when MUXSEL_ROW_ELIM_INCREMENT,
		row_count					when MUXSEL_ROW_ELIM_MOVE_DOWN,
		"00000"						when MUXSEL_ROW_ELIM_ZERO, -- N/A
		"00000"						when others;


	with ram_write_data_mux		select block_o <=
		block_i						when MUXSEL_MOVE_DOWN,
		TETRIMINO_SHAPE_NONE		when others;


	-------------------------------------------------------
	-------------- support counters for FSM ---------------
	-------------------------------------------------------

	Inst_row_counter:		entity work.counter_until
	generic map
	(
		width               => tetris.row.width,
		step				=> '0' -- downcounter
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> row_count_enable,
		reset_when_i        => tetris.row.object (to_unsigned (0, tetris.row.width)),
		reset_value_i       => tetris.row.object (to_unsigned (tetris.row.max, tetris.row.width)),
		count_o				=> row_count,
		count_at_top_o		=> row_count_at_top,
		overflow_o			=> open
	);

	Inst_reg_old:			entity work.generic_register
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		clock_enable_i		=> row_count_enable,
		data_i				=> row_count,
		data_o				=> row_count_old
	);

	Inst_column_counter:    entity work.counter_until
	generic map             (width => tetris.column.width)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> column_count_enable,
		reset_when_i        => tetris.column.object (to_unsigned (tetris.column.max, tetris.column.width)),
		reset_value_i       => tetris.column.object (to_unsigned (0, tetris.column.width)),
		count_o				=> column_count,
		count_at_top_o		=> column_count_at_top,
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
				state <= state_start;
			else
				state <= next_state;
			end if;
		end if;
	end process;


	-- FSM output
	process (state)
	begin

		fsm_ready_o					<= '0';


		block_write_enable_o		<= '0';
		ram_write_data_mux			<= MUXSEL_MOVE_DOWN;

		column_count_enable			<= '0';
		row_count_enable			<= '0';

		row_elim_mode				<= MUXSEL_ROW_ELIM_RENDER;
		row_elim_write_enable		<= '0';

		case state is
		when state_start =>
			fsm_ready_o				<= '1';

		-- logic that increments block removal counters (row_elim)
		when state_check_block =>
			null;
		when state_check_block_increment_column =>
			column_count_enable		<= '1';
		when state_check_block_increment_column_til_end =>
			column_count_enable		<= '1';
		when state_increment_row_elim =>
			row_elim_mode			<= MUXSEL_ROW_ELIM_INCREMENT;
			row_elim_write_enable	<= '1';
		when state_check_block_decrement_row =>
			row_count_enable		<= '1';

		-- logic that finds what row we have to remove and then fires
		-- removal down below
		when state_check_row =>
			row_elim_mode			<= MUXSEL_ROW_ELIM_INCREMENT; -- same r addr
		when state_check_row_decrement_row =>
			row_count_enable		<= '1';

		-- logic that moves blocks down by one
		when state_pre_decrement_row =>
			row_count_enable		<= '1';

		when state_move_block_down =>
			-- enable writes
			block_write_enable_o	<= '1';
			-- activate counter
			column_count_enable		<= '1';
		when state_decrement_row =>
			row_elim_mode			<= MUXSEL_ROW_ELIM_MOVE_DOWN;
			row_elim_write_enable	<= '1';
			row_count_enable		<= '1';

		-- finaly zero upper row
		when state_zero_upper_row =>
			row_elim_mode			<= MUXSEL_ROW_ELIM_ZERO;
			row_elim_write_enable	<= '1';
			-- enable writes
			block_write_enable_o	<= '1';
			ram_write_data_mux		<= MUXSEL_ZERO;
			-- activate counter
			column_count_enable		<= '1';
		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process (state,
		block_i, row_elim_read_data,
		fsm_start_i,
		row_count_at_top, column_count_at_top)
	begin
		next_state	<= state;

		case state is
		when state_start =>
			if fsm_start_i = '1' then
				next_state <= state_check_block;
			end if;

		-- logic that increments block removal counters (row_elim)
		when state_check_block =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_check_block_increment_column_til_end;
			else
				next_state <= state_check_block_increment_column;
			end if;
		when state_check_block_increment_column_til_end =>
			if column_count_at_top = '1' then
				next_state <= state_check_block_decrement_row;
			end if;
		when state_check_block_increment_column =>
			if column_count_at_top = '1' then
				next_state <= state_increment_row_elim;
			else
				next_state <= state_check_block;
			end if;
		when state_increment_row_elim =>
			next_state <= state_check_block_decrement_row;
		when state_check_block_decrement_row =>
			if row_count_at_top = '1' then
				-- start row check passes
				next_state <= state_check_row;
			else
				next_state <= state_check_block;
			end if;

		-- logic that finds what row we have to remove and then fires
		-- removal down below
		when state_check_row =>
			if row_elim_read_data = "11111" then
				next_state <= state_pre_decrement_row;
			else
				next_state <= state_check_row_decrement_row;
			end if;
		when state_check_row_decrement_row =>
			if row_count_at_top = '1' then
				next_state <= state_start;
			else
				next_state <= state_check_row;
			end if;

		-- logic that moves blocks down by one
		when state_pre_decrement_row =>
			next_state <= state_move_block_down;

		when state_move_block_down =>
			if column_count_at_top = '1' then
				next_state <= state_decrement_row;
			end if;
		when state_decrement_row =>
			-- if we finished moving, go to end
			if row_count_at_top = '1' then
				next_state <= state_zero_upper_row;
			else
				next_state <= state_move_block_down;
			end if;

		when state_zero_upper_row =>
			if column_count_at_top = '1' then
				next_state <= state_check_row;
			end if;

		when others =>
			next_state <= state_start;
		end case;
	end process;

end Behavioral;
