library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;

use     work.definitions        .all;



entity tetris_render_pipeline is
	port
	(
		clock_i					: in	std_logic;
		reset_i					: in	std_logic;

		vga_pixel_clock_i		: in	std_logic;
		display                 : out   VGA.display.object;

		active_operation_i		: in	active_tetrimino_operations;
		active_operation_ack_o	: out	std_logic;

		cathodes_o				: out	std_logic_vector(6 downto 0);
		anodes_o				: out	std_logic_vector(7 downto 0)
	);
end tetris_render_pipeline;



architecture Behavioral of tetris_render_pipeline is

	signal vga_sync                     : VGA.sync.object;
	signal vga_pixel_address            : vga.pixel.address.object;
	signal vga_enable_draw				: std_logic;
	signal vga_screen_end				: std_logic;
	signal vga_off_screen				: std_logic;

	-- pipeline stuff
	signal on_tetris_surface			: std_logic;

	signal stage1_vga_sync              : VGA.sync.object;
	signal stage1_vga_pixel_address     : vga.pixel.address.object;
	signal stage1_vga_enable_draw		: std_logic;
	signal stage1_vga_off_screen		: std_logic;
	signal stage1_tetrimino_shape		: tetrimino_shape_type;
	signal stage1_row_elim_data_out     : tetris.row_elim.vga_compat.object;

	signal stage2_vga_sync              : VGA.sync.object;
	signal stage2_vga_pixel_address     : vga.pixel.address.object;
	signal stage2_vga_enable_draw		: std_logic;
	signal stage2_tetrimino_shape		: tetrimino_shape_type;
	signal stage2_row_elim_data_out     : tetris.row_elim.vga_compat.object;
	signal stage2_block_colours         : VGA.colours.object;

	signal stage3_vga_sync              : VGA.sync.object;
	signal stage3_vga_pixel_address     : vga.pixel.address.object;
	signal stage3_vga_enable_draw		: std_logic;
	signal stage3_tetrimino_shape		: tetrimino_shape_type;
	signal stage3_row_elim_data_out     : tetris.row_elim.vga_compat.object;
	signal stage3_block_colours         : VGA.colours.object;
	signal stage3_block_final_colours   : VGA.colours.object;

	signal stage4_vga_sync              : VGA.sync.object;
	signal stage4_vga_pixel_address     : vga.pixel.address.object;
	signal stage4_block_colours         : VGA.colours.object;
	signal stage4_vga_enable_draw		: std_logic;
	signal stage4_tetrimino_shape		: tetrimino_shape_type;

	signal score_count					: score_count_type;

	signal tetrimino_shape_next         : tetrimino_shape_type;
