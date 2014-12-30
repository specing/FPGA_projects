-- common anode 7 seg display

library IEEE;
use		IEEE.std_logic_1164.all;



entity seven_seg_display is
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
end seven_seg_display;



architecture Behavioral of seven_seg_display is

	COMPONENT seven_seg_digit
	PORT
	(
		bcd_i			: in	std_logic_vector (3 downto 0);
		segment_o		: out	std_logic_vector (6 downto 0)
	);
	end COMPONENT;




	signal bcd				: std_logic_vector(3 downto 0);

	signal cathodes			: std_logic_vector(6 downto 0);
	signal anodes			: std_logic_vector(7 downto 0);

begin

	anodes_o				<= anodes;
	cathodes_o				<= cathodes;

	Inst_seven_seg_digit:	seven_seg_digit
	PORT MAP
	(
		bcd_i				=> bcd,
		segment_o			=> cathodes
	);


	process (clock_i)
	begin
		if clock_i'event and clock_i = '1' then
			if sig_cycle_i = '1' then
				case anodes is
				when "10000000" =>
					anodes	<= "00000001";
					bcd		<= bcd0_i;
				when "00000001" =>
					anodes	<= "00000010";
					bcd		<= bcd1_i;
				when "00000010" =>
					anodes	<= "00000100";
					bcd		<= bcd2_i;
				when "00000100" =>
					anodes	<= "00001000";
					bcd		<= bcd3_i;
				when "00001000" =>
					anodes	<= "00010000";
					bcd		<= bcd4_i;
				when "00010000" =>
					anodes	<= "00100000";
					bcd		<= bcd5_i;
				when "00100000" =>
					anodes	<= "01000000";
					bcd		<= bcd6_i;
				when "01000000" =>
					anodes	<= "10000000";
					bcd		<= bcd7_i;
				when others =>
					anodes	<= "00000001";
					bcd		<= bcd0_i;
				end case;
			end if;
		end if;
	end process;

end Behavioral;
