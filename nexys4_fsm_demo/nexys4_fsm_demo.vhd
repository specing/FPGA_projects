library IEEE;
use		IEEE.std_logic_1164.	all;
use		IEEE.std_logic_ARITH.	all;
use		IEEE.std_logic_UNSIGNED.all;
use		IEEE.Numeric_STD.		all;



entity nexys4_fsm_demo is
	Port
	(
		clock_i			: in	std_logic;
		reset_low_i		: in	std_logic;
		btnC_i			: in	std_logic;
		led_o			: out	std_logic_vector(15 downto 0)
	);
end nexys4_fsm_demo;



architecture Behavioral of nexys4_fsm_demo is


	COMPONENT rising_edge_detector
	PORT
	(
		clock_i			: in	std_logic;
		reset_i			: in	std_logic;
		input_i			: in	std_logic;
		output_o		: out	std_logic
	);
	END COMPONENT;


	COMPONENT counter
	GENERIC
	(
		width			: integer := 8
	);
	PORT
	(
		clock_i			: in	std_logic;
		count_enable_i	: in	std_logic;
		reset_i			: in	std_logic;
		count_o			: out	std_logic_vector(width - 1 downto 0)
	);
	END COMPONENT;	




	signal reset_i		: std_logic;

	signal input		: std_logic;

	signal count		: std_logic_vector(7 downto 0);
	
	signal sig_negedge	: std_logic;

begin

	-- inverted input ... negative edge detection
	input					<= not btnC_i;
	reset_i					<= not reset_low_i;

	led_o(7 downto 0)		<= count;
	led_o(15 downto 8)		<= (others => '0');
	

	Inst_rising_detector:	rising_edge_detector
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		input_i				=> input,
		output_o			=> sig_negedge
	);


	Inst_counter:			counter
	GENERIC MAP (width => 8)
	PORT MAP
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		count_enable_i		=> sig_negedge,
		count_o				=> count
	);

end Behavioral;
