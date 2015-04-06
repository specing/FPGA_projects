library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;

use     work.definitions        .all;



entity tetris is
	generic
	(
		vga_row_width		: integer := 10;
		vga_column_width	: integer := 10
	);
	port
	(
		clock_i					: in	std_logic;
		reset_i					: in	std_logic;

		vga_pixel_clock_i		: in	std_logic;
		hsync_o					: out	std_logic;
		vsync_o					: out	std_logic;
		vga_red_o				: out	std_logic_vector (vga_red_width   - 1 downto 0);
		vga_green_o				: out	std_logic_vector (vga_green_width - 1 downto 0);
		vga_blue_o				: out	std_logic_vector (vga_blue_width  - 1 downto 0);

		active_operation_i		: in	active_tetrimino_operations;
		active_operation_ack_o	: out	std_logic
	);
end tetris;



architecture Behavioral of tetris is

	constant line_remove_counter_width	: integer := 5;

	signal vga_hsync					: std_logic;
	signal vga_vsync					: std_logic;
	signal vga_column					: std_logic_vector (vga_column_width - 1 downto 0);
	signal vga_row						: std_logic_vector (vga_row_width    - 1 downto 0);
	signal vga_enable_draw				: std_logic;
	signal vga_screen_end				: std_logic;
	signal vga_off_screen				: std_logic;

	-- pipeline stuff
	signal on_tetris_surface			: std_logic;

	signal stage1_vga_hsync				: std_logic;
	signal stage1_vga_vsync				: std_logic;
	signal stage1_vga_column			: std_logic_vector (vga_column_width - 1 downto 0);
	signal stage1_vga_row				: std_logic_vector (vga_row_width    - 1 downto 0);
	signal stage1_vga_enable_draw		: std_logic;
	signal stage1_vga_off_screen		: std_logic;
	signal stage1_tetrimino_shape		: std_logic_vector (tetrimino_shape_width - 1 downto 0);
	signal stage1_row_elim_data_out		: std_logic_vector (4 downto 0);
	signal stage1_line_remove_counter	: std_logic_vector (line_remove_counter_width - 1 downto 0);

	signal stage2_vga_hsync				: std_logic;
	signal stage2_vga_vsync				: std_logic;
	signal stage2_vga_column			: std_logic_vector (vga_column_width - 1 downto 0);
	signal stage2_vga_row				: std_logic_vector (vga_row_width    - 1 downto 0);
	signal stage2_vga_enable_draw		: std_logic;
	signal stage2_tetrimino_shape		: std_logic_vector (tetrimino_shape_width - 1 downto 0);
	signal stage2_row_elim_data_out		: std_logic_vector (4 downto 0);
	signal stage2_line_remove_counter	: std_logic_vector (line_remove_counter_width - 1 downto 0);
	signal stage2_block_red				: std_logic_vector (vga_red_width   - 1 downto 0);
	signal stage2_block_green			: std_logic_vector (vga_green_width - 1 downto 0);
	signal stage2_block_blue			: std_logic_vector (vga_blue_width  - 1 downto 0);

	signal stage3_vga_hsync				: std_logic;
	signal stage3_vga_vsync				: std_logic;
	signal stage3_vga_column			: std_logic_vector (vga_column_width - 1 downto 0);
	signal stage3_vga_row				: std_logic_vector (vga_row_width    - 1 downto 0);
	signal stage3_vga_enable_draw		: std_logic;
	signal stage3_tetrimino_shape		: std_logic_vector (tetrimino_shape_width - 1 downto 0);
	signal stage3_row_elim_data_out		: std_logic_vector (4 downto 0);
	signal stage3_line_remove_counter	: std_logic_vector (line_remove_counter_width - 1 downto 0);
	signal stage3_block_red				: std_logic_vector (vga_red_width   - 1 downto 0);
	signal stage3_block_green			: std_logic_vector (vga_green_width - 1 downto 0);
	signal stage3_block_blue			: std_logic_vector (vga_blue_width  - 1 downto 0);
	signal stage3_block_final_red		: std_logic_vector (vga_red_width   - 1 downto 0);
	signal stage3_block_final_green		: std_logic_vector (vga_green_width - 1 downto 0);
	signal stage3_block_final_blue		: std_logic_vector (vga_blue_width  - 1 downto 0);

	signal stage4_vga_hsync				: std_logic;
	signal stage4_vga_vsync				: std_logic;
	signal stage4_vga_column			: std_logic_vector (vga_column_width - 1 downto 0);
	signal stage4_vga_row				: std_logic_vector (vga_row_width    - 1 downto 0);
	signal stage4_vga_enable_draw		: std_logic;
	signal stage4_tetrimino_shape		: std_logic_vector (tetrimino_shape_width - 1 downto 0);
	signal stage4_line_remove_counter	: std_logic_vector (line_remove_counter_width - 1 downto 0);
	signal stage4_block_red				: std_logic_vector (vga_red_width   - 1 downto 0);
	signal stage4_block_green			: std_logic_vector (vga_green_width - 1 downto 0);
	signal stage4_block_blue			: std_logic_vector (vga_blue_width  - 1 downto 0);