begin

	Inst_VGA_controller:	entity work.VGA_controller
	GENERIC MAP
	(
		row_width			=> vga.pixel.row.width,
		column_width		=> vga.pixel.column.width
	)
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		pixelclock_i		=> vga_pixel_clock_i,

		hsync_o             => vga_sync.h,
		vsync_o             => vga_sync.v,
		col_o               => vga_pixel_address.col,
		row_o               => vga_pixel_address.row,
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
			stage1_vga_sync         <= vga_sync;
			stage1_vga_pixel_address<= vga_pixel_address;
			stage1_vga_enable_draw	<= vga_enable_draw;
			stage1_vga_off_screen	<= vga_off_screen;
		end if;
	end process;

	Inst_tetris_next_tetrimino:     entity work.tetris_next_tetrimino
	port map
	(
		clock_i                     => clock_i,
		reset_i                     => reset_i,
		-- for next tetrimino selection (random)
		tetrimino_shape_next_o      => tetrimino_shape_next
	);

	-- obtain the block descriptor given row and column
	Inst_tetris_block:				entity work.tetris_block
	port map
	(
		clock_i						=> clock_i,
		reset_i						=> reset_i,

		row_elim_data_o				=> stage1_row_elim_data_out,
		tetrimino_shape_o			=> stage1_tetrimino_shape,
		block_render_address_i.row  => stage1_vga_pixel_address.row (8 downto 4),
		block_render_address_i.col  => stage1_vga_pixel_address.col (7 downto 4),
		-- for next tetrimino selection (random)
		tetrimino_shape_next_i      => tetrimino_shape_next,

		screen_finished_render_i	=> stage1_vga_off_screen,
		active_operation_i			=> active_operation_i,
		active_operation_ack_o		=> active_operation_ack_o,

		score_count_o				=> score_count
	);

	-- Stage2: save row, column, hsync, vsync, en_draw + block desc, line remove
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage2_vga_sync         <= stage1_vga_sync;
			stage2_vga_pixel_address<= stage1_vga_pixel_address;
			stage2_vga_enable_draw	<= stage1_vga_enable_draw;
			stage2_tetrimino_shape	<= stage1_tetrimino_shape;
			stage2_row_elim_data_out<= stage1_row_elim_data_out;
		end if;
	end process;

	-- obtain colour from tetrimino shape
	get_colour (stage2_tetrimino_shape, stage2_block_colours.red, stage2_block_colours.green, stage2_block_colours.blue);

	-- Stage3: save row, column, hsync, vsync and en_draw + block desc, RGB of block, line remove
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage3_vga_sync         <= stage2_vga_sync;
			stage3_vga_pixel_address<= stage2_vga_pixel_address;
			stage3_vga_enable_draw	<= stage2_vga_enable_draw;

			stage3_row_elim_data_out<= stage2_row_elim_data_out;
			stage3_block_colours    <= stage2_block_colours;
		end if;
	end process;

	-- Merge row elimination colours
	stage3_block_final_colours.red   <= stage3_block_colours.red   or stage3_row_elim_data_out(4 downto 1);
	stage3_block_final_colours.green <= stage3_block_colours.green or stage3_row_elim_data_out(4 downto 1);
	stage3_block_final_colours.blue  <= stage3_block_colours.blue  or stage3_row_elim_data_out(4 downto 1);

	-- Stage4: save row, column, hsync, vsync and en_draw + block desc, final RGB of block, line remove
	process (clock_i)
	begin
		if rising_edge (clock_i) then
			stage4_vga_sync         <= stage3_vga_sync;
			stage4_vga_pixel_address<= stage3_vga_pixel_address;
			stage4_vga_enable_draw	<= stage3_vga_enable_draw;

			stage4_block_colours    <= stage3_block_final_colours;
		end if;
	end process;

	-- column must be from 0 to 16 * 16 - 1 =  0 .. 256 - 1 = 0 .. 255
	-- row must be from 0 to 30 * 16 - 1 = 0 .. 480 - 1 = 0 .. 479
	with stage4_vga_pixel_address.col(stage4_vga_pixel_address.col'length - 1 downto 8) select on_tetris_surface <=
		'1' when "00",
		'0' when others;

	-- ==========================
	-- figure out what to display
	-- ==========================
	display.sync <= stage4_vga_sync;
	-- main draw multiplexer
	process
	(
		stage4_vga_enable_draw, stage4_vga_pixel_address, stage4_block_colours,
		on_tetris_surface
	)
	begin
		-- check if we are on display surface
		if stage4_vga_enable_draw = '0' then
			display.c       <= vga.colours.all_off;
		-- check if we have to draw static lines
		elsif stage4_vga_pixel_address.col = std_logic_vector(to_unsigned(255, stage4_vga_pixel_address.col'length))
		or stage4_vga_pixel_address.col = std_logic_vector(to_unsigned(0,   stage4_vga_pixel_address.col'length))
		or stage4_vga_pixel_address.col = std_logic_vector(to_unsigned(639, stage4_vga_pixel_address.col'length))
		or stage4_vga_pixel_address.row = std_logic_vector(to_unsigned(0,   stage4_vga_pixel_address.row'length))
		or stage4_vga_pixel_address.row = std_logic_vector(to_unsigned(479, stage4_vga_pixel_address.row'length))
		then
			display.c.red   <= "1000";
			display.c.green <= "0000";
			display.c.blue  <= "0100";
		-- check if we are on the tetris block surface
		elsif on_tetris_surface = '1' then
			display.c       <= stage4_block_colours;
		-- else don't draw anything.
		else
			display.c       <= vga.colours.all_off;
		end if;
	end process;

	-- show score count
	Inst_7seg:        entity work.seven_seg_display
	generic map
	(
		f_clock       => 100_000_000,
		num_of_digits => 8,
		dim_top       => 3,
		-- bit values for segment on
		-- Nexys 4's anodes are active low (have transistors for amplification)
		anode_on      => '0',
		-- Nexys 4's cathodes have A on right and inverted, but our seven_seg_digit has A on the left
		cathode_on    => '0'
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		bcd_digits_i		=> score_count,
		anodes_o			=> anodes_o,
		cathodes_o			=> cathodes_o
	);

end Behavioral;
