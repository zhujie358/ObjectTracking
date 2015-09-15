# Using the DE2 SRAM
### Overview
The goal of this experiment was to write a Verilog module to abstract the DE2 SRAM signals to a simpler interface. The simplest implemenation of a block RAM has only a few signals:
- write enable: `wen`
- address: `addr`
- input data: `din`
- output data: `dout`

Sometimes there will be an overall enable signal  (which was not implemented in this design), and of course the clock and reset. Working with an interface such as this will be much simpler than working with the bus of signals that the SRAM chip needs driven. The Verilog module `sram_wrapper.v` does this, by driving the control signals based on the table in page 4 of the SRAM datasheet (provided in the DE2 system CD). The only non-obvious part of the design was how to work with a bidirectional port, which handled by using two temporary signals and latching them. This gives the module one clock-cycle latency for reads and writes, which is expected for RAM implementations.

### Hardware Used

1.  Altera DE2 board

### Verification: Simulation
The module was first verified in simulation. Since there was no Verilog model on hand for the SRAM, the only function that could be verified was writes (reads would require some actual memory). The SystemVerilog file `testbench.sv` uses a mailbox to drop a few address/data packets in, and the results are viewed in modelsim.

To recreate this simulation, just add `./sram_wrapper.v` to the `vlog` line of the Makefile (there is a comment to indicate where). 

### Verification: Hardware
To get full verification that the SRAM was working properly, it had to be tested on the DE2 board. This was done by using the switches, keys, and LEDs. In `sram_controller.v`, the lower 8-bits of the input data and address are mapped to the switches. A value is written into the SRAM by putting these switches into a desired configuration, and pressing KEY2 (write enable). Pressing KEY3 reads back the value at that address on the LEDs. 

To make sure it was working a bunch of values were written into various address, and then read back randomly. The SRAM appeared to be storing the values correctly.