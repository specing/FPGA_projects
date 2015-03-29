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

		row_elim_data_o				: out	std_logic_vector(4 downto 0);
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
		"001", "001", "111", "111", "111", "010", "010", "010", "110", "010", "001", "010", "011", "101", "010", "010",
		"000", "000", "101", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "110", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"001", "001", "111", "111", "111", "010", "010", "010", "110", "010", "001", "010", "011", "101", "010", "010",

		"111", "011", "101", "100", "111", "010", "110", "110", "001", "010", "100", "001", "100", "001", "100", "001",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "010", "000", "000", "000", "000", "000", "010", "010", "010", "001", "100", "001", "010", "001", "000",
		"000", "000", "000", "000", "000", "000", "000", "100", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "001", "010", "100", "001", "001", "100", "010", "010", "000",
		"001", "001", "111", "111", "111", "010", "010", "010", "110", "010", "001", "010", "011", "101", "010", "010",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000"
	);

	type ram_access_mux_enum is
	(
		MUXSEL_RENDER,
		MUXSEL_ROW_ELIM,
		MUXSEL_ACTIVE_ELEMENT
	);
	signal ram_access_mux					: ram_access_mux_enum;

	signal ram_write_enable					: std_logic;
	signal ram_write_address				: std_logic_vector (ram_width - 1 downto 0);
	signal ram_write_data					: std_logic_vector (block_descriptor_width - 1 downto 0);

	signal ram_read_address					: std_logic_vector (ram_width - 1 downto 0);
	signal ram_read_data					: std_logic_vector (block_descriptor_width - 1 downto 0);


	type fsm_states is
	(
		state_start,

		state_full_row_elim,
		state_full_row_elim_wait,

		state_active_element,
		state_active_element_wait
	);
	signal state, next_state				: fsm_states := state_start;

	constant refresh_count_top				: integer := 59; --255;
	constant refresh_count_width			: integer := integer(CEIL(LOG2(real(refresh_count_top))));
	signal refresh_count_overflow			: std_logic;

	signal row_elim_read_data				: std_logic_vector (block_descriptor_width - 1 downto 0);
	signal row_elim_read_row				: std_logic_vector (row_width - 1 downto 0);
	signal row_elim_read_column				: std_logic_vector (column_width - 1 downto 0);
	signal row_elim_write_data				: std_logic_vector (block_descriptor_width - 1 downto 0);
	signal row_elim_write_enable			: std_logic;
	signal row_elim_write_row				: std_logic_vector (row_width - 1 downto 0);
	signal row_elim_write_column			: std_logic_vector (column_width - 1 downto 0);

	signal row_elim_start					: std_logic;
	signal row_elim_ready					: std_logic;

	signal active_write_data				: std_logic_vector (block_descriptor_width - 1 downto 0);
	signal active_write_enable				: std_logic;
	signal active_read_row					: std_logic_vector (row_width - 1 downto 0);
	signal active_read_column				: std_logic_vector (column_width - 1 downto 0);
	signal active_write_row					: std_logic_vector (row_width - 1 downto 0);
	signal active_write_column				: std_logic_vector (column_width - 1 downto 0);

	signal active_block_descriptor			: std_logic_vector (block_descriptor_width - 1 downto 0);

	signal active_start						: std_logic;
	signal active_ready						: std_logic;

begin

	block_descriptor_o						<= ram_read_data or active_block_descriptor;

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
		"000"										when MUXSEL_RENDER,
		row_elim_write_data							when MUXSEL_ROW_ELIM,
		active_write_data							when MUXSEL_ACTIVE_ELEMENT,
		"000"										when others;

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
	generic map
	(
		number_of_rows						=> number_of_rows,
		number_of_columns					=> number_of_columns
	)
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
	generic map
	(
		number_of_rows						=> number_of_rows,
		number_of_columns					=> number_of_columns
	)
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
		active_data_o						=> active_block_descriptor,
		active_row_i						=> block_row_i,
		active_column_i						=> block_column_i,

		fsm_start_i							=> active_start,
		fsm_ready_o							=> active_ready
	);

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
		count_at_top_o		=> open,
		overflow_o			=> refresh_count_overflow
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

		ram_access_mux				<= MUXSEL_RENDER;

		row_elim_start				<= '0';
		active_start				<= '1';

		case state is
		when state_start =>
			ram_access_mux			<= MUXSEL_RENDER;

		when state_full_row_elim =>
			row_elim_start			<= '1';
			ram_access_mux			<= MUXSEL_ROW_ELIM;
		when state_full_row_elim_wait =>
			ram_access_mux			<= MUXSEL_ROW_ELIM;

		when state_active_element =>
			active_start			<= '1';
			ram_access_mux			<= MUXSEL_ACTIVE_ELEMENT;
		when state_active_element_wait =>
			ram_access_mux			<= MUXSEL_ACTIVE_ELEMENT;

		when others =>
			null;
		end case;

	end process;

	-- FSM next state
	process (state,
		refresh_count_overflow,
		row_elim_ready,
		active_ready)
	begin
		next_state	<= state;

		case state is
		when state_start =>
			-- active only one clock
			if refresh_count_overflow = '1' then
				next_state <= state_full_row_elim;
			end if;

		when state_full_row_elim =>
			next_state <= state_full_row_elim_wait;
		when state_full_row_elim_wait =>
			if row_elim_ready = '1' then
				next_state <= state_active_element;
			end if;

		when state_active_element =>
			next_state <= state_active_element_wait;
		when state_active_element_wait =>
			if active_ready = '1' then
				next_state <= state_start;
			end if;

		when others =>
			next_state <= state_start;
		end case;

	end process;


end Behavioral;
