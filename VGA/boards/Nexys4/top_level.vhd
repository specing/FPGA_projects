library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.numeric_std.all;



entity top_level is
	generic
	(
		row_width			: integer := 10;
		column_width		: integer := 10;

		num_of_buttons		: integer := 4
	);
	port
	(
		clock_i				: in	std_logic;
		reset_low_i			: in	std_logic;

		hsync_o				: out	std_logic;
		vsync_o				: out	std_logic;
		vga_red_o			: out	std_logic_vector(3 downto 0);
		vga_green_o			: out	std_logic_vector(3 downto 0);
		vga_blue_o			: out	std_logic_vector(3 downto 0);

		-- debug
		switches_i			: in	std_logic_vector(15 downto 0);
		btnL_i				: in	std_logic;
		btnR_i				: in	std_logic;
		btnU_i				: in	std_logic;
		btnD_i				: in	std_logic;

		led_o				: out	std_logic_vector(15 downto 0)
	);
end top_level;



architecture Behavioral of top_level is

	signal btnL				: std_logic;
	signal btnR				: std_logic;
	signal btnD				: std_logic;
	signal btnU				: std_logic;

	signal reset_i			: std_logic;

	-- vga controller related signals
	signal pixel_clock		: std_logic;
--	signal hsync			: std_logic;
--	signal vsync			: std_logic;

	-- pixel drawing related signals
	signal row				: std_logic_vector(row_width - 1 downto 0);
	signal col				: std_logic_vector(column_width - 1 downto 0);

--	signal vga_red			: std_logic_vector(3 downto 0);
--	signal vga_green		: std_logic_vector(3 downto 0);
--	signal vga_blue			: std_logic_vector(3 downto 0);

	signal en_draw			: std_logic;


	-- debug signals
	signal screen_end		: std_logic;


	signal vga_red			: std_logic_vector(3 downto 0);
	signal vga_green		: std_logic_vector(3 downto 0);
	signal vga_blue			: std_logic_vector(3 downto 0);

	signal line_left		: std_logic_vector(column_width -1 downto 0);
	signal line_right		: std_logic_vector(column_width -1 downto 0);
	signal line_top			: std_logic_vector(row_width -1 downto 0);
	signal line_bottom		: std_logic_vector(row_width -1 downto 0);

	signal led				: std_logic_vector(15 downto 0);
	signal pixel_column		: std_logic_vector(39 downto 0);

	signal pwm_count		: std_logic;

begin
	-- board reset is active low
	reset_i					<= not reset_low_i;


	-- prescale the main clock to obtain the "pixel clock"
	-- /4 for nexys 4
	Inst_counter_pixelclockprescale: entity work.counter_until
	generic map               (width => 2)
	port map
	(
		clock_i               => clock_i,
		reset_i               => reset_i,
		enable_i              => '1',
		reset_when_i          => "11",
		reset_value_i         => "00",
		count_o               => open,
		count_at_top_o        => open,
		overflow_o            => pixel_clock
	);


	Inst_VGA_controller:	entity work.VGA_controller
	generic map
	(
		row_width			=> 10,
		column_width		=> 10
	)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		pixelclock_i		=> pixel_clock,

		hsync_o				=> hsync_o,
		vsync_o				=> vsync_o,
		col_o				=> col,
		row_o				=> row,
		en_draw_o			=> en_draw,

		screen_end_o		=> screen_end
	);



	process(en_draw, vga_red, vga_green, vga_blue)
	begin
		if en_draw = '1' then
			vga_red_o				<= vga_red;
			vga_green_o				<= vga_green;
			vga_blue_o				<= vga_blue;
		else
			vga_red_o				<= "0000";
			vga_green_o				<= "0000";
			vga_blue_o				<= "0000";
		end if;
	end process;

	-- ==========================
	-- figure out what to display
	-- ==========================

	buttons_logic: block
		signal buttons_pulse	: std_logic_vector(num_of_buttons - 1 downto 0);
	begin

		-- sync & rising edge detectors on input buttons
		Inst_button_input:entity work.button_input
		generic map       ( num_of_buttons => 4 )
		port map
		(
			clock_i       => clock_i,
			reset_i       => reset_i,
			buttons_i     => btnL_i & btnR_i & btnU_i & btnD_i,
			buttons_ack_i => (others => '1'),
			buttons_o     => buttons_pulse
		);

		btnL	<= buttons_pulse(0);
		btnR	<= buttons_pulse(1);
		btnU	<= buttons_pulse(2);
		btnD	<= buttons_pulse(3);
	end block;

	-- 4 registers, each for the corresponding line
	Inst_GR_line_lelft:	entity work.generic_register
	generic map
	(
		reset_value		=> 100
	)
	port map
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnL,
		data_i			=> switches_i (column_width - 1 downto 0),
		data_o			=> line_left
	);

	Inst_GR_line_right:	entity work.generic_register
	generic map
	(
		reset_value		=> 539
	)
	port map
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnR,
		data_i			=> switches_i (column_width - 1 downto 0),
		data_o			=> line_right
	);

	Inst_GR_line_top:	entity work.generic_register
	generic map
	(
		reset_value		=> 100
	)
	port map
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnU,
		data_i			=> switches_i (row_width - 1 downto 0),
		data_o			=> line_top
	);

	Inst_GR_line_bottom:entity work.generic_register
	generic map
	(
		reset_value		=> 379
	)
	port map
	(
		clock_i			=> clock_i,
		reset_i			=> reset_i,
		clock_enable_i	=> btnD,
		data_i			=> switches_i (row_width - 1 downto 0),
		data_o			=> line_bottom
	);

	-- actual display value selection

	process (col, row, line_left, line_right, line_top, line_bottom, pixel_column)
	begin
		if col = std_logic_vector(to_unsigned(0, col'length))
		or col = std_logic_vector(to_unsigned(639, col'length))
		or row = std_logic_vector(to_unsigned(0, row'length))
		or row = std_logic_vector(to_unsigned(479, row'length))
		then
			vga_red					<= "1000";
			vga_green				<= "0000";
			vga_blue				<= "0100";
		elsif col = line_left  -- 0
		or col = line_right	-- 638
		or row = line_top	-- 5
		or row = line_bottom-- 478
		then
			vga_red					<= "0011";
			vga_green				<= "1000";
			vga_blue				<= "0100";
		elsif pixel_column(conv_integer( col(9 downto 4) ) ) = '1' then
			vga_red					<= "1000";
			vga_green				<= "0000";
			vga_blue				<= "0000";
		else
			vga_red					<= "0000";
			vga_green				<= "0000";
			vga_blue				<= "0000";
		end if;
	end process;


	Inst_RAM:				entity work.RAM32x40
	port map
	(
		clock_i 			=> clock_i,

		write_enable_i		=> '1',
		waddr_i			 	=> "01001",
		wdata_i				=> "0101010101010101010101010101010101010101",

		raddr_i				=> row (8 downto 4),
		rdata_o				=> pixel_column
	);

	-- dim LEDs

	process (clock_i)
	begin
		if rising_edge (clock_i) then
			pwm_count <= not pwm_count;
		end if;
	end process;

	with pwm_count select led_o <=
		led				when '0',
		(others => '0') when others;

	-- assign debug signals
	Inst_counter_screencount: entity work.counter
	generic map (width => 16)
	port map
	(
		clock_i				=> clock_i,
		reset_i				=> reset_i,
		count_enable_i		=> screen_end,
		count_o				=> led
	);

end Behavioral;
