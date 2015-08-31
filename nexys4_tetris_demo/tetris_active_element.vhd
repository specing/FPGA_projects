library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;

use     work.definitions        .all;



entity tetris_active_element is
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

		-- readout for drawing of active element
		active_data_o				: out	tetrimino_shape_type;
		active_row_i				: in	block_storage_row_type;
		active_column_i				: in	block_storage_column_type;

		-- communication with the main finite state machine
		operation_i					: in	active_tetrimino_operations;
		fsm_start_i					: in	std_logic;
		fsm_ready_o					: out	std_logic;
		fsm_game_over_o				: out	std_logic
	);
end tetris_active_element;



architecture Behavioral of tetris_active_element is

	constant extended_column_width : integer := 5;
	subtype extended_column_type is std_logic_vector (extended_column_width - 1 downto 0);

	constant row0                        : block_storage_row_type
	  := block_storage_row_type(to_unsigned(0, row_width));
	constant row1                        : block_storage_row_type
	  := block_storage_row_type(to_unsigned(1, row_width));
	constant rowNm1                      : block_storage_row_type
	  := block_storage_row_type(to_unsigned(number_of_rows - 1, row_width));
	constant rowN                        : block_storage_row_type
	  := block_storage_row_type(to_unsigned(number_of_rows, row_width));

	constant column0                     : extended_column_type
	  := extended_column_type(to_unsigned(0, extended_column_width));
	constant column1                     : extended_column_type
	  := extended_column_type(to_unsigned(1, extended_column_width));
	constant columnNm1                   : extended_column_type
	  := extended_column_type(to_unsigned(number_of_columns - 1, extended_column_width));
	constant columnN                     : extended_column_type
	  := extended_column_type(to_unsigned(number_of_columns, extended_column_width));


	signal corner_row                   : block_storage_row_type;
	signal corner_column                : block_storage_column_type;
	signal block0_row					: block_storage_row_type;
	signal block1_row					: block_storage_row_type;
	signal block2_row					: block_storage_row_type;
	signal block3_row					: block_storage_row_type;
	signal block0_column				: block_storage_column_type;
	signal block1_column				: block_storage_column_type;
	signal block2_column				: block_storage_column_type;
	signal block3_column				: block_storage_column_type;
	signal active_address_write_enable	: std_logic;

	signal corner_row_new               : block_storage_row_type;
	signal corner_column_new            : block_storage_column_type;
	signal block0_row_new				: block_storage_row_type;
	signal block1_row_new				: block_storage_row_type;
	signal block2_row_new				: block_storage_row_type;
	signal block3_row_new				: block_storage_row_type;
	signal block0_column_new            : extended_column_type;
	signal block1_column_new            : extended_column_type;
	signal block2_column_new            : extended_column_type;
	signal block3_column_new            : extended_column_type;
	signal new_address_write_enable		: std_logic;

	signal corner_row_next              : block_storage_row_type;
	signal corner_column_next           : block_storage_column_type;

	signal corner_row_operand           : block_storage_row_type;
	signal corner_column_operand        : block_storage_column_type;

	type operation_enum is
	(
		ZERO,
		PLUS_ONE,
		MINUS_ONE
	);
	signal corner_row_operation         : operation_enum;
	signal corner_column_operation      : operation_enum;


	type fsm_states is
	(
		state_start,
		-- NT...NEW_TETRIMINO
		state_NT_new_addresses,
		state_NT_check_contents0,
		state_NT_check_contents1,
		state_NT_check_contents2,
		state_NT_check_contents3,
		state_NT_game_over,
		-- MD...MOVE_DOWN
		state_MD_addresses,
		state_MD_check_contents0,
		state_MD_check_contents1,
		state_MD_check_contents2,
		state_MD_check_contents3,
		  -- when MOVE_DOWN fails, transfer active tetrimino to ram
		  -- and go to NEW_TETRIMINO
		state_MD_fill_contents0,
		state_MD_fill_contents1,
		state_MD_fill_contents2,
		state_MD_fill_contents3,
		-- ML... MOVE_LEFT
		state_ML_addresses,
		-- MR... MOVE_RIGHT
		state_MR_addresses,
		-- RC... ROTATE_CLOCKWISE
		state_RC_rotation,
		state_RC_addresses,
		state_RC_addresses_check,
		-- RCC... ROTATE_COUNTER_CLOCKWISE
		state_RCC_rotation,
		state_RCC_addresses,
		state_RCC_addresses_check,
		-- check contents of cells (generic) and go back to start on failure
		state_check_contents0,
		state_check_contents1,
		state_check_contents2,
		state_check_contents3,
		-- apply operation
		state_writeback
	);
	signal state, next_state			: fsm_states := state_NT_new_addresses;


	type tetrimino_select_enum is
	(
		TETRIMINO_OLD, TETRIMINO_NEW
	);
	signal tetrimino_select				: tetrimino_select_enum;


	type block_select_enum is
	(
		BLOCK0,	BLOCK1,	BLOCK2, BLOCK3
	);
	signal block_select					: block_select_enum;


	signal tetrimino_shape				: tetrimino_shape_type := TETRIMINO_SHAPE_L_LEFT;
	signal tetrimino_shape_next			: tetrimino_shape_type;
	signal tetrimino_shape_new			: tetrimino_shape_type;

	signal next_tetrimino_init_row      : tetrimino_init_row;


	signal tetrimino_rotation           : tetrimino_rotation_type := TETRIMINO_ROTATION_90;
	signal tetrimino_rotation_next      : tetrimino_rotation_type;
	signal tetrimino_rotation_new       : tetrimino_rotation_type;

