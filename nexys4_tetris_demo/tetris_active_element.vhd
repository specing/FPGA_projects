library	ieee;
use		ieee.std_logic_1164		.all;
use		ieee.std_logic_unsigned	.all;
use		ieee.numeric_std		.all;
use		ieee.math_real			.all;



entity tetris_active_element is
	generic
	(	
		number_of_rows				: integer := 30;
		number_of_columns			: integer := 16
	);
	port
	(
		clock_i						: in	std_logic;
		reset_i						: in	std_logic;

		-- communication with main RAM
		block_o						: out	std_logic_vector(2 downto 0);
		block_i						: in	std_logic_vector(2 downto 0);
		block_write_enable_o		: out	std_logic;
		block_read_row_o			: out	std_logic_vector(integer(CEIL(LOG2(real(number_of_rows    - 1)))) - 1 downto 0);
		block_read_column_o			: out	std_logic_vector(integer(CEIL(LOG2(real(number_of_columns - 1)))) - 1 downto 0);
		block_write_row_o			: out	std_logic_vector(integer(CEIL(LOG2(real(number_of_rows    - 1)))) - 1 downto 0);
		block_write_column_o		: out	std_logic_vector(integer(CEIL(LOG2(real(number_of_columns - 1)))) - 1 downto 0);

		-- readout for drawing of active element
		active_data_o				: out	std_logic_vector(2 downto 0);
		active_row_i				: in	std_logic_vector(integer(CEIL(LOG2(real(number_of_rows    - 1)))) - 1 downto 0);
		active_column_i				: in	std_logic_vector(integer(CEIL(LOG2(real(number_of_columns - 1)))) - 1 downto 0);

		-- communication with the main finite state machine
		fsm_start_i					: in	std_logic;
		fsm_ready_o					: out	std_logic
	);
end tetris_active_element;