begin

	Inst_VGA_controller:	entity work.VGA_controller
	GENERIC MAP
	(
		row_width			=> vga_row_width,
		column_width		=> vga_column_width
	)
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		pixelclock_i		=> vga_pixel_clock_i,

		hsync_o				=> vga_hsync,
		vsync_o				=> vga_vsync,
		col_o				=> vga_column,
		row_o				=> vga_row,
		en_draw_o			=> vga_enable_draw,

		screen_end_o		=> vga_screen_end,
		off_screen_o		=> vga_off_screen
	);


	-------------------------------------------------------
	----------------- Rendering pipeline ------------------
	-------------------------------------------------------
	-- Stage1: save  row, column, hsync, vsync and en_draw from the VGA module
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage1_vga_hsync		<= vga_hsync;
			stage1_vga_vsync		<= vga_vsync;
			stage1_vga_column		<= vga_column;
			stage1_vga_row			<= vga_row;
			stage1_vga_enable_draw	<= vga_enable_draw;
			stage1_vga_off_screen	<= vga_off_screen;
		end if;
	end process;

	-- obtain the block descriptor given row and column
	Inst_tetris_block:				entity work.tetris_block
	port map
	(
		clock_i						=> clock_i,
		reset_i						=> reset_i,

		row_elim_data_o				=> stage1_row_elim_data_out,
		tetrimino_shape_o			=> stage1_tetrimino_shape,
		block_row_i					=> stage1_vga_row (8 downto 4),
		block_column_i				=> stage1_vga_column (7 downto 4),

		screen_finished_render_i	=> stage1_vga_off_screen,
		active_operation_i			=> active_operation_i,
		active_operation_ack_o		=> active_operation_ack_o
	);

	-- Stage2: save row, column, hsync, vsync, en_draw + block desc, line remove
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage2_vga_hsync		<= stage1_vga_hsync;
			stage2_vga_vsync		<= stage1_vga_vsync;
			stage2_vga_column		<= stage1_vga_column;
			stage2_vga_row			<= stage1_vga_row;
			stage2_vga_enable_draw	<= stage1_vga_enable_draw;
			stage2_tetrimino_shape	<= stage1_tetrimino_shape;
			stage2_row_elim_data_out<= stage1_row_elim_data_out;
		end if;
	end process;

	-- obtain block colour from block descriptor
	with stage2_tetrimino_shape select stage2_block_red <=
		X"0" when tetrimino_shape_pipe,
		X"0" when tetrimino_shape_L_left,
		X"F" when tetrimino_shape_L_right,
		X"F" when tetrimino_shape_Z_left,
		X"0" when tetrimino_shape_Z_right,
		X"F" when tetrimino_shape_T,
		X"F" when tetrimino_shape_square,
		X"0" when others;
	with stage2_tetrimino_shape select stage2_block_green <=
		X"F" when tetrimino_shape_pipe,
		X"0" when tetrimino_shape_L_left,
		X"A" when tetrimino_shape_L_right,
		X"0" when tetrimino_shape_Z_left,
		X"F" when tetrimino_shape_Z_right,
		X"0" when tetrimino_shape_T,
		X"F" when tetrimino_shape_square,
		X"0" when others;
	with stage2_tetrimino_shape select stage2_block_blue <=
		X"F" when tetrimino_shape_pipe,
		X"F" when tetrimino_shape_L_left,
		X"0" when tetrimino_shape_L_right,
		X"0" when tetrimino_shape_Z_left,
		X"0" when tetrimino_shape_Z_right,
		X"F" when tetrimino_shape_T,
		X"0" when tetrimino_shape_square,
		X"0" when others;

	-- Stage3: save row, column, hsync, vsync and en_draw + block desc, RGB of block, line remove
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage3_vga_hsync		<= stage2_vga_hsync;
			stage3_vga_vsync		<= stage2_vga_vsync;
			stage3_vga_column		<= stage2_vga_column;
			stage3_vga_row			<= stage2_vga_row;
			stage3_vga_enable_draw	<= stage2_vga_enable_draw;

			stage3_row_elim_data_out<= stage2_row_elim_data_out;
			stage3_block_red		<= stage2_block_red;
			stage3_block_green		<= stage2_block_green;
			stage3_block_blue		<= stage2_block_blue;
		end if;
	end process;

	stage3_block_final_red			<= stage3_block_red   or stage3_row_elim_data_out(4 downto 1);
	stage3_block_final_green		<= stage3_block_green or stage3_row_elim_data_out(4 downto 1);
	stage3_block_final_blue			<= stage3_block_blue  or stage3_row_elim_data_out(4 downto 1);


	-- Stage4: save row, column, hsync, vsync and en_draw + block desc, final RGB of block, line remove
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage4_vga_hsync		<= stage3_vga_hsync;
			stage4_vga_vsync		<= stage3_vga_vsync;
			stage4_vga_column		<= stage3_vga_column;
			stage4_vga_row			<= stage3_vga_row;
			stage4_vga_enable_draw	<= stage3_vga_enable_draw;

			stage4_block_red		<= stage3_block_final_red;
			stage4_block_green		<= stage3_block_final_green;
			stage4_block_blue		<= stage3_block_final_blue;
		end if;
	end process;

	hsync_o							<= stage4_vga_hsync;
	vsync_o							<= stage4_vga_vsync;

	-- column must be from 0 to 16 * 16 - 1 =  0 .. 256 - 1 = 0 .. 255
	-- row must be from 0 to 30 * 16 - 1 = 0 .. 480 - 1 = 0 .. 479
	with stage4_vga_column(vga_column_width - 1 downto 8) select on_tetris_surface <=
		'1' when "00",
		'0' when others;

	-- ==========================
	-- figure out what to display
	-- ==========================

	-- main draw multiplexer
	process
	(
		stage4_vga_enable_draw,	stage4_vga_column, stage4_vga_row,
		on_tetris_surface, stage4_block_red, stage4_block_green, stage4_block_blue
	)
	begin
		-- check if we are on display surface
		if stage4_vga_enable_draw = '0' then
			vga_red_o				<= "0000";
			vga_green_o				<= "0000";
			vga_blue_o				<= "0000";
		-- check if we have to draw static lines
		elsif stage4_vga_column = std_logic_vector(to_unsigned(256, stage4_vga_column'length)) -- right of tetris
		or stage4_vga_column = std_logic_vector(to_unsigned(0,   stage4_vga_column'length))
		or stage4_vga_column = std_logic_vector(to_unsigned(639, stage4_vga_column'length))
		or stage4_vga_row    = std_logic_vector(to_unsigned(0,   stage4_vga_row'length))
		or stage4_vga_row    = std_logic_vector(to_unsigned(479, stage4_vga_row'length))
		then
			vga_red_o				<= "1000";
			vga_green_o				<= "0000";
			vga_blue_o				<= "0100";
		-- check if we are on the tetris block surface
		elsif on_tetris_surface = '1' then
			vga_red_o				<= stage4_block_red;
			vga_green_o				<= stage4_block_green;
			vga_blue_o				<= stage4_block_blue;
		-- else don't draw anything.
		else
			vga_red_o				<= "0000";
			vga_green_o				<= "0000";
			vga_blue_o				<= "0000";
		end if;
	end process;

end Behavioral;
