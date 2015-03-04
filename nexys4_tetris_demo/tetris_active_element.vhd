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

		fsm_start_i					: in	std_logic;
		fsm_ready_o					: out	std_logic
	);
end tetris_active_element;



architecture Behavioral of tetris_active_element is

	constant row_width					: integer := integer(CEIL(LOG2(real(number_of_rows    - 1))));
	constant column_width				: integer := integer(CEIL(LOG2(real(number_of_columns - 1))));

	-- block descriptor
	constant block_descriptor_width		: integer := 3;
	constant block_descriptor_empty 	: std_logic_vector := std_logic_vector(to_unsigned(0, block_descriptor_width));
	-- ####
	constant block_descriptor_pipe	 	: std_logic_vector := std_logic_vector(to_unsigned(1, block_descriptor_width));
	-- #
	-- ###
	constant block_descriptor_L_left	: std_logic_vector := std_logic_vector(to_unsigned(2, block_descriptor_width));
	--   #
	-- ###
	constant block_descriptor_L_right 	: std_logic_vector := std_logic_vector(to_unsigned(3, block_descriptor_width));
	-- ##
	--  ##
	constant block_descriptor_Z_left 	: std_logic_vector := std_logic_vector(to_unsigned(4, block_descriptor_width));
	--  ##
	-- ##
	constant block_descriptor_Z_right 	: std_logic_vector := std_logic_vector(to_unsigned(5, block_descriptor_width));
	--  #
	-- ###
	constant block_descriptor_T			: std_logic_vector := std_logic_vector(to_unsigned(6, block_descriptor_width));
	-- ##
	-- ##
	constant block_descriptor_square	: std_logic_vector := std_logic_vector(to_unsigned(7, block_descriptor_width));


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


	type fsm_states is
	(
		state_new_elem,
		state_start
	);
	signal state, next_state			: fsm_states := state_new_elem;


	type rotation_enum is
	(
		ROTATION_0,
		ROTATION_90,
		ROTATION_180,
		ROTATION_270
	);

	type operation_enum is
	(
		OP_NULL,
		OP_NEW,
		OP_MOVE_LEFT,
		OP_MOVE_RIGHT,
		OP_ROT_LEFT,
		OP_ROT_RIGHT,
		OP_MOVE_DOWN
	);

	type sub_operation_enum is
	(
		SUB_OP_NULL,
		SUB_OP_PLUS_ONE,
		SUB_OP_PLUS_TWO,
		SUB_OP_MINUS_ONE,
		SUB_OP_MINUS_TWO,
		SUB_OP_NEW
	);
	signal sub_op_row0					: sub_operation_enum;
	signal sub_op_row1					: sub_operation_enum;
	signal sub_op_row2					: sub_operation_enum;
	signal sub_op_row3					: sub_operation_enum;
	signal sub_op_column0				: sub_operation_enum;
	signal sub_op_column1				: sub_operation_enum;
	signal sub_op_column2				: sub_operation_enum;
	signal sub_op_column3				: sub_operation_enum;

	signal operation					: operation_enum;
	signal next_operation				: operation_enum;

	signal descriptor					: std_logic_vector (block_descriptor_width - 1 downto 0);
	signal next_descriptor				: std_logic_vector (block_descriptor_width - 1 downto 0);
	signal rotation						: rotation_enum;
	signal next_rotation				: rotation_enum;
	signal row0							: std_logic_vector (row_width - 1 downto 0);
	signal row1							: std_logic_vector (row_width - 1 downto 0);
	signal row2							: std_logic_vector (row_width - 1 downto 0);
	signal row3							: std_logic_vector (row_width - 1 downto 0);
	signal next_row0					: std_logic_vector (row_width - 1 downto 0);
	signal next_row1					: std_logic_vector (row_width - 1 downto 0);
	signal next_row2					: std_logic_vector (row_width - 1 downto 0);
	signal next_row3					: std_logic_vector (row_width - 1 downto 0);
	signal column0						: std_logic_vector (column_width - 1 downto 0);
	signal column1						: std_logic_vector (column_width - 1 downto 0);
	signal column2						: std_logic_vector (column_width - 1 downto 0);
	signal column3						: std_logic_vector (column_width - 1 downto 0);
	signal next_column0					: std_logic_vector (column_width - 1 downto 0);
	signal next_column1					: std_logic_vector (column_width - 1 downto 0);
	signal next_column2					: std_logic_vector (column_width - 1 downto 0);
	signal next_column3					: std_logic_vector (column_width - 1 downto 0);

	signal element_write_enable			: std_logic;

