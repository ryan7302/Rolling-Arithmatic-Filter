 # Basys 3 Rolling Arithmetic Filters - Design Constraints file 
# Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports i_Clk]
# defining clock signal, period is in ns: name must be different from port, waveform 50:50 duty cycle and assign to same entity port
create_clock -add -period 10.000 -name C100MHz_pin -waveform {0.000 5.000} [get_ports i_Clk]

# Buttons
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports i_Reset]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports i_Start]

#Switches
#SWO
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {i_Fast}]
set_property -dict { PACKAGE_PIN R2   IOSTANDARD LVCMOS33 } [get_ports {i_WaveSwitch}]
set_property -dict { PACKAGE_PIN T1   IOSTANDARD LVCMOS33 } [get_ports {i_XADCSwitch}] 

# Constraints for two switches
# Buffer Size switches
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {i_BufferSizeSwitch[0]}] 
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports {i_BufferSizeSwitch[1]}] 

# Display Select switches
set_property -dict { PACKAGE_PIN T3   IOSTANDARD LVCMOS33 } [get_ports {i_DisplaySwitch[0]}] 
set_property -dict { PACKAGE_PIN T2   IOSTANDARD LVCMOS33 } [get_ports {i_DisplaySwitch[1]}]


# Auxiliary Analog Inputs (VAUX6)
set_property PACKAGE_PIN J3 [get_ports vauxp6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxp6]

set_property PACKAGE_PIN K3 [get_ports vauxn6] 
set_property IOSTANDARD LVCMOS33 [get_ports vauxn6]

# Auxiliary Analog Inputs (VAUX7)
set_property PACKAGE_PIN M2 [get_ports vauxp7]
set_property IOSTANDARD LVCMOS33 [get_ports vauxp7]

set_property PACKAGE_PIN M1 [get_ports vauxn7]
set_property IOSTANDARD LVCMOS33 [get_ports vauxn7]

#LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[5]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[6]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {o_LEDs[7]}]


# Seven-segment display
# Cathode A
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[6]}]
# CB
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[5]}]
# CC
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[4]}]
# CD
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[3]}]
# CE
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[2]}]
# CF
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[1]}]
# CG
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentCathodes[0]}]

# Anodes
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentAnodes[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentAnodes[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentAnodes[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {o_SegmentAnodes[3]}]

# Bitstream configuration
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]



