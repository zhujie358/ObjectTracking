vsim -t 1ns -voptargs=+acc -L work testbench

#Add the waveforms you want to see here
add wave -logic clk
add wave -logic rst_n
add wave -logic wen
add wave -logic addr
add wave -logic din
add wave -logic dout
add wave -logic SRAM_ADDR
add wave -logic SRAM_CE_N
add wave -logic SRAM_DQ
add wave -logic SRAM_LB_N
add wave -logic SRAM_OE_N
add wave -logic SRAM_UB_N
add wave -logic SRAM_WE_N
add wave -logic sram_wrapper_inst/a
add wave -logic sram_wrapper_inst/b
add wave -logic sram_wrapper_inst/output_enable

run -all