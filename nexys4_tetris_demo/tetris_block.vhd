library	ieee;
use		ieee.std_logic_1164		.all;
use		ieee.std_logic_unsigned	.all;
use		ieee.numeric_std		.all;
use		ieee.math_real			.all;



entity tetris_block is
	generic
	(	
		number_of_rows		: integer := 32;
		number_of_columns	: integer := 16
	);
	port
	(
		clock_i				: in	std_logic;
		reset_i				: in	std_logic;
		
		block_descriptor_o	: out	std_logic_vector(2 downto 0);
		block_row_i			: in	std_logic_vector(integer(CEIL(LOG2(real(number_of_rows    - 1)))) - 1 downto 0);
		block_column_i		: in	std_logic_vector(integer(CEIL(LOG2(real(number_of_columns - 1)))) - 1 downto 0)
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
	type ram_type is array (0 to ram_size - 1) of std_logic_vector (0 to block_descriptor_width - 1);

	signal RAM : ram_type := (
		"010", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "100",
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

		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000",
		"111", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "001"
	);

	type fsm_states is
	(
		state_start,
		state_drop_block,
		state_end
	);
	signal state, next_state			: fsm_states := state_start;

	signal ram_write_enable				: std_logic;
	signal ram_write_address			: std_logic_vector (ram_width - 1 downto 0);
	signal ram_write_data				: std_logic_vector (block_descriptor_width - 1 downto 0);

	signal ram_read_address				: std_logic_vector (ram_width - 1 downto 0);
	signal ram_read_data				: std_logic_vector (block_descriptor_width - 1 downto 0);

begin

	-- process for RAM
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if ram_write_enable = '1' then
				RAM (conv_integer(ram_write_address)) <= ram_write_data;
			end if;
		end if;
	end process;

	ram_read_address		<= block_row_i & block_column_i;
	ram_read_data			<= RAM (conv_integer(ram_read_address));

	block_descriptor_o		<= ram_read_data;

	-- MOORE state change process
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

	-- MOORE output
	process (state)
	begin

		ram_write_enable	<= '0';
		ram_write_address	<= (others => '0');
		ram_write_data		<= (others => '0');

		case state is
		when state_start =>
			null;
		when state_drop_block =>
			ram_write_enable	<= '1';
			ram_write_address	<= "00001" & "0100";
			ram_write_data		<= "100";
		when state_end =>
			null;
		when others =>
			null;
		end case;

	end process;

	-- MOORE next state
	process (state)
	begin
		next_state	<= state;

		case state is
		when state_start =>
			next_state <= state_drop_block;
		when state_drop_block =>
			next_state <= state_end;
		when state_end =>
			next_state <= state;
		when others =>
			next_state <= state_start;
		end case;

	end process;


end Behavioral;
