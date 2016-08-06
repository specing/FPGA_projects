library ieee;
use ieee.math_real.all;



package util is

    -- Given maximum value that a std_logic_vector must store, return
    -- the minimum width of such a vector
    function compute_width (max : natural) return natural;

end package util;



package body util is

    function compute_width (max : natural) return natural is
    begin
        return natural (CEIL (LOG2 (real (max) ) ) );
    end function compute_width;

end package body util;
