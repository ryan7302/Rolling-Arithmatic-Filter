----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 10/30/2024 07:27:59 PM
-- Design Name: Data generator
-- Module Name: T05_M3_TopLevel - Behavioral
-- Project Name: T05_M3_Project
-- Target Devices: Basys 3
-- Revision 0.05 - File Created
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

entity T05_M3_TopLevel is
Port ( i_Clk : in STD_LOGIC;
       i_Reset : in STD_LOGIC;
       i_Start : in STD_LOGIC;
       i_Fast : in STD_LOGIC;
       
       i_WaveSwitch: in std_logic;
       i_XADCSwitch: in std_logic;
       
       i_DisplaySwitch : in std_logic_vector(1 downto 0); -- Input from two switches
       i_BufferSizeSwitch: in  std_logic_vector(1 downto 0); -- Input from two switches
       
      -- XADC Analog Inputs
       vauxp6, vauxn6 : in std_logic; -- Analog input VAUX6
       vauxp7, vauxn7 : in std_logic; -- Analog input VAUX7
       
       o_SegmentCathodes : out STD_LOGIC_VECTOR (6 downto 0);
       o_SegmentAnodes : out STD_LOGIC_VECTOR (3 downto 0);
       o_LEDs : out STD_LOGIC_VECTOR (7 downto 0));
    

end T05_M3_TopLevel;

architecture Behavioral of T05_M3_TopLevel is
    
    --Signals for clocks
    signal r_SystemClock : std_logic := '0';
    signal clk_locked : std_logic;
    signal i_CE1Hz: std_logic:='0';
    signal ClkEn250Hz: std_logic:='0';
    
    --Signals for XADC Block
    signal channel: std_logic_vector (6 downto 0);
    signal eoc: std_logic;
    signal XADCData_out: std_logic_vector(15 downto 0);
    signal drdy:std_logic;
    
    -- XADC signals
    signal i_XADCData : std_logic_vector(15 downto 0);
    signal o_XADCData_0 : std_logic_vector(7 downto 0);
    signal o_XADCData_1 : std_logic_vector(7 downto 0);
    
    --Signals data form wave generator or analog reading
    signal o_Channel_0 : std_logic_vector (7 downto 0);
    signal o_Channel_1 : std_logic_vector (7 downto 0);
    
    -- Buffer I/O signals
    signal i_Data_0 : std_logic_vector(7 downto 0);
    signal i_Data_1 : std_logic_vector(7 downto 0);
    signal o_Data_0 : std_logic_vector(7 downto 0);
    signal o_Data_1 : std_logic_vector(7 downto 0);

    -- DisplaySelect and BufferSize from switches
    signal i_BufferSize : integer range 0 to 8:= 8;
    signal i_DisplaySelect : integer range 0 to 3:= 0; 

    --Signals for display driver
    signal BinaryCount: std_logic_vector (1 downto 0);
    signal ToDisplay1: std_logic_vector (3 downto 0);
    signal ToDisplay2: std_logic_vector (3 downto 0);
    signal ToDisplay3: std_logic_vector (3 downto 0);
    signal ToDisplay4: std_logic_vector (3 downto 0);



    -- Component Declaration for clk_wiz_0
    component clk_wiz_0
    Port (clk_out1 : out STD_LOGIC;
          reset : in STD_LOGIC;
          locked : out STD_LOGIC;
          clk_in1 : in STD_LOGIC);
    end component;
    
     -- Component Declaration for xadc_wiz_0
    component xadc_wiz_0
    Port (
        di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        den_in : IN STD_LOGIC;
        dwe_in : IN STD_LOGIC;
        drdy_out : OUT STD_LOGIC;
        do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dclk_in : IN STD_LOGIC;
        vp_in : IN STD_LOGIC;
        vn_in : IN STD_LOGIC;
        vauxp6 : IN STD_LOGIC;
        vauxn6 : IN STD_LOGIC;
        vauxp7 : IN STD_LOGIC;
        vauxn7 : IN STD_LOGIC;
        channel_out: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        eoc_out : OUT STD_LOGIC;
        alarm_out : OUT STD_LOGIC;
        eos_out : OUT STD_LOGIC;
        busy_out : OUT STD_LOGIC);
     end component;
    
