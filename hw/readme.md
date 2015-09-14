# Phase II: Hardware Development
### Overview
Phase II of the __ObjectTracking__ project is focused on hardware implementation of the motion based object tracking algorithm developed in the `sw/` directory. As discussed in the Phase I documentation, the hardware platform chosen is the Altera DE2 board made by Terasic. The hardware targeted on this board is the Cyclone IV FPGA, on-board memory, and video peripherals.
### Usage
A Makefile flow has been developed for functional simulation and the FPGA programming toolchain. Copy, or symbolically link, the `Makefile` from the `common/` directory into the experiment directory of interest. In this file, change the variable `EXP_NAME` to the directory name. Type `make` in your shell to see the list of options, and then type `make` followed by that option to use it. You will need Quartus and Modelsim to use the Makefile flow.
### Directory Structure
Each folder in this directory represents an experiment using the hardware, which builds on the ones before it. Each directory is a Quartus II project folder, meaning the experiments can be recreated locally with just the files in the Git repository and the necessary hardware specified within each experiment.
### Experiments
Order | Name | Goal | Status
----- | ---- | ---- | ------
1 | `vga_demo`    | Write a Verilog module to produce a sample VGA output using the ADV7123. Learn about the VGA interface. | Complete
2 | `vid_io_demo` | Use the Terasic TV Decoder demonstration to show live video from a NTSC camera on a VGA monitor. Strip down the video pipeline in the Terasic demonstration to the bare minimum to understand what modules are needed in the video pipeline, and to speculate how our algorithm could fit into this pipeline. Perform a major clean-up of the Terasic code, to make it readable. | Complete
3 | `new_pipeline`| Modify the pipeline from the previous experiment such that the SDRAM frame buffer holds RGB pixel data instead of YCbCr.| Complete
4 | `sram_controller`| Write a wrapper module to abstract the DE2 SRAM signals as a simple RAM block (i.e. write enable, data in, data out, address). Test in functional simulation to ensure the signals match the data sheet, and test in hardware using some random values and the LEDs to verify.| In progress
