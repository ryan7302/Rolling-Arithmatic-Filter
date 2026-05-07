----------------------------------------------------------------------------------
-- Team: T05  up2244748, up2301555
-- Company: UoP Milestone-3
-- Engineer: Joseph Stiles & Paing Htet Kyaw
-- Create Date: 11/28/2024 01:10:23 PM
-- Design Name: Data generator
-- Module Name: T05_M3_BufferFilters - Behavioral
-- Project Name: T05_M3_Project
-- Target Devices: Basys 3
-- Revision 0.04 - File Created
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


entity T05_M3_BufferFilters is    
    Port (
        i_Clk : in  std_logic;
        i_Reset : in  std_logic;
        i_CE1Hz : in std_logic;
        i_DisplaySelect: in integer range 0 to 3;
        i_BufferLength : in integer range 0 to 8; 
        i_Data_0 : in  std_logic_vector(7 downto 0);
        i_Data_1 : in  std_logic_vector(7 downto 0);
        o_Data_0   : out std_logic_vector(7 downto 0);
        o_Data_1   : out std_logic_vector(7 downto 0)

    );
end T05_M3_BufferFilters;


architecture Behavioral of T05_M3_BufferFilters is

    type BufferArray is array (0 to 7) of std_logic_vector(7 downto 0);
    --Signals to control process
    signal r_Buffer_ON: boolean  := FALSE;
    
    -- Signals to update buffer 
    signal r_Buffer_0 : BufferArray := (others => (others => '0'));
    signal r_Buffer_1 : BufferArray := (others => (others => '0'));
    signal r_WriteIndex : integer range 0 to 7 := 0;
   
    -- Signals to sort buffer
    signal r_SortedBuffer_0 : BufferArray := (others => (others => '0'));
    signal r_SortedBuffer_1 : BufferArray := (others => (others => '0'));
    
    -- Signals to choose calculation
     signal cal_Median : boolean  := FALSE;
     signal cal_Mean : boolean  := FALSE;
     signal cal_Mode : boolean  := FALSE;
     signal cal_Range : boolean  := FALSE;
     
     
    -- Signals to calculate Median
    signal r_Median_0 : std_logic_vector(7 downto 0):= (others => '0'); 
    signal r_Median_1 : std_logic_vector(7 downto 0):= (others => '0');
    
    -- Signals to calculate Mean
    signal r_Mean_0 : STD_LOGIC_VECTOR (7 downto 0):= (others => '0'); 
    signal r_Mean_1 : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
    
    -- Signals to calculate Range
    signal r_Mode_0  : std_logic_vector(7 downto 0) := (others => '0');
    signal r_Mode_1  : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Signals to calculate Range
    signal r_Range_0 : std_logic_vector(7 downto 0) := (others => '0');
    signal r_Range_1 : std_logic_vector(7 downto 0) := (others => '0');
    
    
    
