library	ieee;
use		ieee.std_logic_1164		.all;
use		ieee.std_logic_unsigned	.all;
use		ieee.numeric_std		.all;



entity nexys4_tetris_demo is
	generic
	(
		row_width			: integer := 10;
		column_width		: integer := 10;

		vga_red_bits		: integer := 4;
		vga_green_bits		: integer := 4;
		vga_blue_bits		: integer := 4;

		num_of_buttons		: integer := 4
	);
	port
	(
		clock_i				: in	std_logic;
		reset_low_i			: in	std_logic;

		hsync_o				: out	std_logic;
		vsync_o				: out	std_logic;
		vga_red_o			: out	std_logic_vector(vga_red_bits   - 1 downto 0);
		vga_green_o			: out	std_logic_vector(vga_green_bits - 1 downto 0);
		vga_blue_o			: out	std_logic_vector(vga_blue_bits  - 1 downto 0);

		switches_i			: in	std_logic_vector(15 downto 0);
		btnL_i				: in	std_logic;
		btnR_i				: in	std_logic;
		btnU_i				: in	std_logic;
		btnD_i				: in	std_logic;

		led_o				: out	std_logic_vector(15 downto 0);
		anode_o				: out	std_logic_vector(7 downto 0);
		cathode_o			: out	std_logic_vector(6 downto 0)
	);
end nexys4_tetris_demo;



architecture Behavioral of nexys4_tetris_demo is

	signal reset_i			: std_logic;

	-- vga signals
	signal counter_prescale : std_logic_vector(1 downto 0);
	signal vga_pixel_clock	: std_logic;

	signal led				: std_logic_vector(15 downto 0);
	signal pwm_count		: std_logic;
begin
	-- board reset is active low
	reset_i					<= not reset_low_i;


	-- prescale the main clock to obtain the "pixel clock"
	-- /4 for nexys 4
	Inst_counter_pixelclockprescale: entity work.counter_until
	generic map				(width => 2)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		count_enable_i		=> '1',
		reset_when_i		=> "11",
		count_o				=> counter_prescale,
		overflow_o			=> vga_pixel_clock
	);

	Inst_tetris:			entity work.tetris
	generic map
	(
		vga_red_width		=> 4,
		vga_green_width		=> 4,
		vga_blue_width		=> 4
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,

		vga_pixel_clock_i	=> vga_pixel_clock,
		hsync_o				=> hsync_o,
		vsync_o				=> vsync_o,
		vga_red_o			=> vga_red_o,
		vga_green_o			=> vga_green_o,
		vga_blue_o			=> vga_blue_o,
		
		switches_i			=> switches_i,
		btnL_i				=> btnL_i,
		btnR_i				=> btnR_i,
		btnU_i				=> btnU_i,
		btnD_i				=> btnD_i
	);
	
	-- dim LEDs

	process(clock_i)
	begin
		if rising_edge (clock_i) then
			pwm_count <= not pwm_count;
		end if;
	end process;

	with pwm_count select led_o <=
		led				when '0',
		(others => '0')	when others;

	-- assign debug signals

	anode_o					<= (others => '1');
	cathode_o				<= (others => '0');
	
end Behavioral;
