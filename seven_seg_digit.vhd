-- A translator for one digit of a seven segment segment
-- assuming A is connected to the leftmost bit of segment_o.
-- and active when the corresponding bit of segment_o is 1

library IEEE;
use		IEEE.std_logic_1164.all;



entity seven_seg_digit is
	Port
	(
		bcd_i			: in	std_logic_vector (3 downto 0);
		segment_o		: out	std_logic_vector (6 downto 0)
	);
end seven_seg_digit;



architecture Behavioral of seven_seg_digit is

	signal segment		: std_logic_vector (6 downto 0);

begin

	segment_o			<= segment;


	process (bcd_i)
	begin
		case bcd_i is
		when "0000" => segment <= "1111110"; -- 0
		when "0001" => segment <= "0110000"; -- 1
		when "0010" => segment <= "1101101"; -- 2
		when "0011" => segment <= "1111001"; -- 3

		when "0100" => segment <= "0110011"; -- 4
		when "0101" => segment <= "1011011"; -- 5
		when "0110" => segment <= "0011111"; -- 6
		when "0111" => segment <= "1110000"; -- 7

		when "1000" => segment <= "1111111"; -- 8
		when "1001" => segment <= "1110011"; -- 9
		when "1010" => segment <= "1110111"; -- A
		when "1011" => segment <= "0011111"; -- B

		when "1100" => segment <= "1001110"; -- C
		when "1101" => segment <= "0111101"; -- D
		when "1110" => segment <= "1001111"; -- E
		when "1111" => segment <= "1000111"; -- F

		when others => segment <= "1111111";
		end case;
	end process;

end Behavioral;
