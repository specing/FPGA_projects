library ieee;
use ieee.std_logic_1164.all;



package basic is

    component comparator is
        port
        (
            a_i     : in     std_logic_vector;
            b_i     : in     std_logic_vector;
            eq_o    : out    std_logic
        );
    end component comparator;


    component counter is
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
    end component counter;


    component flip_flop_jk is
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
    end component flip_flop_jk;


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


    component falling_edge_detector is
        port
        (
            clock_i     : in     std_logic;
            reset_i     : in     std_logic;
            input_i     : in     std_logic;
            output_o    : out    std_logic
        );
    end component falling_edge_detector;

end package basic;
