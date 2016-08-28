library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library flib;
use flib.util;

use work.definitions.all;



entity tetris_block is
    port
    (
        clock_i                 : in     std_logic;
        reset_i                 : in     std_logic;

        row_elim_data_o         : out    tetris.row_elim.vga_compat.object;
        tetrimino_shape_o       : out    tetrimino_shape_type;
        block_render_address_i  : in     tetris.storage.address.object;
        -- for next tetrimino selection (random)
        tetrimino_shape_next_i  : in     tetrimino_shape_type;

        screen_finished_render_i: in     std_logic;
        active_operation_i      : in     active_tetrimino_operations;
        active_operation_ack_o  : out    std_logic;

        score_count_o           : out    score_count_type
    );
end tetris_block;



architecture Behavioral of tetris_block is

    alias ts is tetris.storage;

    constant ram_size  : integer := 2 ** ts.address.width;
    -------------------------------------------------------
    ----------------- Tetris Active Data ------------------
    -------------------------------------------------------
    -- number_of_rows*number_of_columns for storing block descriptors
    -- of type tetrimino_shape_type + wasted space (if the sizes are not a power of two).
    type tetrimino_block_storage_type is array (0 to ram_size - 1) of tetrimino_shape_type;
    signal RAM : tetrimino_block_storage_type := (others => TETRIMINO_SHAPE_NONE);

    type ram_access_mux_enum is
    (
        MUXSEL_RENDER,
        MUXSEL_ROW_ELIM,
        MUXSEL_ACTIVE_ELEMENT
    );
    signal ram_access_mux       : ram_access_mux_enum;

    signal ram_write_enable     : std_logic;
    signal ram_write_address    : ts.address.object;
    signal ram_write_data       : tetrimino_shape_type;

    signal ram_read_address     : ts.address.object;
    signal ram_read_data        : tetrimino_shape_type;


    type fsm_states is
    (
        state_wait_for_initial_input,
        state_confirm_start,
        state_start,
        -- removes full rows
        state_full_row_elim,
        state_full_row_elim_wait,
        -- move down
        state_active_tetrimino_MD,
        state_active_tetrimino_MD_wait,
        -- user input
        state_active_tetrimino_input,
        state_active_tetrimino_input_wait,
        state_active_tetrimino_input_ack
    );
    signal state, next_state : fsm_states := state_wait_for_initial_input;

    constant refresh_count_top      : natural := 59; --255;
    constant refresh_count_width    : natural := util.compute_width (refresh_count_top);
    signal refresh_count_at_top     : std_logic;

    signal row_elim_read_address    : ts.address.object;
    signal row_elim_read_column     : block_storage_column_type;
    signal row_elim_write_data      : tetrimino_shape_type;
    signal row_elim_write_enable    : std_logic;
    signal row_elim_write_address   : ts.address.object;

    signal row_elim_start           : std_logic;
    signal row_elim_ready           : std_logic;

    signal active_write_data        : tetrimino_shape_type;
    signal active_write_enable      : std_logic;
    signal active_read_address      : ts.address.object;
    signal active_write_address     : ts.address.object;

    signal active_tetrimino_shape   : tetrimino_shape_type;
    type active_tetrimino_command_mux_enum is
    (
        ATC_DISABLED,
        ATC_MOVE_DOWN,
        ATC_USER_INPUT
    );
    signal active_tetrimino_command_mux : active_tetrimino_command_mux_enum;
    signal active_operation             : active_tetrimino_operations;

    signal active_start : std_logic;
    signal active_ready : std_logic;

    signal game_start   : std_logic;
    signal game_over    : std_logic;

