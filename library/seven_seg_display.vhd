library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library flib;



-- common anode 7 seg display
entity seven_seg_display is
    generic
    (
        f_clock         : positive; -- := 100_000_000;
        num_of_digits   : positive; -- := 8;
        dim_top         : natural; --  := 3;
        -- bit values for segment on
        -- Nexys 4's anodes are active low (have transistors for amplification)
        anode_on        : std_logic := '0';
        -- Nexys 4's cathodes have A on right and inverted, but our seven_seg_digit has A on the left
        cathode_on      : std_logic := '0'
    );
    port
    (
        clock_i         : in     std_logic;
        reset_i         : in     std_logic;

        bcd_digits_i    : in     std_logic_vector (num_of_digits*4 - 1 downto 0);

        anodes_o        : out    std_logic_vector (num_of_digits - 1 downto 0);
        cathodes_o      : out    std_logic_vector (6 downto 0) -- no dot
    );
end seven_seg_display;



architecture Behavioral of seven_seg_display is

    constant anode_off          : std_logic := not anode_on;
    constant cathode_off        : std_logic := not cathode_on;

    constant prescaler_divisor  : positive  := f_clock / 1000; -- 1 millisecond
    constant prescaler_top      : natural   := integer (prescaler_divisor) - 1;
    constant prescaler_width    : natural   := flib.util.compute_width (prescaler_top);
    signal   prescaler_overflow : std_logic;

    signal   bcd                : std_logic_vector (3 downto 0);
    signal   cathodes           : std_logic_vector (6 downto 0); -- no dot
    signal   anodes             : std_logic_vector (num_of_digits - 1 downto 0)
                                := (0 => anode_on, others => anode_off);

    constant dim_width          : natural   := flib.util.compute_width (dim_top + 1);
    signal   dim_overflow       : std_logic;

begin

    -- invert cathodes if needed
    with cathode_on select cathodes_o <=
      not cathodes when '0',
      cathodes     when others;

    Inst_seven_seg_digit: entity work.seven_seg_digit
    port map
    (
        bcd_i       => bcd,
        segment_o   => cathodes
    );

    -- display toggle signal prescaler
    inst_prescaler: entity work.counter_until
    generic map         ( width => prescaler_width)
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => '1',
        reset_when_i    => std_logic_vector (to_unsigned (prescaler_top, prescaler_width)),
        reset_value_i   => std_logic_vector (to_unsigned (0, prescaler_width)),
        count_o         => open,
        count_at_top_o  => open,
        overflow_o      => prescaler_overflow
    );

    --dim_enable <= prescaler_count(ceil(prescaler_width / 2)e_off) and prescaler_overflow;
    -- display dimming counter
    inst_dimmer: entity work.counter_until
    generic map         ( width => dim_width)
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => '1',
        reset_when_i    => std_logic_vector (to_unsigned (dim_top, dim_width)),
        reset_value_i   => std_logic_vector (to_unsigned (0, dim_width)),
        count_o         => open,
        count_at_top_o  => open,
        overflow_o      => dim_overflow
    );

    with dim_overflow select anodes_o <=
      anodes when '1', --std_logic_vector(to_unsigned(0, dim_width)),
      (others => anode_off) when others;


    -- digit selector
    process (clock_i)
    begin
        if rising_edge (clock_i) then
            if reset_i = '1' then
                anodes <= (0 => anode_on, others => anode_off);
            elsif prescaler_overflow = '1' then
                -- starting (loop around)
                anodes (0) <= anodes (num_of_digits - 1);
                -- remaining ones
                for i in 1 to num_of_digits - 1 loop
                    anodes (i) <= anodes (i - 1);
                end loop;
            end if;
        end if;
    end process;


    -- combinatorial selector for which of the incoming digits goes onto the
    -- decoder and subsequently on the display
    process (bcd_digits_i, anodes)
    begin
        bcd <= (others => '0');

        for i in 0 to num_of_digits - 1 loop
            if anodes(i) = anode_on then
                bcd (0) <= bcd_digits_i (4 * i);
                bcd (1) <= bcd_digits_i (4 * i + 1);
                bcd (2) <= bcd_digits_i (4 * i + 2);
                bcd (3) <= bcd_digits_i (4 * i + 3);
            end if;
        end loop;
    end process;

end Behavioral;
