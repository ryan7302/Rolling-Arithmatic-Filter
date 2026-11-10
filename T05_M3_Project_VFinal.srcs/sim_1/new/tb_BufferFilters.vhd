----------------------------------------------------------------------------------
-- tb_BufferFilters.vhd
-- Self-checking testbench for T05_M3_BufferFilters (rolling mean/median/mode/range)
--
-- How it works:
--   1. Generates a 100 MHz clock.
--   2. Pushes known samples into the buffer using the 1 Hz clock-enable input.
--   3. For each statistic, selects it with i_DisplaySelect and compares the
--      output against an answer worked out by hand.
--   4. Counts failures and prints PASS / FAIL at the end.
--
-- Run in Vivado: set as simulation top, then "Run All" (not the default 1000 ns).
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_BufferFilters is
end tb_BufferFilters;                      -- a testbench has no ports

architecture sim of tb_BufferFilters is

    constant CLK_PERIOD : time := 10 ns;   -- 100 MHz
    -- Clocks to wait before reading a result. The multi-cycle sort needs up to
    -- 20 clocks (finish current pass + one full 10-clock pass); 25 gives margin.
    constant SETTLE     : integer := 25;

    -- Signals that drive / observe the design under test (DUT)
    signal i_Clk           : std_logic := '0';
    signal i_Reset         : std_logic := '0';
    signal i_CE1Hz         : std_logic := '0';
    signal i_DisplaySelect : integer range 0 to 3 := 0;   -- 0 mean, 1 median, 2 mode, 3 range
    signal i_BufferLength  : integer range 0 to 8 := 8;
    signal i_Data_0        : std_logic_vector(7 downto 0) := (others => '0');
    signal i_Data_1        : std_logic_vector(7 downto 0) := (others => '0');
    signal o_Data_0        : std_logic_vector(7 downto 0);
    signal o_Data_1        : std_logic_vector(7 downto 0);

    signal sim_done        : boolean := false;               -- stops the clock at the end

