----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/13/2024 10:28:17 AM
-- Design Name: 
-- Module Name: T05_M3_TopLevel_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
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

entity T05_M3_TopLevel_TB is
--  Port ( );
end T05_M3_TopLevel_TB;

architecture Behavioral of T05_M3_TopLevel_TB is
    --Inputs
    signal i_Clk : std_logic := '0';
    signal i_Reset : std_logic := '0';
    signal i_Start : std_logic := '0';
    signal i_Fast:  std_logic := '0';
    
    signal i_WaveSwitch: std_logic:= '0';
    signal i_XADCSwitch: std_logic:= '0';
    
    signal i_DisplaySwitch: std_logic_vector(1 downto 0);    
    signal i_BufferSizeSwitch: std_logic_vector(1 downto 0);
    
    signal vauxp6, vauxn6 : std_logic := '0'; -- Analog input VAUX6
    signal vauxp7, vauxn7 : std_logic := '0'; -- Analog input VAUX7
    
    signal o_SegmentCathodes :  STD_LOGIC_VECTOR (6 downto 0);
    signal o_SegmentAnodes :  STD_LOGIC_VECTOR (3 downto 0);

    -- Clock frequency for simulation
    constant i_Clk_period : time := 10 ns;
   
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.T05_M3_TopLevel(Behavioral)
    port map (i_Clk => i_Clk, 
              i_Reset => i_Reset,
              i_Start => i_Start,
              i_Fast => i_Fast,
              i_WaveSwitch => i_WaveSwitch,
              i_XADCSwitch => i_XADCSwitch,
              i_DisplaySwitch => i_DisplaySwitch,
              i_BufferSizeSwitch => i_BufferSizeSwitch,
              vauxp6 => vauxp6,
              vauxn6 => vauxn6,
              vauxp7 => vauxp7,
              vauxn7 => vauxn7,
              o_SegmentCathodes => o_SegmentCathodes,
              o_SegmentAnodes => o_SegmentAnodes);

    -- Clock process
    sysClock_process : process
    begin
        i_Clk <= '0';
        wait for i_Clk_period / 2;
        i_Clk <= '1';
        wait for i_Clk_period / 2;
    end process;
 
    -- stimulus process for reset
    reset_process: process
    begin
        i_Reset <= '0';
        wait for 5 ns;
        i_Reset <= '0';
        wait for 500 ns;
        i_Reset <= '0';
        wait;
     end process;
     
     -- stimulus process for start
    start_process: process
    begin
        i_Start <= '0';
        wait for 10 ns;
        i_Start <= '1';
        wait for 10 ns;
        i_Start <= '0';
        wait;
     end process;
     
    -- stimulus process for fast
    fast_process: process
    begin
        i_Fast <= '0';
        wait for 20 ns;
        i_Fast <= '1';
        wait;
     end process;
     
    -- stimulus process for the Waveswitch
    WaveSelect_process: process
     begin
        i_WaveSwitch <= '0';
        wait for 30 ns;
        i_WaveSwitch <= '1';
        wait;
     end process;
     
    -- stimulus process for the buffer length
    Buffersize_process: process
     begin
        i_BufferSizeSwitch <= "10";
        wait for 5 ms;
        i_BufferSizeSwitch <= "01";
        wait for 5 ms;
        i_BufferSizeSwitch <= "10";
        wait for 5 ms;
        i_BufferSizeSwitch <= "11";
        wait for 5 ms;
     end process;
     
    -- stimulus process for the buffer length
    Displayselect_process: process
     begin
        i_DisplaySwitch <= "11";
        wait for 5 ms;
        i_DisplaySwitch <= "01";
        wait for 200 us;
        i_DisplaySwitch <= "10";
        wait for 200 us;
        i_DisplaySwitch <= "11";
        wait for 200 us;
     end process;
     
--     -- stimulus process for the analogue data input
--     i_XADC: process
--     begin
--        wait for 5 ms;
--        i_XADCSwitch <= '0';        
--        wait for 30 ns;
--        i_XADCSwitch <= '1';
--        wait for 5 ms;
--        vauxp6 <= '1';       
--        wait for 5 ms;
--        vauxn6 <= '1';
--        wait for 5 ms;
--        vauxp7 <= '1';
--        wait for 5 ms;
--        vauxn7 <= '1';
--        wait;
--     end process;
     
end Behavioral;

