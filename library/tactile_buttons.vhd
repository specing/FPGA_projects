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

    signal buttons_sync : std_logic_vector(num_of_buttons - 1 downto 0);

begin
    -- sync to clock
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                buttons_sync <= (others => '0');
            else
                buttons_sync <= buttons_i;
            end if;
        end if;
    end process;

    -- generate RED
    detectors:
    for index in 0 to num_of_buttons - 1 generate
    begin
        -- Individual tactile buttons
        Inst_button: entity work.tactile_button
        port map
        (
            clock_i         => clock_i,
            reset_i         => reset_i,
            button_sync_i   => buttons_sync (index),
            press_ack_i     => buttons_ack_i (index),
            press_o         => buttons_o (index)
        );
    end generate;

end Behavioral;
