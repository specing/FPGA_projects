library ieee;
use ieee.std_logic_1164.all;


-- Note: tactile_buttons has this vectored
entity tactile_button is
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;
        button_i        : in     std_logic;
        press_ack_i     : in     std_logic;
        press_o         : out    std_logic
    );
end tactile_button;



architecture Behavioral of tactile_button is

    type state_type is
    (
        state_wait_for_press,
        state_wait_for_ack_or_depress,
        state_wait_for_ack,
        state_wait_for_depress
    );
    signal state, next_state : state_type := state_wait_for_press;

    signal button_sync1 : std_logic := '0';
    signal button_sync  : std_logic := '0';

begin
    -- sync to clock
    SYNC: process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                button_sync1    <= '0';
                button_sync     <= '0';
            else
                button_sync1    <= button_i;
                button_sync     <= button_sync1;
            end if;
        end if;
    end process;
    ---------------------------------------------------------------------------------------------
    --------------------------------- Key press detection logic ---------------------------------
    ---------------------------------------------------------------------------------------------
    FSM_STATE_CHANGE: process (clock_i)
    begin
        if rising_edge (clock_i) then
            state <= state_wait_for_press when reset_i = '1'
                else next_state;
        end if;
    end process;

    FSM_OUTPUT: process (state)
    begin
        case state is
        when state_wait_for_press           => press_o <= '0';
        when state_wait_for_ack_or_depress  => press_o <= '1';
        when state_wait_for_ack             => press_o <= '1';
        when state_wait_for_depress         => press_o <= '0';
        end case;
    end process;

    FSM_NEXT_STATE: process (state, button_sync, press_ack_i)
    begin
        next_state <= state;

        case state is
        when state_wait_for_press =>
            next_state <= state_wait_for_ack_or_depress when button_sync = '1';

        when state_wait_for_ack_or_depress =>
            next_state <= state_wait_for_ack            when button_sync = '0'
                     else state_wait_for_depress        when press_ack_i = '1';

        when state_wait_for_ack =>
            next_state <= state_wait_for_press          when press_ack_i = '1';

        when state_wait_for_depress =>
            next_state <= state_wait_for_press          when button_sync = '0';
        end case;
    end process;

end Behavioral;
