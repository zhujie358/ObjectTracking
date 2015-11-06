vsim -t 1ns -voptargs=+acc -L work testbench

#Add the waveforms you want to see here
add wave -logic clk
add wave -logic rst_n
add wave -logic valid
add wave -logic ready
add wave -logic myKalman/division_done
add wave -logic -radix hexadecimal myKalman/fsm_curr
add wave -logic -radix hexadecimal myKalman/z_vec
add wave -logic -radix hexadecimal myKalman/x_next
add wave -logic -radix hexadecimal myKalman/p_next
add wave -logic -radix hexadecimal myKalman/y_vec
add wave -logic -radix hexadecimal myKalman/s_mat
add wave -logic -radix hexadecimal myKalman/s_det
add wave -logic -radix hexadecimal myKalman/s_inv
add wave -logic -radix hexadecimal myKalman/k_mat
add wave -logic -radix hexadecimal myKalman/x_curr
add wave -logic -radix hexadecimal myKalman/p_curr
add wave -logic -radix hexadecimal myKalman/z_x_new
add wave -logic -radix hexadecimal myKalman/z_y_new

run -all
