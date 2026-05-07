transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+T05_M3_TopLevel_TB  -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.T05_M3_TopLevel_TB xil_defaultlib.glbl

do {T05_M3_TopLevel_TB.udo}

run 1000ns

endsim

quit -force
