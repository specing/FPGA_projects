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
		cathode_o	: out	std_logic_vector(0 to 6);
		anode_o		: out	std_logic_vector(7 downto 0)
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


	COMPONENT counter_until
	GENERIC
	(
		width			: integer := 8
	);
	PORT
	(
		clock_i			: IN	std_logic;
		reset_i			: IN	std_logic;
		count_enable_i	: IN	std_logic;
		reset_when_i	: IN	std_logic_vector(width - 1 downto 0);
		count_o			: OUT	std_logic_vector(width - 1 downto 0);
		overflow_o		: OUT	std_logic
	);
	END COMPONENT;


	COMPONENT seven_seg_display
	Port
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;
		sig_cycle_i		: in	std_logic;

		bcd0_i			: in	std_logic_vector (3 downto 0);
		bcd1_i			: in	std_logic_vector (3 downto 0);
		bcd2_i			: in	std_logic_vector (3 downto 0);
		bcd3_i			: in	std_logic_vector (3 downto 0);
		bcd4_i			: in	std_logic_vector (3 downto 0);
		bcd5_i			: in	std_logic_vector (3 downto 0);
		bcd6_i			: in	std_logic_vector (3 downto 0);
		bcd7_i			: in	std_logic_vector (3 downto 0);

		anodes_o		: out	std_logic_vector (7 downto 0);
		cathodes_o		: out	std_logic_vector (6 downto 0)
	);
	end COMPONENT;



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


	signal bcd					: std_logic_vector(3 downto 0);
	signal bcd0					: std_logic_vector(3 downto 0);
	signal bcd1					: std_logic_vector(3 downto 0);
	signal bcd2					: std_logic_vector(3 downto 0);
	signal bcd3					: std_logic_vector(3 downto 0);
	signal bcd4					: std_logic_vector(3 downto 0);
	signal bcd5					: std_logic_vector(3 downto 0);
	signal bcd6					: std_logic_vector(3 downto 0);
	signal bcd7					: std_logic_vector(3 downto 0);

	signal cathodes				: std_logic_vector(6 downto 0);
	signal anodes				: std_logic_vector(7 downto 0);

begin
	--board reset is inverted
	reset_i					<= not reset_low_i;
	
	
	-- prescales cycles to miliseconds
	-- Nexys 4 OSC is 100Mhz, that is 100,000,000 cycles to a second
	-- or 100,000 cycles for a milisecond. ceil( log_2(100,000) ) = 17 bits

	Inst_prescaler_osc:		counter_until
	GENERIC MAP (width => 17) PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		count_enable_i		=> '1',
		reset_when_i		=> std_logic_vector(to_unsigned(999_999, counter_osc'length)),
		count_o				=> counter_osc,
		overflow_o			=> counter_osc_overflow
	);

	-- prescales miliseconds to seconds
	-- 1000 ms to s, need 10 bits
	Inst_prescaler_ms:		counter_until
	GENERIC MAP (width => 10) PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		count_enable_i		=> counter_osc_overflow,
		reset_when_i		=> std_logic_vector(to_unsigned(999, counter_1ms'length)),
		count_o				=> counter_1ms,
		overflow_o			=> counter_1ms_overflow
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


	
	Inst_7seg:				seven_seg_display
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		sig_cycle_i			=> counter_osc_overflow,

		bcd0_i				=> counter_1s(3 downto 0),
		bcd1_i				=> counter_1s(7 downto 4),
		bcd2_i				=> counter_1s(11 downto 8),
		bcd3_i				=> counter_1s(15 downto 12),
		bcd4_i				=> (others => '0'),
		bcd5_i				=> (others => '0'),
		bcd6_i				=> (others => '0'),
		bcd7_i				=> (others => '0'),

		anodes_o			=> anodes,
		cathodes_o			=> cathodes
	);

	-- Nexys 4's cathodes have A on right and inverted, but our seven_seg_digit has A on the left
	-- cathodes_o declared in reverse
	cathode_o				<= not cathodes(6 downto 0);
	-- Nexys 4's anodes are active low (have transistors for amplification)
	anode_o					<= not anodes;

end Behavioral;
