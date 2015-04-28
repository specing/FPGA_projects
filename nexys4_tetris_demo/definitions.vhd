library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;
use     ieee.math_real          .all;



package definitions is

	function compute_width (max : integer) return integer is
	begin return integer (CEIL (LOG2 (real (max) ) ) );
	end function compute_width;


	constant vga_red_width				: integer := 4;
	constant vga_green_width			: integer := 4;
	constant vga_blue_width				: integer := 4;


	type active_tetrimino_operations is
	(
		ATO_NONE,
		ATO_MOVE_DOWN,
		ATO_MOVE_LEFT,
		ATO_MOVE_RIGHT,
		ATO_ROTATE_CLOCKWISE,
		ATO_ROTATE_COUNTER_CLOCKWISE
	);

	constant number_of_rows             : integer := 30;
	constant number_of_columns          : integer := 16;
	constant row_width                  : integer := compute_width (number_of_rows    - 1);
	constant column_width               : integer := compute_width (number_of_columns - 1);

	subtype block_storage_row_type      is std_logic_vector (row_width    - 1 downto 0);
	subtype block_storage_column_type   is std_logic_vector (column_width - 1 downto 0);

	-- it seems Xilinx does not like creating ROMs with enums in them.
	type tetrimino_shape_type is array (2 downto 0) of bit;
	constant TETRIMINO_SHAPE_NONE       : tetrimino_shape_type := "000";
	constant TETRIMINO_SHAPE_PIPE       : tetrimino_shape_type := "001";
	constant TETRIMINO_SHAPE_L_LEFT     : tetrimino_shape_type := "010";
	constant TETRIMINO_SHAPE_L_RIGHT    : tetrimino_shape_type := "011";
	constant TETRIMINO_SHAPE_Z_LEFT     : tetrimino_shape_type := "100";
	constant TETRIMINO_SHAPE_Z_RIGHT    : tetrimino_shape_type := "101";
	constant TETRIMINO_SHAPE_T          : tetrimino_shape_type := "110";
	constant TETRIMINO_SHAPE_SQUARE     : tetrimino_shape_type := "111";

	procedure get_colour (
		shape: tetrimino_shape_type;
		signal red, green, blue : out std_logic_vector (3 downto 0) )
	is
	begin
		case shape is
		when TETRIMINO_SHAPE_NONE       => red <= X"0"; green <= X"0"; blue <= X"0";
		when TETRIMINO_SHAPE_PIPE       => red <= X"0"; green <= X"F"; blue <= X"F";
		when TETRIMINO_SHAPE_L_LEFT     => red <= X"0"; green <= X"0"; blue <= X"F";
		when TETRIMINO_SHAPE_L_RIGHT    => red <= X"F"; green <= X"A"; blue <= X"0";
		when TETRIMINO_SHAPE_Z_LEFT     => red <= X"F"; green <= X"0"; blue <= X"0";
		when TETRIMINO_SHAPE_Z_RIGHT    => red <= X"0"; green <= X"F"; blue <= X"0";
		when TETRIMINO_SHAPE_T          => red <= X"F"; green <= X"0"; blue <= X"F";
		when TETRIMINO_SHAPE_SQUARE     => red <= X"F"; green <= X"F"; blue <= X"0";
		end case;
	end procedure get_colour;

	-- default start positions
	constant default_pipe_row0			: block_storage_row_type := "00001";
	constant default_pipe_row1			: block_storage_row_type := "00001";
	constant default_pipe_row2			: block_storage_row_type := "00001";
	constant default_pipe_row3			: block_storage_row_type := "00001";
	constant default_pipe_column0		: block_storage_column_type := "0110";
	constant default_pipe_column1		: block_storage_column_type := "0111";
	constant default_pipe_column2		: block_storage_column_type := "1000";
	constant default_pipe_column3		: block_storage_column_type := "1001";

	constant default_L_left_row0		: block_storage_row_type := "00001";
	constant default_L_left_row1		: block_storage_row_type := "00010";
	constant default_L_left_row2		: block_storage_row_type := "00010";
	constant default_L_left_row3		: block_storage_row_type := "00010";
	constant default_L_left_column0		: block_storage_column_type := "0111";
	constant default_L_left_column1		: block_storage_column_type := "0111";
	constant default_L_left_column2		: block_storage_column_type := "1000";
	constant default_L_left_column3		: block_storage_column_type := "1001";

	constant default_L_right_row0		: block_storage_row_type := "00001";
	constant default_L_right_row1		: block_storage_row_type := "00010";
	constant default_L_right_row2		: block_storage_row_type := "00010";
	constant default_L_right_row3		: block_storage_row_type := "00010";
	constant default_L_right_column0	: block_storage_column_type := "1000";
	constant default_L_right_column1	: block_storage_column_type := "1000";
	constant default_L_right_column2	: block_storage_column_type := "0111";
	constant default_L_right_column3	: block_storage_column_type := "0110";

	constant default_square_row0		: block_storage_row_type := "00001";
	constant default_square_row1		: block_storage_row_type := "00001";
	constant default_square_row2		: block_storage_row_type := "00010";
	constant default_square_row3		: block_storage_row_type := "00010";
	constant default_square_column0		: block_storage_column_type := "0111";
	constant default_square_column1		: block_storage_column_type := "1000";
	constant default_square_column2		: block_storage_column_type := "1000";
	constant default_square_column3		: block_storage_column_type := "0111";

	constant default_Z_right_row0		: block_storage_row_type := "00010";
	constant default_Z_right_row1		: block_storage_row_type := "00010";
	constant default_Z_right_row2		: block_storage_row_type := "00001";
	constant default_Z_right_row3		: block_storage_row_type := "00001";
	constant default_Z_right_column0	: block_storage_column_type := "0110";
	constant default_Z_right_column1	: block_storage_column_type := "0111";
	constant default_Z_right_column2	: block_storage_column_type := "0111";
	constant default_Z_right_column3	: block_storage_column_type := "1000";

	constant default_Z_left_row0		: block_storage_row_type := "00001";
	constant default_Z_left_row1		: block_storage_row_type := "00001";
	constant default_Z_left_row2		: block_storage_row_type := "00010";
	constant default_Z_left_row3		: block_storage_row_type := "00010";
	constant default_Z_left_column0		: block_storage_column_type := "0111";
	constant default_Z_left_column1		: block_storage_column_type := "1000";
	constant default_Z_left_column2		: block_storage_column_type := "1000";
	constant default_Z_left_column3		: block_storage_column_type := "1001";

	constant default_T_row0				: block_storage_row_type := "00001";
	constant default_T_row1				: block_storage_row_type := "00010";
	constant default_T_row2				: block_storage_row_type := "00010";
	constant default_T_row3				: block_storage_row_type := "00010";
	constant default_T_column0			: block_storage_column_type := "0111";
	constant default_T_column1			: block_storage_column_type := "0110";
	constant default_T_column2			: block_storage_column_type := "0111";
	constant default_T_column3			: block_storage_column_type := "1000";

end package definitions;
