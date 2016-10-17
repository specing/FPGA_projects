library ieee;
use ieee.std_logic_1164.all;



entity testbench_ps2 is
entity testbench_ps2;



architecture behavior of testbench_ps2 is
   --Inputs
   signal clock_i       : std_logic := '0';
   signal reset_i       : std_logic := '0';
   signal ps2_data_i    : std_logic := '0';
   signal ps2_clock_i   : std_logic := '0';

   --Outputs
   signal output_o      : std_logic;

   signal data_o        : std_logic_vector (7 downto 0);
   signal data_ready_o  : std_logic;
   signal state_o       : std_logic_vector (3 downto 0);
   signal pulse_o       : std_logic;

   -- Clock period definitions
   constant clock_i_period    : time := 10 ns;

   constant ps2_clock_before  : time := 10 us;
   constant ps2_clock_after   : time := 15 us;
   constant ps2_clock_to_high : time := 50 us;
   constant ps2_clock_to_low  : time := 50 us;

begin

   uut: entity work.ps2_controller
   port map (
      clock_i        => clock_i,
      reset_i        => reset_i,

      ps2_data_i     => ps2_data_i,
      ps2_clock_i    => ps2_clock_i,

      data_o         => data_o,
      data_ready_o   => data_ready_o,

      state_o        => state_o,
      pulse_o        => pulse_o
   );

   -- Clock process definitions
   clock_i_process: process
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
      reset_i        <= '1';
      ps2_data_i     <= '1';
      ps2_clock_i    <= '1';
      wait for 100 ns;
      reset_i        <= '0';

      -- posiljam D : 0x23
      wait for clock_i_period*100000; -- 1 ms
      -- start bit
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b0: 1
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '1';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b1: 1
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '1';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b2: 0
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b3: 0
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b4: 0
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b5: 1
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '1';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b6: 0
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- b7: 0
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';


      -- parity
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '0';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- stop
      wait for ps2_clock_to_low - ps2_clock_before;
      ps2_data_i     <= '1';
      wait for ps2_clock_before;
      ps2_clock_i    <= '0';
      wait for ps2_clock_to_high;
      ps2_clock_i    <= '1';

      -- insert stimulus here
      wait;
   end process;
end;
