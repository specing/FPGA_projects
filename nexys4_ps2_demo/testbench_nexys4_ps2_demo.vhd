library ieee;
use     ieee.std_logic_1164.all;



entity testbench_nexys4_ps2_demo is
end testbench_nexys4_ps2_demo;


architecture behavior of testbench_nexys4_ps2_demo is

	--Inputs
	signal clock_i			: std_logic := '0';
	signal reset_i			: std_logic := '0';
	signal ps2_data_i		: std_logic := '1';
	signal ps2_clock_i		: std_logic := '1';

	--Outputs
	signal led_o			: std_logic_vector(15 downto 0);
	signal cathode_o		: std_logic_vector(6 downto 0);
	signal anode_o			: std_logic_vector(7 downto 0);
	signal JB				: std_logic_vector(1 downto 0);

	-- Clock period definitions
	constant clock_i_period			: time := 10 ns;

	constant ps2_clock_before		: time := 10 us;
	constant ps2_clock_after		: time := 15 us;
	constant ps2_clock_to_high		: time := 50 us;
	constant ps2_clock_to_low		: time := 50 us;

	constant transmit_data			: std_logic_vector (7 downto 0) := "00100011"; -- posiljam D : 0x23

begin

	uut:				entity work.nexys4_ps2_demo
	port map
	(
		clock_i			=> clock_i,
		reset_low_i		=> not reset_i,

		led_o			=> led_o,
		cathode_o		=> cathode_o,
		anode_o			=> anode_o,

		ps2_data_i		=> ps2_data_i,
		ps2_clock_i		=> ps2_clock_i,

		JB				=> JB
	);


	-- Clock process definitions
	clock_i_process :process
	begin
		clock_i <= '0';
		wait for clock_i_period/2;
		clock_i <= '1';
		wait for clock_i_period/2;
	end process;


	-- Stimulus process
	stim_proc: process
	begin
		-- hold reset state for 100 ns.
		reset_i			<= '0';
		wait for 100 ns;

		for i in 0 to 10 loop
			wait for ps2_clock_to_low - ps2_clock_before;

			if i = 0 then
				-- start bit
				ps2_data_i		<= '0';

			elsif i = 9 then
				-- parity TODO
				ps2_data_i		<= '0';
			elsif i = 10 then
				-- stop
				ps2_data_i		<= '1';
			else
				-- data
				ps2_data_i		<= transmit_data(i - 1);
			end if;

			wait for ps2_clock_before;
			ps2_clock_i		<= '0';
			wait for ps2_clock_to_high;
			ps2_clock_i		<= '1';
		end loop;

		wait;
	end process;

end;
