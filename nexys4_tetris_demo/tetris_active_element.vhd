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



	type fsm_states is
	(
		state_start
	);
	signal state, next_state			: fsm_states := state_start;

	signal element_descriptor			: std_logic_vector (block_descriptor_width - 1 downto 0)
										:=block_descriptor_L_left;

begin

	process (active_row_i, active_column_i)
	begin
		if (active_row_i = "00000" and active_column_i = "1000")
		or (active_row_i = "00001" and active_column_i = "1000")
		or (active_row_i = "00010" and active_column_i = "1000")
		or (active_row_i = "00010" and active_column_i = "0111")
		then
			active_data_o				<= block_descriptor_L_left;
		else
			active_data_o				<= block_descriptor_empty;
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


		case state is
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
		when state_start =>
			if fsm_start_i = '1' then
				next_state <= state_start;
			end if;

		when others =>
			next_state <= state_start;
		end case;
	end process;

end Behavioral;
