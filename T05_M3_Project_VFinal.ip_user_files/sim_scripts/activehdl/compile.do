transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../ipstatic" -l xpm -l xil_defaultlib \
"C:/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  \
"C:/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -93  \
"../../../T05_M3_Project_VFinal.gen/sources_1/ip/xadc_wiz_0/xadc_wiz_0.vhd" \
"../../../T05_M3_Project_VFinal.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_sim_netlist.vhdl" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M2_XADCController.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_BinaryCounter.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_BufferFilters.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_ClkEn1Hz.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_ClkEn250Hz.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_DisplayDriver.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_WaveGenerator.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sources_1/new/T05_M3_TopLevel.vhd" \
"../../../T05_M3_Project_VFinal.srcs/sim_1/new/T05_M3_TopLevel_TB.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

