EXP_NAME = kalman_filter

make all:
	@echo "------------ TARGETS ------------"
	@echo "simulate   : Functional simulation of Verilog test bench."
	@echo "hw_all     : Entire hardware flow."
	@echo "hw_compile : Compile the RTL code to check for bugs."
	@echo "hw_pnr     : Perform place and route."
	@echo "hw_build   : Generate bitstream to program FPGA."
	@echo "hw_prog    : Program the hardware design onto the FPGA."
	@echo "clean      : Blast transient files away."

clean:
	rm -rf db/
	rm -rf incremental_db/
	rm -rf work/
	rm -f *.rpt *.smsg *.rpt *.pin *.sof *.summary *.done *.txt *.bak *.qpf *.wlf
	rm -f transcript
	rm -f hw_compile 
	rm -f hw_pnr
	rm -f hw_build
	rm -f hw_prog
	rm -f hw_all
	rm -f simulate

hw_compile: 
	quartus_map $(EXP_NAME)
	touch hw_compile

hw_pnr: hw_compile
	quartus_fit $(EXP_NAME)
	touch hw_pnr

hw_build: hw_pnr
	quartus_asm $(EXP_NAME)
	touch hw_build

hw_prog: hw_build
	quartus_pgm -c USB-Blaster -m JTAG -o p\;$(EXP_NAME).sof\;@1
	touch hw_prog

hw_all:
	make hw_compile
	make hw_pnr
	make hw_build
	sleep 3
	make hw_prog
	touch hw_compile
	touch hw_pnr
	touch hw_build
	touch hw_prog

simulate:
	vlib  work
	# Append other Verilog needed for sim in this line
	vlog  ./sim/testbench.sv ./kalman.v ../common/fixed_point/qadd.v ../common/fixed_point/qmult.v
	modelsim -do sim/signals.do
	touch simulate