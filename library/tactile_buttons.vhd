library ieee;
use ieee.std_logic_1164.all;



-- holds button pulse until it is acknowledged by the system
entity tactile_buttons is
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;

        buttons_i       : in     std_logic_vector;
        buttons_ack_i   : in     std_logic_vector;
        presses_o       : out    std_logic_vector
    );
end tactile_buttons;



architecture Behavioral of tactile_buttons is
    constant vec_low    : natural := buttons_i'Low;
    constant vec_high   : natural := buttons_i'High;
begin
    -- Asserts to check vector shapes
    assert vec_low = buttons_ack_i'Low and vec_high = buttons_ack_i'High
      report "buttons_ack_i vector shape does not match that of buttons_i"
      severity FAILURE;

    assert vec_low = presses_o'Low and vec_high = presses_o'High
      report "presses_o vector shape does not match that of buttons_i"
      severity FAILURE;

    -- Individual tactile buttons
    TBUTTONS: for index in vec_low to vec_high generate
    begin
        Inst_button: entity work.tactile_button
        port map
        (
            clock_i         => clock_i,
            reset_i         => reset_i,
            button_i        => buttons_i (index),
            press_ack_i     => buttons_ack_i (index),
            press_o         => presses_o (index)
        );
    end generate;

end Behavioral;
