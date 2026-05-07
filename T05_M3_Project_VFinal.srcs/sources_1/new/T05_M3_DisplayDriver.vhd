----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 11/14/2024 12:48:08 PM
-- Design Name: Data generator
-- Module Name: T05_M3_DisplayDriver - Behavioral
-- Project Name: T05_M3_Project
-- Target Devices: Basys 3
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity T05_M3_DisplayDriver is
    Port ( Display1: in  STD_LOGIC_VECTOR (3 downto 0);
           Display2: in  STD_LOGIC_VECTOR (3 downto 0);
           Display3: in  STD_LOGIC_VECTOR (3 downto 0);
           Display4: in  STD_LOGIC_VECTOR (3 downto 0);
           i_digitSelect : in  STD_LOGIC_vector(1 downto 0);
		   o_segmentAnodes : out STD_LOGIC_VECTOR (3 downto 0);
		   o_segmentCathodes : out  STD_LOGIC_VECTOR (6 downto 0));
end T05_M3_DisplayDriver;

architecture Behavioral of T05_M3_DisplayDriver is
    signal Digit : std_logic_vector (3 downto 0);
begin

digitSelect : process (Display1, Display2, Display3,Display4, i_digitSelect)
begin
  case i_digitSelect is                                                -- This is from the binary counter 
    when "00" => Digit <= Display1; 
        o_segmentAnodes<= "1110";
    when "01" => Digit <= Display2; 
        o_segmentAnodes<= "1101"; 
    when "10" => Digit <= Display3; 
        o_segmentAnodes<= "1011";
    when "11"=> Digit <= Display4;
        o_segmentAnodes<= "0111";
    when others => Digit <= "0000"; 
        o_segmentAnodes <= "0000";
  end case;
end process digitSelect;

			
    with Digit select                                       
    o_segmentCathodes <= 
      "0000001" when "0000",   -- 0
      "1001111" when "0001",   -- 1
      "0010010" when "0010",   -- 2
      "0000110" when "0011",   -- 3
      "1001100" when "0100",   -- 4
      "0100100" when "0101",   -- 5
      "0100000" when "0110",   -- 6
      "0001111" when "0111",   -- 7
      "0000000" when "1000",   -- 8
      "0000100" when "1001",   -- 9
      "0001000" when "1010",   -- A
      "1100000" when "1011",   -- B
      "0110001" when "1100",   -- C
      "1000010" when "1101",   -- D
      "0110000" when "1110",   -- E
      "0111000" when "1111",   -- F
      "1111111" when others;   -- Default case


end Behavioral;