library	ieee;
use		ieee.std_logic_1164		.all;
use		ieee.std_logic_unsigned	.all;
use		ieee.numeric_std		.all;



entity tetris is
	generic
	(
		vga_row_width		: integer := 10;
		vga_column_width	: integer := 10;

		vga_red_width		: integer;
		vga_green_width		: integer;
		vga_blue_width		: integer;

		num_of_buttons		: integer := 4
	);
	port
	(
		clock_i				: in	std_logic;
		reset_i				: in	std_logic;

		vga_pixel_clock_i	: in	std_logic;
		hsync_o				: out	std_logic;
		vsync_o				: out	std_logic;
		vga_red_o			: out	std_logic_vector (vga_red_width   - 1 downto 0);
		vga_green_o			: out	std_logic_vector (vga_green_width - 1 downto 0);
		vga_blue_o			: out	std_logic_vector (vga_blue_width  - 1 downto 0);
		
		switches_i			: in	std_logic_vector(15 downto 0);
		btnL_i				: in	std_logic;
		btnR_i				: in	std_logic;
		btnU_i				: in	std_logic;
		btnD_i				: in	std_logic
	);
end tetris;



architecture Behavioral of tetris is
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
	
	signal line_left					: std_logic_vector (vga_column_width - 1 downto 0);
	signal line_right					: std_logic_vector (vga_column_width - 1 downto 0);
	signal line_top						: std_logic_vector (vga_row_width - 1 downto 0);
	signal line_bottom					: std_logic_vector (vga_row_width - 1 downto 0);

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
	signal stage1_block_descriptor		: std_logic_vector (block_descriptor_width - 1 downto 0);
	signal stage1_row_elim_data_out		: std_logic_vector (4 downto 0);
	signal stage1_line_remove_counter	: std_logic_vector (line_remove_counter_width - 1 downto 0);

	signal stage2_vga_hsync				: std_logic;
	signal stage2_vga_vsync				: std_logic;
	signal stage2_vga_column			: std_logic_vector (vga_column_width - 1 downto 0);
	signal stage2_vga_row				: std_logic_vector (vga_row_width    - 1 downto 0);
	signal stage2_vga_enable_draw		: std_logic;
	signal stage2_block_descriptor		: std_logic_vector (block_descriptor_width - 1 downto 0);
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
	signal stage3_block_descriptor		: std_logic_vector (block_descriptor_width - 1 downto 0);
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
	signal stage4_block_descriptor		: std_logic_vector (block_descriptor_width - 1 downto 0);
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

		row_elim_data_out			=> stage1_row_elim_data_out,
		block_descriptor_o			=> stage1_block_descriptor,
		block_row_i					=> stage1_vga_row (8 downto 4),
		block_column_i				=> stage1_vga_column (7 downto 4),

		screen_finished_render_i	=> stage1_vga_off_screen
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
			stage2_block_descriptor	<= stage1_block_descriptor;
			stage2_row_elim_data_out<= stage1_row_elim_data_out;
		end if;
	end process;

	-- obtain block colour from block descriptor
	with stage2_block_descriptor select stage2_block_red <=
		X"0" when block_descriptor_pipe,
		X"0" when block_descriptor_L_left,
		X"F" when block_descriptor_L_right,
		X"F" when block_descriptor_Z_left,
		X"0" when block_descriptor_Z_right,
		X"F" when block_descriptor_T,
		X"F" when block_descriptor_square,
		X"0" when others;
	with stage2_block_descriptor select stage2_block_green <=
		X"F" when block_descriptor_pipe,
		X"0" when block_descriptor_L_left,
		X"A" when block_descriptor_L_right,
		X"0" when block_descriptor_Z_left,
		X"F" when block_descriptor_Z_right,
		X"0" when block_descriptor_T,
		X"F" when block_descriptor_square,
		X"0" when others;
	with stage2_block_descriptor select stage2_block_blue <=
		X"F" when block_descriptor_pipe,
		X"F" when block_descriptor_L_left,
		X"0" when block_descriptor_L_right,
		X"0" when block_descriptor_Z_left,
		X"0" when block_descriptor_Z_right,
		X"F" when block_descriptor_T,
		X"0" when block_descriptor_square,
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
			stage3_block_descriptor	<= stage2_block_descriptor;
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

			stage4_block_descriptor	<= stage3_block_descriptor;
			stage4_block_red		<= stage3_block_final_red;
			stage4_block_green		<= stage3_block_final_green;
			stage4_block_blue		<= stage3_block_final_blue;
		end if;
	end process;

	hsync_o				<= stage4_vga_hsync;
	vsync_o				<= stage4_vga_vsync;

	-- column must be from 0 to 16 * 16 - 1 =  0 .. 256 - 1 = 0 .. 255
	-- row must be from 0 to 30 * 16 - 1 = 0 .. 480 - 1 = 0 .. 479
	with stage4_vga_column(vga_column_width - 1 downto 8) select on_tetris_surface <=
		'1' when "00",
		'0' when others;

	-- ==========================
	-- figure out what to display
	-- ==========================

	-- 4 registers, each for the corresponding line
	Inst_GR_line_left:	entity work.generic_register
	GENERIC MAP
	(
		reset_value		=> 100
	)
	PORT MAP
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnL_i,
		data_i			=> switches_i (vga_column_width - 1 downto 0),
		data_o			=> line_left
	);

	Inst_GR_line_right:	entity work.generic_register
	GENERIC MAP
	(
		reset_value		=> 539
	)
	PORT MAP
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnR_i,
		data_i			=> switches_i (vga_column_width - 1 downto 0),
		data_o			=> line_right
	);

	Inst_GR_line_top:	entity work.generic_register
	GENERIC MAP
	(
		reset_value		=> 100
	)
	PORT MAP
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnU_i,
		data_i			=> switches_i (vga_row_width - 1 downto 0),
		data_o			=> line_top
	);

	Inst_GR_line_bottom:entity work.generic_register
	GENERIC MAP
	(
		reset_value		=> 379
	)
	PORT MAP
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnD_i,
		data_i			=> switches_i (vga_row_width - 1 downto 0),
		data_o			=> line_bottom
	);

	-- main draw multiplexer
	process
	(
		stage4_vga_enable_draw,	stage4_vga_column, stage4_vga_row,
		line_left, line_right, line_top, line_bottom,
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
		-- check if we have to draw dynamic (for testing) lines
		elsif stage4_vga_column = line_left   -- 0
		or    stage4_vga_column = line_right  -- 638
		or    stage4_vga_row    = line_top	  -- 5
		or    stage4_vga_row    = line_bottom -- 478
		then
			vga_red_o				<= "0011";
			vga_green_o				<= "1000";
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

--	GENERIC MAP (width => 16) PORT MAP
--	(
--		clock_i				=> clock_i,
--		reset_i				=> reset_i,
--		count_enable_i		=> vga_screen_end,
--		count_o				=> led
--	);

	
end Behavioral;