begin

    ------------------------------------------------------------------------------
    -- Design under test
    ------------------------------------------------------------------------------
    uut: entity work.T05_M3_BufferFilters(Behavioral)
        port map (
            i_Clk           => i_Clk,
            i_Reset         => i_Reset,
            i_CE1Hz         => i_CE1Hz,
            i_DisplaySelect => i_DisplaySelect,
            i_BufferLength  => i_BufferLength,
            i_Data_0        => i_Data_0,
            i_Data_1        => i_Data_1,
            o_Data_0        => o_Data_0,
            o_Data_1        => o_Data_1);

    ------------------------------------------------------------------------------
    -- Clock: toggles every 5 ns until sim_done, so the simulation ends by itself
    ------------------------------------------------------------------------------
    clk_proc: process
    begin
        while not sim_done loop
            i_Clk <= '0'; wait for CLK_PERIOD / 2;
            i_Clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    ------------------------------------------------------------------------------
    -- Stimulus + checking
    ------------------------------------------------------------------------------
    stim: process
        variable errors : integer := 0;    -- failed functional checks
        variable checks : integer := 0;    -- total checks run
        variable bugs   : integer := 0;    -- known-bug checks that reproduced the bug

        -- Wait for n rising clock edges, then 1 ns so outputs have settled
        procedure tick(n : integer) is
        begin
            for k in 1 to n loop
                wait until rising_edge(i_Clk);
            end loop;
            wait for 1 ns;
        end procedure;

        -- Push one sample per channel, exactly like one 1 Hz tick on the board
        procedure push(d0, d1 : integer) is
        begin
            i_Data_0 <= std_logic_vector(to_unsigned(d0, 8));
            i_Data_1 <= std_logic_vector(to_unsigned(d1, 8));
            i_CE1Hz  <= '1';               -- enable is high for exactly one clock edge
            tick(1);
            i_CE1Hz  <= '0';
            tick(1);
        end procedure;

        -- Select one statistic and compare both channels with the expected values
        procedure check(sel : integer; exp0, exp1 : integer; name : string) is
            variable got0, got1 : integer;
        begin
            i_DisplaySelect <= sel;
            tick(SETTLE);                  -- wait for buffer -> sort -> statistic
            got0 := to_integer(unsigned(o_Data_0));
            got1 := to_integer(unsigned(o_Data_1));
            checks := checks + 2;
            if got0 /= exp0 then
                errors := errors + 1;
                report "FAIL " & name & " ch0: expected " & integer'image(exp0) &
                       ", got " & integer'image(got0) severity error;
            end if;
            if got1 /= exp1 then
                errors := errors + 1;
                report "FAIL " & name & " ch1: expected " & integer'image(exp1) &
                       ", got " & integer'image(got1) severity error;
            end if;
        end procedure;

        -- Check all four statistics in one go
        procedure check_stats(name : string;
                              mean0, mean1, med0, med1,
                              mode0, mode1, rng0, rng1 : integer) is
        begin
            check(0, mean0, mean1, name & " mean");
            check(1, med0,  med1,  name & " median");
            check(2, mode0, mode1, name & " mode");
            check(3, rng0,  rng1,  name & " range");
            report "done: " & name severity note;
        end procedure;

    begin
        ------------------------------------------------------------------------
        -- Reset
        ------------------------------------------------------------------------
        i_BufferLength <= 8;
        i_Reset <= '1'; tick(3);
        i_Reset <= '0'; tick(2);

        ------------------------------------------------------------------------
        -- T1  Length 8, buffer only part full: empty slots count as 0
        --     ch0: 6,6,9,0,0,0,0,0   sum 21 / 8 = 2 (integer division)
        --     ch1: 10,20,30,0...     sum 60 / 8 = 7
        ------------------------------------------------------------------------
        push(6, 10); push(6, 20); push(9, 30);
        check_stats("T1 part-full L=8", 2,7,  0,0,  0,0,  9,30);

        ------------------------------------------------------------------------
        -- T2  Fill all 8 slots
        --     ch0: 6,6,9,7,2,9,9,1   sorted 1,2,6,6,7,9,9,9
        --          mean 49/8=6  median (6+7)/2=6  mode 9  range 8
        --     ch1: 10..80            mean 45  median 45  mode tie->smallest 10  range 70
        ------------------------------------------------------------------------
        push(7, 40); push(2, 50); push(9, 60); push(9, 70); push(1, 80);
        check_stats("T2 full L=8", 6,45,  6,45,  9,10,  8,70);

        ------------------------------------------------------------------------
        -- T3  Rolling: 9th sample overwrites the OLDEST (slot 0)
        --     ch0: 100 replaces 6 -> sorted 1,2,6,7,9,9,9,100
        --          mean 143/8=17  median (7+9)/2=8  mode 9  range 99
        --     ch1: 255 replaces 10 -> mean 605/8=75  median 55  mode 20  range 235
        ------------------------------------------------------------------------
        push(100, 255);
        check_stats("T3 rolling overwrite", 17,75,  8,55,  9,20,  99,235);

        ------------------------------------------------------------------------
        -- T4  Seven equal values + one outlier
        --     ch0: 100,42x7  mean 394/8=49  median 42  mode 42  range 58
        --     ch1: 255,0x7   mean 31        median 0   mode 0   range 255
        ------------------------------------------------------------------------
        for k in 1 to 7 loop
            push(42, 0);
        end loop;
        check_stats("T4 mostly equal", 49,31,  42,0,  42,0,  58,255);

        ------------------------------------------------------------------------
        -- T5  Shrink length to 4 (no new data): only slots 0..3 count
        --     ch0: 100,42,42,42  mean 226/4=56  median 42  mode 42  range 58
        --     ch1: 255,0,0,0     mean 63        median 0   mode 0   range 255
        ------------------------------------------------------------------------
        i_BufferLength <= 4; tick(2);
        check_stats("T5 shrink to L=4", 56,63,  42,0,  42,0,  58,255);

        ------------------------------------------------------------------------
        -- T6  New data at length 4, including a tie for mode
        --     ch0: 3,7,7,2          sorted 2,3,7,7  mean 4  median 5  mode 7  range 5
        --     ch1: 200,100,200,100  mean 150  median 150  mode tie->100  range 100
        ------------------------------------------------------------------------
        push(3, 200); push(7, 100); push(7, 200); push(2, 100);
        check_stats("T6 L=4 new data", 4,150,  5,150,  7,100,  5,100);

        ------------------------------------------------------------------------
        -- T7  Shrink to length 2: slots 0,1 only
        --     ch0: 3,7      mean 5  median 5  mode tie->3  range 4
        --     ch1: 200,100  mean 150 median 150 mode 100  range 100
        ------------------------------------------------------------------------
        i_BufferLength <= 2; tick(2);
        check_stats("T7 shrink to L=2", 5,150,  5,150,  3,100,  4,100);

        ------------------------------------------------------------------------
        -- T8  Extreme values (overflow check)
        --     ch0: 255,255  mean 255  median 255  mode 255  range 0
        --     ch1: 0,255    mean 127  median 127  mode 0    range 255
        ------------------------------------------------------------------------
        push(255, 0); push(255, 255);
        check_stats("T8 max values L=2", 255,127,  255,127,  255,0,  0,255);

        ------------------------------------------------------------------------
        -- T9  Length 1 = buffer OFF: output must pass the input straight through
        ------------------------------------------------------------------------
        i_BufferLength <= 1;
        i_Data_0 <= x"AB"; i_Data_1 <= x"CD";
        tick(2);
        check(0, 16#AB#, 16#CD#, "T9 L=1 passthrough (sel 0)");
        check(3, 16#AB#, 16#CD#, "T9 L=1 passthrough (sel 3)");

        ------------------------------------------------------------------------
        -- T10 Reset clears everything
        ------------------------------------------------------------------------
        i_BufferLength <= 8; tick(1);
        i_Reset <= '1'; tick(2);
        i_Reset <= '0'; tick(3);
        check_stats("T10 after reset", 0,0,  0,0,  0,0,  0,0);

        ------------------------------------------------------------------------
        -- T11 KNOWN BUG: r_WriteIndex is not reset and not limited when the
        --     length shrinks. Write 5 samples at L=8 (index = 5), switch to L=4,
        --     push 50. A correct design shows 50 in the window (range = 40).
        --     The current design writes it to slot 5, outside the window.
        ------------------------------------------------------------------------
        for k in 1 to 5 loop
            push(10, 10);
        end loop;
        i_BufferLength <= 4; tick(2);
        push(50, 50);
        i_DisplaySelect <= 3; tick(SETTLE);
        checks := checks + 1;
        if to_integer(unsigned(o_Data_0)) /= 40 then
            bugs := bugs + 1;
            report "KNOWN BUG reproduced (T11): newest sample lost after shrinking length; range expected 40, got "
                   & integer'image(to_integer(unsigned(o_Data_0))) severity warning;
        else
            report "T11: write-index bug is FIXED" severity note;
        end if;

        ------------------------------------------------------------------------
        -- Summary
        ------------------------------------------------------------------------
        if errors = 0 then
            report "==== ALL FUNCTIONAL TESTS PASSED (" & integer'image(checks) &
                   " checks, " & integer'image(bugs) & " known bug(s) reproduced) ====" severity note;
        else
            report "==== " & integer'image(errors) & " FAILURE(S) out of " &
                   integer'image(checks) & " checks ====" severity error;
        end if;

        sim_done <= true;
        wait;
    end process;

end sim;
