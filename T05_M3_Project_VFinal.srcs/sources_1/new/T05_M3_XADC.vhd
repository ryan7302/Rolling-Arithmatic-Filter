----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 12/13/2024 09:31:53 PM
-- Design Name: Data generator
-- Module Name: T05_M3_XADC - Behavioral
-- Project Name: T05_M3_Project
-- Target Devices: Basys 3
-- Revision 0.02 - File Created
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity T05_M3_XADC is
    Port (i_Clk: in STD_LOGIC;
          i_CE: in STD_LOGIC;
          i_Reset: in STD_LOGIC;
          i_Data: in STD_LOGIC_VECTOR(15 downto 0);
          i_DataReady: in STD_LOGIC;
          o_Channel: out STD_LOGIC_VECTOR(6 downto 0);
          o_XADCData_0: out STD_LOGIC_VECTOR (7 downto 0);
          o_XADCData_1: out STD_LOGIC_VECTOR (7 downto 0));
end T05_M3_XADC;

architecture Behavioral of T05_M3_XADC is

type StateChannel is (S0, S1); --Define states for each state of the square wave
signal channelState : StateChannel := S0; --assign state to 00 at start

begin
    -- Input Assignment process
    Assignment:process(i_Clk,i_Data) -- Written By Paing 
    begin
        if rising_edge(i_Clk) then
            if i_Reset = '1' then
                -- Reset outputs
                o_XADCData_0 <= (others => '0');
                o_XADCData_1 <= (others => '0');
            elsif i_DataReady = '1' then
                case channelState is 
                    when S0 =>
                        o_Channel <= "0010110"; -- Select VAUX6 channel
                        o_XADCData_0 <= i_Data(15 downto 8); -- Scale to 8-bit
                        channelState <= S1;
                    when S1 =>
                        o_Channel <= "0010111"; -- Select VAUX7 channel
                        o_XADCData_1 <= i_Data(15 downto 8); -- Scale to 8-bit
                        channelState <= S0;
                end case; 
            end if;        
        end if;
    end process;
end Behavioral;