library IEEE;
use		IEEE. std_logic_1164	. all;
use		IEEE. std_logic_ARITH	. all;
use		IEEE. std_logic_UNSIGNED. all;
use		IEEE. Numeric_STD		. all;



entity nexys4_7seg_demo is
	Port
	(
		clock_i		: in	std_logic;
		reset_low_i	: in	std_logic;

		led_o		: out	std_logic_vector(15 downto 0);
		cathodes_o	: out	std_logic_vector(0 to 6);
		anodes_o	: out	std_logic_vector(7 downto 0)
	);
end nexys4_7seg_demo;



architecture Behavioral of nexys4_7seg_demo is


	COMPONENT counter
	GENERIC
	(
		width			: integer := 8
	);
	PORT
	(
		clock_i			: IN	std_logic;
		reset_i			: IN	std_logic;
		count_enable_i	: IN	std_logic;
		count_o			: OUT	std_logic_vector(width - 1 downto 0)
	);
	END COMPONENT;	


	-- actual reset, because board reset is inverted
	signal reset_i				: std_logic;

	-- counts seconds
	signal counter_1s			: std_logic_vector(15 downto 0);

	-- counts miliseconds
	signal counter_1ms			: std_logic_vector(9 downto 0);
	signal counter_1ms_overflow	: std_logic;

	-- counts cycles
	signal counter_osc			: std_logic_vector(16 downto 0);
	signal counter_osc_overflow	: std_logic;

begin
	--board reset is inverted
	reset_i					<= not reset_low_i;
	
	
	-- prescales cycles to miliseconds
	-- Nexys 4 OSC is 100Mhz, that is 100,000,000 cycles to a second
	-- or 100,000 cycles for a milisecond. ceil( log_2(100,000) ) = 17 bits

	Inst_prescaler_osc:		entity work.counter_until
	GENERIC MAP (width => 17) PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> '1',
		reset_when_i		=> std_logic_vector(to_unsigned(999_999, counter_osc'length)),
		reset_value_i		=> std_logic_vector(to_unsigned(0,       counter_osc'length)),
		count_o				=> counter_osc,
		overflow_o			=> counter_osc_overflow,
		count_at_top_o		=> open
	);

	Inst_prescaler_ms:		entity work.counter_until
	GENERIC MAP (width => 10) PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		enable_i			=> counter_osc_overflow,
		reset_when_i		=> std_logic_vector(to_unsigned(999, counter_1ms'length)),
		reset_value_i		=> std_logic_vector(to_unsigned(0,   counter_1ms'length)),
		count_o				=> counter_1ms,
		overflow_o			=> counter_1ms_overflow,
		count_at_top_o		=> open
	);

	-- 16-bit seconds counter
	Inst_counter_1s:		counter
	GENERIC MAP (width => 16) PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		count_enable_i		=> counter_1ms_overflow,
		count_o				=> counter_1s
	);



	led_o					<= counter_1s;


	Inst_7seg:				entity work.seven_seg_display
    generic map
    (
        f_clock              => 100_000_000.0,
        num_of_digits        => 8,
        dim_top              => 3,

        -- bit values for segment on
        -- Nexys 4's anodes are active low (have transistors for amplification)
        anode_on             => '0',
        -- Nexys 4's cathodes have A on right and inverted, but our seven_seg_digit has A on the left
        cathode_on           => '0'
    )
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,

        bcd_digits_i		=> counter_1s & "0000" & "0000" & "0000" & "0000",

		anodes_o			=> anodes_o,
		cathodes_o			=> cathodes_o
	);

end Behavioral;
