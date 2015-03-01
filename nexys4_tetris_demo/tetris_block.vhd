library	ieee;
use		ieee.std_logic_1164		.all;
use		ieee.std_logic_unsigned	.all;
use		ieee.numeric_std		.all;
use		ieee.math_real			.all;



entity tetris_block is
	generic
	(	
		number_of_rows		: integer := 30;
		number_of_columns	: integer := 16
	);
	port
	(
		clock_i						: in	std_logic;
		reset_i						: in	std_logic;
		
		block_descriptor_o			: out	std_logic_vector(2 downto 0);
		block_row_i					: in	std_logic_vector(integer(CEIL(LOG2(real(number_of_rows    - 1)))) - 1 downto 0);
		block_column_i				: in	std_logic_vector(integer(CEIL(LOG2(real(number_of_columns - 1)))) - 1 downto 0);

		screen_finished_render_i	: in	std_logic
	);
end tetris_block;



architecture Behavioral of tetris_block is

	constant row_width						: integer := integer(CEIL(LOG2(real(number_of_rows    - 1))));
	constant column_width					: integer := integer(CEIL(LOG2(real(number_of_columns - 1))));

	constant ram_width						: integer := row_width + column_width;
	constant ram_size						: integer := 2 ** (ram_width);

	-- block descriptor
	constant block_descriptor_width			: integer := 3;
	constant block_descriptor_empty 		: std_logic_vector := std_logic_vector(to_unsigned(0, block_descriptor_width));
	-- ####
	constant block_descriptor_pipe	 		: std_logic_vector := std_logic_vector(to_unsigned(1, block_descriptor_width));
	-- #
	-- ###
	constant block_descriptor_L_left		: std_logic_vector := std_logic_vector(to_unsigned(2, block_descriptor_width));
	--   #
	-- ###
	constant block_descriptor_L_right 		: std_logic_vector := std_logic_vector(to_unsigned(3, block_descriptor_width));
	-- ##
	--  ##
	constant block_descriptor_Z_left 		: std_logic_vector := std_logic_vector(to_unsigned(4, block_descriptor_width));
	--  ##
	-- ##
	constant block_descriptor_Z_right 		: std_logic_vector := std_logic_vector(to_unsigned(5, block_descriptor_width));
	--  #
	-- ###
	constant block_descriptor_T				: std_logic_vector := std_logic_vector(to_unsigned(6, block_descriptor_width));
	-- ##
	-- ##
	constant block_descriptor_square		: std_logic_vector := std_logic_vector(to_unsigned(7, block_descriptor_width));


	constant line_remove_counter_width	: integer := 5;
	
	-------------------------------------------------------
	----------------- Tetris Active Data ------------------
	-------------------------------------------------------
	-- 30x16x(block_descriptor_width) RAM for storing block descriptors
	type ram_blocks_type is array (0 to ram_size - 1) of std_logic_vector (0 to block_descriptor_width - 1);

	signal RAM : ram_blocks_type := (
		"011", "001", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "001", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",

		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",

		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "001", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "010", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "011", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "100", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "101", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "110", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",

		"111", "011", "101", "100", "111", "010", "110", "110", "001", "010", "100", "001", "100", "001", "100", "001",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "100", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "001", "010", "100", "001", "001", "100", "010", "010", "000",
		"000", "010", "000", "000", "000", "000", "000", "010", "010", "010", "001", "100", "001", "010", "001", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "010", "000", "000", "000", "000", "000", "000", "000", "000"
	);

	signal ram_write_enable				: std_logic;
	signal ram_write_address			: std_logic_vector (ram_width - 1 downto 0);
	type ram_write_data_mux_enum is (
		MUXSEL_MOVE_DOWN,
		MUXSEL_ZERO
	);
	signal ram_write_data_mux			: ram_write_data_mux_enum;
	signal ram_write_data				: std_logic_vector (block_descriptor_width - 1 downto 0);

	type ram_read_address_mux_enum is (
		MUXSEL_RENDER,
		MUXSEL_ROW_ELIM
	);
	signal ram_read_address_mux			: ram_read_address_mux_enum;
	signal ram_read_address				: std_logic_vector (ram_width - 1 downto 0);
	signal ram_read_data				: std_logic_vector (block_descriptor_width - 1 downto 0);

	type fsm_states is
	(
		state_start,

		state_pre_decrement_row,

		state_move_block_down,
		state_decrement_row,

		state_zero_upper_row
	);
	signal state, next_state			: fsm_states := state_start;

	constant refresh_count_top			: integer := 59;
	constant refresh_count_width		: integer := integer(CEIL(LOG2(real(refresh_count_top))));
