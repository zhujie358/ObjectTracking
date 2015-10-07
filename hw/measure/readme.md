# Using the Delta Frame to Produce Object Coordinates
### Overview
The point of the delta frame is generate a position for the object in the frame. The goal of this experiment to develop two Verilog modules:
1. measure.v : Takes in the delta frame and generates an (x,y) coordinate marking the center of the object in the frame.
2. draw_pt.v : Takes in the pixels prior to the VGA controller and changes the color to red if it matches an (x,y) input.

These modules will be verified in hardware, and simulation if necessary.

### Hardware Used
1.  Altera DE2 board
2.  VGA cable
3.  Acer LED monitor with a VGA port
4.  Mini CCD Digital Camera (outputs NTSC video on an RCA cable)


