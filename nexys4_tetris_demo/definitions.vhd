library ieee;
use     ieee.std_logic_1164     .all;
use     ieee.std_logic_unsigned .all;
use     ieee.numeric_std        .all;

library flib;
use flib.util;



package definitions is

	-- Tetris configuration
	package config is
		-- VGA display
		constant red_width   : integer := 4;
		constant green_width : integer := 4;
		constant blue_width  : integer := 4;
		-- Must be enough to hold onscreen pixels + front/back porch + dead time
		constant vga_row_width    : integer := 10;
		constant vga_column_width : integer := 10;

		-- Tetris playing surface size
		constant number_of_rows    : positive := 30;
		constant number_of_columns : positive := 16;
		-- Tetrimino start position on the playing surface
		constant tetrimino_start_row    : natural := 0;
		constant tetrimino_start_column : natural := 6;
		-- Counter for visual effects when removing a full row
		constant row_elim_counter_width : natural := 5;
	end package config;


	-- SCREEN
	package VGA is
		package colours is
			-- One package for each colour channel
			package red is
				alias width is config.red_width;
				subtype object is std_logic_vector (width - 1 downto 0);
			end package red;

			package green is
				alias width is config.green_width;
				subtype object is std_logic_vector (width - 1 downto 0);
			end package green;

			package blue is
				alias width is config.blue_width;
				subtype object is std_logic_vector (width - 1 downto 0);
			end package blue;
			-- finaly the record combining all the colour channels
			type object is record
				red   : red.object;
				green : green.object;
				blue  : blue.object;
			end record;

			constant all_off : object := (
			  red   => (others => '0'),
			  green => (others => '0'),
			  blue  => (others => '0')
			);

			-- Object that is wide enough to store all colour channels
			package any is
				constant width : natural := maximum (red.width, maximum (green.width, blue.width));
			end package any;
		end package colours;


		package sync is
			type object is record
				h : std_logic;
				v : std_logic;
			end record;
		end package sync;


		package display is
			type object is record
				sync    : sync.object;
				-- TODO:c->colours proper alias?
--				colours : colours.object;
				c       : colours.object;
			end record;
		end package display;


		package pixel is
			package row is
				alias width is config.vga_row_width;
				subtype object is std_logic_vector (width - 1 downto 0);
			end package row;

			package column is
				alias width is config.vga_column_width;
				subtype object is std_logic_vector (width - 1 downto 0);
			end package column;
			-- short-hand alias
			alias col is column;

			package address is
				type object is record
					row : row.object;
					col : column.object;
				end record;
			end package address;
		end package pixel;
	end package VGA;



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

	package tetris is
		package storage is
			-- Seperate packages for row/column
			package row is
				constant max   : positive := config.number_of_rows - 1;
				constant width : positive := util.compute_width (max);
				-- Storage object
				subtype object is std_logic_vector (width - 1 downto 0);
			end package row;
			package column is
				constant max   : positive := config.number_of_columns - 1;
				constant width : positive := util.compute_width (max);
				-- Storage object
				subtype object is std_logic_vector (width - 1 downto 0);
			end package column;
			-- short-hand alias
			alias col is column;

			package address is
				type object is record
					row : row.object;
					col : column.object;
				end record;
				constant width : positive := row.width + column.width;
				constant all_zeros : object := (
				  row => "00000",
				  col => "0000"
				);
			end package address;
		end package storage;

		-- default start positions
		constant tetrimino_start_row : storage.row.object :=
		  storage.row.object (to_unsigned (config.tetrimino_start_row, storage.row.width));
		constant tetrimino_start_col : storage.col.object :=
		  storage.col.object (to_unsigned (config.tetrimino_start_column, storage.col.width));

		-- Full row elimination
		package row_elim is
			alias width is config.row_elim_counter_width;
			subtype object is std_logic_vector (width - 1 downto 0);
			package vga_compat is
				subtype object is std_logic_vector
				  (tetris.row_elim.width - 1 downto tetris.row_elim.width - vga.colours.any.width);

				-- A simple function to return the compatibility object (aka the top part)
				-- that is then merged with colours going to display
				function to_compat (input : tetris.row_elim.object) return object;
				-- ^ Implemented below in the package body
			end package vga_compat;
		end package row_elim;
	end package tetris;

	-- Compatibility aliases, will be removed shortly
	alias block_storage_row_type    is tetris.storage.row.object;
	alias block_storage_column_type is tetris.storage.column.object;

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
		signal red, green, blue : out std_logic_vector (3 downto 0)
	);


	subtype tetrimino_rotation_type     is std_logic_vector (1 downto 0);
	constant TETRIMINO_ROTATION_0       : tetrimino_rotation_type := "00";
	constant TETRIMINO_ROTATION_90      : tetrimino_rotation_type := "01";
	constant TETRIMINO_ROTATION_180     : tetrimino_rotation_type := "10";
	constant TETRIMINO_ROTATION_270     : tetrimino_rotation_type := "11";

	type corner_offset_enum is ( OFF0, OFF1, OFF2, OFF3 );
	function to_integer (offset: corner_offset_enum) return integer;

	-- first indexed by tetrimino_shape, then by tetrimino_rotation
	-- data is row0, row1, row2, row3, col0, col1, col2, col3
	-- and tells us which blocks relative to the "corner address" are filled
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

end package definitions;



package body definitions is

	procedure get_colour (
		shape: tetrimino_shape_type;
		signal red, green, blue : out std_logic_vector (3 downto 0)
	) is
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


	function to_integer (offset: corner_offset_enum) return integer is
	begin
		case offset is
		when OFF0 => return 0;
		when OFF1 => return 1;
		when OFF2 => return 2;
		when OFF3 => return 3;
		end case;
	end function to_integer;


	package body tetris is
		package body row_elim is
			package body vga_compat is
				function to_compat (input : tetris.row_elim.object) return object is
				begin
--					return input (input'left downto input'left - object'left);
					return input (object'range);
				end to_compat;
			end package body vga_compat;
		end package body row_elim;
	end package body tetris;

end package body definitions;
