library ieee;
use ieee.std_logic_1164.all;

library flib;
use flib.basic.all;



entity falling_edge_detector is
    port
    (
        clock_i     : in     std_logic;
        reset_i     : in     std_logic;
        input_i     : in     std_logic;
        output_o    : out    std_logic
    );
end falling_edge_detector;



architecture Behavioral of falling_edge_detector is

    type state_type is
    (
        state_waiting_for_falling_edge,
        state_falling_edge,
        state_waiting_for_one
    );

    signal state, next_state : state_type;

begin

    SYNC_PROC: process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                state <= state_waiting_for_falling_edge;
            else
                state <= next_state;
            end if;
        end if;
    end process;


    OUTPUT_DECODE: process (state)
    begin
        case state is
        when state_waiting_for_falling_edge => output_o <= '0';
        when state_falling_edge             => output_o <= '1';
        when state_waiting_for_one          => output_o <= '0';
        when others                         => output_o <= '0';
        end case;
    end process;


    NEXT_STATE_DECODE: process (state, input_i)
    begin
        --declare default state for next_state to avoid latches
        next_state <= state;

        case state is
        when state_waiting_for_falling_edge =>
            if input_i = '0' then
                next_state <= state_falling_edge;
            end if;

        when state_falling_edge =>
            next_state <= state_waiting_for_one;

        when state_waiting_for_one =>
            if input_i = '1' then
                next_state <= state_waiting_for_falling_edge;
            end if;

        when others =>
            next_state <= state_waiting_for_falling_edge;

        end case;
    end process;

end Behavioral;
