library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

use work.definitions.all;



entity tetris_render_pipeline is
    port
    (
        clock_i                 : in     std_logic;
        reset_i                 : in     std_logic;
        -- VGA module signals telling us where we are on the screen
        vga_pixel_address       : in     vga.pixel.address.object;
        vga_enable_draw         : in     std_logic;
        vga_off_screen          : in     std_logic;
        vga_sync                : in     vga.sync.object;
        -- VGA pipelined output signals (sync and colour lines)
        display                 : out    vga.display.object;

        active_operation_i      : in     active_tetrimino_operations;
        active_operation_ack_o  : out    std_logic;

        cathodes_o              : out    std_logic_vector(6 downto 0);
        anodes_o                : out    std_logic_vector(7 downto 0)
    );
end tetris_render_pipeline;



architecture Behavioral of tetris_render_pipeline is
    -- pipeline stuff
    signal on_tetris_surface            : std_logic;

    signal stage1_vga_sync              : vga.sync.object;
    signal stage1_vga_pixel_address     : vga.pixel.address.object;
    signal stage1_vga_enable_draw       : std_logic;
    signal stage1_vga_off_screen        : std_logic;
    signal stage1_tetrimino_shape       : tetrimino_shape_type;
    signal stage1_row_elim_data_out     : tetris.row_elim.vga_compat.object;

    signal stage2_vga_sync              : vga.sync.object;
    signal stage2_vga_pixel_address     : vga.pixel.address.object;
    signal stage2_vga_enable_draw       : std_logic;
    signal stage2_tetrimino_shape       : tetrimino_shape_type;
    signal stage2_row_elim_data_out     : tetris.row_elim.vga_compat.object;
    signal stage2_block_colours         : vga.colours.object;

    signal stage3_vga_sync              : vga.sync.object;
    signal stage3_vga_pixel_address     : vga.pixel.address.object;
    signal stage3_vga_enable_draw       : std_logic;
    signal stage3_tetrimino_shape       : tetrimino_shape_type;
    signal stage3_row_elim_data_out     : tetris.row_elim.vga_compat.object;
    signal stage3_block_colours         : vga.colours.object;
    signal stage3_block_final_colours   : vga.colours.object;
    signal stage3_draw_tetrimino_bb     : std_logic;
    signal stage3_text_dot              : std_logic;

    signal stage4_vga_sync              : vga.sync.object;
    signal stage4_vga_pixel_address     : vga.pixel.address.object;
    signal stage4_block_colours         : vga.colours.object;
    signal stage4_vga_enable_draw       : std_logic;
    signal stage4_tetrimino_shape       : tetrimino_shape_type;
    signal stage4_draw_tetrimino_bb     : std_logic;
    signal stage4_text_enable_draw      : std_logic;

    signal score_count                  : score_count_type;


    signal stage2_nt_shape              : tetrimino_shape_type;
    signal stage3_nt_shape              : tetrimino_shape_type;
    signal stage3_nt_colours            : vga.colours.object;
    signal stage4_nt_colours            : vga.colours.object;
    signal stage3_nt_enable_draw        : std_logic;
    signal stage4_nt_enable_draw        : std_logic;

    -- New Tetrimino
    signal nt_shape                     : tetrimino_shape_type;
    signal nt_retrieved                 : std_logic;

