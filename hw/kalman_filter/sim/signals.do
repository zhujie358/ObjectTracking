vsim -t 1ns -voptargs=+acc -L work testbench

#Add the waveforms you want to see here
add wave -logic clk
add wave -logic rst_n

run -all
