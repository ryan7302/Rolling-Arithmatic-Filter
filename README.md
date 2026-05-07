# Rolling Arithmetic Filter – FPGA Design on Basys 3

> **A hierarchical VHDL system for the Xilinx Artix‑7 FPGA that performs real‑time rolling Mean, Median, Mode and Range calculations on both generated waveforms and live XADC analogue inputs.**

![Vivado](https://img.shields.io/badge/Vivado-2024.1-blue)
![VHDL](https://img.shields.io/badge/VHDL-2008-orange)
![Board](https://img.shields.io/badge/Board-Basys%203%20(Artix‑7)-green)
![Status](https://img.shields.io/badge/Status-Validated%20on%20Hardware-brightgreen)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

<p align="center">
  <i>Developed as the capstone team project for ENG631 – VHDL &amp; FPGA Systems (University of Portsmouth, 2024/25).</i>
</p>

---

## 📖 Overview

This repository contains the complete Vivado project for a **rolling arithmetic filter** that processes data from two sources:

1. **Waveform generator** – produces sixteen‑byte sequences of square, triangular and sawtooth waves.
2. **Xilinx XADC** – samples two auxiliary analogue channels (0‑1 V) and converts them to 8‑bit digital values.

Both streams are fed into a **configurable buffer** whose length can be set to 2, 4 or 8 samples. A **filter engine** then computes one of four statistics—**Mean, Median, Mode or Range**—and displays the result in hexadecimal on the Basys 3’s four‑digit seven‑segment display and on eight LEDs.

The design is fully synchronous: a 100 MHz system clock drives two clock‑enable generators (1 Hz and 250 Hz) that pace data generation, buffer updates, filter calculations and display multiplexing.

---

## 🚀 Key Features

- **Rolling Filter Engine**
  Computes **Mean, Median, Mode and Range** on‑the‑fly using a circular buffer.
- **Configurable Buffer Depth**
  User‑selectable window lengths of 2, 4 or 8 samples, changed at runtime via slide switches.
- **Waveform Generator**
  Generates sixteen‑byte sequences of Square 1, Square 2, Triangular and Sawtooth waves.
- **XADC Interface**
  Reads two analogue channels (VAUX6 & VAUX7) and scales 16‑bit data to 8‑bit values.
- **Hexadecimal Display Driver**
  Drives the four‑digit seven‑segment display with full hexadecimal encoding (0‑F), multiplexed at 250 Hz.
- **Hardware Controls**
  Debounced push‑buttons for Start/Reset, slide switches for mode selection, and LED status indicators.
- **Fully Synchronous RTL Design**
  All modules written in behavioural VHDL; verified with Vivado Simulator and tested on physical hardware.
- **Complete Vivado Project**
  Includes source files, a top‑level testbench, and an XDC constraints file.

---

## 🧱 Repository Structure

```bash
Rolling-Arithmatic-Filter/
├── T05_M3_Project_VFinal.cache/ # Vivado cache
├── T05_M3_Project_VFinal.gen/ # Generated IP sources (clk_wiz, xadc_wiz)
├── T05_M3_Project_VFinal.hw/ # Hardware manager files
├── T05_M3_Project_VFinal.ip_user_files/ # IP user files
├── T05_M3_Project_VFinal.runs/ # Implementation runs
├── T05_M3_Project_VFinal.sim/ # Simulation files
├── T05_M3_Project_VFinal.srcs/
│ ├── constrs_1/new/
│ │ └── T05_M3_Project.xdc # Pin constraints & clock definition
│ ├── sim_1/new/
│ │ └── T05_M3_TopLevel_TB.vhd # Top‑level testbench
│ └── sources_1/
│ ├── ip/ # IP core containers
│ └── new/
│ ├── T05_M3_BinaryCounter.vhd
│ ├── T05_M3_BufferFilters.vhd
│ ├── T05_M3_ClkEn1Hz.vhd
│ ├── T05_M3_ClkEn250Hz.vhd
│ ├── T05_M3_DisplayDriver.vhd
│ ├── T05_M3_TopLevel.vhd
│ ├── T05_M3_WaveGenerator.vhd
│ └── T05_M3_XADC.vhd
└── README.md
```


---

## 👥 Team

| Name | Student ID | Role |
|------|------------|------|
| **Paing Htet Kyaw** | `up2301555` | Buffer‑filter engine, XADC integration, mode/range filters, simulation & hardware test |
| **Joseph Stiles** | `up2244748` | Wave‑generator FSM, median/mean modules, top‑level integration & troubleshooting |

**Repository Owner:** [ryan7302 (Paing Htet Kyaw)](https://github.com/ryan7302)

---

## 🛠️ Tools & Technologies

| Tool / Technology | Purpose |
|-------------------|---------|
| **Xilinx Vivado 2024.1** | Synthesis, implementation, simulation, and bitstream generation |
| **VHDL (IEEE 1076‑2008)** | All custom modules written in behavioural VHDL |
| **Basys 3 (Artix‑7 XC7A35T)** | Target FPGA board with 100 MHz oscillator, 7‑seg display, LEDs, XADC, switches |
| **XADC Wizard IP** | On‑chip ADC configuration and data acquisition |
| **clk_wiz_0 IP** | Clock Management Tile (CMT) for stable 100 MHz system clock |
| **SystemVerilog / Verilog** | Generated IP wrappers (clk_wiz, xadc_wiz) |
| **Tcl** | Vivado project scripts and constraints |

---

## 🧠 Key Design Details

### 1. Clock Enables (1 Hz & 250 Hz)
Two modules divide the 100 MHz system clock to produce precise enable pulses. The 1 Hz enable paces data generation and buffer updates; the 250 Hz enable drives the seven‑segment display multiplexing.

### 2. Waveform Generator (`T05_M3_WaveGenerator.vhd`)
A finite‑state machine (FSM) generates sixteen 8‑bit values per cycle:
- **Channel 0** – Square1 & Square2 sequences
- **Channel 1** – Triangular & Sawtooth sequences

A “flush” mechanism outputs sixteen bytes of `0x00` whenever the user switches between waveform families.

### 3. XADC Module (`T05_M3_XADC.vhd`)
Interfaces with the `xadc_wiz_0` IP in **continuous sequential mode**. An internal FSM toggles between channel addresses `0x16` (VAUX6) and `0x17` (VAUX7), extracts the upper 8 bits of the 16‑bit conversion result, and stores them in two 8‑bit registers.

### 4. Buffer & Filter Engine (`T05_M3_BufferFilters.vhd`)
- **Buffer** – a static array of 8 elements that behaves like a dynamic circular buffer. When the depth is set to 2, 4 or 8, only the active portion is sorted and used for calculations; the inactive portion is zeroed.
- **Sorting** – bubble sort algorithm implemented with nested `for` loops, operating solely on the active buffer region.
- **Filter Selection** – controlled by `i_DisplaySelect` ( `00` = Mean, `01` = Median, `10` = Mode, `11` = Range ).
- **Edge Cases** – median for even‑length buffers averages the two middle values; mode breaks ties by choosing the smallest value.

### 5. Display Driver (`T05_M3_DisplayDriver.vhd`)
Accepts two 4‑bit BCD digits per seven‑segment position and encodes them as hexadecimal (0‑F). Anodes are multiplexed by a 2‑bit binary counter clocked at 250 Hz.

### 6. Top‑Level (`T05_M3_TopLevel.vhd`)
Instantiates all submodules, maps the XADC and Waveform Generator outputs to the Buffer/Filter inputs (depending on the XADC switch), and routes filter outputs to the Display Driver and LEDs.

---

## 🔌 Pin Mapping (Basys 3)

| Signal | Pin | Description |
|--------|-----|-------------|
| `i_Clk` | W5 | 100 MHz system clock |
| `i_Reset` | T18 | Reset push‑button (BTNU) |
| `i_Start` | U17 | Start push‑button (BTND) |
| `i_Fast` | V17 | Fast‑mode switch (SW0) |
| `i_WaveSwitch` | R2 | Waveform select switch (SW15) |
| `i_XADCSwitch` | T1 | XADC enable switch (SW14) |
| `i_BufferSizeSwitch[0]` | V16 | Buffer size LSB (SW1) |
| `i_BufferSizeSwitch[1]` | W16 | Buffer size MSB (SW2) |
| `i_DisplaySwitch[0]` | T3 | Filter select LSB (SW9) |
| `i_DisplaySwitch[1]` | T2 | Filter select MSB (SW10) |
| `vauxp6` / `vauxn6` | J3 / K3 | Analogue input channel 6 |
| `vauxp7` / `vauxn7` | M2 / M1 | Analogue input channel 7 |
| `o_SegmentCathodes` | — | Seven‑segment cathodes |
| `o_SegmentAnodes` | — | Seven‑segment anodes |
| `o_LEDs[7:0]` | U16, E19, … | LED status indicators |

---

## 🧪 Validation & Testing

### Simulation
- A top‑level testbench (`T05_M3_TopLevel_TB.vhd`) exercises the design with a 100 MHz clock, stimulus processes for Reset, Start, Fast, WaveSelect, BufferSize and DisplaySelect.
- Simulations confirm correct waveform generation, buffer sizing, filter calculations, and display multiplexing.

### Synthesis & Implementation
- **Device:** xc7a35tcpg236‑1 (Basys 3)
- **Synthesis warnings:** mainly unconnected XADC data bits (expected when scaling 16‑bit → 8‑bit)
- **Implementation:** passes routing with minor clock‑region warnings; timing met for all critical paths
- **WNS (example):** +1.904 ns (≥ 0)

### Hardware Test
The design was fully validated on a Basys 3 board:
- Counter increments correctly; resets on BTNU press
- Square, triangular and sawtooth waves generate correct 16‑byte sequences
- Flush sequence appears when toggling the waveform switch
- XADC reads a potentiometer (0‑1 V) and displays hexadecimal values
- Buffer lengths 2, 4, 8 work interchangeably; inactive slots are ignored
- Mean, Median, Mode, Range outputs are mathematically correct
- LED indicators show active filter and buffer size

---

## 🚀 How to Use

1. **Clone the repository**
   ```bash
   git clone https://github.com/ryan7302/Rolling-Arithmatic-Filter.git
    ```
2. **Open Vivado 2024.1 (or later) and launch the project file:**
   ```bash
    T05_M3_Project_VFinal.xpr
    ```
3. **Validate the IP cores** – both `clk_wiz_0` and `xadc_wiz_0` should regenerate automatically. If prompted, upgrade IP to the current version.

4. **Run synthesis, implementation, and generate bitstream.**

5. **Program the Basys 3 board** via the Hardware Manager.

6. **Operate the system:**
   - Press **Start** (U17) to begin waveform generation.
   - Use **SW15** (R2) to switch between square‑wave and triangular/sawtooth families.
   - Use **SW14** (T1) to switch between waveform data and XADC analogue readings.
   - Use **SW1 & SW2** to set buffer length (00 = OFF, 01 = 2, 10 = 4, 11 = 8).
   - Use **SW9 & SW10** to select the filter (00 = Mean, 01 = Median, 10 = Mode, 11 = Range).
   - Press **Reset** (T18) to return to initial state at any time.

---

## 🤝 Team & Credits

**Paing Htet Kyaw** – Buffer‑filter engine, XADC integration, start‑flush synchronisation, mode/range filters, simulation & hardware test.

**Joseph** – Finite state machine design for wave generator, initial median/mean modules, top‑level integration and troubleshooting.

Supervised by **University of Portsmouth**, module **ENG631 – VHDL & FPGA Systems**.

---

<p align="center">
  <i>Built by <a href="https://github.com/ryan7302">Paing Htet Kyaw</a> &amp; Joseph Stiles<br>
  University of Portsmouth – ENG631 VHDL &amp; FPGA Systems</i>
</p>


