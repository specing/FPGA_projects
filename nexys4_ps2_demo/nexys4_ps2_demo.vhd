library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_arith.all;
use     ieee.std_logic_unsigned.all;
use     ieee.numeric_std.all;



entity nexys4_ps2_demo is
	port
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



architecture behavioral of nexys4_ps2_demo is

	-- actual reset, because board reset is inverted
	signal reset_i				: std_logic;

	-- counts seconds
	signal counter_1s			: std_logic_vector(15 downto 0);

	signal ps2_data				: std_logic_vector(7 downto 0);
	signal ps2_data_ready		: std_logic;
	signal ps2_state			: std_logic_vector(3 downto 0);
	signal ps2_pulse			: std_logic;

	signal led					: std_logic_vector(15 downto 0);

begin
	--board reset is inverted
	reset_i					<= not reset_low_i;

	-- 16-bit seconds counter
	Inst_counter_1s:		entity work.counter
	generic map				(width => 16)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
--		count_enable_i		=> '0',
		count_enable_i		=> ps2_pulse,
		count_o				=> counter_1s
	);

	Inst_7seg:				entity work.seven_seg_display
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		bcd_digits_i		=> counter_1s & "0000" & ps2_state & ps2_data,
		anodes_o			=> anode_o,
		cathodes_o			=> cathode_o
	);


	Inst_ps2_controller:	entity work.ps2_controller
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,

		ps2_data_i			=> ps2_data_i,
		ps2_clock_i			=> ps2_clock_i,

		data_o				=> ps2_data,
		data_ready_o		=> ps2_data_ready,

		state_o				=> ps2_state,
		pulse_o				=> ps2_pulse
	);

	process (clock_i)
	begin
		if rising_edge (clock_i) then
			if ps2_data_ready = '1' then
				led (7 downto 0) <= ps2_data;
			end if;
		end if;
	end process;


	-- debug part --
	led (15)				<= ps2_data_ready;
	led (14 downto 8)		<= (others => '0');
	JB (0)					<= ps2_data_i;
	JB (1)					<= ps2_clock_i;
	led_o <= led;

end behavioral;
