library ieee;
use ieee.std_logic_1164.all;



package basic is

    component generic_register is
        generic (reset_value : natural := 0);
        port
        (
           clock_i          : in    std_logic;
           reset_i          : in    std_logic;
           clock_enable_i   : in    std_logic;
           data_i           : in    std_logic_vector;
           data_o           : out   std_logic_vector
        );
    end component generic_register;

end package basic;
