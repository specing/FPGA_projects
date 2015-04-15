library ieee;
use		ieee.std_logic_1164.all;



entity testbench_tetris_block is
end testbench_tetris_block;
 


architecture behavior of testbench_tetris_block is
 
	--Inputs
	signal clock_i					: std_logic := '0';
	signal reset_i					: std_logic := '1';

	signal block_row_i				: std_logic_vector(4 downto 0) := (others => '0');
	signal block_column_i			: std_logic_vector(3 downto 0) := (others => '0');
	signal screen_finished_render_i	: std_logic := '0';

 	--Outputs
	signal block_descriptor_o		: std_logic_vector(2 downto 0) := (others => '0');

	-- Clock period definitions
	constant clock_i_period			: time := 10 ns;

 
begin
	uut:							entity work.tetris_block
	port map
	(
		clock_i						=> clock_i,
		reset_i						=> reset_i,

		block_descriptor_o			=> block_descriptor_o,
		block_row_i					=> block_row_i,
		block_column_i				=> block_column_i,

		screen_finished_render_i	=> screen_finished_render_i
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

		wait for 10 * clock_i_period;

		for i in 0 to 65 loop
			screen_finished_render_i <= '1';
			wait for 1 * clock_i_period;
			screen_finished_render_i <= '0';
			wait for 10 * clock_i_period;
		end loop;

		wait;
	end process;

end behavior;
