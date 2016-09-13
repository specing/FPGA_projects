library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.definitions.all;



entity tetris_next_tetrimino is
    port
    (
        clock_i                 : in     std_logic;
        reset_i                 : in     std_logic;
        -- for Next Tetrimino selection (random)
        nt_shape_o              : out    tetrimino_shape_type;
        nt_retrieved_i          : in     std_logic;
        -- render pipeline
        render_shape_o          : out    tetrimino_shape_type;
        render_address_i        : in     vga.pixel.address.object
    );
end tetris_next_tetrimino;



architecture Behavioral of tetris_next_tetrimino is

    signal tetrimino_shape_next : tetrimino_shape_type := TETRIMINO_SHAPE_L_LEFT;

begin
    -- output asignments
    nt_shape_o <= tetrimino_shape_next;

    -- crude random
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if nt_retrieved_i = '1' then
                case tetrimino_shape_next is
                when "000" => tetrimino_shape_next <= "010";
                when "001" => tetrimino_shape_next <= "010";
                when "010" => tetrimino_shape_next <= "011";
                when "011" => tetrimino_shape_next <= "100";
                when "100" => tetrimino_shape_next <= "101";
                when "101" => tetrimino_shape_next <= "110";
                when "110" => tetrimino_shape_next <= "111";
                when "111" => tetrimino_shape_next <= "001";
                when others => report "Oops" severity FAILURE;
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------
    ---------- determine what to put on screen ------------
    -------------------------------------------------------
    Show_NT: block
        signal next_tetrimino_init_row  : tetrimino_init_row;

        type block_select_enum is (BLOCK0, BLOCK1, BLOCK2, BLOCK3);
        type block_rows is array (block_select_enum'low to block_select_enum'high) of
          std_logic_vector (1 downto 0);
        type block_cols is array (block_select_enum'low to block_select_enum'high) of
          std_logic_vector (1 downto 0);

        signal rows : block_rows;
        signal cols : block_cols;
    begin
        -- compute next tetrimino block addresses
        next_tetrimino_init_row <= tetrimino_init_rom (to_integer (
          tetrimino_shape_next & TETRIMINO_ROTATION_90));

        process (clock_i)
        begin
            if rising_edge (clock_i) then
                rows (BLOCK0)   <= To_SLV (to_integer (next_tetrimino_init_row (0)), 2);
                rows (BLOCK1)   <= To_SLV (to_integer (next_tetrimino_init_row (1)), 2);
                rows (BLOCK2)   <= To_SLV (to_integer (next_tetrimino_init_row (2)), 2);
                rows (BLOCK3)   <= To_SLV (to_integer (next_tetrimino_init_row (3)), 2);

                cols (BLOCK0)   <= To_SLV (to_integer (next_tetrimino_init_row (4)), 2);
                cols (BLOCK1)   <= To_SLV (to_integer (next_tetrimino_init_row (5)), 2);
                cols (BLOCK2)   <= To_SLV (to_integer (next_tetrimino_init_row (6)), 2);
                cols (BLOCK3)   <= To_SLV (to_integer (next_tetrimino_init_row (7)), 2);
            end if;
        end process;

        process (
          render_address_i,
          rows, cols, tetrimino_shape_next )
        is
            alias inside_row is render_address_i.row (5 downto 4);
            alias inside_col is render_address_i.col (5 downto 4);
        begin
            -- render tetrimino inside next tetrimino box
            -- note: we don't have to check if we are inside as render pipeline
            --       logic does that for now
            if   (inside_row = rows (BLOCK0) and inside_col = cols (BLOCK0))
              or (inside_row = rows (BLOCK1) and inside_col = cols (BLOCK1))
              or (inside_row = rows (BLOCK2) and inside_col = cols (BLOCK2))
              or (inside_row = rows (BLOCK3) and inside_col = cols (BLOCK3))
              then
                render_shape_o <= tetrimino_shape_next;
            else
                render_shape_o <= TETRIMINO_SHAPE_NONE;
            end if;
        end process;
    end block;

end Behavioral;
