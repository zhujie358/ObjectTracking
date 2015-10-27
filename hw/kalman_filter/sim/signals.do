vsim -t 1ns -voptargs=+acc -L work testbench

#Add the waveforms you want to see here
add wave -logic clk
add wave -logic rst_n
add wave -logic valid
add wave -logic ready
add wave -logic -radix unsigned myKalman/fsm_curr
add wave -logic -radix unsigned myKalman/x_next
add wave -logic -radix unsigned myKalman/x_curr
add wave -logic -radix unsigned myKalman/z_x_new
add wave -logic -radix unsigned myKalman/z_y_new

run -all
