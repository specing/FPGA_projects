library ieee;
use ieee.std_logic_1164.all;

use work.definitions.all;



entity tetris_next_tetrimino is
    port
    (
        clock_i                 : in     std_logic;
        reset_i                 : in     std_logic;
        -- for Next Tetrimino selection (random)
        nt_shape_o              : out    tetrimino_shape_type;
        nt_retrieved_i          : in     std_logic;
    );
end tetris_next_tetrimino;



architecture Behavioral of tetris_next_tetrimino is

    signal tetrimino_shape_next : tetrimino_shape_type := TETRIMINO_SHAPE_L_LEFT;

begin
    -- output asignments
    nt_shape_o <= tetrimino_shape_next;

    -- crude random
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if nt_retrieved_i = '1' then
                case tetrimino_shape_next is
                when "000" => tetrimino_shape_next <= "010";
                when "001" => tetrimino_shape_next <= "010";
                when "010" => tetrimino_shape_next <= "011";
                when "011" => tetrimino_shape_next <= "100";
                when "100" => tetrimino_shape_next <= "101";
                when "101" => tetrimino_shape_next <= "110";
                when "110" => tetrimino_shape_next <= "111";
                when "111" => tetrimino_shape_next <= "001";
                when others => report "Oops" severity FAILURE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
