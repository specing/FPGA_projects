library ieee;
use ieee.std_logic_1164.all;

library flib;
use flib.basic.all;



entity flip_flop_jk is
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;
        reset_value_i   : in     std_logic;
        j_i             : in     std_logic;
        k_i             : in     std_logic;
        q_o             : out    std_logic
    );
end flip_flop_jk;



architecture Behavioral of flip_flop_jk is
begin

    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                q_o <= reset_value_i;
            else
                if    j_i = '1' and k_i = '0' then  q_o <= '1';
                elsif j_i = '0' and k_i = '1' then  q_o <= '0';
                elsif j_i = '0' and k_i = '0' then  q_o <= q_o;
                elsif j_i = '1' and k_i = '1' then  q_o <= not q_o;
                else q_o <= '-'; -- unsynthesizable statement: report "Oops" severity FAILURE;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
