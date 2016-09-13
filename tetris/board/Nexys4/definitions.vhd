library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

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
        --
        package vga is
            constant refresh_rate : natural := 60; -- Hz
        end package vga;

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
--              colours : colours.object;
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



    constant score_count_width : integer := 32;
    subtype score_count_type is std_logic_vector (score_count_width - 1 downto 0);

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
                  row => row.object (to_unsigned (0, row.width)),
                  col => col.object (to_unsigned (0, col.width))
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
            -- This constant is supposed to behave like 'high for std_logic: "11111"
            -- 'high for std_logic_vector is instead the high array index
            constant high : object := object (to_unsigned (2**width -1, width));

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



    package letter is
        -- generated by
        -- sed -e "s/.*letter.//" < file  | sed -e "s/ .*/ /" | tr '\n' ','
        -- where file is a copy&paste list of font_data below
        type object is (
          space, exclam, percent,
          zero, one, two, three, four, five, six, seven, eight, nine,
          colon,
          A_upper, B_upper, C_upper, D_upper, E_upper, F_upper, G_upper, H_upper, I_upper,
          J_upper, K_upper, L_upper, M_upper, N_upper, O_upper, P_upper, Q_upper, R_upper,
          S_upper, T_upper, U_upper, V_upper, W_upper, X_upper, Y_upper, Z_upper,
          a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
        );


    end package letter;



    package font is
        -- real font package, externally generated
        alias data is work.uni_vga;
        -- addressed first by row (4 bit) then by column (3 bit)
        -- total 2**7 = 128 dots per letter
        package row is
            constant width : natural := util.compute_width (data.character_height);
            subtype object is std_logic_vector (width - 1 downto 0);
        end package row;

        package column is
            constant width : natural := util.compute_width (data.character_width);
            subtype object is std_logic_vector (width - 1 downto 0);
        end package column;
        -- as usual, a helpful alias
        alias col is column;

        package address is
            type object is record
                row : row.object;
                col : column.object;
            end record;
        end package address;

        -- mapping from letters to dots
        function get_dot (l : in letter.object;
                          r : in row.object;
                          c : in col.object
                         ) return std_logic;

        type font_storage is array (letter.object'low to letter.object'high) of data.pixel_rows;

        -- TODO: UNI-VGA should probably be read by VHDL's text_io,
        -- then both this mapping and the constants in uni_vga.vhd
        -- automatically generated in memory.
        -- generated by
        -- grep constant uni_vga.vhd | \
        --   sed -e "s/.*constant /          letter.               => data./" | \
        --   sed -e "s/ : .*//" | less
        -- followed by some filling in the blanks
        constant font_data : font_storage := (
          letter.space          => data.glyph_for_20_space,
          letter.exclam         => data.glyph_for_21_exclam,
          letter.percent        => data.glyph_for_25_percent,

          letter.zero           => data.glyph_for_30_zero,
          letter.one            => data.glyph_for_31_one,
          letter.two            => data.glyph_for_32_two,
          letter.three          => data.glyph_for_33_three,
          letter.four           => data.glyph_for_34_four,
          letter.five           => data.glyph_for_35_five,
          letter.six            => data.glyph_for_36_six,
          letter.seven          => data.glyph_for_37_seven,
          letter.eight          => data.glyph_for_38_eight,
          letter.nine           => data.glyph_for_39_nine,
          letter.colon          => data.glyph_for_3a_colon,

          letter.A_upper        => data.glyph_for_41_A,
          letter.B_upper        => data.glyph_for_42_B,
          letter.C_upper        => data.glyph_for_43_C,
          letter.D_upper        => data.glyph_for_44_D,
          letter.E_upper        => data.glyph_for_45_E,
          letter.F_upper        => data.glyph_for_46_F,
          letter.G_upper        => data.glyph_for_47_G,
          letter.H_upper        => data.glyph_for_48_H,
          letter.I_upper        => data.glyph_for_49_I,
          letter.J_upper        => data.glyph_for_4a_J,
          letter.K_upper        => data.glyph_for_4b_K,
          letter.L_upper        => data.glyph_for_4c_L,
          letter.M_upper        => data.glyph_for_4d_M,
          letter.N_upper        => data.glyph_for_4e_N,
          letter.O_upper        => data.glyph_for_4f_O,
          letter.P_upper        => data.glyph_for_50_P,
          letter.Q_upper        => data.glyph_for_51_Q,
          letter.R_upper        => data.glyph_for_52_R,
          letter.S_upper        => data.glyph_for_53_S,
          letter.T_upper        => data.glyph_for_54_T,
          letter.U_upper        => data.glyph_for_55_U,
          letter.V_upper        => data.glyph_for_56_V,
          letter.W_upper        => data.glyph_for_57_W,
          letter.X_upper        => data.glyph_for_58_X,
          letter.Y_upper        => data.glyph_for_59_Y,
          letter.Z_upper        => data.glyph_for_5a_Z,

          letter.a              => data.glyph_for_61_a,
          letter.b              => data.glyph_for_62_b,
          letter.c              => data.glyph_for_63_c,
          letter.d              => data.glyph_for_64_d,
          letter.e              => data.glyph_for_65_e,
          letter.f              => data.glyph_for_66_f,
          letter.g              => data.glyph_for_67_g,
          letter.h              => data.glyph_for_68_h,
          letter.i              => data.glyph_for_69_i,
          letter.j              => data.glyph_for_6a_j,
          letter.k              => data.glyph_for_6b_k,
          letter.l              => data.glyph_for_6c_l,
          letter.m              => data.glyph_for_6d_m,
          letter.n              => data.glyph_for_6e_n,
          letter.o              => data.glyph_for_6f_o,
          letter.p              => data.glyph_for_70_p,
          letter.q              => data.glyph_for_71_q,
          letter.r              => data.glyph_for_72_r,
          letter.s              => data.glyph_for_73_s,
          letter.t              => data.glyph_for_74_t,
          letter.u              => data.glyph_for_75_u,
          letter.v              => data.glyph_for_76_v,
          letter.w              => data.glyph_for_77_w,
          letter.x              => data.glyph_for_78_x,
          letter.y              => data.glyph_for_79_y,
          letter.z              => data.glyph_for_7a_z
        );
    end package font;



    package letters is
        -- How much text do we have to store? Whole screen is 640x480 further divided
        -- into 16x16 blocks. Therefore there are 40 x 30 such blocks.
        -- However, a letter box is 16x8, meaning we have to store 80 x 30 such letter boxes
        -- from which we can deduce the size of row/col address lines
        package row is
            constant num_chars : natural := 480 / 16;
            constant width     : natural := util.compute_width (num_chars - 1);
            subtype object is std_logic_vector (width - 1 downto 0);
        end package row;

        package column is
            constant num_chars : natural := 640 / 16 * 2;
            constant width     : natural := util.compute_width (num_chars - 1);
            subtype object is std_logic_vector (width - 1 downto 0);
        end package column;
        -- as usual, a helpful alias
        alias col is column;

        package address is
            -- Now we can define the address types
            type object is record
                row : row.object;
                col : col.object;
            end record;

            package combined is
                -- and further, the total address width
                constant width : natural := row.width + column.width;
                -- and a combined storage object
                subtype object is std_logic_vector (width - 1 downto 0);

                function to_combined (o : address.object) return object;
            end package combined;
        end package address;

        -- and the storage RAM/ROM type
--        package storage is
--            type sobject is array (0 to (2 ** address.combined.width) - 1) of letter.object;
--        end package storage;
    end package letters;

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
--                  return input (input'left downto input'left - object'left);
                    return input (object'range);
                end to_compat;
            end package body vga_compat;
        end package body row_elim;
    end package body tetris;


    package body font is
        function get_dot (l : in letter.object;
                          r : in row.object;
                          c : in col.object
                         ) return std_logic is
            constant prows : data.pixel_rows := font_data (l);
            constant prow  : data.pixel_row  := prows (to_integer (r));
        begin
            return prow (to_integer (c));
        end get_dot;
    end package body font;


    package body letters is
        package body address is
            package body combined is
                function to_combined (o : address.object) return object is
                begin
                    return o.row & o.col;
                end;
            end package body combined;
        end package body address;
    end package body letters;

end package body definitions;
