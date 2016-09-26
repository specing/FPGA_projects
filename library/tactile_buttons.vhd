library ieee;
use ieee.std_logic_1164.all;



-- holds button pulse until it is acknowledged by the system
entity tactile_buttons is
    generic
    (
        num_of_buttons  : positive
    );
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;

        buttons_i       : in     std_logic_vector (num_of_buttons - 1 downto 0);
        buttons_ack_i   : in     std_logic_vector (num_of_buttons - 1 downto 0);
        buttons_o       : out    std_logic_vector (num_of_buttons - 1 downto 0)
    );
end tactile_buttons;



architecture Behavioral of tactile_buttons is
begin

    -- Individual tactile buttons
    TBUTTONS: for index in 0 to num_of_buttons - 1 generate
    begin
        Inst_button: entity work.tactile_button
        port map
        (
            clock_i         => clock_i,
            reset_i         => reset_i,
            button_i        => buttons_i (index),
            press_ack_i     => buttons_ack_i (index),
            press_o         => buttons_o (index)
        );
    end generate;

end Behavioral;
