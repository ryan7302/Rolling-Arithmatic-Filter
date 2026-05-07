----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 11/08/2024 12:27:59 PM
-- Design Name: Data generator
-- Module Name: T05_M3_WaveGenerator - Behavioral
-- Project Name: T05_M3_Project
-- Target Devices: Basys 3
-- Revision 0.02 - File Created
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity T05_M3_WaveGenerator is
    Port (i_Clk: in STD_LOGIC;
          i_CE1Hz: in STD_LOGIC;
          i_Reset: in STD_LOGIC;
          i_Start: in STD_LOGIC;
          i_WaveSelect: in STD_LOGIC;
          o_Channel_0: out STD_LOGIC_VECTOR (7 downto 0);
          o_Channel_1: out STD_LOGIC_VECTOR (7 downto 0));
     
end T05_M3_WaveGenerator;

architecture Behavioral of T05_M3_WaveGenerator is

type StateTypeSquare is (S0, S1, S2, S3); --Define states for each state of the square wave
signal stateSquare : StateTypeSquare := S0; --assign state to 00 at start

type StateTypeTRW is (S0, S1, S2, S3, S4, S5, S6, S7, S8); --Define states for each state of the TRW 
signal stateTRW : StateTypeTRW := S0; --assign state to 00 at start

type StateTypeSAW is (S0, S1, S2, S3, S4, S5, S6, S7); --Define states for each state of the SAW wave
signal stateSAW : StateTypeSAW := S0; --assign state to 00 at start

signal r_Square01 : STD_LOGIC_VECTOR(7 downto 0):= X"00";
signal r_Square02 : STD_LOGIC_VECTOR(7 downto 0):= X"00";
signal r_TRW : STD_LOGIC_VECTOR(7 downto 0):= X"00";
signal r_SAW : STD_LOGIC_VECTOR(7 downto 0):= X"00";

signal r_counter: integer range 0 to 15:= 0;
signal r_flushCounter: integer range 0 to 7:= 0;
signal r_flushActivate : boolean := FALSE;

signal r_start_sync1 : std_logic := '0'; 
signal r_start_sync2 : std_logic := '0';
signal r_start : boolean := FALSE;

signal r_waveSelect : STD_LOGIC := '0';
signal r_waveSelect_perv : STD_LOGIC := '0';

