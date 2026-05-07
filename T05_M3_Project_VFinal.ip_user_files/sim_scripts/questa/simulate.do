onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib T05_M3_TopLevel_TB_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {T05_M3_TopLevel_TB.udo}

run 1000ns

quit -force
