vsim -t 1ns -voptargs=+acc -L work testbench

#Add the waveforms you want to see here
add wave -logic clk
add wave -logic rst
add wave -logic v_in
add wave -logic v_out
add wave -logic grayscale1
add wave -logic red1
add wave -logic green1
add wave -logic blue1

run -all