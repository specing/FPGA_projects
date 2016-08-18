library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity counter is
    generic
    (
        width           : positive
    );
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;
        count_enable_i  : in     std_logic;
        count_o         : out    std_logic_vector (width - 1 downto 0)
    );
end counter;



architecture Behavioral of counter is

    signal count        : std_logic_vector (width - 1 downto 0);

begin

    count_o             <= count;

    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                count <= (others => '0');
            else
                if count_enable_i = '1' then
                    count <= count + '1';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
