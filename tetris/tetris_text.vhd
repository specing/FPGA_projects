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
    type storage_object is
      array (0 to 2 ** letters.row.width - 1, 0 to 2 ** letters.col.width - 1) of
      letter.object;

begin
    Next_Tetrimino: block

        constant ntrom : storage_object := (
          1 => (
            36     => letter.N_upper,
            37     => letter.a,
            38     => letter.s,
            39     => letter.l,
            40     => letter.e,
            41     => letter.d,
            42     => letter.n,
            43     => letter.j,
            44     => letter.i,
            others => letter.space),
          2 => (
            36     => letter.t,
            37     => letter.e,
            38     => letter.t,
            39     => letter.r,
            40     => letter.i,
            41     => letter.m,
            42     => letter.i,
            43     => letter.n,
            44     => letter.o,
            others => letter.space),
          others => (
            others => letter.space)
        );

        signal nt_read_data : letter.object;
    begin
        nt_read_data <= ntrom (to_integer (read_address_i.row), to_integer (read_address_i.col));
        read_dot_o  <= font.get_dot (nt_read_data, read_subaddress_i.row, read_subaddress_i.col);
    end block;
end Behavioral;
