library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;



entity counter_until is
    generic
    (
        width           : positive;
        step            : std_logic := '1' -- up
    );
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;
        enable_i        : in     std_logic;
        reset_when_i    : in     std_logic_vector (width - 1 downto 0);
        reset_value_i   : in     std_logic_vector (width - 1 downto 0);
        count_o         : out    std_logic_vector (width - 1 downto 0);
        count_at_top_o  : out    std_logic;
        overflow_o      : out    std_logic
    );
end counter_until;



architecture Behavioral of counter_until is

    signal count        : std_logic_vector (width - 1 downto 0)
                        :=reset_value_i;

    signal count_at_top : std_logic;

begin
    count_o         <= count;
    overflow_o      <= count_at_top and enable_i;
    count_at_top_o  <= count_at_top;

    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                count <= reset_value_i;
            else
                if enable_i = '1' then
                    if count_at_top = '1' then
                        count <= reset_value_i;
                    elsif step = '1' then
                        count <= count + '1';
                    else
                        count <= count - '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (count, reset_when_i)
    begin
        if count = reset_when_i then
            count_at_top <= '1';
        else
            count_at_top <= '0';
        end if;
    end process;

end Behavioral;
