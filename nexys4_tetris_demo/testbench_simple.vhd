library ieee;
use		ieee.std_logic_1164.all;



entity testbench_simple is
end testbench_simple;
 


architecture behavior of testbench_simple is
 
	--Inputs
	signal clock_i			: std_logic := '0';
	signal reset_i			: std_logic := '1';
	signal reset_low_i		: std_logic := '0';

	signal switches_i		: std_logic_vector(15 downto 0) := (others => '0');
	signal btnL_i			: std_logic := '0';
	signal btnR_i			: std_logic := '0';
	signal btnU_i			: std_logic := '0';
	signal btnD_i			: std_logic := '0';


 	--Outputs
	signal led_o			: std_logic_vector(15 downto 0);
	signal cathode_o		: std_logic_vector(6 downto 0);
	signal anode_o			: std_logic_vector(7 downto 0);

	signal hsync_o			: std_logic;
	signal vsync_o			: std_logic;
	signal vga_red_o		: std_logic_vector(3 downto 0);
	signal vga_green_o		: std_logic_vector(3 downto 0);
	signal vga_blue_o		: std_logic_vector(3 downto 0);


	-- Clock period definitions
	constant clock_i_period			: time := 10 ns;

 
begin
	uut:					entity work.nexys4_tetris_demo
	port map
	(
		clock_i				=> clock_i,
		reset_low_i			=> reset_low_i,

		hsync_o				=> hsync_o,
		vsync_o				=> vsync_o,
		vga_red_o			=> vga_red_o,
		vga_green_o			=> vga_green_o,
		vga_blue_o			=> vga_blue_o,

		switches_i			=> switches_i,
		btnL_i				=> btnL_i,
		btnR_i				=> btnR_i,
		btnU_i				=> btnU_i,
		btnD_i				=> btnD_i,

		led_o				=> led_o,
		anode_o				=> anode_o,
		cathode_o			=> cathode_o
	);

	reset_low_i	<= not reset_i;

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



		wait;
	end process;

end behavior;