architecture Behavioral of tetris_active_element is

	constant row_width					: integer := integer(CEIL(LOG2(real(number_of_rows    - 1))));
	constant column_width				: integer := integer(CEIL(LOG2(real(number_of_columns - 1))));

	-- tetrimino type
	constant tetrimino_type_width		: integer := 3;
	constant tetrimino_type_empty 		: std_logic_vector := std_logic_vector(to_unsigned(0, tetrimino_type_width));
	-- ####
	constant tetrimino_type_pipe	 	: std_logic_vector := std_logic_vector(to_unsigned(1, tetrimino_type_width));
	-- #
	-- ###
	constant tetrimino_type_L_left		: std_logic_vector := std_logic_vector(to_unsigned(2, tetrimino_type_width));
	--   #
	-- ###
	constant tetrimino_type_L_right 	: std_logic_vector := std_logic_vector(to_unsigned(3, tetrimino_type_width));
	-- ##
	--  ##
	constant tetrimino_type_Z_left 		: std_logic_vector := std_logic_vector(to_unsigned(4, tetrimino_type_width));
	--  ##
	-- ##
	constant tetrimino_type_Z_right 	: std_logic_vector := std_logic_vector(to_unsigned(5, tetrimino_type_width));
	--  #
	-- ###
	constant tetrimino_type_T			: std_logic_vector := std_logic_vector(to_unsigned(6, tetrimino_type_width));
	-- ##
	-- ##
	constant tetrimino_type_square		: std_logic_vector := std_logic_vector(to_unsigned(7, tetrimino_type_width));


	constant default_pipe_row0			: std_logic_vector := "00001";
	constant default_pipe_row1			: std_logic_vector := "00001";
	constant default_pipe_row2			: std_logic_vector := "00001";
	constant default_pipe_row3			: std_logic_vector := "00001";
	constant default_pipe_column0		: std_logic_vector := "0110";
	constant default_pipe_column1		: std_logic_vector := "0111";
	constant default_pipe_column2		: std_logic_vector := "1000";
	constant default_pipe_column3		: std_logic_vector := "1001";

	constant default_L_left_row0		: std_logic_vector := "00001";
	constant default_L_left_row1		: std_logic_vector := "00010";
	constant default_L_left_row2		: std_logic_vector := "00010";
	constant default_L_left_row3		: std_logic_vector := "00010";
	constant default_L_left_column0		: std_logic_vector := "0111";
	constant default_L_left_column1		: std_logic_vector := "0111";
	constant default_L_left_column2		: std_logic_vector := "1000";
	constant default_L_left_column3		: std_logic_vector := "1001";

	constant default_L_right_row0		: std_logic_vector := "00001";
	constant default_L_right_row1		: std_logic_vector := "00010";
	constant default_L_right_row2		: std_logic_vector := "00010";
	constant default_L_right_row3		: std_logic_vector := "00010";
	constant default_L_right_column0	: std_logic_vector := "1000";
	constant default_L_right_column1	: std_logic_vector := "1000";
	constant default_L_right_column2	: std_logic_vector := "0111";
	constant default_L_right_column3	: std_logic_vector := "0110";

	constant default_square_row0		: std_logic_vector := "00001";
	constant default_square_row1		: std_logic_vector := "00001";
	constant default_square_row2		: std_logic_vector := "00010";
	constant default_square_row3		: std_logic_vector := "00010";
	constant default_square_column0		: std_logic_vector := "0111";
	constant default_square_column1		: std_logic_vector := "1000";
	constant default_square_column2		: std_logic_vector := "1000";
	constant default_square_column3		: std_logic_vector := "0111";

	constant default_Z_right_row0		: std_logic_vector := "00010";
	constant default_Z_right_row1		: std_logic_vector := "00010";
	constant default_Z_right_row2		: std_logic_vector := "00001";
	constant default_Z_right_row3		: std_logic_vector := "00001";
	constant default_Z_right_column0	: std_logic_vector := "0110";
	constant default_Z_right_column1	: std_logic_vector := "0111";
	constant default_Z_right_column2	: std_logic_vector := "0111";
	constant default_Z_right_column3	: std_logic_vector := "1000";

	constant default_Z_left_row0		: std_logic_vector := "00001";
	constant default_Z_left_row1		: std_logic_vector := "00001";
	constant default_Z_left_row2		: std_logic_vector := "00010";
	constant default_Z_left_row3		: std_logic_vector := "00010";
	constant default_Z_left_column0		: std_logic_vector := "0111";
	constant default_Z_left_column1		: std_logic_vector := "1000";
	constant default_Z_left_column2		: std_logic_vector := "1000";
	constant default_Z_left_column3		: std_logic_vector := "1001";

	constant default_T_row0				: std_logic_vector := "00001";
	constant default_T_row1				: std_logic_vector := "00010";
	constant default_T_row2				: std_logic_vector := "00010";
	constant default_T_row3				: std_logic_vector := "00010";
	constant default_T_column0			: std_logic_vector := "0111";
	constant default_T_column1			: std_logic_vector := "0110";
	constant default_T_column2			: std_logic_vector := "0111";
	constant default_T_column3			: std_logic_vector := "1000";

	signal block0_row					: std_logic_vector (row_width - 1 downto 0);
	signal block1_row					: std_logic_vector (row_width - 1 downto 0);
	signal block2_row					: std_logic_vector (row_width - 1 downto 0);
	signal block3_row					: std_logic_vector (row_width - 1 downto 0);
	signal block0_column				: std_logic_vector (column_width - 1 downto 0);
	signal block1_column				: std_logic_vector (column_width - 1 downto 0);
	signal block2_column				: std_logic_vector (column_width - 1 downto 0);
	signal block3_column				: std_logic_vector (column_width - 1 downto 0);
	signal active_address_write_enable	: std_logic;

	signal block0_row_new				: std_logic_vector (row_width - 1 downto 0);
	signal block1_row_new				: std_logic_vector (row_width - 1 downto 0);
	signal block2_row_new				: std_logic_vector (row_width - 1 downto 0);
	signal block3_row_new				: std_logic_vector (row_width - 1 downto 0);
	signal block0_column_new			: std_logic_vector (column_width - 1 downto 0);
	signal block1_column_new			: std_logic_vector (column_width - 1 downto 0);
	signal block2_column_new			: std_logic_vector (column_width - 1 downto 0);
	signal block3_column_new			: std_logic_vector (column_width - 1 downto 0);
	signal new_address_write_enable		: std_logic;

	signal block0_row_next				: std_logic_vector (row_width - 1 downto 0);
	signal block1_row_next				: std_logic_vector (row_width - 1 downto 0);
	signal block2_row_next				: std_logic_vector (row_width - 1 downto 0);
	signal block3_row_next				: std_logic_vector (row_width - 1 downto 0);
	signal block0_column_next			: std_logic_vector (column_width - 1 downto 0);
	signal block1_column_next			: std_logic_vector (column_width - 1 downto 0);
	signal block2_column_next			: std_logic_vector (column_width - 1 downto 0);
	signal block3_column_next			: std_logic_vector (column_width - 1 downto 0);

	signal block0_row_operand			: std_logic_vector (row_width - 1 downto 0);
	signal block1_row_operand			: std_logic_vector (row_width - 1 downto 0);
	signal block2_row_operand			: std_logic_vector (row_width - 1 downto 0);
	signal block3_row_operand			: std_logic_vector (row_width - 1 downto 0);
	signal block0_column_operand		: std_logic_vector (column_width - 1 downto 0);
	signal block1_column_operand		: std_logic_vector (column_width - 1 downto 0);
	signal block2_column_operand		: std_logic_vector (column_width - 1 downto 0);
	signal block3_column_operand		: std_logic_vector (column_width - 1 downto 0);

	type operation_enum is
	(
		ZERO,
		PLUS_ONE,
		MINUS_ONE
	);
	signal block0_row_operation			: operation_enum;
	signal block1_row_operation			: operation_enum;
	signal block2_row_operation			: operation_enum;
	signal block3_row_operation			: operation_enum;
	signal block0_column_operation		: operation_enum;
	signal block1_column_operation		: operation_enum;
	signal block2_column_operation		: operation_enum;
	signal block3_column_operation		: operation_enum;


	type fsm_states is
	(
		state_start,
		state_NT_new_addresses,
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


	signal tetrimino_type				: std_logic_vector (tetrimino_type_width - 1 downto 0)
										:= tetrimino_type_L_left;
	signal tetrimino_type_next			: std_logic_vector (tetrimino_type_width - 1 downto 0);
	signal tetrimino_we					: std_logic;

begin

	process
	(
		tetrimino_select,
		block0_row,    block1_row,    block2_row,    block3_row,
		block0_column, block1_column, block2_column, block3_column
	)
	begin
		case tetrimino_select is
		when TETRIMINO_OLD =>
			block0_row_operand		<= block0_row;
			block0_column_operand	<= block0_column;
			block1_row_operand		<= block1_row;
			block1_column_operand	<= block1_column;
			block2_row_operand		<= block2_row;
			block2_column_operand	<= block2_column;
			block3_row_operand		<= block3_row;
			block3_column_operand	<= block3_column;
		when TETRIMINO_NEW =>
			block0_row_operand		<= default_L_left_row0;
			block0_column_operand	<= default_L_left_column0;
			block1_row_operand		<= default_L_left_row1;
			block1_column_operand	<= default_L_left_column1;
			block2_row_operand		<= default_L_left_row2;
			block2_column_operand	<= default_L_left_column2;
			block3_row_operand		<= default_L_left_row3;
			block3_column_operand	<= default_L_left_column3;
		end case;
	end process;

	with block0_row_operation		select block0_row_next <=
		block0_row_operand + 1			when PLUS_ONE,
		block0_row_operand - 1			when MINUS_ONE,
		block0_row_operand				when others; -- ZERO
	with block1_row_operation		select block1_row_next <=
		block1_row_operand + 1			when PLUS_ONE,
		block1_row_operand - 1			when MINUS_ONE,
		block1_row_operand				when others; -- ZERO
	with block2_row_operation		select block2_row_next <=
		block2_row_operand + 1			when PLUS_ONE,
		block2_row_operand - 1			when MINUS_ONE,
		block2_row_operand				when others; -- ZERO
	with block3_row_operation		select block3_row_next <=
		block3_row_operand + 1			when PLUS_ONE,
		block3_row_operand - 1			when MINUS_ONE,
		block3_row_operand				when others; -- ZERO

	with block0_column_operation	select block0_column_next <=
		block0_column_operand + 1		when PLUS_ONE,
		block0_column_operand - 1		when MINUS_ONE,
		block0_column_operand			when others; -- ZERO
	with block1_column_operation	select block1_column_next <=
		block1_column_operand + 1		when PLUS_ONE,
		block1_column_operand - 1		when MINUS_ONE,
		block1_column_operand			when others; -- ZERO
	with block2_column_operation	select block2_column_next <=
		block2_column_operand + 1		when PLUS_ONE,
		block2_column_operand - 1		when MINUS_ONE,
		block2_column_operand			when others; -- ZERO
	with block3_column_operation	select block3_column_next <=
		block3_column_operand + 1		when PLUS_ONE,
		block3_column_operand - 1		when MINUS_ONE,
		block3_column_operand			when others; -- ZERO

	-- 8 registers for storing new rows and columns
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if new_address_write_enable = '1' then
				block0_row_new		<= block0_row_next;
				block0_column_new	<= block0_column_next;
				block1_row_new		<= block1_row_next;
				block1_column_new	<= block1_column_next;
				block2_row_new		<= block2_row_next;
				block2_column_new	<= block2_column_next;
				block3_row_new		<= block3_row_next;
				block3_column_new	<= block3_column_next;
			end if;
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
				block0_row			<= block0_row_new;
				block0_column		<= block0_column_new;
				block1_row			<= block1_row_new;
				block1_column		<= block1_column_new;
				block2_row			<= block2_row_new;
				block2_column		<= block2_column_new;
				block3_row			<= block3_row_new;
				block3_column		<= block3_column_new;
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

		block0_row_operation				<= ZERO;
		block1_row_operation				<= ZERO;
		block2_row_operation				<= ZERO;
		block3_row_operation				<= ZERO;
		block1_column_operation				<= ZERO;
		block1_column_operation				<= ZERO;
		block2_column_operation				<= ZERO;
		block3_column_operation				<= ZERO;

		new_address_write_enable			<= '0';
		active_address_write_enable			<= '0';

		tetrimino_select					<= TETRIMINO_OLD;

		case state is
		when state_start =>
			fsm_ready_o						<= '1';

		when state_NT_new_addresses =>
			-- all operations ZERO
			tetrimino_select				<= TETRIMINO_NEW;
			new_address_write_enable		<= '1';

		when state_writeback =>
			active_address_write_enable		<= '1';

		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process (state, fsm_start_i)
	begin
		next_state	<= state;

		case state is
		when state_start =>
			if fsm_start_i = '1' then
				next_state <= state_start;
			end if;

		when state_NT_new_addresses =>
			next_state <= state_writeback;

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
		tetrimino_type
	) begin
		if (active_row_i = block0_row and active_column_i = block0_column)
		or (active_row_i = block1_row and active_column_i = block1_column)
		or (active_row_i = block2_row and active_column_i = block2_column)
		or (active_row_i = block3_row and active_column_i = block3_column)
		then
			active_data_o				<= tetrimino_type;
		else
			active_data_o				<= tetrimino_type_empty;
		end if;
	end process;


end Behavioral;
