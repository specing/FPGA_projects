library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

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
                ram (to_integer (write_address_combined)) <= write_data;
            end if;
        end if;
    end process;

    read_data   <= ram (to_integer (read_address_combined));

    Next_Tetrimino: block
        type ntrom_storage is
          array (0 to 2 ** letters.row.width - 1, 0 to 2 ** letters.col.width - 1) of
          letter.object;

        constant ntrom : ntrom_storage := (
          1 => (
            34     => letter.N_upper,
            35     => letter.a,
            36     => letter.s,
            37     => letter.l,
            38     => letter.e,
            39     => letter.d,
            40     => letter.n,
            41     => letter.j,
            42     => letter.i,
            others => letter.space),
          2 => (
            34     => letter.t,
            35     => letter.e,
            36     => letter.t,
            37     => letter.r,
            38     => letter.i,
            39     => letter.m,
            40     => letter.i,
            41     => letter.n,
            42     => letter.o,
            others => letter.space),
          others => (
            others => letter.space)
        );

        signal nt_read_data : letter.object;
    begin
        nt_read_data <= ntrom (to_integer (read_address_i.row), to_integer (read_address_i.col));
        read_dot_o  <= font.get_dot (read_data, read_subaddress_i.row, read_subaddress_i.col)
                    or font.get_dot (nt_read_data, read_subaddress_i.row, read_subaddress_i.col);
    end block;
end Behavioral;