begin
    -- Stage1: save  row, column, hsync, vsync and en_draw from the VGA module
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            stage1_vga_sync             <= vga_sync;
            stage1_vga_pixel_address    <= vga_pixel_address;
            stage1_vga_enable_draw      <= vga_enable_draw;
            stage1_vga_off_screen       <= vga_off_screen;
        end if;
    end process;

    Inst_tetris_next_tetrimino: entity work.tetris_next_tetrimino
    port map
    (
        clock_i                 => clock_i,
        reset_i                 => reset_i,
        -- for Next Tetrimino selection (random)
        nt_shape_o              => nt_shape,
        nt_retrieved_i          => nt_retrieved,
        -- render pipeline
        render_shape_o          => stage2_nt_shape,
        render_address_i        => stage3_vga_pixel_address
    );

    -- obtain the block descriptor given row and column
    Inst_tetris_block: entity work.tetris_block
    port map
    (
        clock_i                     => clock_i,
        reset_i                     => reset_i,

        row_elim_data_o             => stage1_row_elim_data_out,
        tetrimino_shape_o           => stage1_tetrimino_shape,
        block_render_address_i.row  => stage1_vga_pixel_address.row (8 downto 4),
        block_render_address_i.col  => stage1_vga_pixel_address.col (7 downto 4),
        -- for Next Tetrimino selection (random)
        nt_shape_i                  => nt_shape,
        nt_retrieved_o              => nt_retrieved,

        screen_finished_render_i    => stage1_vga_off_screen,
        active_operation_i          => active_operation_i,
        active_operation_ack_o      => active_operation_ack_o,

        score_count_o               => score_count
    );

    -- Stage2: save row, column, hsync, vsync, en_draw + block desc, line remove
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            stage2_vga_sync             <= stage1_vga_sync;
            stage2_vga_pixel_address    <= stage1_vga_pixel_address;
            stage2_vga_enable_draw      <= stage1_vga_enable_draw;
            stage2_tetrimino_shape      <= stage1_tetrimino_shape;
            stage2_row_elim_data_out    <= stage1_row_elim_data_out;
        end if;
    end process;

    -- obtain colour from tetrimino shape
    get_colour (stage2_tetrimino_shape, stage2_block_colours.red, stage2_block_colours.green, stage2_block_colours.blue);

    -- Stage3: save row, column, hsync, vsync and en_draw + block desc, RGB of block, line remove
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            stage3_vga_sync             <= stage2_vga_sync;
            stage3_vga_pixel_address    <= stage2_vga_pixel_address;
            stage3_vga_enable_draw      <= stage2_vga_enable_draw;

            stage3_row_elim_data_out    <= stage2_row_elim_data_out;
            stage3_block_colours        <= stage2_block_colours;

            stage3_nt_shape             <= stage2_nt_shape;
        end if;
    end process;

    get_colour (stage3_nt_shape,
                stage3_nt_colours.red,
                stage3_nt_colours.green,
                stage3_nt_colours.blue
               );

    -- Merge row elimination colours
    stage3_block_final_colours.red   <= stage3_block_colours.red   or stage3_row_elim_data_out(4 downto 1);
    stage3_block_final_colours.green <= stage3_block_colours.green or stage3_row_elim_data_out(4 downto 1);
    stage3_block_final_colours.blue  <= stage3_block_colours.blue  or stage3_row_elim_data_out(4 downto 1);

    -- figure out if we are on the next tetrimino screen
    -- column 16 + 1space + 6(next tetrimino text) + 1space + padding = 24
    -- = 011000|0000 pixel column to 011011|1111
    -- row 000000|0000 to 000011|1111

    -- figure out if we have to draw the next tetrimino bounding box
    process (all)
        alias pa is stage3_vga_pixel_address;

        alias pa_common_row is pa.row (pa.row'high    downto pa.row'low + 6);
        alias pa_inside_row is pa.row (pa.row'low + 5 downto pa.row'low);

        alias pa_common_col is pa.col (pa.col'high    downto pa.col'low + 6);
        alias pa_inside_col is pa.col (pa.col'low + 5 downto pa.col'low);
    begin
        if pa_common_row = "0000" and pa_common_col = "0110" then
            stage3_nt_enable_draw <= '1';

            if   pa_inside_row = "000000" or pa_inside_row = "111111" -- upper and lower row
              or pa_inside_col = "000000" or pa_inside_col = "111111" -- left and right column
              then
                stage3_draw_tetrimino_bb <= '1';
            else
                stage3_draw_tetrimino_bb <= '0';
            end if;

        else
            stage3_draw_tetrimino_bb <= '0';
            stage3_nt_enable_draw <= '0';
        end if;
    end process;

    Inst_text: entity work.tetris_text
    port map
    (
        clock_i                 => clock_i,
        reset_i                 => reset_i,

        read_address_i.row      => stage3_vga_pixel_address.row (stage3_vga_pixel_address.row'left downto stage3_vga_pixel_address.row'right + 4),
        read_address_i.col      => stage3_vga_pixel_address.col (stage3_vga_pixel_address.col'left downto stage3_vga_pixel_address.col'right + 3),
        read_subaddress_i.row   => stage3_vga_pixel_address.row (stage3_vga_pixel_address.row'right + 3 downto stage3_vga_pixel_address.row'right),
        read_subaddress_i.col   => stage3_vga_pixel_address.col (stage3_vga_pixel_address.col'right + 2 downto stage3_vga_pixel_address.col'right),
        read_dot_o              => stage3_text_dot
    );

    -- Stage4: save row, column, hsync, vsync and en_draw + block desc, final RGB of block, line remove
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            stage4_vga_sync             <= stage3_vga_sync;
            stage4_vga_pixel_address    <= stage3_vga_pixel_address;
            stage4_vga_enable_draw      <= stage3_vga_enable_draw;

            stage4_block_colours        <= stage3_block_final_colours;
            stage4_draw_tetrimino_bb    <= stage3_draw_tetrimino_bb;

            stage4_text_enable_draw     <= stage3_text_dot;

            stage4_nt_colours           <= stage3_nt_colours;
            stage4_nt_enable_draw       <= stage3_nt_enable_draw;
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
        stage4_vga_enable_draw, stage4_draw_tetrimino_bb, stage4_text_enable_draw,
        stage4_nt_enable_draw, stage4_nt_colours,
        stage4_vga_pixel_address, stage4_block_colours,
        on_tetris_surface
    )
    begin
        -- check if we are on display surface
        if stage4_vga_enable_draw = '0' then
            display.c       <= vga.colours.all_off;
        -- check if we have to draw text
        elsif stage4_text_enable_draw = '1' then
            display.c.red   <= "1000";
            display.c.green <= "1000";
            display.c.blue  <= "1000";
        -- check if we have to draw the next tetrimino bounding box
        elsif stage4_draw_tetrimino_bb = '1' then
            display.c.red   <= "0100";
            display.c.green <= "1000";
            display.c.blue  <= "0111";
        -- check if we have to draw static lines
        elsif stage4_vga_pixel_address.col = To_SLV (255, stage4_vga_pixel_address.col'length)
        or    stage4_vga_pixel_address.col = To_SLV (0,   stage4_vga_pixel_address.col'length)
        or    stage4_vga_pixel_address.col = To_SLV (639, stage4_vga_pixel_address.col'length)
        or    stage4_vga_pixel_address.row = To_SLV (0,   stage4_vga_pixel_address.row'length)
        or    stage4_vga_pixel_address.row = To_SLV (479, stage4_vga_pixel_address.row'length)
        then
            display.c.red   <= "1000";
            display.c.green <= "0000";
            display.c.blue  <= "0100";
        -- check if we are on the tetris block surface
        elsif on_tetris_surface = '1' then
            display.c       <= stage4_block_colours;
        elsif stage4_nt_enable_draw then
            display.c       <= stage4_nt_colours;
        -- else don't draw anything.
        else
            display.c       <= vga.colours.all_off;
        end if;
    end process;

    -- show score count
    Inst_7seg: entity work.seven_seg_display
    generic map
    (
        f_clock         => 100_000_000,
        num_of_digits   => 8,
        dim_top         => 3,
        -- bit values for segment on
        -- Nexys 4's anodes are active low (have transistors for amplification)
        anode_on        => '0',
        -- Nexys 4's cathodes have A on right and inverted, but our seven_seg_digit has A on the left
        cathode_on      => '0'
    )
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        bcd_digits_i    => score_count,
        anodes_o        => anodes_o,
        cathodes_o      => cathodes_o
    );

end Behavioral;