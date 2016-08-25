library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.definitions.all;



entity tetris_text is
    port
    (
        clock_i             : in     std_logic;
        reset_i             : in     std_logic;

        read_address_i      : in     letters.address.object;
        read_subaddress_i   : in     font.address.object;
        read_dot_o          : out    std_logic
    );
end tetris_text;



architecture Behavioral of tetris_text is

    -- storage type
    type storage_object is array (0 to 2 ** letters.address.combined.width - 1) of letter.object;
    -- storage space
    signal ram : storage_object := (others => letter.space);

    -- R/W signals
    signal write_enable             : std_logic := '1';
    signal write_address            : letters.address.object;
    signal write_address_combined   : letters.address.combined.object;
    signal read_address_combined    : letters.address.combined.object;
    signal write_data               : letter.object := letter.N_upper;
    signal read_data                : letter.object;

begin

    -- Temporary
    write_address.row       <= "00001";
    write_address.col       <= "0100010";
    write_address_combined  <= letters.address.combined.to_combined (write_address);

    read_address_combined   <= letters.address.combined.to_combined (read_address_i);

    -- RAM write
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if write_enable = '1' then
                ram (conv_integer(write_address_combined)) <= write_data;
            end if;
        end if;
    end process;

    read_data   <= ram (conv_integer(read_address_combined));

    read_dot_o  <= font.get_dot (read_data, read_subaddress_i.row, read_subaddress_i.col);

end Behavioral;
