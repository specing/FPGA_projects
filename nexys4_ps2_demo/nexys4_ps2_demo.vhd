library IEEE;
use		IEEE. std_logic_1164	. all;
use		IEEE. std_logic_ARITH	. all;
use		IEEE. std_logic_UNSIGNED. all;
use		IEEE. Numeric_STD		. all;



entity nexys4_ps2_demo is
	Port
	(
		clock_i		: in	std_logic;
		reset_low_i	: in	std_logic;

		led_o		: out	std_logic_vector(15 downto 0);
		cathode_o	: out	std_logic_vector(0 to 6);
		anode_o		: out	std_logic_vector(7 downto 0);

		ps2_data_i	: in	std_logic;
		ps2_clock_i	: in	std_logic;

		JB			: out	std_logic_vector(1 downto 0)
	);
end nexys4_ps2_demo;



architecture Behavioral of nexys4_ps2_demo is


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

	signal ps2_data				: std_logic_vector(7 downto 0);
	signal ps2_state			: std_logic_vector(3 downto 0);
	signal ps2_pulse			: std_logic;

	signal cathodes				: std_logic_vector(6 downto 0);
	signal anodes				: std_logic_vector(7 downto 0);

	signal led					: std_logic_vector(15 downto 0);
	signal dim_flag				: std_logic;
	
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
		count_enable_i		=> '1',
		reset_when_i		=> std_logic_vector(to_unsigned(999_999, counter_osc'length)),
		count_o				=> counter_osc,
		overflow_o			=> counter_osc_overflow
	);

	-- prescales miliseconds to seconds
	-- 1000 ms to s, need 10 bits
	Inst_prescaler_ms:		entity work.counter_until
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
	Inst_counter_1s:		entity work.counter
	GENERIC MAP (width => 16) PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
--		count_enable_i		=> '0',
		count_enable_i		=> ps2_pulse,
		count_o				=> counter_1s
	);



	
	Inst_7seg:				entity work.seven_seg_display
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
		bcd5_i				=> ps2_state,
		bcd6_i				=> ps2_data(3 downto 0),
		bcd7_i				=> ps2_data(7 downto 4),

		anodes_o			=> anodes,
		cathodes_o			=> cathodes
	);

	-- Nexys 4's cathodes have A on right and inverted, but our seven_seg_digit has A on the left
	-- cathodes_o declared in reverse

	-- dim LEDs and 7seg disp
	process (clock_i)
	begin
		if clock_i'event and clock_i = '1' then
			if reset_i = '1' then
				dim_flag		<= '0';
				led_o			<= (others => '0');
				anode_o			<= (others => '1');
			else
				if dim_flag = '0' then
					dim_flag		<= '1';
					led_o			<= (others => '0');
					anode_o			<= (others => '1');
				else
					dim_flag		<= '0';
					led_o			<= led;
					anode_o			<= not anodes;
				end if;
			end if;
		end if;
	end process;

	cathode_o				<= not cathodes(6 downto 0);
	-- Nexys 4's anodes are active low (have transistors for amplification)



	Inst_ps2_controller:	entity work.ps2_controller
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,

		ps2_data_i			=> ps2_data_i,
		ps2_clock_i			=> ps2_clock_i,

		data_o				=> ps2_data,
		data_ready_o		=> led(15),
		
		state_o				=> ps2_state,
		pulse_o				=> ps2_pulse
	);

	led (7 downto 0)		<= ps2_data;
	led (14 downto 8)		<= (others => '0');
	JB (0)					<= ps2_pulse;
	JB (1)					<= ps2_clock_i;

end Behavioral;
