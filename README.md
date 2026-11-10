# Rolling Arithmetic Filter – VHDL on a Basys 3 FPGA

A VHDL design for the Artix-7 FPGA (Digilent Basys 3) that computes a rolling **mean, median, mode and range** over the last 2, 4 or 8 samples of two data channels, taken either from an on-chip waveform generator or from the XADC analogue inputs. Results are shown in hexadecimal on the seven-segment display.

![Vivado](https://img.shields.io/badge/Vivado-2026.1-blue)
![VHDL](https://img.shields.io/badge/VHDL-2008-orange)
![Board](https://img.shields.io/badge/Board-Basys%203%20(Artix--7)-green)
![Timing](https://img.shields.io/badge/Timing-met%20at%20100%20MHz-brightgreen)
![Tests](https://img.shields.io/badge/Testbench-77%2F77%20passing-brightgreen)

Originally built as a two-person team project for ENG631 – VHDL & FPGA Systems (University of Portsmouth, 2024/25). In November 2026 I reworked the filter engine: added a self-checking testbench, fixed a timing failure, a write-pointer bug and 64 inferred latches, and re-ran implementation to confirm the results below.

---

## Results of the 2026 rework

| Metric (Vivado, xc7a35tcpg236-1, 100 MHz) | Original (Jan 2025) | Reworked (Nov 2026) |
|---|---|---|
| Worst negative slack (setup) | **−30.691 ns** (fails) | **+1.436 ns** (meets) |
| Total negative slack | −2,914.9 ns | 0 ns |
| Failing timing endpoints | 128 of 515 | 0 of 1,153 |
| Worst hold slack | +0.158 ns | +0.074 ns |
| Achievable clock (approx.) | ~24.6 MHz | 100 MHz |
| Slice LUTs | 2,501 | 1,077 (−57%) |
| Registers | 417 | 741 |
| Inferred latches | 64 | 0 |
| Clock domains | 2 (unintended crossing) | 1 |
| Methodology critical warnings | TIMING-4, -6, -7, -27 | none |

### What was wrong and how it was fixed

**1. Sort did not fit in one clock cycle (−30.7 ns slack).**
The buffer was bubble-sorted with nested `for` loops on *variables* inside one clocked process. In hardware a loop is unrolled, so all 28 compare-and-swap steps were chained between two registers: 49 logic levels and 40.5 ns of delay against a 10 ns clock. 72% of that delay was routing.

Samples only arrive once per second, so the sort does not need to finish in one clock. It is now an **odd-even transposition sort** running one phase per clock: each phase compares up to four disjoint pairs in parallel, so each path is a single comparator deep. A full sort of 8 values takes 10 clocks (100 ns). It uses signals, not variables, so nothing chains within a clock cycle.

**2. Newest sample lost after shrinking the buffer (functional bug, found by the testbench).**
The write pointer was not cleared by reset, and was not brought back inside the window when the buffer length was reduced. With the pointer on slot 5, switching from length 8 to length 4 caused the next sample to be written outside the active window and ignored. The pointer is now reset, and wraps to slot 0 when it is outside the window. The `mod` by a variable length (which builds a divider) was replaced by a compare-and-wrap.

**3. 64 latches in the statistics logic.**
Mean, median, mode and range were unclocked processes that only updated while their statistic was selected on the switches, so Vivado inferred latches to hold the values in between. All four are now computed every clock into registers:
- **Mean:** balanced adder tree (3 levels instead of 7), then divide by 2, 4 or 8 as a right shift instead of a divider.
- **Median:** fixed middle position(s) for each supported length.
- **Range:** last active value minus first (the buffer is sorted).
- **Mode:** two-stage pipeline. Stage 1 counts how often each value appears; stage 2 picks the highest count with a three-level tournament. Ties go to the smaller value.

**4. Two clock domains.**
Every module ran on the clocking wizard's output except the waveform generator, which used the raw board clock, so data crossed between two clocks. It now uses the system clock like the rest of the design. A duplicate `create_clock -add` in the XDC (the clocking wizard IP already constrains its input) was also removed.

The current critical path is the mean adder tree (`r_SortedBuffer → r_Mean`): 11 logic levels, 8.5 ns, 1.4 ns of slack.

---

## Verification

`T05_M3_Project_VFinal.srcs/sim_1/new/tb_BufferFilters.vhd` is a self-checking testbench for the filter engine (`T05_M3_BufferFilters`). It drives samples through the 1 Hz clock-enable input exactly as the hardware does, selects each statistic in turn, and compares both channels against values worked out by hand. It counts failures and prints a pass/fail summary, so no waveform reading is needed.

| Test | What it checks |
|---|---|
| T1 | Buffer not yet full: empty slots count as zero (e.g. (6+6+9)/8 = 2, integer division) |
| T2 | Full buffer of 8; three-way mode tie resolves to the smallest value |
| T3 | Ninth sample overwrites the oldest |
| T4 | Outlier: mean pulled up, median and mode unaffected |
| T5–T7 | Buffer length changed at runtime (8 → 4 → 2) |
| T8 | Maximum value 255 on both channels (no overflow) |
| T9 | Length 1 switches the buffer off; input passes straight through |
| T10 | Reset clears all state |
| T11 | Regression test for the write-pointer bug above |

Result: **77/77 checks pass** on the reworked design, in both Vivado XSim and GHDL. The testbench was written first, run against the original design (all functional checks passed, T11 reproduced the bug), and then used as a regression check after every change.

To run it in Vivado: set `tb_BufferFilters` as the simulation top, run behavioural simulation, then **Run All** (the default 1000 ns is not long enough). The last line in the Tcl console should read:

```
==== ALL FUNCTIONAL TESTS PASSED (77 checks, 0 known bug(s) reproduced) ====
```

`T05_M3_TopLevel_TB.vhd` is the original top-level testbench from 2024. It applies stimulus only and is checked by eye in the waveform viewer.

---

## Design overview

```
 Wave generator ─┐                ┌──────────── BufferFilters ────────────┐
 (test patterns) ├─► input select ─►  circular  ─► odd-even ─► statistics ─┼─► display driver ─► 7-segment
 XADC (VAUX6/7) ─┘   (SW14)        │  buffer       sort        (registered)│    (hex, 250 Hz)
                                   └────────────────────────────────────────┘
 All logic on one 100 MHz clock (clocking wizard); 1 Hz and 250 Hz clock enables pace the data and display.
```

| Module | Function |
|---|---|
| `T05_M3_TopLevel.vhd` | Instantiates all modules; selects waveform or XADC data; drives display and LEDs |
| `T05_M3_ClkEn1Hz.vhd`, `T05_M3_ClkEn250Hz.vhd` | Clock-enable pulses for sampling (1 Hz, with a fast mode) and display multiplexing |
| `T05_M3_WaveGenerator.vhd` | FSM producing 16-step square, triangle and sawtooth sequences; Start button synchronised to the clock; outputs zeros for 8 samples when the waveform family is switched |
| `T05_M3_XADC.vhd` | Alternates the XADC between channels VAUX6 and VAUX7 and keeps the upper 8 bits of each result |
| `T05_M3_BufferFilters.vhd` | Circular buffer (length 2, 4 or 8), multi-cycle sort, registered mean/median/mode/range |
| `T05_M3_BinaryCounter.vhd`, `T05_M3_DisplayDriver.vhd` | Seven-segment digit multiplexing and hex encoding |

IP: `clk_wiz_0` (Clocking Wizard) and `xadc_wiz_0` (XADC Wizard).

---

## Known limitations

- **Hardware:** the original design was tested on a Basys 3 board in 2025. The 2026 changes are verified in simulation and through implementation and timing analysis, but have not yet been re-tested on the board.
- **I/O timing:** the switches, buttons and display have no input/output delay constraints (methodology warning TIMING-18). These are human-speed signals, so the risk is low, but they are not formally timed.
- **Buffer lengths:** the statistics support lengths 1 (off), 2, 4 and 8, which are the values the switches can select.
- **Asynchronous inputs:** apart from Start, the switches and the reset button are not synchronised to the clock.

---

## Repository structure

```
Rolling-Arithmatic-Filter/
├── T05_M3_Project_VFinal.xpr              Vivado project file
├── T05_M3_Project_VFinal.srcs/
│   ├── constrs_1/new/T05_M3_Project.xdc   Pin and clock constraints
│   ├── sim_1/new/
│   │   ├── tb_BufferFilters.vhd           Self-checking testbench (2026)
│   │   └── T05_M3_TopLevel_TB.vhd         Original top-level testbench
│   └── sources_1/
│       ├── ip/                            clk_wiz_0 and xadc_wiz_0 (.xci)
│       └── new/                           VHDL sources
├── .gitignore                             Excludes Vivado build output
└── README.md
```

Vivado build output (`.cache`, `.gen`, `.runs`, `.sim`, `.hw`, `.ip_user_files`) is not tracked; Vivado regenerates it.

---

## How to build

1. Clone the repository:
   ```
   git clone https://github.com/ryan7302/Rolling-Arithmatic-Filter.git
   ```
2. Open `T05_M3_Project_VFinal.xpr` in Vivado 2026.1 or later. If prompted, upgrade the two IP cores and let Vivado generate their output products.
3. Run synthesis, implementation and bitstream generation.
4. Program the Basys 3 from the Hardware Manager.

## How to operate

| Control | Function |
|---|---|
| BTND (U17) | Start waveform generation |
| BTNU (T18) | Reset |
| SW0 (V17) | Fast mode: a sample every 250 clocks instead of once per second (for testing) |
| SW15 (R2) | Waveform family: square / triangle and sawtooth |
| SW14 (T1) | Data source: waveform generator / XADC |
| SW2, SW1 (W16, V16) | Buffer length: 00 = off, 01 = 2, 10 = 4, 11 = 8 |
| SW10, SW9 (T2, T3) | Statistic: 00 = mean, 01 = median, 10 = mode, 11 = range |

The display shows two hexadecimal digits per channel. LEDs show the selected buffer length and statistic.

## Pin mapping (Basys 3)

| Signal | Pin | Description |
|---|---|---|
| `i_Clk` | W5 | 100 MHz oscillator |
| `i_Reset` | T18 | BTNU |
| `i_Start` | U17 | BTND |
| `i_Fast` | V17 | SW0 |
| `i_WaveSwitch` | R2 | SW15 |
| `i_XADCSwitch` | T1 | SW14 |
| `i_BufferSizeSwitch[1:0]` | W16, V16 | SW2, SW1 |
| `i_DisplaySwitch[1:0]` | T2, T3 | SW10, SW9 |
| `vauxp6` / `vauxn6` | J3 / K3 | XADC channel 6 (JXADC header) |
| `vauxp7` / `vauxn7` | M2 / M1 | XADC channel 7 (JXADC header) |

---

## Team and credits

**Paing Htet Kyaw** ([ryan7302](https://github.com/ryan7302)) – buffer and filter engine, XADC integration, Start synchronisation and flush, mode and range filters, simulation and hardware test (2024/25); verification, timing closure and rework of the filter engine (2026).

**Joseph Stiles** – waveform generator FSM, first versions of the median and mean modules, top-level integration and troubleshooting (2024/25).

University of Portsmouth, ENG631 – VHDL & FPGA Systems.
