----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 11/14/2024 01:05:21 PM
-- Design Name: Data generator
-- Module Name: T05_M3_BinaryCounter - Behavioral
-- Project Name: T05_M3_Project
-- Target Devices: Basys 3
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity T05_M3_BinaryCounter is
    Port ( i_Clk: in STD_LOGIC;
           i_ClkEn250Hz: in STD_LOGIC;
           i_Reset :in STD_LOGIC;
	       o_BinaryCounter : out STD_LOGIC_VECTOR(1 downto 0));
end T05_M3_BinaryCounter;

architecture Behavioral of T05_M3_BinaryCounter is

    signal r_Count : STD_LOGIC_VECTOR(1 downto 0) := "00";

begin


    counter: process (i_Clk,i_ClkEn250Hz, i_Reset)
    begin
        if (i_Reset = '1') then
        r_Count <= "00";
        elsif (rising_edge(i_Clk)) then                                  
            if i_ClkEn250Hz = '1' then
                r_Count <= std_logic_vector(unsigned(r_count) + 1);      
            end if;
        end if;
    end process counter;

    o_BinaryCounter <= r_count;



end Behavioral;
