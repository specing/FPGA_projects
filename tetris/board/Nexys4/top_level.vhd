library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

library flib;
use flib.vga.VGA_controller;



entity top_level is
    port
    (
        clock_i         : in     std_logic;
        reset_low_i     : in     std_logic;
        -- contains colours and sync
        display_o       : out    vga.display.object;

        btnL_i          : in     std_logic;
        btnR_i          : in     std_logic;
        btnU_i          : in     std_logic;
        btnD_i          : in     std_logic;
        btnC_i          : in     std_logic;

        anode_o         : out    std_logic_vector (7 downto 0);
        cathode_o       : out    std_logic_vector (0 to 6)
    );
end top_level;



architecture Behavioral of top_level is
    signal reset_i                  : std_logic;
    signal tetrimino_operation      : active_tetrimino_operations;
    signal tetrimino_operation_ack  : std_logic;

    -- VGA misc signals
    signal vga_pixel_clock          : std_logic;
    -- VGA module signals telling us where we are on the screen
    signal vga_pixel_address        : vga.pixel.address.object;
    signal vga_enable_draw          : std_logic;
    signal vga_off_screen           : std_logic;
    signal vga_sync                 : vga.sync.object;
begin
    -- assign output signals

    -- board reset is active low
    reset_i <= not reset_low_i;
    -------------------------------------------------------
    ------------------------ INPUT ------------------------
    -------------------------------------------------------
    INPUT_LOGIC: block
        constant num_of_buttons : integer := 5;
        subtype button_vector is std_logic_vector (num_of_buttons - 1 downto 0);
        signal buttons_joined   : button_vector;
        signal buttons          : button_vector;
        alias button_drop       is buttons (4);
        alias button_left       is buttons (3);
        alias button_right      is buttons (2);
        alias button_up         is buttons (1);
        alias button_down       is buttons (0);

        type state_type is
        (
            state_start,
            state_drop,
            state_left,
            state_right,
            state_up,
            state_down
        );
        signal state, next_state : state_type := state_start;


        signal buttons_ack_joined : button_vector;
        alias button_drop_ack     is buttons_ack_joined(4);
        alias button_left_ack     is buttons_ack_joined(3);
        alias button_right_ack    is buttons_ack_joined(2);
        alias button_up_ack       is buttons_ack_joined(1);
        alias button_down_ack     is buttons_ack_joined(0);
    begin
        buttons_joined <= btnC_i & btnL_i & btnR_i & btnU_i & btnD_i;

        -- sync & button input logic on tactile buttons
        Inst_button_input: entity work.tactile_buttons
        port map
        (
            clock_i         => clock_i,
            reset_i         => reset_i,
            buttons_i       => buttons_joined,
            buttons_ack_i   => buttons_ack_joined,
            buttons_o       => buttons
        );

        FSM_STATE_CHANGE: process (clock_i)
        begin
            if rising_edge (clock_i) then
                if reset_i = '1' then
                    state <= state_start;
                else
                    state <= next_state;
                end if;
            end if;
        end process;

        FSM_OUTPUT: process (state)
        begin
            buttons_ack_joined      <= (others => '0');
            tetrimino_operation     <= ATO_NONE;

            case state is
            when state_start =>
                null;
            when state_drop =>
                tetrimino_operation <= ATO_DROP_DOWN;
                button_drop_ack     <= '1';
            when state_left =>
                tetrimino_operation <= ATO_MOVE_LEFT;
                button_left_ack     <= '1';
            when state_right =>
                tetrimino_operation <= ATO_MOVE_RIGHT;
                button_right_ack    <= '1';
            when state_up =>
                tetrimino_operation <= ATO_ROTATE_CLOCKWISE;
                button_up_ack       <= '1';
            when state_down =>
                tetrimino_operation <= ATO_ROTATE_COUNTER_CLOCKWISE;
                button_down_ack     <= '1';
            end case;
        end process;

        FSM_NEXT_STATE: process (state, tetrimino_operation_ack, buttons)
        begin
            case state is
            when state_start =>
                if    button_drop  = '1' then next_state <= state_drop;
                elsif button_left  = '1' then next_state <= state_left;
                elsif button_right = '1' then next_state <= state_right;
                elsif button_up    = '1' then next_state <= state_up;
                elsif button_down  = '1' then next_state <= state_down;
                else                          next_state <= state_start;
                end if;
            when state_drop | state_left | state_right | state_up | state_down =>
                if tetrimino_operation_ack = '1' then
                    next_state <= state_start;
                else
                    next_state <= state;
                end if;
            end case;
        end process;

    end block;

    -------------------------------------------------------
    ----------------------- SCREEN ------------------------
    -------------------------------------------------------
    -- prescale the main clock to obtain the "pixel clock"
    Inst_counter_pixelclockprescale: entity work.counter_until
    generic map         (width => 2)
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => '1',
        reset_when_i    => "11", -- /4 here
        reset_value_i   => "00",
        count_o         => open,
        count_at_top_o  => open,
        overflow_o      => vga_pixel_clock
    );

    Inst_VGA_controller: component flib.vga.VGA_controller
    generic map
    (
        row_width       => vga.pixel.row.width,
        column_width    => vga.pixel.column.width
    )
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        pixelclock_i    => vga_pixel_clock,
        -- Vertical and Horizontal SYNC
        hsync_o         => vga_sync.h,
        vsync_o         => vga_sync.v,
        -- Pixel address on the virtual screen
        col_o           => vga_pixel_address.col,
        row_o           => vga_pixel_address.row,
        -- signals where we are
        enable_draw_o   => vga_enable_draw,
        screen_end_o    => vga_off_screen
    );
    -------------------------------------------------------------------------
    ------------------ include board independent top level ------------------
    -------------------------------------------------------------------------
    Inst_tetris_render_pipeline: entity work.tetris_render_pipeline
    port map
    (
        clock_i                 => clock_i,
        reset_i                 => reset_i,
        -- VGA module signals telling us where we are on the screen
        vga_pixel_address       => vga_pixel_address,
        vga_enable_draw         => vga_enable_draw,
        vga_off_screen          => vga_off_screen,
        vga_sync                => vga_sync,
        -- VGA pipelined output signals (sync and colour lines)
        display                 => display_o,

        active_operation_i      => tetrimino_operation,
        active_operation_ack_o  => tetrimino_operation_ack,

        cathodes_o              => cathode_o,
        anodes_o                => anode_o
    );

end Behavioral;