begin

	process ( tetrimino_select, corner_row, corner_column, tetrimino_shape )
	begin
		case tetrimino_select is
		when TETRIMINO_OLD =>
			corner_row_operand    <= corner_row;
			corner_column_operand <= corner_column;
			tetrimino_shape_next  <= tetrimino_shape;
		when TETRIMINO_NEW =>
			corner_row_operand    <= block_storage_start_row;
			corner_column_operand <= block_storage_start_column;

			case tetrimino_shape is
			when "000" => tetrimino_shape_next <= "010";
			when "001" => tetrimino_shape_next <= "010";
			when "010" => tetrimino_shape_next <= "011";
			when "011" => tetrimino_shape_next <= "100";
			when "100" => tetrimino_shape_next <= "101";
			when "101" => tetrimino_shape_next <= "110";
			when "110" => tetrimino_shape_next <= "111";
			when "111" => tetrimino_shape_next <= "001";
			when others => report "Oops" severity FAILURE;
			end case;
		end case;
	end process;

	-- determine next orientation
	process ( operation_i, tetrimino_rotation )
	begin
		case operation_i is
		when ATO_ROTATE_CLOCKWISE =>
			case tetrimino_rotation is
			when TETRIMINO_ROTATION_0 =>   tetrimino_rotation_next <= TETRIMINO_ROTATION_90;
			when TETRIMINO_ROTATION_90 =>  tetrimino_rotation_next <= TETRIMINO_ROTATION_180;
			when TETRIMINO_ROTATION_180 => tetrimino_rotation_next <= TETRIMINO_ROTATION_270;
			when TETRIMINO_ROTATION_270 => tetrimino_rotation_next <= TETRIMINO_ROTATION_0;
			when others =>                 report "Oops" severity FAILURE;
			end case;
		when ATO_ROTATE_COUNTER_CLOCKWISE =>
			case tetrimino_rotation is
			when TETRIMINO_ROTATION_0 =>   tetrimino_rotation_next <= TETRIMINO_ROTATION_270;
			when TETRIMINO_ROTATION_90 =>  tetrimino_rotation_next <= TETRIMINO_ROTATION_0;
			when TETRIMINO_ROTATION_180 => tetrimino_rotation_next <= TETRIMINO_ROTATION_90;
			when TETRIMINO_ROTATION_270 => tetrimino_rotation_next <= TETRIMINO_ROTATION_180;
			when others =>                 report "Oops" severity FAILURE;
			end case;
		when others =>
			                               tetrimino_rotation_next <= tetrimino_rotation;
		end case;
	end process;

	with corner_row_operation    select corner_row_next <=
		corner_row_operand + 1     when PLUS_ONE,
		corner_row_operand - 1     when MINUS_ONE,
		corner_row_operand         when ZERO;
	with corner_column_operation select corner_column_next <=
		corner_column_operand + 1  when PLUS_ONE,
		corner_column_operand - 1  when MINUS_ONE,
		corner_column_operand      when ZERO;

	-- compute next tetrimino block addresses
	next_tetrimino_init_row <= tetrimino_init_rom (conv_integer (
	  tetrimino_shape_next & tetrimino_rotation_new));

	-- 8 registers for storing new rows and columns
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if new_address_write_enable = '1' then
				corner_row_new    <= corner_row_next;
				corner_column_new <= corner_column_next;

				block0_row_new    <=        corner_row_next     + to_integer (next_tetrimino_init_row (0));
				block1_row_new    <=        corner_row_next     + to_integer (next_tetrimino_init_row (1));
				block2_row_new    <=        corner_row_next     + to_integer (next_tetrimino_init_row (2));
				block3_row_new    <=        corner_row_next     + to_integer (next_tetrimino_init_row (3));
				block0_column_new <= ("0" & corner_column_next) + to_integer (next_tetrimino_init_row (4));
				block1_column_new <= ("0" & corner_column_next) + to_integer (next_tetrimino_init_row (5));
				block2_column_new <= ("0" & corner_column_next) + to_integer (next_tetrimino_init_row (6));
				block3_column_new <= ("0" & corner_column_next) + to_integer (next_tetrimino_init_row (7));
				tetrimino_shape_new	<= tetrimino_shape_next;
			end if;
		end if;
	end process;

	process (clock_i)
	begin
		if rising_edge (clock_i) then
			tetrimino_rotation_new <= tetrimino_rotation_next;
		end if;
	end process;

	-------------------------------------------------------
	---------------- active tetrimino data ----------------
	-------------------------------------------------------
	-- 8 registers for storing active rows and columns
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if active_address_write_enable = '1' then
				corner_row         <= corner_row_new;
				corner_column      <= corner_column_new (3 downto 0);

				block0_row         <= block0_row_new;
				block0_column      <= block0_column_new(3 downto 0);
				block1_row         <= block1_row_new;
				block1_column      <= block1_column_new(3 downto 0);
				block2_row         <= block2_row_new;
				block2_column      <= block2_column_new(3 downto 0);
				block3_row         <= block3_row_new;
				block3_column      <= block3_column_new(3 downto 0);

				tetrimino_rotation <= tetrimino_rotation_new;
				tetrimino_shape    <= tetrimino_shape_new;
			end if;
		end if;
	end process;

	-------------------------------------------------------
	------------------------- FSM -------------------------
	-------------------------------------------------------

	-- FSM state change process
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				state <= state_NT_new_addresses;
			else
				state <= next_state;
			end if;
		end if;
	end process;

	-- FSM output
	process (state)
	begin

		fsm_ready_o							<= '0';
		fsm_game_over_o						<= '0';

		-- addresses start at top left corner
		corner_row_operation                <= ZERO;
		corner_column_operation             <= ZERO;

		new_address_write_enable			<= '0';
		active_address_write_enable			<= '0';
		block_write_enable_o				<= '0';

		tetrimino_select					<= TETRIMINO_OLD;

		block_select						<= BLOCK0;

		case state is
		when state_start =>
			fsm_ready_o						<= '1';

		when state_NT_new_addresses =>
			tetrimino_select				<= TETRIMINO_NEW;
			new_address_write_enable		<= '1';
		when state_NT_check_contents0 =>
			block_select					<= BLOCK0;
		when state_NT_check_contents1 =>
			block_select					<= BLOCK1;
		when state_NT_check_contents2 =>
			block_select					<= BLOCK2;
		when state_NT_check_contents3 =>
			block_select					<= BLOCK3;
		when state_NT_game_over =>
			fsm_game_over_o					<= '1';
			fsm_ready_o						<= '1';

		when state_MD_addresses =>
			corner_row_operation            <= PLUS_ONE;
			new_address_write_enable		<= '1';

		when state_MD_check_contents0 =>
			block_select					<= BLOCK0;
		when state_MD_check_contents1 =>
			block_select					<= BLOCK1;
		when state_MD_check_contents2 =>
			block_select					<= BLOCK2;
		when state_MD_check_contents3 =>
			block_select					<= BLOCK3;

		-- transfer active tetrimino to main RAM
		when state_MD_fill_contents0 =>
			block_select					<= BLOCK0;
			block_write_enable_o			<= '1';
		when state_MD_fill_contents1 =>
			block_select					<= BLOCK1;
			block_write_enable_o			<= '1';
		when state_MD_fill_contents2 =>
			block_select					<= BLOCK2;
			block_write_enable_o			<= '1';
		when state_MD_fill_contents3 =>
			block_select					<= BLOCK3;
			block_write_enable_o			<= '1';

		when state_ML_addresses =>
			corner_column_operation         <= MINUS_ONE;
			new_address_write_enable		<= '1';

		when state_MR_addresses =>
			corner_column_operation         <= PLUS_ONE;
			new_address_write_enable		<= '1';

		when state_RC_rotation =>
			null;
		when state_RC_addresses =>
			new_address_write_enable        <= '1';
		when state_RC_addresses_check =>
			null;

		when state_RCC_rotation =>
			null;
		when state_RCC_addresses =>
			new_address_write_enable        <= '1';
		when state_RCC_addresses_check =>
			null;

		-- generic check contents
		when state_check_contents0 =>
			block_select					<= BLOCK0;
		when state_check_contents1 =>
			block_select					<= BLOCK1;
		when state_check_contents2 =>
			block_select					<= BLOCK2;
		when state_check_contents3 =>
			block_select					<= BLOCK3;

		when state_writeback =>
			active_address_write_enable		<= '1';

		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process
	(
		state, fsm_start_i, operation_i, block_i,
		block0_row,    block1_row,    block2_row,    block3_row,
		block0_column, block1_column, block2_column, block3_column
	)
	begin
		next_state	<= state;

		case state is
		when state_start =>
			if fsm_start_i = '1' then
				case operation_i is
				when ATO_NONE =>                     next_state <= state_start;
				when ATO_MOVE_DOWN =>                next_state <= state_MD_addresses;
				when ATO_MOVE_LEFT =>                next_state <= state_ML_addresses;
				when ATO_MOVE_RIGHT =>               next_state <= state_MR_addresses;
				when ATO_ROTATE_CLOCKWISE =>         next_state <= state_RC_rotation;
				when ATO_ROTATE_COUNTER_CLOCKWISE => next_state <= state_RCC_rotation;
				end case;
			end if;

		when state_NT_new_addresses =>
			next_state <= state_NT_check_contents0;
		when state_NT_check_contents0 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_NT_check_contents1;
			else
				next_state <= state_NT_game_over;
			end if;
		when state_NT_check_contents1 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_NT_check_contents2;
			else
				next_state <= state_NT_game_over;
			end if;
		when state_NT_check_contents2 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_NT_check_contents3;
			else
				next_state <= state_NT_game_over;
			end if;
		when state_NT_check_contents3 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_writeback;
			else
				next_state <= state_NT_game_over;
			end if;
		when state_NT_game_over =>
			next_state <= state_start;

		when state_MD_addresses =>
			if block0_row = rowNm1 or block1_row = rowNm1 or block2_row = rowNm1 or block3_row = rowNm1 then
				next_state <= state_MD_fill_contents0;
			else
				next_state <= state_MD_check_contents0;
			end if;

		when state_MD_check_contents0 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_MD_check_contents1;
			else
				next_state <= state_MD_fill_contents0;
			end if;
		when state_MD_check_contents1 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_MD_check_contents2;
			else
				next_state <= state_MD_fill_contents0;
			end if;
		when state_MD_check_contents2 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_MD_check_contents3;
			else
				next_state <= state_MD_fill_contents0;
			end if;
		when state_MD_check_contents3 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_writeback;
			else
				next_state <= state_MD_fill_contents0;
			end if;

		when state_MD_fill_contents0 =>
			next_state <= state_MD_fill_contents1;
		when state_MD_fill_contents1 =>
			next_state <= state_MD_fill_contents2;
		when state_MD_fill_contents2 =>
			next_state <= state_MD_fill_contents3;
		when state_MD_fill_contents3 =>
			next_state <= state_NT_new_addresses;

		when state_ML_addresses =>
			if block0_column = column0 or block1_column = column0
			or block2_column = column0 or block3_column = column0 then
				next_state <= state_start;
			else
				next_state <= state_check_contents0;
			end if;

		when state_MR_addresses =>
			if block0_column = columnNm1 or block1_column = columnNm1
			or block2_column = columnNm1 or block3_column = columnNm1 then
				next_state <= state_start;
			else
				next_state <= state_check_contents0;
			end if;

		when state_RC_rotation =>
			next_state <= state_RC_addresses;
		when state_RC_addresses =>
			next_state <= state_RC_addresses_check;
		when state_RC_addresses_check =>
			if block0_column_new(4) = '1' or block0_row_new(4 downto 1) = "1111"
			or block1_column_new(4) = '1' or block1_row_new(4 downto 1) = "1111"
			or block2_column_new(4) = '1' or block2_row_new(4 downto 1) = "1111"
			or block3_column_new(4) = '1' or block3_row_new(4 downto 1) = "1111" then
				next_state <= state_start;
			else
				next_state <= state_check_contents0;
			end if;

		when state_RCC_rotation =>
			next_state <= state_RCC_addresses;
		when state_RCC_addresses =>
			next_state <= state_RCC_addresses_check;
		when state_RCC_addresses_check =>
			if block0_column_new(4) = '1' or block0_row_new(4 downto 1) = "1111"
			or block1_column_new(4) = '1' or block1_row_new(4 downto 1) = "1111"
			or block2_column_new(4) = '1' or block2_row_new(4 downto 1) = "1111"
			or block3_column_new(4) = '1' or block3_row_new(4 downto 1) = "1111" then
				next_state <= state_start;
			else
				next_state <= state_check_contents0;
			end if;

		-- generic check contents, goes to start on error
		when state_check_contents0 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_check_contents1;
			else
				next_state <= state_start;
			end if;
		when state_check_contents1 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_check_contents2;
			else
				next_state <= state_start;
			end if;
		when state_check_contents2 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_check_contents3;
			else
				next_state <= state_start;
			end if;
		when state_check_contents3 =>
			if block_i = TETRIMINO_SHAPE_NONE then
				next_state <= state_writeback;
			else
				next_state <= state_start;
			end if;

		-- write the new addresses
		when state_writeback =>
			next_state <= state_start;

		when others =>
			next_state <= state_start;
		end case;
	end process;


	-------------------------------------------------------
	---------- determine what to put on screen ------------
	-------------------------------------------------------

	process (
		active_row_i,    block0_row,    block1_row,    block2_row,    block3_row,
		active_column_i, block0_column, block1_column, block2_column, block3_column,
		tetrimino_shape
	) begin
		if (active_row_i = block0_row and active_column_i = block0_column)
		or (active_row_i = block1_row and active_column_i = block1_column)
		or (active_row_i = block2_row and active_column_i = block2_column)
		or (active_row_i = block3_row and active_column_i = block3_column)
		then
			active_data_o				<= tetrimino_shape;
		else
			active_data_o				<= TETRIMINO_SHAPE_NONE;
		end if;
	end process;

	with block_select		select block_read_row_o <=
		block0_row_new			when BLOCK0,
		block1_row_new			when BLOCK1,
		block2_row_new			when BLOCK2,
		block3_row_new			when BLOCK3;

	with block_select                  select block_read_column_o <=
		block0_column_new(3 downto 0)    when BLOCK0,
		block1_column_new(3 downto 0)    when BLOCK1,
		block2_column_new(3 downto 0)    when BLOCK2,
		block3_column_new(3 downto 0)    when BLOCK3;

	with block_select		select block_write_row_o <=
		block0_row				when BLOCK0,
		block1_row				when BLOCK1,
		block2_row				when BLOCK2,
		block3_row				when BLOCK3;

	with block_select		select block_write_column_o	<=
		block0_column			when BLOCK0,
		block1_column			when BLOCK1,
		block2_column			when BLOCK2,
		block3_column			when BLOCK3;

	block_o <= tetrimino_shape;

end Behavioral;