--	signal refresh_count_enable			: std_logic;
	signal refresh_count				: std_logic_vector (refresh_count_width - 1 downto 0);
	signal refresh_count_overflow		: std_logic;

	signal row_count_enable				: std_logic;
	signal row_count					: std_logic_vector (row_width - 1 downto 0);
	signal row_count_old				: std_logic_vector (row_width - 1 downto 0);
	signal row_count_overflow			: std_logic;

	signal column_count_enable			: std_logic;
	signal column_count					: std_logic_vector (column_width - 1 downto 0);
	signal column_count_overflow		: std_logic;

	type ram_row_elim_type is array (0 to 31) of std_logic_vector (0 to 4);
	signal RAM_ROW_ELIM					: ram_row_elim_type :=
	(
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",

		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",

		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",

		"11111",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000"
	);

	signal row_elim_read_address		: std_logic_vector (row_width - 1 downto 0);
	signal row_elim_read_data			: std_logic_vector (4 downto 0);

	signal row_elim_write_enable		: std_logic;
	signal row_elim_write_address		: std_logic_vector (row_width - 1 downto 0);
	signal row_elim_write_data			: std_logic_vector (4 downto 0);

begin

	-- process for RAM for line elimination
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if row_elim_write_enable = '1' then
				RAM_ROW_ELIM (conv_integer(row_elim_write_address)) <= row_elim_write_data;
			end if;
		end if;
	end process;

	row_elim_read_data		<= RAM_ROW_ELIM (conv_integer(row_elim_read_address));
	row_elim_write_data		<= row_elim_read_data + '1';


	-- process for RAM for blocks
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if ram_write_enable = '1' then
				RAM (conv_integer(ram_write_address)) <= ram_write_data;
			end if;
		end if;
	end process;

	ram_read_data			<= RAM (conv_integer(ram_read_address));

	with ram_write_data_mux select ram_write_data <=
		ram_read_data	when MUXSEL_MOVE_DOWN,
		"000"			when others;

	with ram_read_address_mux select ram_read_address <=
		block_row_i & block_column_i		when MUXSEL_RENDER,
		row_count & column_count			when MUXSEL_ROW_ELIM,
		"00000" & "0000"					when others;

	ram_write_address		<= row_count_old & column_count;


	block_descriptor_o		<= ram_read_data;


	Inst_refresh_counter:	entity work.counter_until
	generic map				(width => refresh_count_width)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		reset_when_i		=> std_logic_vector (to_unsigned (refresh_count_top, refresh_count_width)),
		count_enable_i		=> screen_finished_render_i,
		count_o				=> refresh_count,
		overflow_o			=> refresh_count_overflow
	);


	Inst_row_counter:		entity work.counter_until_new
	generic map
	(
		width				=> row_width,
		step				=> '0', -- downcounter
		reset_value			=> number_of_rows - 1
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		reset_when_i		=> std_logic_vector (to_unsigned (0, row_width)),
		count_enable_i		=> row_count_enable,
		count_o				=> row_count,
		overflow_o			=> row_count_overflow
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

	Inst_column_counter:	entity work.counter_until
	generic map				(width => column_width)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		reset_when_i		=> std_logic_vector (to_unsigned (number_of_columns - 1, column_width)),
		count_enable_i		=> column_count_enable,
		count_o				=> column_count,
		overflow_o			=> column_count_overflow
	);



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

		ram_write_enable			<= '0';
		ram_write_data_mux			<= MUXSEL_MOVE_DOWN;
		ram_read_address_mux		<= MUXSEL_ROW_ELIM;

		column_count_enable			<= '0';
		row_count_enable			<= '0';

		case state is
		when state_start =>
			ram_read_address_mux		<= MUXSEL_RENDER;

		when state_pre_decrement_row =>
			row_count_enable			<= '1';

		when state_move_block_down =>
			-- enable writes
			ram_write_enable		<= '1';
			-- activate counter
			column_count_enable		<= '1';

		when state_decrement_row =>
			row_count_enable		<= '1';

		when state_zero_upper_row =>
			-- enable writes
			ram_write_enable		<= '1';
			ram_write_data_mux		<= MUXSEL_ZERO;
			-- activate counter
			column_count_enable		<= '1';
		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process (state,
		screen_finished_render_i, refresh_count_overflow,
		row_count_overflow, column_count_overflow)
	begin
		next_state	<= state;

		case state is
		when state_start =>
			if refresh_count_overflow = '1' then
				next_state <= state_pre_decrement_row;
			end if;

		when state_pre_decrement_row =>
			next_state <= state_move_block_down;

		when state_move_block_down =>
			if column_count_overflow = '1' then
				next_state <= state_decrement_row;
			end if;
		when state_decrement_row =>
			-- if we finished moving, go to end
			if row_count_overflow = '1' then
				next_state <= state_zero_upper_row;
			else
				next_state <= state_move_block_down;
			end if;

		when state_zero_upper_row =>
			if column_count_overflow = '1' then
				next_state <= state_start;
			end if;
		when others =>
			next_state <= state_start;
		end case;

	end process;


end Behavioral;
