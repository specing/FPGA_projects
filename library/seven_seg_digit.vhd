-- A translator for one digit of a seven segment segment
-- assuming A is connected to the leftmost bit of segment_o.
-- and active when the corresponding bit of segment_o is 1
library IEEE;
use		IEEE.std_logic_1164.all;



entity seven_seg_digit is
	port
	(
		bcd_i			: in	std_logic_vector (3 downto 0);
		segment_o		: out	std_logic_vector (6 downto 0)
	);
end seven_seg_digit;



architecture Behavioral of seven_seg_digit is

begin

	with bcd_i select segment_o <=
		"1111110" when "0000", -- 0
		"0110000" when "0001", -- 1
		"1101101" when "0010", -- 2
		"1111001" when "0011", -- 3

		"0110011" when "0100", -- 4
		"1011011" when "0101", -- 5
		"0011111" when "0110", -- 6
		"1110000" when "0111", -- 7

		"1111111" when "1000", -- 8
		"1110011" when "1001", -- 9
		"1110111" when "1010", -- A
		"0011111" when "1011", -- B

		"1001110" when "1100", -- C
		"0111101" when "1101", -- D
		"1001111" when "1110", -- E
		"1000111" when "1111", -- F

		"0000000" when others;

end Behavioral;
