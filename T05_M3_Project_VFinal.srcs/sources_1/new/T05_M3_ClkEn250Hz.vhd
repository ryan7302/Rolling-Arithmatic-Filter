----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 10/30/2024 06:22:57 PM
-- Design Name: Data generator
-- Module Name: T05_M3_ClkEn250Hz - Behavioral
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

entity T05_M3_ClkEn250Hz is
    Port ( i_Clk: in std_logic;
           i_Reset: in std_logic;
           o_ClkEn250Hz: out std_logic);
end T05_M3_ClkEn250Hz;

architecture Behavioral of T05_M3_ClkEn250Hz is
    -- clock enable counter
    signal r_Counter: integer range 0 to 40000;
    
begin
    
    -- clock divider for 250 Hz Enable
    clock_divider: process (i_Clk, i_Reset, r_Counter)
    begin
        if i_Reset = '1' then 
            r_Counter <= 0;
        elsif rising_edge (i_Clk) then
            if r_Counter >= (40000-1) then
                r_Counter <= 0;
            else
                r_Counter <= r_Counter + 1;
            end if;
        end if;
    end process clock_divider;
    
    --enable pulse generator
    enable_gen250Hz: process (i_Clk, i_Reset, r_Counter)
    begin
        if i_Reset = '1' then 
            o_ClkEn250Hz <= '0';
        elsif falling_edge (i_Clk) then
            if r_Counter >= (40000-1) then
                o_ClkEn250Hz <= '1';
            else
                o_ClkEn250Hz <= '0';
            end if;
        end if;
    end process enable_gen250Hz;  

end Behavioral;
