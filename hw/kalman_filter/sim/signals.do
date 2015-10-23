vsim -t 1ns -voptargs=+acc -L work testbench

#Add the waveforms you want to see here
add wave -logic clk
add wave -logic rst_n
add wave -logic valid
add wave -logic ready
add wave -logic myKalman/fsm_clear_all
add wave -logic myKalman/fsm_clear_tmp
add wave -logic -radix unsigned x_pos
add wave -logic -radix unsigned y_pos
add wave -logic -radix unsigned x_res
add wave -logic -radix unsigned y_res
add wave -logic -radix unsigned myKalman/fsm_curr
add wave -logic -radix unsigned myKalman/x_next
add wave -logic -radix unsigned myKalman/x_curr
add wave -logic -radix decimal myKalman/p_next
add wave -logic -radix decimal myKalman/p_curr
add wave -logic -radix decimal myKalman/y_vec

run -all