begin

	-------------------------------------------------------
	---------------- determine next state -----------------
	-------------------------------------------------------

	with sub_op_row0			select next_row0 <=
		default_L_left_row0			when SUB_OP_NEW,
		row0						when others;

	with sub_op_row1			select next_row1 <=
		default_L_left_row1			when SUB_OP_NEW,
		row1						when others;

	with sub_op_row2			select next_row2 <=
		default_L_left_row2			when SUB_OP_NEW,
		row2						when others;

	with sub_op_row3			select next_row3 <=
		default_L_left_row3			when SUB_OP_NEW,
		row3						when others;

	with sub_op_column0			select next_column0 <=
		default_L_left_column0		when SUB_OP_NEW,
		column0						when others;

	with sub_op_column1			select next_column1 <=
		default_L_left_column1		when SUB_OP_NEW,
		column1						when others;

	with sub_op_column2			select next_column2 <=
		default_L_left_column2		when SUB_OP_NEW,
		column2						when others;

	with sub_op_column3			select next_column3 <=
		default_L_left_column3		when SUB_OP_NEW,
		column3						when others;

	next_descriptor				<= block_descriptor_L_left;
	next_rotation				<= ROTATION_0;

	-------------------------------------------------------
	---------------- active element data ------------------
	-------------------------------------------------------

	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if element_write_enable = '1' then
				descriptor		<= next_descriptor;
				rotation		<= next_rotation;
				row0			<= next_row0;
				row1			<= next_row1;
				row2			<= next_row2;
				row3			<= next_row3;
				column0			<= next_column0;
				column1			<= next_column1;
				column2			<= next_column2;
				column3			<= next_column3;
			end if;
		end if;
	end process;

--	process (clock_i)
--	begin
--		if rising_edge (clock_i) then
--			if operation_write_enable = '1' then
--				operation		<= next_operation;
--			end if;
--		end if;
--	end process;

	-------------------------------------------------------
	------------------------- FSM -------------------------
	-------------------------------------------------------

	-- FSM state change process
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if reset_i = '1' then
				state <= state_new_elem;
			else
				state <= next_state;
			end if;
		end if;
	end process;


	-- FSM output
	process (state)
	begin

		fsm_ready_o					<= '0';

		operation					<= OP_NULL;

		sub_op_row0					<= SUB_OP_NULL;
		sub_op_row1					<= SUB_OP_NULL;
		sub_op_row2					<= SUB_OP_NULL;
		sub_op_row3					<= SUB_OP_NULL;
		sub_op_column0				<= SUB_OP_NULL;
		sub_op_column1				<= SUB_OP_NULL;
		sub_op_column2				<= SUB_OP_NULL;
		sub_op_column3				<= SUB_OP_NULL;

		element_write_enable		<= '0';


		case state is
		when state_new_elem =>
			operation				<= OP_NEW;

			sub_op_row0				<= SUB_OP_NEW;
			sub_op_row1				<= SUB_OP_NEW;
			sub_op_row2				<= SUB_OP_NEW;
			sub_op_row3				<= SUB_OP_NEW;
			sub_op_column0			<= SUB_OP_NEW;
			sub_op_column1			<= SUB_OP_NEW;
			sub_op_column2			<= SUB_OP_NEW;
			sub_op_column3			<= SUB_OP_NEW;

			element_write_enable	<= '1';

		when state_start =>
			fsm_ready_o				<= '1';

		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process (state,
		block_i,
		fsm_start_i)
	begin
		next_state	<= state;

		case state is
		when state_new_elem =>
			next_state <= state_start;

		when state_start =>
			if fsm_start_i = '1' then
				next_state <= state_start;
			end if;

		when others =>
			next_state <= state_start;
		end case;
	end process;


	-------------------------------------------------------
	---------- determine what to put on screen ------------
	-------------------------------------------------------

	process (
		active_row_i, row0, row1, row2, row3,
		active_column_i, column0, column1, column2, column3,
		descriptor
	) begin
		if (active_row_i = row0 and active_column_i = column0)
		or (active_row_i = row1 and active_column_i = column1)
		or (active_row_i = row2 and active_column_i = column2)
		or (active_row_i = row3 and active_column_i = column3)
		then
			active_data_o				<= block_descriptor_L_left;
		else
			active_data_o				<= block_descriptor_empty;
		end if;
	end process;


end Behavioral;
