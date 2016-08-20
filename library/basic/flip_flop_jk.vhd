library ieee;
use ieee.std_logic_1164.all;

library flib;
use flib.basic.all;



entity flip_flop_jk is
    generic
    (
        reset_value : std_logic := '0'
    );
    port
    (
        clock_i : in     std_logic;
        reset_i : in     std_logic;
        j_i     : in     std_logic;
        k_i     : in     std_logic;
        q_o     : out    std_logic
    );
end flip_flop_jk;



architecture Behavioral of flip_flop_jk is

    signal q : std_logic;

begin
    q_o <= q;

    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                q <= reset_value;
            else
                if j_i = '1' and k_i = '0' then
                    q <= '1';
                elsif j_i = '0' and k_i = '1' then
                    q <= '0';
                elsif j_i = '0' and k_i = '0' then
                    q <= q;
                else
                    q <= not q;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
