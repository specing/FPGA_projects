library ieee;
use ieee.std_logic_1164.all;



entity rising_edge_detector is
    port
    (
        clock_i     : in     std_logic;
        reset_i     : in     std_logic;
        input_i     : in     std_logic;
        input_ack_i : in     std_logic;
        output_o    : out    std_logic
    );
end rising_edge_detector;



architecture Behavioral of rising_edge_detector is

    type state_type is
    (
        state_waiting_for_rising_edge,
        state_rising_edge,
        state_waiting_for_zero
    );
    signal state, next_state : state_type;

begin

    FSM_STATE_CHANGE: process (clock_i)
    begin
        if rising_edge (clock_i) then
            state <= state_waiting_for_rising_edge when reset_i = '1'
                else next_state;
        end if;
    end process;

    FSM_OUTPUT: process (state)
    begin
        case state is
        when state_waiting_for_rising_edge => output_o <= '0';
        when state_rising_edge             => output_o <= '1';
        when state_waiting_for_zero        => output_o <= '0';
        end case;
    end process;

    FSM_NEXT_STATE: process (state, input_i, input_ack_i)
    begin
        next_state <= state;

        case state is
        when state_waiting_for_rising_edge =>
            next_state <= state_rising_edge             when input_i = '1';

        when state_rising_edge =>
            next_state <= state_waiting_for_zero        when input_ack_i = '1';

        when state_waiting_for_zero =>
            next_state <= state_waiting_for_rising_edge when input_i = '0';
        end case;
    end process;

end Behavioral;