begin
    --This ensures that the system does not start until Start button is pressed
    StartButton : process(i_Clk, i_Reset, i_Start, r_start_sync1, r_start_sync2, r_start) -- Written by Paing
    begin
        if i_Reset = '1' then 
             r_start <= FALSE;
        else
            if rising_edge(i_Clk) then
                r_start_sync1 <= i_Start;
                r_start_sync2 <= r_start_sync1;
                -- Detect the rising edge of the button press
                if r_start_sync2 = '1' and r_start_sync1 = '0' then
                    r_start <= TRUE; -- Update the status only on a valid rising edge
                end if; 
            end if;  
        end if;      
    end process;
    
    --This detects if there is a change in wave select and if so triggers the flush
    Flush : process(i_Clk, i_Reset, i_CE1Hz, r_start, i_WaveSelect)  -- Written by Joe -- Modified by Paing  
    begin
        r_waveSelect <= i_WaveSelect; 
        if i_Reset = '1' then 
            r_flushActivate <= FALSE;
            r_flushCounter  <= 0;  
        elsif r_start then
            if rising_edge(i_Clk) then
                if r_waveSelect_perv /= r_waveSelect then -- Detect change in wave selection
                    r_flushActivate <= TRUE; 
                    r_flushCounter  <= 0; -- Reset the flush generation
                    r_waveSelect_perv <= r_waveSelect; -- Update previous state
                end if;
                
                if i_CE1Hz = '1' then
                    if r_flushActivate then
                        if r_flushCounter = 7 then
                            r_flushActivate <= FALSE; -- End flush after 16 cycles
                            r_flushCounter <= 0;
                         else
                            r_flushCounter <= r_flushCounter + 1;
                         end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    Counter: process (i_Clk, i_Reset, i_CE1Hz, r_start)-- Written by Joe 
    begin
        if i_Reset = '1' then 
            r_counter <= 0;
        elsif r_start then
            if rising_edge(i_Clk) then
                if i_CE1Hz = '1' then
                    if  r_counter = 15 or r_flushActivate then --if counter is at its maxiumum or if the systen is flushing
                        r_counter <= 0; --reset back to 0    
                     else 
                        r_counter <= r_counter +1; --otherwise increment counter       
                     end if;
                end if;
            end if;
        end if;
    end process;
    
    WaveGeneration : process(i_Clk, i_CE1Hz, r_WaveSelect) -- Written by Joe
    begin
        if rising_edge(i_Clk) then
            if r_waveSelect = '0' then
                case r_counter is --set the states for the both the square waves relative to counter value
                    when 0 => stateSquare <=S0;
                    when 4 => stateSquare <=S1;
                    when 8 => stateSquare <=S2;
                    when 12 => stateSquare <=S3;
                    when others =>stateSquare <= stateSquare;
                end case; 
            elsif r_waveSelect = '1' then   
                case r_counter is --set states for SAW and TRW waves relative to counter value
                    when 0 => stateTRW <=S0; stateSAW <=S0;
                    when 1 => stateTRW <=S1; stateSAW <=S1;
                    when 2 => stateTRW <=S2; stateSAW <=S2;
                    when 3 => stateTRW <=S3; stateSAW <=S3;
                    when 4 => stateTRW <=S4; stateSAW <=S4;
                    when 5 => stateTRW <=S5; stateSAW <=S5;
                    when 6 => stateTRW <=S6; stateSAW <=S6;
                    when 7 => stateTRW <=S7; stateSAW <=S7;
                    when 8 => stateTRW <=S8; stateSAW <=S0;
                    when 9 => stateTRW <=S7; stateSAW <=S1;
                    when 10 => stateTRW <=S6; stateSAW <=S2;
                    when 11 => stateTRW <=S5; stateSAW <=S3;
                    when 12 => stateTRW <=S4; stateSAW <=S4;
                    when 13 => stateTRW <=S3; stateSAW <=S5;
                    when 14 => stateTRW <=S2; stateSAW <=S6;
                    when 15 => stateTRW <=S1; stateSAW <=S7;
                    when others =>stateTRW <= stateTRW; stateSAW <= stateSAW;
                end case; 
            else
                stateSquare <= S0;
                stateTRW <= S0;
                stateSAW <= S0;
            end if;
        end if;
    end process;


    DefineStates: process(stateSquare, stateTRW, stateSAW)
    begin
        case stateSquare is --States for square wave 1 and 2
            when S0 => r_Square01 <= X"00"; r_Square02 <= X"00";
            when S1 => r_Square01 <= X"FF"; r_Square02 <= X"00";
            when S2 => r_Square01 <= X"00"; r_Square02 <= X"FF";
            when S3 => r_Square01 <= X"FF"; r_Square02 <= X"FF";
            when others => r_Square01 <= X"00"; r_Square02 <= X"00";
        end case;

        case stateTRW is --States for TRW wave
            when S0 => r_TRW <= X"00";
            when S1 => r_TRW <= X"20";
            when S2 => r_TRW <= X"40";
            when S3 => r_TRW <= X"60";
            when S4 => r_TRW <= X"80";
            when S5 => r_TRW <= X"A0";
            when S6 => r_TRW <= X"C0";
            when S7 => r_TRW <= X"E0";
            when S8 => r_TRW <= X"FF";
            when others => r_TRW <= X"00";
            
        end case;
                  
        case stateSAW is --States for SAW wave
            when S0 => r_SAW <= X"00";
            when S1 => r_SAW <= X"20";
            when S2 => r_SAW <= X"40";
            when S3 => r_SAW <= X"60";
            when S4 => r_SAW <= X"80";
            when S5 => r_SAW <= X"A0";
            when S6 => r_SAW <= X"C0";
            when S7 => r_SAW <= X"E0";
            when others => r_SAW <= X"00";
        end case;
    end process;

    OuputAssignments : process (i_Clk, r_flushActivate, r_waveSelect) -- Written by Joe
    begin
        if rising_edge (i_Clk) then
            if r_flushActivate then          
                o_Channel_0 <= X"00";
                o_Channel_1 <= X"00";
            elsif r_waveSelect = '0' then
                o_Channel_0 <= r_Square01;
                o_Channel_1 <= r_Square02;
            elsif r_waveSelect = '1' then
                o_Channel_0 <= r_TRW;
                o_Channel_1 <= r_SAW;
            end if;
        end if;
    end process;

end Behavioral;