begin
    -- Control Process - Written by Paing
    Control: Process (i_Clk,i_Reset)
    begin
        if i_Reset = '1'then
            r_Buffer_ON <= FAlSE;     
        elsif rising_edge(i_Clk) then
            if i_BufferLength > 1 then
                r_Buffer_ON <= TRUE;
            else
                r_Buffer_ON <= FAlSE; 
            end if;
        end if;
    end process;
    
    
    -- Process to update buffer - Written by Paing & Joe
    Bufferstore: process(i_Clk, i_Reset, i_BufferLength)  
    begin
        if i_Reset = '1'then
            r_Buffer_0 <= (others => (others => '0'));        
            r_Buffer_1 <= (others => (others => '0'));       
        elsif rising_edge(i_Clk) then
            if i_CE1Hz = '1' and r_Buffer_ON then 
            -- Store the incoming data in the buffers
            r_Buffer_0(r_WriteIndex) <= i_Data_0;
            r_Buffer_1(r_WriteIndex) <= i_Data_1;
            
            -- Increment write index
            r_WriteIndex <= (r_WriteIndex + 1) mod i_BufferLength;         
            end if;
        end if;
    end process;
   
   
    -- Process to Sort buffer - Synthesis Compatible Version -- Written By Paing 
    Sorting_Buffer: process (i_Clk, i_Reset, i_BufferLength)
        variable arr0, arr1 : BufferArray;
        variable temp0, temp1 : std_logic_vector(7 downto 0);
        constant BUFFER_SIZE : integer := 8; -- Fixed buffer size
        variable i, j : integer;
    begin
        if i_Reset = '1' then
            r_SortedBuffer_0 <= (others => (others => '0'));        
            r_SortedBuffer_1 <= (others => (others => '0'));              
        elsif rising_edge(i_Clk) then
                -- Load buffer into temporary arrays for sorting
                arr0 := r_Buffer_0;
                arr1 := r_Buffer_1;
    
                -- Bubble Sort for fixed buffer size
                for i in 0 to BUFFER_SIZE - 2 loop
                    for j in 0 to BUFFER_SIZE - 2 - i loop
                        -- Sort only up to i_BufferLength, leave unused indices untouched
                        if j < i_BufferLength - 1 then
                            if arr0(j) > arr0(j + 1) then
                                -- Swap arr0 elements
                                temp0 := arr0(j);
                                arr0(j) := arr0(j + 1);
                                arr0(j + 1) := temp0;
                            end if;
    
                            if arr1(j) > arr1(j + 1) then
                                -- Swap arr1 elements
                                temp1 := arr1(j);
                                arr1(j) := arr1(j + 1);
                                arr1(j + 1) := temp1;
                            end if;
                        end if;
                    end loop;
                end loop;
    
                -- Assign sorted values back to output buffers
                for i in 0 to BUFFER_SIZE - 1 loop
                    if i < i_BufferLength then
                    
                        -- Pass sorted values for active buffer elements
                        r_SortedBuffer_0(i) <= arr0(i);
                        r_SortedBuffer_1(i) <= arr1(i);
                    else
                        -- Assign zero to inactive buffer slots
                        r_SortedBuffer_0(i) <= (others => '0');
                        r_SortedBuffer_1(i) <= (others => '0');
                    end if;
                end loop;
            end if;
    end process;
    
    -- Process to choose calulation - Written by Paing
    Cal_Control: process (i_Clk, i_DisplaySelect)
    begin
        case i_DisplaySelect is 
        when 0 =>              
            cal_Mean <= TRUE;
            cal_Median <= FALSE;   
            cal_Mode <= FALSE;
            cal_Range <= FALSE;
        when 1 =>              
            cal_Mean <= FALSE;
            cal_Median <= TRUE;
            cal_Mode <= FALSE;
            cal_Range <= FALSE; 
        when 2 =>     
            cal_Median <= FALSE;
            cal_Mean <= FALSE;
            cal_Mode <= TRUE;
            cal_Range <= FALSE;
        when 3 => 
            cal_Median <= FALSE;
            cal_Mean <= FALSE;
            cal_Mode <= FALSE;
            cal_Range <= TRUE;
        when others =>    
            cal_Median <= FALSE;
            cal_Mean <= FALSE;
            cal_Mode <= FALSE;
            cal_Range <= FALSE;
        end case;
    end process;
    
    
    -- Process to calculate median - Written by Paing
    Median_Filter: process (i_Clk, i_Reset, i_BufferLength, r_SortedBuffer_0, r_SortedBuffer_1, cal_Median)
        variable arr0, arr1 : BufferArray;
        variable mid1, mid2, mid3, mid4 : unsigned(7 downto 0);
        variable avg0, avg1 : unsigned(8 downto 0); -- Use 1 extra bit for intermediate results
    begin
        if i_Reset = '1'then
            r_Median_0 <= x"00";        
            r_Median_1 <= x"00"; 
        elsif cal_Median then 
            -- Initialize the array
            arr0 := r_SortedBuffer_0;
            arr1 := r_SortedBuffer_1;    
        
            -- Compute the median for arr0
            if i_BufferLength mod 2 = 0 then
                -- Even number of elements: take the average of the two middle values
                mid1 := unsigned(arr0(i_BufferLength/ 2 - 1));
                mid2 := unsigned(arr0(i_BufferLength / 2));
                avg0 := (resize(mid1, 9) + resize(mid2, 9)) / 2; -- Resize to avoid overflow
                r_Median_0 <= std_logic_vector(avg0(7 downto 0)); -- Convert back to 8-bit std_logic_vector
            else
                -- Odd number of elements: take the middle value
                r_Median_0 <= arr0(i_BufferLength / 2);
            end if;
        
            -- Compute the median for arr1
            if i_BufferLength mod 2 = 0 then
                -- Even number of elements: take the average of the two middle values
                mid3 := unsigned(arr1(i_BufferLength / 2 - 1));
                mid4 := unsigned(arr1(i_BufferLength / 2));
                avg1 := (resize(mid3, 9) + resize(mid4, 9)) / 2; -- Resize to avoid overflow
                r_Median_1 <= std_logic_vector(avg1(7 downto 0)); -- Convert back to 8-bit std_logic_vector
            else
                -- Odd number of elements: take the middle value
                r_Median_1 <= arr1(i_BufferLength / 2);       
            end if;
        end if;
    end process;
    
    
    --Process to calculate mean value - Written by Joe -- Modified by Paing for consistancy with 'for loop'
    MeanFilter: process (i_Clk, i_Reset, i_BufferLength, r_SortedBuffer_0, r_SortedBuffer_1, cal_Mean) 
        variable arr0, arr1 : BufferArray;
        variable sum0, sum1 : unsigned(15 downto 0); -- Use extended width to prevent overflow
        variable mean0, mean1 : unsigned(7 downto 0); -- Final mean value (8 bits)
        variable i          : integer;              -- Loop index
    begin
        if i_Reset = '1'then
            r_Mean_0 <= x"00";        
            r_Mean_1 <= x"00"; 
        elsif cal_Mean then
            -- Initialize the array
            arr0 := r_SortedBuffer_0;
            arr1 := r_SortedBuffer_1;
                
            -- Initialize the sum to zero
            sum0 := (others => '0');
            sum1 := (others => '0');   
                     
            -- Iterate through the array and compute the sum
            for i in arr0'range loop
                sum0 := sum0 + resize(unsigned(arr0(i)), 16); -- Extend to 16 bits
                sum1 := sum1 + resize(unsigned(arr1(i)), 16); -- Extend to 16 bits
            end loop;       
               
            -- Compute the mean by dividing the sum by the array length
            mean0 := resize(sum0 / to_unsigned(i_BufferLength, sum0'length), 8);
            mean1 := resize(sum1 / to_unsigned(i_BufferLength, sum1'length), 8);           
            
            -- Assign the mean to the output
            r_Mean_0 <= std_logic_vector(mean0);
            r_Mean_1 <= std_logic_vector(mean1); 
                  
        end if;
    end process;
  
  
   -- Process to calculate mode  -- Written by Paing 
    Mode_Calculation: process(i_Clk, i_Reset, i_BufferLength, r_SortedBuffer_0, r_SortedBuffer_1, cal_Mode)
        variable buffer_max_length: integer := 8;
        variable count : integer := 0;
        variable max_count : integer := 0;
        variable mode_value : std_logic_vector(7 downto 0) := (others => '0'); -- Track the mode value
        variable i, j : integer;
    begin
        if i_Reset = '1' then
            r_Mode_0 <= x"00";
            r_Mode_1 <= x"00";
        elsif cal_Mode then
            -- Mode for r_SortedBuffer_0
            max_count := 0;
            mode_value := x"00";
            for i in 0 to buffer_max_length - 1 loop
                count := 0;
                -- Only process active elements
                if i < i_BufferLength then
                    for j in 0 to buffer_max_length - 1 loop
                        if j < i_BufferLength then
                            if r_SortedBuffer_0(i) = r_SortedBuffer_0(j) then
                                count := count + 1;
                            end if;
                        end if;
                    end loop;

                    -- Check if this value has the highest count
                    if count > max_count then
                        max_count := count;
                        mode_value := r_SortedBuffer_0(i);
                    elsif count = max_count then
                        -- If tied, select the smallest value
                        if unsigned(r_SortedBuffer_0(i)) < unsigned(mode_value) then
                            mode_value := r_SortedBuffer_0(i);
                        end if;
                    end if;
                end if;
            end loop;

            -- Assign the mode to the output
            r_Mode_0 <= mode_value;

            -- Mode for r_SortedBuffer_1 (repeat same logic for second buffer)
            max_count := 0;
            mode_value := x"00";
            for i in 0 to buffer_max_length - 1 loop
                count := 0;
                -- Only process active elements
                if i < i_BufferLength then
                    for j in 0 to buffer_max_length - 1 loop
                        if j < i_BufferLength then
                            if r_SortedBuffer_1(i) = r_SortedBuffer_1(j) then
                                count := count + 1;
                            end if;
                        end if;
                    end loop;

                    -- Check if this value has the highest count
                    if count > max_count then
                        max_count := count;
                        mode_value := r_SortedBuffer_1(i);
                    elsif count = max_count then
                        -- If tied, select the smallest value
                        if unsigned(r_SortedBuffer_1(i)) < unsigned(mode_value) then
                            mode_value := r_SortedBuffer_1(i);
                        end if;
                    end if;
                end if;
            end loop;

            -- Assign the mode to the output
            r_Mode_1 <= mode_value;
        end if;
    end process;
       
   -- Process to calculate range - Written by Paing
    Range_Calculation: process(i_Clk, i_Reset, i_BufferLength, r_SortedBuffer_0, r_SortedBuffer_1, cal_Range)
        variable min_value_0, max_value_0 : unsigned(8 downto 0) := (others => '0'); 
        variable min_value_1, max_value_1 : unsigned(8 downto 0) := (others => '0');
        variable range_0, range_1 : unsigned(8 downto 0) := (others => '0'); -- 9 bits for safety
    begin
        if i_Reset = '1' then
            -- Reset the range values to zero
            r_Range_0 <= x"00";
            r_Range_1 <= x"00";
        elsif cal_Range then
            -- Range for r_SortedBuffer_0
            if i_BufferLength > 0 then
               -- Calculate the range
                min_value_0 := resize(unsigned(r_SortedBuffer_0(0)), 9); -- Resize to 9 bits
                max_value_0 := resize(unsigned(r_SortedBuffer_0(i_BufferLength - 1)), 9); -- Resize to 9 bits
                range_0 := max_value_0 - min_value_0;

                -- Assign range back to 8-bit std_logic_vector
                r_Range_0 <= std_logic_vector(range_0(7 downto 0));
            end if;

            -- Range for r_SortedBuffer_1
            if i_BufferLength > 0 then
               -- Calculate the range
                min_value_1 := resize(unsigned(r_SortedBuffer_1(0)), 9); -- Resize to 9 bits
                max_value_1 := resize(unsigned(r_SortedBuffer_1(i_BufferLength - 1)), 9); -- Resize to 9 bits
                range_1 := max_value_1 - min_value_1;

                -- Assign range back to 8-bit std_logic_vector
                r_Range_1 <= std_logic_vector(range_1(7 downto 0));
            end if;
        end if;
    end process;
      
    -- Assignment -- Written by Paing 
    OuputAssignments : process (i_Clk, r_Buffer_ON, i_DisplaySelect,i_Data_0, i_Data_1, r_Mean_0, r_Mean_1, r_Median_0, r_Median_1,r_Mode_0, r_Mode_1, r_Range_0, r_Range_1)
    begin
        if r_Buffer_ON then 
            case i_DisplaySelect is 
                when 0 => 
                    -- Output the mean values to the outputs
                    o_Data_0 <= r_Mean_0;
                    o_Data_1 <= r_Mean_1;
                when 1 =>
                -- Output the median values to the outputs
                    o_Data_0 <= r_Median_0;
                    o_Data_1 <= r_Median_1;
                when 2 => 
                -- Output the mode values to the outputs
                    o_Data_0 <= r_Mode_0;
                    o_Data_1 <= r_Mode_1;
                when 3 =>
                -- Output the range values to the outputs
                    o_Data_0 <= r_Range_0;
                    o_Data_1 <= r_Range_1;
                when others =>
                    o_Data_0 <= i_Data_0;
                    o_Data_1 <= i_Data_1;               
                end case;
         else
            o_Data_0 <= i_Data_0;
            o_Data_1 <= i_Data_1;
         end if;
    end process;
   
end Behavioral;
