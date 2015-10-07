# Phase II: Hardware Development
## Overview
Phase II of the __ObjectTracking__ project is focused on hardware implementation of the motion based object tracking algorithm developed in the `sw/` directory. As discussed in the Phase I documentation, the hardware platform chosen is the Altera DE2 board made by Terasic. The hardware targeted on this board is the Cyclone IV FPGA, on-board memory, and video peripherals.

## Directory Structure
Each folder in this directory represents an experiment using the hardware, which builds on the ones before it. Each directory is a Quartus II project folder, meaning the experiments can be recreated locally with just the files in the Git repository and the necessary hardware specified within each experiment. 

## Experiments
Order | Name | Goal | Status
----- | ---- | ---- | ------
1 | `vga_demo`    | Write a Verilog module to produce a sample VGA output using the ADV7123. Learn about the VGA interface. | Complete
2 | `vid_io_demo` | Use the Terasic TV Decoder demonstration to show live video from a NTSC camera on a VGA monitor. Strip down the video pipeline in the Terasic demonstration to the bare minimum to understand what modules are needed in the video pipeline, and to speculate how our algorithm could fit into this pipeline. Perform a major clean-up of the Terasic code, to make it readable. | Complete
3 | `new_pipeline`| Modify the pipeline from the previous experiment such that the SDRAM frame buffer holds RGB pixel data instead of YCbCr.| Complete
4 | `sram_controller`| Write a wrapper module to abstract the DE2 SRAM signals as a simple RAM block (i.e. write enable, data in, data out, address). Test in functional simulation to ensure the signals match the data sheet, and test in hardware using some random values and the LEDs to verify.| Complete
5 | `rgb_to_grayscale`| Write a Verilog module that implements the RGB to grayscale equation from software. Scale the colour coefficients to their fixed point values. Test in functional simulation to ensure equation works properly.| Complete
6 | `new_pipeline_2` | Integrate the SRAM controller and the RGB to grayscale modules into the video pipeline. The goal is to latch a specific frame using a button on the DE2, and store that frame in the SRAM. Then, the RGB to grayscale module will be used to produce the delta frame on the VGA display. | Complete
7 | `measure` | Convert `../sw/measure.m`, or a similar algorithm that produces a (x,y) coordinate from the delta frame, to hardware. This can be verified in hardware by also writing a Verilog module to color the (x,y) and the surrounding area red. | In progress

## Creating a New Experiment
A new experiment (that works with the Makefile flow) can be created by following these steps:

1. Create a new folder with the name of your experiment (no spaces).
2. Open the "Terasic DE2-115 System Builder" program (can be downloaded from the Terasic website), type the experiment name into the "Project Name" text box, choose the peripherals needed for the experiment, and press "Generate".
3. Navigate through the "CodeGenerated" directory produced by the program and find your experiment. Copy the QSF, Verilog, and SDC files into the folder created in step 1. If you'd like to work with Quartus in GUI mode, copy the QPF file as well.
4. If you plan on doing functional simulations in this experiment, you will need to create a `sim/` directory with a Verilog module called `testbench.v` and a DO file called `signals.do`. The `sram_controller` experiment has these files already and you can copy them to act as a starting point for your experiment.
5. Open the QSF file and navigate to the bottom. Here you will add any Verilog files your experiment needs, and the SDC file (you don't need to add the top-level Verilog file just created, it is inferred by Quartus). See QSF files from other experiments for example syntax.
6. Symbolically link, or copy the Makefile from the `common/` directory into your new experiment. A symbolic link can be created on Windows by running cmd as an administrator and using `mklink Makefile ..\common\Makefile`.
7. Set the variable `EXP_NAME` in the Makefile to the name of your new experiment.

## Using the Makefile Flow
To use the Makefile flow and recreate the results from any of the experiments, start by repeating steps 6 and 7 from the process above for the experiment of interest.

In the experiment directory, type `make` into your shell to see the list of options.

### Hardware
All Makefile options starting with `hw_` are hardware targets. `hw_all` will perform the entire FPGA sequence, starting with source file compilation, place and route, bistream generation, and finally device programming. When running `hw_all` or `hw_prog`, make sure the DE2 is plugged in.

Quartus II is required for Makefile hardware targets. Specifically, Version 10.1 Web Edition is being used for development.

### Simulation 
The Makefile option `simulate` performs all the Modelsim steps needed for a functional simulation. If an experiment had a simulation, there will be `sim/` directory in the experiment folder. This directory contains two files (minimum):

1. A SystemVerilog testbench used to stimulate the Verilog modules of interest.
2. A DO file containing the list of waveforms that will be displayed in Modelsim.

To recreate the simulation, you need to modify the Makefile to have all the Verilog modules being stimulated in the `vlog` line (there is a comment in the Makefile to flag this). This allows Modelsim to compile the files you want to sim. Simply append the location of the Verilog files to the end of this line (after the testbench).

Modelsim is required for the Makefile simulation target. Specifically, Modelsim-Altera Starter is being used for development.

### Cleaning
To blast away all transients after running hardware or simulation targets, use the Makefile option `clean`. This is useful before checking files in on Git, and is required if you want to run a Makefile target multiple times in a row.

