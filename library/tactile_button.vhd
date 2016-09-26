library ieee;
use ieee.std_logic_1164.all;


-- Note: do not instanciate this directly, but go via tactile_buttons,
-- which syncronises incoming signals for mitigation of metastability.
entity tactile_button is
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;
        button_sync_i   : in     std_logic;
        press_ack_i     : in     std_logic;
        press_o         : out    std_logic
    );
end tactile_button;



architecture Behavioral of tactile_button is

    type state_type is
    (
        state_waiting_for_rising_edge,
        state_rising_edge,
        state_waiting_for_zero
    );
    signal state, next_state : state_type := state_waiting_for_rising_edge;

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
        when state_waiting_for_rising_edge => press_o <= '0';
        when state_rising_edge             => press_o <= '1';
        when state_waiting_for_zero        => press_o <= '0';
        end case;
    end process;

    FSM_NEXT_STATE: process (state, button_sync_i, press_ack_i)
    begin
        next_state <= state;

        case state is
        when state_waiting_for_rising_edge =>
            next_state <= state_rising_edge             when button_sync_i = '1';

        when state_rising_edge =>
            next_state <= state_waiting_for_zero        when press_ack_i = '1';

        when state_waiting_for_zero =>
            next_state <= state_waiting_for_rising_edge when button_sync_i = '0';
        end case;
    end process;

end Behavioral;