begin

    Inst_score_counter: component flib.basic.counter
    generic map         ( width => score_count_width )
    port map
    (
        clock_i         => clock_i,
        reset_i         => game_start,
        count_enable_i  => active_write_enable, -- temporary?
        count_o         => score_count_o
    );

    -- determine what goes out on screen
    with active_tetrimino_shape select tetrimino_shape_o <=
      ram_read_data          when TETRIMINO_SHAPE_NONE,
      active_tetrimino_shape when others;

    -------------------------------------------------------
    --------------- logic for RAM for blocks --------------
    -------------------------------------------------------
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if ram_write_enable = '1' then
                RAM (conv_integer(ram_write_address.row & ram_write_address.col)) <= ram_write_data;
            end if;
        end if;
    end process;

    ram_read_data <= RAM (conv_integer(ram_read_address.row & ram_read_address.col));


    -- figure out who has access to it
    with ram_access_mux select ram_write_data <=
      TETRIMINO_SHAPE_NONE      when MUXSEL_RENDER,
      row_elim_write_data       when MUXSEL_ROW_ELIM,
      active_write_data         when MUXSEL_ACTIVE_ELEMENT,
      TETRIMINO_SHAPE_NONE      when others;

    --type address is record row : ts.row.object; col : ts.column.object; end record;
    with ram_access_mux select ram_write_address <=
      active_write_address      when MUXSEL_ACTIVE_ELEMENT,
      ts.address.all_zeros      when MUXSEL_RENDER,
      row_elim_write_address    when MUXSEL_ROW_ELIM,
      ts.address.all_zeros      when others; -- This is unnecessary,
      -- but otherwise Vivado uses 2 more LUTs on xc7a100t ...

    with ram_access_mux select ram_write_enable <=
      '0'                       when MUXSEL_RENDER,
      row_elim_write_enable     when MUXSEL_ROW_ELIM,
      active_write_enable       when MUXSEL_ACTIVE_ELEMENT,
      '0'                       when others;

    with ram_access_mux select ram_read_address <=
      active_read_address       when MUXSEL_ACTIVE_ELEMENT,
      block_render_address_i    when MUXSEL_RENDER,
      row_elim_read_address     when MUXSEL_ROW_ELIM,
      ts.address.all_zeros      when others; -- This is unnecessary,
      -- but otherwise Vivado uses 30 more LUTs on xc7a100t. The same happens
      -- if any of the other three is used instead of ts.address.all_zeros ...


    -------------------------------------------------------
    --------------------- sub modules ---------------------
    -------------------------------------------------------

    Inst_tetris_row_elim: entity work.tetris_row_elim
    port map
    (
        clock_i                 => clock_i,
        reset_i                 => reset_i,
        -- communication with main RAM
        block_o                 => row_elim_write_data,
        block_i                 => ram_read_data,
        block_write_enable_o    => row_elim_write_enable,
        block_read_address_o    => row_elim_read_address,
        block_write_address_o   => row_elim_write_address,

        row_elim_address_i      => block_render_address_i.row,
        row_elim_data_o         => row_elim_data_o,

        fsm_start_i             => row_elim_start,
        fsm_ready_o             => row_elim_ready
    );

    Inst_active_tetrimino: entity work.tetris_active_tetrimino
    port map
    (
        clock_i                 => clock_i,
        reset_i                 => reset_i,
        -- communication with main RAM
        block_o                 => active_write_data,
        block_i                 => ram_read_data,
        block_write_enable_o    => active_write_enable,
        block_read_address_o    => active_read_address,
        block_write_address_o   => active_write_address,
        -- for next tetrimino selection (random)
        tetrimino_shape_next_i  => tetrimino_shape_next_i,
        -- readout for drawing of active tetrimino
        active_data_o           => active_tetrimino_shape,
        active_address_i        => block_render_address_i,
        -- communication with the main finite state machine
        operation_i             => active_operation,
        fsm_start_i             => active_start,
        fsm_ready_o             => active_ready,
        fsm_game_over_o         => game_over
    );

    with active_tetrimino_command_mux select active_operation <=
      ATO_NONE              when ATC_DISABLED,
      ATO_MOVE_DOWN         when ATC_MOVE_DOWN,
      active_operation_i    when ATC_USER_INPUT;

    -------------------------------------------------------
    -------------- support counters for FSM ---------------
    -------------------------------------------------------

    Inst_refresh_counter: entity work.counter_until
    generic map (width => refresh_count_width)
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => screen_finished_render_i,
        reset_when_i    => std_logic_vector (to_unsigned (refresh_count_top, refresh_count_width)),
        reset_value_i   => std_logic_vector (to_unsigned (0,                 refresh_count_width)),
        count_o         => open,
        count_at_top_o  => refresh_count_at_top,
        overflow_o      => open
    );

    -------------------------------------------------------
    ------------------------- FSM -------------------------
    -------------------------------------------------------

    -- FSM state change process
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                state <= state_wait_for_initial_input;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- FSM output
    process (state)
    begin

        ram_access_mux                      <= MUXSEL_RENDER;

        row_elim_start                      <= '0';
        active_start                        <= '0';
        active_tetrimino_command_mux        <= ATC_DISABLED;
        active_operation_ack_o              <= '0';

        game_start                          <= '0';

        case state is
        when state_wait_for_initial_input =>
            null;
        when state_confirm_start =>
            game_start                      <= '1';
            -- clear key press
            active_operation_ack_o          <= '1';
        when state_start =>
            ram_access_mux                  <= MUXSEL_RENDER;

        when state_full_row_elim =>
            row_elim_start                  <= '1';
            ram_access_mux                  <= MUXSEL_ROW_ELIM;
        when state_full_row_elim_wait =>
            ram_access_mux                  <= MUXSEL_ROW_ELIM;

        when state_active_tetrimino_MD =>
            active_start                    <= '1';
            ram_access_mux                  <= MUXSEL_ACTIVE_ELEMENT;
            active_tetrimino_command_mux    <= ATC_MOVE_DOWN;
        when state_active_tetrimino_MD_wait =>
            ram_access_mux                  <= MUXSEL_ACTIVE_ELEMENT;
            active_tetrimino_command_mux    <= ATC_MOVE_DOWN;

        when state_active_tetrimino_input =>
            active_start                    <= '1';
            ram_access_mux                  <= MUXSEL_ACTIVE_ELEMENT;
            active_tetrimino_command_mux    <= ATC_USER_INPUT;
        when state_active_tetrimino_input_wait =>
            ram_access_mux                  <= MUXSEL_ACTIVE_ELEMENT;
            active_tetrimino_command_mux    <= ATC_USER_INPUT;
        when state_active_tetrimino_input_ack =>
            active_operation_ack_o          <= '1';
        end case;
    end process;

    -- FSM next state
    process
    (
        state,
        screen_finished_render_i, refresh_count_at_top,
        row_elim_ready,    active_ready,
        active_operation_i, game_over
    )
    begin
        next_state <= state;

        case state is
        when state_wait_for_initial_input =>
            if active_operation_i /= ATO_NONE then
                next_state <= state_confirm_start;
            end if;
        when state_confirm_start =>
            next_state <= state_start;

        when state_start =>
            -- active only one clock
            if screen_finished_render_i = '1' then
            --refresh_count_overflow = '1' then
                next_state <= state_full_row_elim;
            end if;

        when state_full_row_elim =>
            next_state <= state_full_row_elim_wait;
        when state_full_row_elim_wait =>
            if row_elim_ready = '1' then
                if refresh_count_at_top = '1' then
                    next_state <= state_active_tetrimino_MD;
                else
                    next_state <= state_active_tetrimino_input;
                end if;
            end if;

        when state_active_tetrimino_MD =>
            next_state <= state_active_tetrimino_MD_wait;
        when state_active_tetrimino_MD_wait =>
            if active_ready = '1' then
                if game_over = '1' then
                    next_state <= state_wait_for_initial_input;
                else
                    next_state <= state_active_tetrimino_input;
                end if;
            end if;

        when state_active_tetrimino_input =>
            next_state <= state_active_tetrimino_input_wait;
        when state_active_tetrimino_input_wait =>
            if active_ready = '1' then
                next_state <= state_active_tetrimino_input_ack;
            end if;
        when state_active_tetrimino_input_ack =>
            next_state <= state_start;
        end case;
    end process;

end Behavioral;
