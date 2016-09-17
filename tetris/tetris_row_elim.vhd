library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

use work.definitions.all;

library flib;
use flib.basic.generic_register;



entity tetris_row_elim is
    port
    (
        clock_i                 : in     std_logic;
        reset_i                 : in     std_logic;
        -- communication with playing field RAM
        block_o                 : out    tetrimino_shape_type;
        block_i                 : in     tetrimino_shape_type;
        block_write_enable_o    : out    std_logic;
        block_read_address_o    : out    tetris.storage.address.object;
        block_write_address_o   : out    tetris.storage.address.object;
        -- render pipeline access
        row_elim_address_i      : in     tetris.storage.row.object;
        row_elim_data_o         : out    tetris.row_elim.vga_compat.object;
        -- playing field FSM synchronisation signals
        fsm_start_i             : in     std_logic;
        fsm_ready_o             : out    std_logic
    );
end tetris_row_elim;



architecture Behavioral of tetris_row_elim is

    alias ts is tetris.storage;

    type ram_write_data_mux_enum is (
        MUXSEL_MOVE_DOWN,
        MUXSEL_NONE
    );
    signal ram_write_data_mux   : ram_write_data_mux_enum;

    type fsm_states is
    (
        state_start,
        -- logic that increments block removal counters (row_elim)
        state_check_block,
        state_increment_row_elim,
        state_check_block_decrement_row,
        -- logic that finds what row we have to remove and then fires removal down below
        state_check_row,
        state_move_block_down,
        state_decrement_row,
        state_zero_upper_row
    );
    signal state, next_state    : fsm_states := state_start;

    signal row_count_enable     : std_logic;
    signal row_count            : ts.row.object;
    signal row_count_old        : ts.row.object;
    signal row_count_at_top     : std_logic;

    signal column_count_enable  : std_logic;
    signal column_count         : ts.column.object;
    signal column_count_at_top  : std_logic;

    type ram_row_elim_type is array (0 to (2 ** ts.row.width) - 1) of tetris.row_elim.object;
    signal RAM_ROW_ELIM         : ram_row_elim_type := (others => (others => '0'));

    type row_elim_mode_enum is
    (
        MUXSEL_ROW_ELIM_RENDER,
        MUXSEL_ROW_ELIM_INCREMENT,
        MUXSEL_ROW_ELIM_MOVE_DOWN
    );
    signal row_elim_mode            : row_elim_mode_enum;

    signal row_elim_read_address    : ts.row.object;
    signal row_elim_read_data       : tetris.row_elim.object;

    signal row_elim_write_enable    : std_logic;
    signal row_elim_write_address   : ts.row.object;
    signal row_elim_write_data      : tetris.row_elim.object;

