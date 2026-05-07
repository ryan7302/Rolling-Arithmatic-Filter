----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 10/30/2024 07:30:59 PM
-- Design Name: Data generator
-- Module Name: T05_M3_ClkEn1Hz - Behavioral
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

entity T05_M3_ClkEn1Hz is
    Port ( i_Clk: in std_logic;
           i_Reset: in std_logic;
           i_Fast : in STD_LOGIC;
           o_ClkEn1Hz: out std_logic);
end T05_M3_ClkEn1Hz;

architecture Behavioral of T05_M3_ClkEn1Hz is
    -- clock enable counter
    signal r_Counter: integer range 0 to 100000000;
    
begin
    -- clock divider for 1 Hz Enable
    clock_divider: process (i_Reset,i_Clk,i_Fast, r_Counter)
    begin
        if i_Reset = '1' then
            r_Counter <= 0;                  -- reset counter if the reset button is pushed
        elsif rising_edge(i_Clk) then        -- if there is rising_edge from the clock master100MHz
            if r_Counter >= (100000000-1) then     -- has the limit reached?
                r_Counter <= 0;                     -- if yes, reset the counter
            else                                -- if not
                if i_Fast = '1' then                -- check for fast?
                    r_Counter <= r_Counter + 400000;      -- if yes, increment by 1000
                else
                    r_Counter <= r_Counter + 1;         -- if not, increment by 1
                end if;
            end if;
        end if;
    end process clock_divider;
    
    -- pulse generation 
    signal_gen1Hz: process (i_Reset, i_Clk,r_counter)
    begin
        if i_Reset = '1' then
            o_ClkEn1Hz <= '0';         -- reset signal if the reset button is pushed
        elsif falling_edge (i_Clk) then  -- if there is rising_edge from the clock master100MHz
            if r_Counter >= (100000000-1) then  -- has the count completed?
                o_ClkEn1Hz <= '1';            -- if yes, high for 250Hz signal
            else
                o_ClkEn1Hz <= '0';            -- if not, low for 250Hz signal
            end if;
        end if;
    end process signal_gen1Hz;
end Behavioral;

