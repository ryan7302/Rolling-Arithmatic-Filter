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

    -- Signals for the multi-cycle odd-even transposition sort
    -- r_Phase: 0 = load a snapshot of the buffer, 1..8 = one compare-swap phase per clock,
    --          9 = publish the result to r_SortedBuffer, then start again
    signal r_Work_0 : BufferArray := (others => (others => '0'));
    signal r_Work_1 : BufferArray := (others => (others => '0'));
    signal r_Phase  : integer range 0 to 9 := 0;

     
     
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
    -- Mode pipeline registers
    type CountArray is array (0 to 7) of integer range 0 to 8;
    signal r_Count_0, r_Count_1       : CountArray := (others => 0);
    signal r_ModeVals_0, r_ModeVals_1 : BufferArray := (others => (others => '0'));

    -- Mean: add the 8 sorted values as a balanced tree (3 adder levels, not 7),
    -- then divide by the length with a shift. Unused slots are already zero.
    function f_Mean(a : BufferArray; len : integer) return std_logic_vector is
        variable s01, s23, s45, s67 : unsigned(10 downto 0);
        variable s03, s47, total    : unsigned(10 downto 0);
    begin
        s01 := resize(unsigned(a(0)), 11) + resize(unsigned(a(1)), 11);
        s23 := resize(unsigned(a(2)), 11) + resize(unsigned(a(3)), 11);
        s45 := resize(unsigned(a(4)), 11) + resize(unsigned(a(5)), 11);
        s67 := resize(unsigned(a(6)), 11) + resize(unsigned(a(7)), 11);
        s03 := s01 + s23;
        s47 := s45 + s67;
        total := s03 + s47;
        case len is
            when 2      => return std_logic_vector(resize(shift_right(total, 1), 8));
            when 4      => return std_logic_vector(resize(shift_right(total, 2), 8));
            when 8      => return std_logic_vector(resize(shift_right(total, 3), 8));
            when others => return std_logic_vector(resize(total, 8));
        end case;
    end function;

    -- Median of a sorted window: middle value, or average of the two middle values
    function f_Median(a : BufferArray; len : integer) return std_logic_vector is
        variable lo, hi : unsigned(8 downto 0);
    begin
        case len is
            when 2 => lo := resize(unsigned(a(0)), 9); hi := resize(unsigned(a(1)), 9);
            when 4 => lo := resize(unsigned(a(1)), 9); hi := resize(unsigned(a(2)), 9);
            when 8 => lo := resize(unsigned(a(3)), 9); hi := resize(unsigned(a(4)), 9);
            when others => return a(0);
        end case;
        return std_logic_vector(resize(shift_right(lo + hi, 1), 8));
    end function;

    -- Range of a sorted window: largest (last active) minus smallest (first)
    function f_Range(a : BufferArray; len : integer) return std_logic_vector is
        variable top : unsigned(7 downto 0);
    begin
        case len is
            when 2      => top := unsigned(a(1));
            when 4      => top := unsigned(a(3));
            when 8      => top := unsigned(a(7));
            when others => top := unsigned(a(0));
        end case;
        return std_logic_vector(top - unsigned(a(0)));
    end function;

    -- Mode stage 1: for each active slot, how many active slots hold the same value
    function f_Counts(a : BufferArray; len : integer) return CountArray is
        variable c : CountArray := (others => 0);
        variable n : integer range 0 to 8;
    begin
        for i in 0 to 7 loop
            n := 0;
            if i < len then
                for j in 0 to 7 loop
                    if j < len and a(i) = a(j) then
                        n := n + 1;
                    end if;
                end loop;
            end if;
            c(i) := n;
        end loop;
        return c;
    end function;

    -- Mode stage 2: tournament (3 levels) - the higher count wins; on a tie the
    -- LEFT entry wins, and since the window is sorted that is the smaller value
    function f_PickMode(v : BufferArray; c : CountArray) return std_logic_vector is
        type PairV is array (0 to 3) of std_logic_vector(7 downto 0);
        type PairC is array (0 to 3) of integer range 0 to 8;
        variable v1 : PairV; variable c1 : PairC;
        variable v2a, v2b : std_logic_vector(7 downto 0);
        variable c2a, c2b : integer range 0 to 8;
    begin
        for k in 0 to 3 loop
            if c(2*k) >= c(2*k + 1) then
                v1(k) := v(2*k);     c1(k) := c(2*k);
            else
                v1(k) := v(2*k + 1); c1(k) := c(2*k + 1);
            end if;
        end loop;
        if c1(0) >= c1(1) then v2a := v1(0); c2a := c1(0); else v2a := v1(1); c2a := c1(1); end if;
        if c1(2) >= c1(3) then v2b := v1(2); c2b := c1(2); else v2b := v1(3); c2b := c1(3); end if;
        if c2a >= c2b then return v2a; else return v2b; end if;
    end function;

    
    
    
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
    -- Fix (Nov 2026): the write index is now cleared by reset, and pulled back
    -- into the window if the buffer length shrinks below it. The 'mod' by a
    -- variable (which needs a divider) is replaced by a simple compare-and-wrap.
    Bufferstore: process(i_Clk, i_Reset)
        variable v_Index : integer range 0 to 7;
    begin
        if i_Reset = '1'then
            r_Buffer_0 <= (others => (others => '0'));
            r_Buffer_1 <= (others => (others => '0'));
            r_WriteIndex <= 0;
        elsif rising_edge(i_Clk) then
            if i_CE1Hz = '1' and r_Buffer_ON then
                -- If the length was reduced, the old index may be outside the window
                if r_WriteIndex >= i_BufferLength then
                    v_Index := 0;
                else
                    v_Index := r_WriteIndex;
                end if;

                -- Store the incoming data in the buffers
                r_Buffer_0(v_Index) <= i_Data_0;
                r_Buffer_1(v_Index) <= i_Data_1;

                -- Move the pointer on, wrapping at the end of the window
                if v_Index + 1 >= i_BufferLength then
                    r_WriteIndex <= 0;
                else
                    r_WriteIndex <= v_Index + 1;
                end if;
            end if;
        end if;
    end process;
   
   
    -- Process to Sort buffer - Synthesis Compatible Version -- Written By Paing 
    -- Rewritten Nov 2026: odd-even transposition sort, one phase per clock.
    -- The old version bubble-sorted all 8 values in ONE clock using variables,
    -- which built a 49-level logic chain (-30.7 ns slack at 100 MHz).
    -- Here each clock does ONE phase: up to 4 compare-swaps side by side on
    -- disjoint pairs, so the path is a single comparator deep. Uses signals,
    -- not variables, so nothing chains within a clock.
    -- A full sort takes 10 clocks (100 ns); samples arrive once per second.
    Sorting_Buffer: process (i_Clk, i_Reset)
    begin
        if i_Reset = '1' then
            r_SortedBuffer_0 <= (others => (others => '0'));
            r_SortedBuffer_1 <= (others => (others => '0'));
            r_Work_0 <= (others => (others => '0'));
            r_Work_1 <= (others => (others => '0'));
            r_Phase  <= 0;
        elsif rising_edge(i_Clk) then
            if r_Phase = 0 then
                -- Take a snapshot of the buffer to sort
                r_Work_0 <= r_Buffer_0;
                r_Work_1 <= r_Buffer_1;
                r_Phase  <= 1;

            elsif r_Phase <= 8 then
                -- 8 phases always sort up to 8 values
                if (r_Phase mod 2) = 1 then
                    -- Odd phase: compare pairs (0,1) (2,3) (4,5) (6,7)
                    for k in 0 to 3 loop
                        if 2*k + 1 < i_BufferLength then        -- only inside the active window
                            if r_Work_0(2*k) > r_Work_0(2*k + 1) then
                                r_Work_0(2*k)     <= r_Work_0(2*k + 1);
                                r_Work_0(2*k + 1) <= r_Work_0(2*k);
                            end if;
                            if r_Work_1(2*k) > r_Work_1(2*k + 1) then
                                r_Work_1(2*k)     <= r_Work_1(2*k + 1);
                                r_Work_1(2*k + 1) <= r_Work_1(2*k);
                            end if;
                        end if;
                    end loop;
                else
                    -- Even phase: compare pairs (1,2) (3,4) (5,6)
                    for k in 0 to 2 loop
                        if 2*k + 2 < i_BufferLength then
                            if r_Work_0(2*k + 1) > r_Work_0(2*k + 2) then
                                r_Work_0(2*k + 1) <= r_Work_0(2*k + 2);
                                r_Work_0(2*k + 2) <= r_Work_0(2*k + 1);
                            end if;
                            if r_Work_1(2*k + 1) > r_Work_1(2*k + 2) then
                                r_Work_1(2*k + 1) <= r_Work_1(2*k + 2);
                                r_Work_1(2*k + 2) <= r_Work_1(2*k + 1);
                            end if;
                        end if;
                    end loop;
                end if;
                r_Phase <= r_Phase + 1;

            else
                -- Phase 9: publish the sorted result; unused slots read as zero
                for i in 0 to 7 loop
                    if i < i_BufferLength then
                        r_SortedBuffer_0(i) <= r_Work_0(i);
                        r_SortedBuffer_1(i) <= r_Work_1(i);
                    else
                        r_SortedBuffer_0(i) <= (others => '0');
                        r_SortedBuffer_1(i) <= (others => '0');
                    end if;
                end loop;
                r_Phase <= 0;
            end if;
        end if;
    end process;
    
    ----------------------------------------------------------------------------
    -- Statistics - rewritten Nov 2026
    -- Before: four UNclocked processes, each only updating while its statistic
    -- was selected, so Vivado built 64 latches (TIMING-20). The mean also
    -- divided by a variable length, which builds a divider circuit.
    -- Now: all four statistics are computed every clock into registers.
    --   Mean   : balanced adder tree, then divide by 2/4/8 as a right shift
    --   Median : middle value, or average of the two middle values (shift by 1)
    --   Range  : last active value minus first (buffer is sorted)
    --   Mode   : 2-stage pipeline - stage 1 counts how often each value appears,
    --            stage 2 picks the highest count (ties -> smaller value)
    -- Lengths are 1, 2, 4 or 8 (set by the switches in the top level).
    ----------------------------------------------------------------------------
    Statistics: process (i_Clk, i_Reset)
    begin
        if i_Reset = '1' then
            r_Mean_0   <= (others => '0');  r_Mean_1   <= (others => '0');
            r_Median_0 <= (others => '0');  r_Median_1 <= (others => '0');
            r_Range_0  <= (others => '0');  r_Range_1  <= (others => '0');
            r_Mode_0   <= (others => '0');  r_Mode_1   <= (others => '0');
            r_Count_0  <= (others => 0);    r_Count_1  <= (others => 0);
            r_ModeVals_0 <= (others => (others => '0'));
            r_ModeVals_1 <= (others => (others => '0'));
        elsif rising_edge(i_Clk) then
            r_Mean_0   <= f_Mean(r_SortedBuffer_0, i_BufferLength);
            r_Mean_1   <= f_Mean(r_SortedBuffer_1, i_BufferLength);
            r_Median_0 <= f_Median(r_SortedBuffer_0, i_BufferLength);
            r_Median_1 <= f_Median(r_SortedBuffer_1, i_BufferLength);
            r_Range_0  <= f_Range(r_SortedBuffer_0, i_BufferLength);
            r_Range_1  <= f_Range(r_SortedBuffer_1, i_BufferLength);

            -- Mode stage 1: count occurrences, keep the values they belong to
            r_Count_0    <= f_Counts(r_SortedBuffer_0, i_BufferLength);
            r_Count_1    <= f_Counts(r_SortedBuffer_1, i_BufferLength);
            r_ModeVals_0 <= r_SortedBuffer_0;
            r_ModeVals_1 <= r_SortedBuffer_1;

            -- Mode stage 2: pick the winner from the registered counts
            r_Mode_0 <= f_PickMode(r_ModeVals_0, r_Count_0);
            r_Mode_1 <= f_PickMode(r_ModeVals_1, r_Count_1);
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
