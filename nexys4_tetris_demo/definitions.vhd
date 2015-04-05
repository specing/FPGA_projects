library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;



package definitions is

	constant vga_red_width				: integer := 4;
	constant vga_green_width			: integer := 4;
	constant vga_blue_width				: integer := 4;


	type active_tetrimino_operations is
	(
		ATO_NONE, ATO_MOVE_DOWN
	);

	-- tetrimino type
	constant tetrimino_shape_width		: integer := 3;
	constant tetrimino_shape_empty 		: std_logic_vector := std_logic_vector(to_unsigned(0, tetrimino_shape_width));
	-- ####
	constant tetrimino_shape_pipe	 	: std_logic_vector := std_logic_vector(to_unsigned(1, tetrimino_shape_width));
	-- #
	-- ###
	constant tetrimino_shape_L_left		: std_logic_vector := std_logic_vector(to_unsigned(2, tetrimino_shape_width));
	--   #
	-- ###
	constant tetrimino_shape_L_right 	: std_logic_vector := std_logic_vector(to_unsigned(3, tetrimino_shape_width));
	-- ##
	--  ##
	constant tetrimino_shape_Z_left 	: std_logic_vector := std_logic_vector(to_unsigned(4, tetrimino_shape_width));
	--  ##
	-- ##
	constant tetrimino_shape_Z_right 	: std_logic_vector := std_logic_vector(to_unsigned(5, tetrimino_shape_width));
	--  #
	-- ###
	constant tetrimino_shape_T			: std_logic_vector := std_logic_vector(to_unsigned(6, tetrimino_shape_width));
	-- ##
	-- ##
	constant tetrimino_shape_square		: std_logic_vector := std_logic_vector(to_unsigned(7, tetrimino_shape_width));

	-- default start positions
	constant default_pipe_row0			: std_logic_vector := "00001";
	constant default_pipe_row1			: std_logic_vector := "00001";
	constant default_pipe_row2			: std_logic_vector := "00001";
	constant default_pipe_row3			: std_logic_vector := "00001";
	constant default_pipe_column0		: std_logic_vector := "0110";
	constant default_pipe_column1		: std_logic_vector := "0111";
	constant default_pipe_column2		: std_logic_vector := "1000";
	constant default_pipe_column3		: std_logic_vector := "1001";

	constant default_L_left_row0		: std_logic_vector := "00001";
	constant default_L_left_row1		: std_logic_vector := "00010";
	constant default_L_left_row2		: std_logic_vector := "00010";
	constant default_L_left_row3		: std_logic_vector := "00010";
	constant default_L_left_column0		: std_logic_vector := "0111";
	constant default_L_left_column1		: std_logic_vector := "0111";
	constant default_L_left_column2		: std_logic_vector := "1000";
	constant default_L_left_column3		: std_logic_vector := "1001";

	constant default_L_right_row0		: std_logic_vector := "00001";
	constant default_L_right_row1		: std_logic_vector := "00010";
	constant default_L_right_row2		: std_logic_vector := "00010";
	constant default_L_right_row3		: std_logic_vector := "00010";
	constant default_L_right_column0	: std_logic_vector := "1000";
	constant default_L_right_column1	: std_logic_vector := "1000";
	constant default_L_right_column2	: std_logic_vector := "0111";
	constant default_L_right_column3	: std_logic_vector := "0110";

	constant default_square_row0		: std_logic_vector := "00001";
	constant default_square_row1		: std_logic_vector := "00001";
	constant default_square_row2		: std_logic_vector := "00010";
	constant default_square_row3		: std_logic_vector := "00010";
	constant default_square_column0		: std_logic_vector := "0111";
	constant default_square_column1		: std_logic_vector := "1000";
	constant default_square_column2		: std_logic_vector := "1000";
	constant default_square_column3		: std_logic_vector := "0111";

	constant default_Z_right_row0		: std_logic_vector := "00010";
	constant default_Z_right_row1		: std_logic_vector := "00010";
	constant default_Z_right_row2		: std_logic_vector := "00001";
	constant default_Z_right_row3		: std_logic_vector := "00001";
	constant default_Z_right_column0	: std_logic_vector := "0110";
	constant default_Z_right_column1	: std_logic_vector := "0111";
	constant default_Z_right_column2	: std_logic_vector := "0111";
	constant default_Z_right_column3	: std_logic_vector := "1000";

	constant default_Z_left_row0		: std_logic_vector := "00001";
	constant default_Z_left_row1		: std_logic_vector := "00001";
	constant default_Z_left_row2		: std_logic_vector := "00010";
	constant default_Z_left_row3		: std_logic_vector := "00010";
	constant default_Z_left_column0		: std_logic_vector := "0111";
	constant default_Z_left_column1		: std_logic_vector := "1000";
	constant default_Z_left_column2		: std_logic_vector := "1000";
	constant default_Z_left_column3		: std_logic_vector := "1001";

	constant default_T_row0				: std_logic_vector := "00001";
	constant default_T_row1				: std_logic_vector := "00010";
	constant default_T_row2				: std_logic_vector := "00010";
	constant default_T_row3				: std_logic_vector := "00010";
	constant default_T_column0			: std_logic_vector := "0111";
	constant default_T_column1			: std_logic_vector := "0110";
	constant default_T_column2			: std_logic_vector := "0111";
	constant default_T_column3			: std_logic_vector := "1000";

end package definitions;
