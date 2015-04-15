library ieee;
use		ieee.std_logic_1164.all;
use		ieee.numeric_std.all;



entity testbench_active_tetrimino is
end testbench_active_tetrimino;
 


architecture behavior of testbench_active_tetrimino is
 
	--Inputs
	signal clock_i					: std_logic := '0';
	signal reset_i					: std_logic := '1';

	signal block_i					: std_logic_vector(2 downto 0) := (others => '0');
	signal fsm_start_i				: std_logic := '0';

	signal active_row_i				: std_logic_vector(4 downto 0) := "00000";
	signal active_column_i			: std_logic_vector(3 downto 0) := "0000";

 	--Outputs
	signal block_o					: std_logic_vector(2 downto 0);
	signal block_write_enable_o		: std_logic;
	signal block_read_row_o			: std_logic_vector(4 downto 0);
	signal block_read_column_o		: std_logic_vector(3 downto 0);
	signal block_write_row_o		: std_logic_vector(4 downto 0);
	signal block_write_column_o		: std_logic_vector(3 downto 0);

	signal active_data_o			: std_logic_vector(2 downto 0);

	signal fsm_ready_o				: std_logic;

	-- Clock period definitions
	constant clock_i_period			: time := 10 ns;

 
begin
	uut:							entity work.tetris_active_element
	port map
	(
		clock_i								=> clock_i,
		reset_i								=> reset_i,

		-- communication with main RAM
		block_o								=> block_o,
		block_i								=> block_i,
		block_write_enable_o				=> block_write_enable_o,
		block_read_row_o					=> block_read_row_o,
		block_read_column_o					=> block_read_column_o,
		block_write_row_o					=> block_write_row_o,
		block_write_column_o				=> block_write_column_o,

		-- readout for drawing of active element
		active_data_o						=> active_data_o,
		active_row_i						=> active_row_i,
		active_column_i						=> active_column_i,

		fsm_start_i							=> fsm_start_i,
		fsm_ready_o							=> fsm_ready_o
	);

	-- Clock process definitions
	clock_i_process :process
	begin
		clock_i <= '0';
		wait for clock_i_period/2;
		clock_i <= '1';
		wait for clock_i_period/2;
	end process;
 

	-- Stimulus process
	stim_proc: process
	begin		
		-- hold reset state for
		wait for 10 * clock_i_period;
		reset_i			<= '0';

		for row in 0 to 31 loop
			for col in 0 to 15 loop
				active_row_i	<= std_logic_vector(to_unsigned(row, 5));
				active_column_i	<= std_logic_vector(to_unsigned(column, 4));
				wait for 4 * clock_i_period;
			end loop;
		end loop;

		wait;
	end process;

end behavior;
