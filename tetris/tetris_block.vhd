library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

library flib;
use flib.util;

use work.definitions.all;



entity tetris_block is
    port
    (
        clock_i                 : in     std_logic;
        reset_i                 : in     std_logic;
        -- For rendering
        render_address_i        : in     tetris.storage.address.object;
        render_active_shape_o   : out    tetrimino_shape_type;
        render_block_shape_o    : out    tetrimino_shape_type;
        row_elim_data_o         : out    tetris.row_elim.vga_compat.object;
        -- for Next Tetrimino selection (random)
        nt_shape_i              : in     tetrimino_shape_type;
        nt_retrieved_o          : out    std_logic;

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
    signal RAM : tetrimino_block_storage_type;

    type ram_access_mux_enum is
    (
        MUXSEL_RAM_CLEAR,
        MUXSEL_RENDER,
        MUXSEL_ROW_ELIM,
        MUXSEL_ACTIVE_TETRIMINO
    );
    signal ram_access_mux       : ram_access_mux_enum;

    signal ram_write_enable     : std_logic;
    signal ram_write_address    : ts.address.object;
    signal ram_write_data       : tetrimino_shape_type;

    signal ram_read_address     : ts.address.object;
    signal ram_read_data        : tetrimino_shape_type;


    type fsm_states is
    (
        -- RAM clearing
        state_clear_ram,
        -- Various game start states
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
        state_active_tetrimino_input_ack,
        -- the end
        state_game_over
    );
    signal state, next_state : fsm_states := state_clear_ram;

    -- Signals for RAM clearing logic
    signal ram_clear_enable     : std_logic;
    signal ram_clear_finished   : std_logic;
    signal ram_clear_address    : ts.address.object;
    signal ram_clear_caddress   : std_logic_vector (ts.address.width - 1 downto 0);
    -- Signals for row elimination
    signal row_elim_read_address    : ts.address.object;
    signal row_elim_write_data      : tetrimino_shape_type;
    signal row_elim_write_enable    : std_logic;
    signal row_elim_write_address   : ts.address.object;
    signal row_elim_start           : std_logic;
    signal row_elim_ready           : std_logic;
    -- Signals for active tetrimino
    -- Note: this is supposed to decrease the more points we have
    constant refresh_count_top      : natural := config.vga.refresh_rate - 1;
    constant refresh_count_width    : natural := util.compute_width (refresh_count_top);
    signal refresh_count_at_top     : std_logic;

    signal active_read_address      : ts.address.object;
    signal active_write_data        : tetrimino_shape_type;
    signal active_write_enable      : std_logic;
    signal active_write_address     : ts.address.object;
    signal active_start : std_logic;
    signal active_ready : std_logic;

    type active_tetrimino_command_mux_enum is
    (
        ATC_MOVE_DOWN,
        ATC_USER_INPUT
    );
    signal active_tetrimino_command_mux : active_tetrimino_command_mux_enum;
    signal active_operation             : active_tetrimino_operations;

    signal game_over    : std_logic;

    -- sc = score count
    constant sc_number_of_counters : natural := score_count_width/4;
    -- +1 due to last overflow_o
    signal sc_enables : std_logic_vector (0 to sc_number_of_counters - 1 + 1);

begin

    SCORE_COUNTERS_DECIMAL: for index in 0 to score_count_width/4 - 1 generate
    begin
        Inst_score_counter: entity work.counter_until
        generic map
        (
            width   => 4,
            step    => '1' -- upcounter
        )
        port map
        (
            clock_i         => clock_i,
            reset_i         => reset_i,
            enable_i        => sc_enables (index),
            reset_when_i    => To_SLV (9, 4),
            reset_value_i   => To_SLV (0, 4),
            count_o         => score_count_o (4*(index+1) - 1 downto 4*index),
            count_at_top_o  => open,
            overflow_o      => sc_enables (index+1)
        );
    end generate;
    -- first enable in series
    sc_enables (0) <= active_write_enable; -- temporarily permanent!

    -- determine what goes out on screen
    render_block_shape_o <= ram_read_data;
    -------------------------------------------------------
    --------------- logic for RAM for blocks --------------
    -------------------------------------------------------
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if ram_write_enable = '1' then
                RAM (to_integer (ram_write_address.row & ram_write_address.col)) <= ram_write_data;
            end if;
        end if;
    end process;

    ram_read_data <= RAM (to_integer (ram_read_address.row & ram_read_address.col));
    -------------------------------------------------------
    ------------- RAM access [de]multiplexers -------------
    -------------------------------------------------------
    with ram_access_mux select ram_write_data <=
      TETRIMINO_SHAPE_NONE      when MUXSEL_RAM_CLEAR,
      TETRIMINO_SHAPE_NONE      when MUXSEL_RENDER,
      row_elim_write_data       when MUXSEL_ROW_ELIM,
      active_write_data         when MUXSEL_ACTIVE_TETRIMINO;

    with ram_access_mux select ram_write_address <=
      ram_clear_address         when MUXSEL_RAM_CLEAR,
      active_write_address      when MUXSEL_ACTIVE_TETRIMINO,
      ts.address.all_zeros      when MUXSEL_RENDER,
      row_elim_write_address    when MUXSEL_ROW_ELIM;

    with ram_access_mux select ram_write_enable <=
      '1'                       when MUXSEL_RAM_CLEAR,
      '0'                       when MUXSEL_RENDER,
      row_elim_write_enable     when MUXSEL_ROW_ELIM,
      active_write_enable       when MUXSEL_ACTIVE_TETRIMINO;

    with ram_access_mux select ram_read_address <=
      ts.address.all_zeros      when MUXSEL_RAM_CLEAR,
      active_read_address       when MUXSEL_ACTIVE_TETRIMINO,
      render_address_i          when MUXSEL_RENDER,
      row_elim_read_address     when MUXSEL_ROW_ELIM;
    -------------------------------------------------------
    ------------- logic to clear RAM on reset -------------
    -------------------------------------------------------
    -- Workaround due to VHDL not allowing "ram_clear_address.row & ram_clear_address.col"
    -- on the output port count_o down below.
    ram_clear_address.row <= ram_clear_caddress (ts.address.width - 1 downto ts.col.width);
    ram_clear_address.col <= ram_clear_caddress (ts.col.width - 1 downto 0);

    Inst_ram_clear_counter: entity work.counter_until
    generic map
    (
        width   => ts.address.width,
        step    => '1' -- upcounter
    )
    port map
    (
        clock_i         => clock_i,
        reset_i         => '0', -- This counter implements reset, we don't want to reset it!
        enable_i        => ram_clear_enable,
        reset_when_i    => To_SLV (ram_size - 1, ts.address.width),
        reset_value_i   => To_SLV (0,            ts.address.width),
        count_o         => ram_clear_caddress,
        count_at_top_o  => open,
        overflow_o      => ram_clear_finished
    );
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

        row_elim_address_i      => render_address_i.row,
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
        -- for Next Tetrimino selection (random)
        nt_shape_i              => nt_shape_i,
        nt_retrieved_o          => nt_retrieved_o,
        -- for next tetrimino selection (random)
        -- readout for drawing of active tetrimino
        active_data_o           => render_active_shape_o,
        active_address_i        => render_address_i,
        -- communication with the main finite state machine
        operation_i             => active_operation,
        fsm_start_i             => active_start,
        fsm_ready_o             => active_ready,
        fsm_game_over_o         => game_over
    );
    with active_tetrimino_command_mux select active_operation <=
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
        reset_when_i    => To_SLV (refresh_count_top, refresh_count_width),
        reset_value_i   => To_SLV (0,                 refresh_count_width),
        count_o         => open,
        count_at_top_o  => refresh_count_at_top,
        overflow_o      => open
    );
    -------------------------------------------------------
    ------------------------- FSM -------------------------
    -------------------------------------------------------
    FSM_STATE_CHANGE: process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                state <= state_clear_ram;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    FSM_OUTPUT: process (state)
    begin
        ram_access_mux                      <= MUXSEL_RENDER;

        row_elim_start                      <= '0';
        active_start                        <= '0';
        active_tetrimino_command_mux        <= ATC_MOVE_DOWN;
        active_operation_ack_o              <= '0';
        ram_clear_enable                    <= '0';

        case state is
        -- RAM clearing
        when state_clear_ram =>
            ram_access_mux                  <= MUXSEL_RAM_CLEAR;
            ram_clear_enable                <= '1';
        -------------------------------------------------------------
        when state_wait_for_initial_input =>
            null;
        when state_confirm_start =>
            -- clear key press
            active_operation_ack_o          <= '1';
        when state_start =>
            ram_access_mux                  <= MUXSEL_RENDER;
        -------------------------------------------------------------
        when state_full_row_elim =>
            row_elim_start                  <= '1';
            ram_access_mux                  <= MUXSEL_ROW_ELIM;
        when state_full_row_elim_wait =>
            ram_access_mux                  <= MUXSEL_ROW_ELIM;
        -------------------------------------------------------------
        when state_active_tetrimino_MD =>
            active_start                    <= '1';
            ram_access_mux                  <= MUXSEL_ACTIVE_TETRIMINO;
            active_tetrimino_command_mux    <= ATC_MOVE_DOWN;
        when state_active_tetrimino_MD_wait =>
            ram_access_mux                  <= MUXSEL_ACTIVE_TETRIMINO;
            active_tetrimino_command_mux    <= ATC_MOVE_DOWN;
        -------------------------------------------------------------
        when state_active_tetrimino_input =>
            active_start                    <= '1';
            ram_access_mux                  <= MUXSEL_ACTIVE_TETRIMINO;
            active_tetrimino_command_mux    <= ATC_USER_INPUT;
        when state_active_tetrimino_input_wait =>
            ram_access_mux                  <= MUXSEL_ACTIVE_TETRIMINO;
            active_tetrimino_command_mux    <= ATC_USER_INPUT;
        when state_active_tetrimino_input_ack =>
            active_operation_ack_o          <= '1';
        -------------------------------------------------------------
        when state_game_over =>
            null;
        end case;
    end process;

    FSM_NEXT_STATE: process (state,
        screen_finished_render_i, refresh_count_at_top,
        ram_clear_finished, row_elim_ready,
        active_ready, active_operation_i, game_over)
    begin
        next_state <= state;

        case state is
        -- RAM clearing
        when state_clear_ram =>
            if ram_clear_finished = '1' then
                next_state <= state_wait_for_initial_input;
            end if;
        -------------------------------------------------------------
        when state_wait_for_initial_input =>
            if active_operation_i /= ATO_NONE then
                next_state <= state_confirm_start;
            end if;
        when state_confirm_start =>
            next_state <= state_start;

        when state_start =>
            -- active only one clock
            if screen_finished_render_i = '1' then
                next_state <= state_full_row_elim;
            end if;
        -------------------------------------------------------------
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
        -------------------------------------------------------------
        when state_active_tetrimino_MD =>
            next_state <= state_active_tetrimino_MD_wait;
        when state_active_tetrimino_MD_wait =>
            if active_ready = '1' then
                if game_over = '1' then
                    next_state <= state_game_over;
                elsif active_operation_i /= ATO_NONE then
                    next_state <= state_active_tetrimino_input;
                else
                    next_state <= state_start;
                end if;
            end if;
        -------------------------------------------------------------
        when state_active_tetrimino_input =>
            next_state <= state_active_tetrimino_input_wait;
        when state_active_tetrimino_input_wait =>
            if active_ready = '1' then
                next_state <= state_active_tetrimino_input_ack;
            end if;
        when state_active_tetrimino_input_ack =>
            next_state <= state_start;
        -------------------------------------------------------------
        when state_game_over =>
            next_state <= state_game_over; -- stay here until reset.
        end case;
    end process;

end Behavioral;
