library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library flib;
use flib.basic.all;



entity generic_register is
    generic
    (
        reset_value : natural := 0
    );
    port
    (
        clock_i         : in    std_logic;
        reset_i         : in    std_logic;
        clock_enable_i  : in    std_logic;
        data_i          : in    std_logic_vector;
        data_o          : out   std_logic_vector
    );
end generic_register;



architecture Behavioral of generic_register is

    constant data_on_reset  : std_logic_vector(data_i'range)
                            :=std_logic_vector(to_unsigned(reset_value, data_i'length));

    signal data             : std_logic_vector(data_i'range)
                            :=data_on_reset;

begin

    data_o <= data;

    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                data <= data_on_reset;
            elsif clock_enable_i = '1' then
                data <= data_i;
            end if;
        end if;
    end process;

end Behavioral;
