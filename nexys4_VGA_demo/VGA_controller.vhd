library ieee;
use     ieee.std_logic_1164.all;



entity VGA_controller is
	generic
	(
		row_width			: integer := 9;
		column_width		: integer := 10
	);
	port
	(
		clock_i				: in	std_logic;
		reset_i				: in	std_logic;
		pixelclock_i		: in	std_logic;

		vsync_o				: out	std_logic;
		hsync_o				: out	std_logic;
		col_o				: out	std_logic_vector(column_width - 1 downto 0);
		row_o				: out	std_logic_vector(row_width - 1 downto 0);
		en_draw_o			: out	std_logic;

		screen_end_o		: out	std_logic;
		off_screen_o		: out	std_logic
	);
end VGA_controller;



architecture Behavioral of VGA_controller is

	signal colclock			: std_logic; -- aka. pixel clock
	signal rowclock			: std_logic;

	signal counter_prescale : std_logic_vector(1 downto 0);
	signal row				: std_logic_vector(row_width - 1 downto 0);
	signal col				: std_logic_vector(column_width - 1 downto 0);

	signal en_draw_row		: std_logic;
	signal en_draw_col		: std_logic;

begin

	-- export signals
	row_o					<= row;
	col_o					<= col;
	-- draw only when both HSYNC and VSYNC modules say so
	en_draw_o				<= en_draw_row and en_draw_col;
	-- we are off screen when en_draw_row goes 0
	Inst_FED:				entity work.falling_edge_detector
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		input_i				=> en_draw_row,
		output_o			=> off_screen_o
	);


	colclock				<= pixelclock_i;



	Inst_hsync:				entity work.sync_generator
	generic map
	(
		t_display			=> 640,
		t_fp				=> 16,
		t_bp				=> 48,
		t_pw				=> 96,
		counter_width		=> column_width
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> colclock,
		sync_o				=> hsync_o,
		sig_cycle_o			=> rowclock,
		en_draw_o			=> en_draw_col,
		pixel_pos_o			=> col
	);


	Inst_vsync:				entity work.sync_generator
	generic map
	(
		t_display			=> 480,
		t_fp				=> 10, --10,
		t_bp				=> 29, --29,
		t_pw				=> 2,
		counter_width		=> row_width
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> rowclock,
		sync_o				=> vsync_o,
		sig_cycle_o			=> screen_end_o,
		en_draw_o			=> en_draw_row,
		pixel_pos_o			=> row
	);

end Behavioral;