begin
    block_write_address_o.row <= row_count_old;
    block_write_address_o.col <= column_count;
    block_read_address_o.row  <= row_count;
    block_read_address_o.col  <= column_count;
    -------------------------------------------------------
    ---------- logic for RAM for line elimination ---------
    -------------------------------------------------------
    RAM_SAVE: process (clock_i)
    begin
        if rising_edge (clock_i) then
            if row_elim_write_enable = '1' then
                RAM_ROW_ELIM (to_integer (row_elim_write_address)) <= row_elim_write_data;
            end if;
        end if;
    end process;

    row_elim_read_data <= RAM_ROW_ELIM (to_integer (row_elim_read_address));
    row_elim_data_o    <= tetris.row_elim.vga_compat.to_compat (row_elim_read_data);

    with row_elim_mode select row_elim_write_data <=
      (others => '-')           when MUXSEL_ROW_ELIM_RENDER, -- N/A
      row_elim_read_data + '1'  when MUXSEL_ROW_ELIM_INCREMENT,
      row_elim_read_data        when MUXSEL_ROW_ELIM_MOVE_DOWN;

    with row_elim_mode select row_elim_write_address <=
      (others => '-')           when MUXSEL_ROW_ELIM_RENDER, -- N/A
      row_count                 when MUXSEL_ROW_ELIM_INCREMENT,
      row_count_old             when MUXSEL_ROW_ELIM_MOVE_DOWN;

    with row_elim_mode select row_elim_read_address <=
      row_elim_address_i        when MUXSEL_ROW_ELIM_RENDER,
      row_count                 when MUXSEL_ROW_ELIM_INCREMENT,
      row_count                 when MUXSEL_ROW_ELIM_MOVE_DOWN;

    with ram_write_data_mux select block_o <=
      block_i                   when MUXSEL_MOVE_DOWN,
      TETRIMINO_SHAPE_NONE      when MUXSEL_NONE;
    -------------------------------------------------------
    -------------- support counters for FSM ---------------
    -------------------------------------------------------
    Inst_row_counter: entity work.counter_until
    generic map
    (
        width   => ts.row.width,
        step    => '0' -- downcounter
    )
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => row_count_enable,
        reset_when_i    => To_SLV (0,          ts.row.width),
        reset_value_i   => To_SLV (ts.row.max, ts.row.width),
        count_o         => row_count,
        count_at_top_o  => row_count_at_top,
        overflow_o      => open
    );

    Inst_reg_old: component flib.basic.generic_register
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        clock_enable_i  => row_count_enable,
        data_i          => row_count,
        data_o          => row_count_old
    );

    Inst_column_counter: entity work.counter_until
    generic map (width => ts.column.width)
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i or row_count_enable,
        enable_i        => column_count_enable,
        reset_when_i    => To_SLV (ts.column.max, ts.column.width),
        reset_value_i   => To_SLV (0,             ts.column.width),
        count_o         => column_count,
        count_at_top_o  => column_count_at_top,
        overflow_o      => open
    );
    -------------------------------------------------------
    ------------------------- FSM -------------------------
    -------------------------------------------------------
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
        fsm_ready_o             <= '0';

        block_write_enable_o    <= '0';
        ram_write_data_mux      <= MUXSEL_MOVE_DOWN;

        column_count_enable     <= '0';
        row_count_enable        <= '0';

        row_elim_mode           <= MUXSEL_ROW_ELIM_RENDER;
        row_elim_write_enable   <= '0';

        case state is
        when state_start =>
            fsm_ready_o         <= '1';

        -- logic that increments block removal counters (row_elim)
        when state_check_block =>
            column_count_enable     <= '1';
        when state_increment_row_elim =>
            row_elim_mode           <= MUXSEL_ROW_ELIM_INCREMENT;
            row_elim_write_enable   <= '1';
        when state_check_block_decrement_row =>
            row_count_enable        <= '1';

        -- logic that finds what row we have to remove and then fires
        -- removal down below
        when state_check_row =>
            row_elim_mode           <= MUXSEL_ROW_ELIM_INCREMENT; -- same r addr
            row_count_enable        <= '1';

        -- logic that moves blocks down by one
        when state_move_block_down =>
            -- enable writes
            block_write_enable_o    <= '1';
            -- activate counter
            column_count_enable     <= '1';
        when state_decrement_row =>
            row_elim_mode           <= MUXSEL_ROW_ELIM_MOVE_DOWN;
            row_elim_write_enable   <= '1';
            row_count_enable        <= '1';

        -- finaly zero upper row
        when state_zero_upper_row =>
            row_elim_mode           <= MUXSEL_ROW_ELIM_MOVE_DOWN;
            row_elim_write_enable   <= '1';
            -- enable writes
            block_write_enable_o    <= '1';
            ram_write_data_mux      <= MUXSEL_NONE;
            -- activate counter
            column_count_enable     <= '1';
        end case;

    end process;

    FSM_NEXT_STATE: process (state,
        block_i, row_elim_read_data,
        fsm_start_i,
        row_count_at_top, column_count_at_top)
    begin
        next_state    <= state;

        case state is
        when state_start =>
            if fsm_start_i = '1' then
                next_state <= state_check_block;
            end if;

        -- logic that increments block removal counters (row_elim)
        when state_check_block =>
            if block_i = TETRIMINO_SHAPE_NONE then
                next_state <= state_check_block_decrement_row;
            elsif column_count_at_top = '1' then
                next_state <= state_increment_row_elim;
            end if;
        when state_increment_row_elim =>
            next_state <= state_check_block_decrement_row;
        when state_check_block_decrement_row =>
            if row_count_at_top = '1' then
                -- start row check passes
                next_state <= state_check_row;
            else
                next_state <= state_check_block;
            end if;

        -- logic that finds what row we have to remove and then fires removal down below
        when state_check_row =>
            if row_elim_read_data = tetris.row_elim.high then
                next_state <= state_move_block_down;
            elsif row_count_at_top = '1' then
                next_state <= state_start;
            end if;

        -- logic that moves blocks down by one
        when state_move_block_down =>
            if column_count_at_top = '1' then
                next_state <= state_decrement_row;
            end if;
        when state_decrement_row =>
            -- if we finished moving, go to end
            if row_count_at_top = '1' then
                next_state <= state_zero_upper_row;
            else
                next_state <= state_move_block_down;
            end if;

        when state_zero_upper_row =>
            if column_count_at_top = '1' then
                next_state <= state_check_row;
            end if;

        end case;
    end process;

end Behavioral;
