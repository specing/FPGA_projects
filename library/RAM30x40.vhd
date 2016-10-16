library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity RAM32x40 is
   port (
      clock_i        : in     std_logic;

      write_enable_i : in     std_logic;
      waddr_i        : in     std_logic_vector (4 downto 0);
      wdata_i        : in     std_logic_vector (0 to 39);

      raddr_i        : in     std_logic_vector (4 downto 0);
      rdata_o        : out    std_logic_vector (0 to 39)
   );
end RAM32x40;



architecture Behavioral of RAM32x40 is

   type ram_type is array (29 downto 0) of std_logic_vector (0 to 39);
   signal RAM : ram_type;

   signal dataOUT : std_logic_vector (0 to 39);

begin

   rdata_o   <= dataOUT;

   process (clock_i)
   begin
      if rising_edge (clock_i) then
         if write_enable_i = '1' then
            RAM (conv_integer (waddr_i)) <= wdata_i;
         end if;
      end if;
   end process;

   dataOUT <= RAM (conv_integer (raddr_i));

end Behavioral;
