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

	constant score_count_width			: integer := 32;
	subtype score_count_type			is std_logic_vector(score_count_width - 1 downto 0);

	type active_tetrimino_operations is
	(
		ATO_NONE,
		ATO_DROP_DOWN,
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
	subtype tetrimino_shape_type        is std_logic_vector (2 downto 0);
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
		when others                     => report "Oops" severity FAILURE;
		end case;
	end procedure get_colour;



	subtype tetrimino_rotation_type     is std_logic_vector (1 downto 0);
	constant TETRIMINO_ROTATION_0       : tetrimino_rotation_type := "00";
	constant TETRIMINO_ROTATION_90      : tetrimino_rotation_type := "01";
	constant TETRIMINO_ROTATION_180     : tetrimino_rotation_type := "10";
	constant TETRIMINO_ROTATION_270     : tetrimino_rotation_type := "11";

	type corner_offset_enum is ( OFF0, OFF1, OFF2, OFF3 );
	function to_integer (offset: corner_offset_enum) return integer is
	begin
		case offset is
		when OFF0 => return 0;
		when OFF1 => return 1;
		when OFF2 => return 2;
		when OFF3 => return 3;
		end case;
	end function to_integer;

	-- first indexed by tetrimino_shape, then by tetrimino_rotation
	-- data is row0, row1, row2, row3, col0, col1, col2, col3
	type tetrimino_init_row is          array(0 to 7) of corner_offset_enum;
	-- 2**5 = 2**3 tetrimino shapes + 2**2 rotations
	type tetrimino_init_data is         array(0 to (2**5) - 1) of tetrimino_init_row;
	constant tetrimino_init_rom         : tetrimino_init_data := (
		-- tetrimino_empty: "000"
		(OFF0, OFF0, OFF0, OFF0,   OFF0, OFF0, OFF0, OFF0), -- rot0:   "00"
		(OFF0, OFF0, OFF0, OFF0,   OFF0, OFF0, OFF0, OFF0), -- rot90:  "01"
		(OFF0, OFF0, OFF0, OFF0,   OFF0, OFF0, OFF0, OFF0), -- rot180: "10"
		(OFF0, OFF0, OFF0, OFF0,   OFF0, OFF0, OFF0, OFF0), -- rot270: "11"

		-- tetrimino_pipe: "001"
		(OFF1, OFF1, OFF1, OFF1,   OFF0, OFF1, OFF2, OFF3), -- rot0:   "00"
		(OFF0, OFF1, OFF2, OFF3,   OFF2, OFF2, OFF2, OFF2), -- rot90:  "01"
		(OFF2, OFF2, OFF2, OFF2,   OFF3, OFF2, OFF1, OFF0), -- rot180: "10"
		(OFF3, OFF2, OFF1, OFF0,   OFF1, OFF1, OFF1, OFF1), -- rot270: "11"

		-- tetrimino_L_left: "010"
		(OFF1, OFF2, OFF2, OFF2,   OFF1, OFF1, OFF2, OFF3), -- rot0:   "00"
		(OFF1, OFF1, OFF2, OFF3,   OFF2, OFF1, OFF1, OFF1), -- rot90:  "01"
		(OFF2, OFF1, OFF1, OFF1,   OFF2, OFF2, OFF1, OFF0), -- rot180: "10"
		(OFF2, OFF2, OFF1, OFF0,   OFF1, OFF2, OFF2, OFF2), -- rot270: "11"

		-- tetrimino_L_right: "011"
		(OFF1, OFF2, OFF2, OFF2,   OFF2, OFF2, OFF1, OFF0), -- rot0:   "00"
		(OFF2, OFF2, OFF1, OFF0,   OFF2, OFF1, OFF1, OFF1), -- rot90:  "01"
		(OFF2, OFF1, OFF1, OFF1,   OFF1, OFF1, OFF2, OFF3), -- rot180: "10"
		(OFF1, OFF1, OFF2, OFF3,   OFF1, OFF2, OFF2, OFF2), -- rot270: "11"

		-- tetrimino_Z_left: "100"
		(OFF1, OFF1, OFF2, OFF2,   OFF1, OFF2, OFF2, OFF3), -- rot0:   "00"
		(OFF1, OFF2, OFF2, OFF3,   OFF2, OFF2, OFF1, OFF1), -- rot90:  "01"
		(OFF2, OFF2, OFF1, OFF1,   OFF2, OFF1, OFF1, OFF0), -- rot180: "10"
		(OFF2, OFF1, OFF1, OFF0,   OFF1, OFF1, OFF2, OFF2), -- rot270: "11"

		-- tetrimino_Z_right: "101"
		(OFF2, OFF2, OFF1, OFF1,   OFF0, OFF1, OFF1, OFF2), -- rot0:   "00"
		(OFF0, OFF1, OFF1, OFF2,   OFF1, OFF1, OFF2, OFF2), -- rot90:  "01"
		(OFF1, OFF1, OFF2, OFF2,   OFF3, OFF2, OFF2, OFF1), -- rot180: "10"
		(OFF3, OFF2, OFF2, OFF1,   OFF2, OFF2, OFF1, OFF1), -- rot270: "11"

		-- tetrimino_T: "110"
		(OFF1, OFF2, OFF2, OFF2,   OFF1, OFF0, OFF1, OFF2), -- rot0:   "00"
		(OFF1, OFF0, OFF1, OFF2,   OFF2, OFF1, OFF1, OFF1), -- rot90:  "01"
		(OFF2, OFF1, OFF1, OFF1,   OFF2, OFF3, OFF2, OFF1), -- rot180: "10"
		(OFF2, OFF3, OFF2, OFF1,   OFF1, OFF2, OFF2, OFF2), -- rot270: "11"

		-- tetrimino_square: "111"
		(OFF1, OFF1, OFF2, OFF2,   OFF1, OFF2, OFF2, OFF1), -- rot0:   "00"
		(OFF1, OFF2, OFF2, OFF1,   OFF2, OFF2, OFF1, OFF1), -- rot90:  "01"
		(OFF2, OFF2, OFF1, OFF1,   OFF2, OFF1, OFF1, OFF2), -- rot180: "10"
		(OFF2, OFF1, OFF1, OFF2,   OFF1, OFF1, OFF2, OFF2)  -- rot270: "11"
	);

	-- default start positions
	constant block_storage_start_row    : block_storage_row_type    := "00000";
	constant block_storage_start_column : block_storage_column_type := "0110";

end package definitions;