begin
   -- Switch Selection
   Switch: process (i_XADCSwitch, i_BufferSizeSwitch, i_DisplaySwitch, o_Channel_0, o_Channel_1, o_XADCData_0, o_XADCData_1)
   begin
       case i_BufferSizeSwitch is
            when "00" => i_BufferSize <= 1; o_LEDs(3 downto 0) <= "0000";
            when "01" => i_BufferSize <= 2; o_LEDs(3 downto 0) <= "0010";
            when "10" => i_BufferSize <= 4; o_LEDs(3 downto 0) <= "0100";
            when "11" => i_BufferSize <= 8; o_LEDs(3 downto 0) <= "1000";
            when others => i_BufferSize <= 8; o_LEDs(3 downto 0) <= "1000";               
       end case;
       
       case i_DisplaySwitch is
            when "00" => i_DisplaySelect <= 0; o_LEDs(7 downto 5) <= "000";
            when "01" => i_DisplaySelect <= 1; o_LEDs(7 downto 5) <= "001";
            when "10" => i_DisplaySelect <= 2; o_LEDs(7 downto 5) <= "010";
            when "11" => i_DisplaySelect <= 3; o_LEDs(7 downto 5) <= "100";
            when others => i_DisplaySelect <= 0;
       end case;
       
       case  i_XADCSwitch is 
            when '0' => i_Data_0 <= o_Channel_0(7 downto 0); i_Data_1 <= o_Channel_1(7 downto 0);
            when '1' => i_Data_0 <= o_XADCData_0(7 downto 0); i_Data_1 <= o_XADCData_1(7 downto 0);   
            when others => i_Data_0 <= o_Channel_0(7 downto 0); i_Data_1 <= o_Channel_1(7 downto 0);
       end case;
       
   end process;
     
    -- instantiate DCM block
    Demo_DCM : clk_wiz_0 
        port map ( clk_out1 => r_SystemClock, 
                   locked => clk_locked,
                   reset => i_Reset,
                   clk_in1 => i_Clk);
    XADC_Block : xadc_wiz_0
      port map ( di_in => (others => '0'),
                 daddr_in => channel,
                 den_in => eoc,
                 dwe_in => '0',
                 drdy_out => drdy,
                 do_out => XADCData_out,
                 dclk_in => r_SystemClock,
                 vp_in => '0',
                 vn_in => '0',
                 vauxp6 => vauxp6,
                 vauxn6 => vauxn6,
                 vauxp7 => vauxp7,
                 vauxn7 => vauxn7,
                 channel_out => open, 
                 eoc_out => eoc,
                 alarm_out => open,
                 eos_out => open,
                 busy_out => open); 
        
    ClockEn1Hz: entity work.T05_M3_ClkEn1Hz(Behavioral)
        port map( i_Clk => r_SystemClock,
                  i_Reset => i_Reset,
                  i_Fast => i_Fast,
                  o_ClkEn1Hz => i_CE1Hz);
                         
    ClockEn250Hz: entity work.T05_M3_ClkEn250Hz (Behavioral)
        port map( i_Clk => r_SystemClock,
                  i_Reset => i_Reset,
                  o_ClkEn250Hz => ClkEn250Hz);
                     
    WaveGenerator: entity work.T05_M3_WaveGenerator (Behavioral)
        port map ( i_Clk => i_Clk,
                   i_Reset => i_Reset,
                   i_CE1Hz => i_CE1Hz,
                   i_Start => i_Start,
                   i_WaveSelect => i_WaveSwitch,
                   o_Channel_0 => o_Channel_0,
                   o_Channel_1 => o_Channel_1);
    
    XADC_Process: entity work.T05_M3_XADC (Behavioral)
        port map( i_Clk => r_SystemClock,
                  i_CE => eoc,
                  i_Reset => i_Reset,
                  i_Data => XADCData_out,
                  i_DataReady => drdy,
                  o_Channel => channel,
                  o_XADCData_0 => o_XADCData_0,
                  o_XADCData_1 => o_XADCData_1);  
               
    DataBuffer: entity work.T05_M3_BufferFilters(behavioral)
         port map ( i_Clk => r_SystemClock,           
                    i_Reset => i_Reset,               
                    i_CE1Hz => i_CE1Hz, 
                    i_Data_0 => i_Data_0,          
                    i_Data_1 => i_Data_1,
                    i_DisplaySelect => i_DisplaySelect,
                    i_BufferLength => i_BufferSize,
                    o_Data_0 => o_Data_0,           
                    o_Data_1 => o_Data_1);
                            
    BinaryCounter: entity work.T05_M3_BinaryCounter (Behavioral)
        Port map ( i_Clk => r_SystemClock,
                   i_ClkEn250Hz => ClkEn250Hz,
                   i_Reset => i_Reset,
	               o_BinaryCounter => BinaryCount);
                  
    DisplayDriver: entity work.T05_M3_DisplayDriver (Behavioral)
        Port map ( Display1 => ToDisplay1,
                   Display2 => ToDisplay2,
                   Display3 => ToDisplay3, 
                   Display4 => ToDisplay4,
                   i_digitSelect  => BinaryCount,
                   o_SegmentAnodes => o_SegmentAnodes,
                   o_SegmentCathodes => o_SegmentCathodes);
    
   -- assignment to Displays
   ToDisplay1 <= o_Data_0(3 downto 0);
   ToDisplay2 <= o_Data_0(7 downto 4);
   ToDisplay3 <= o_Data_1(3 downto 0); 
   ToDisplay4 <= o_Data_1(7 downto 4);     

end Behavioral;
