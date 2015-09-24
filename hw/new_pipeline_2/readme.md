# Modifying the Video I/O Pipeline: Part 2
### Overview
A good starting point for algorithm implementation will be displaying the delta frame on the VGA display. The delta frame is simply the difference of a "base frame" and the current frame captured by the camera. If the proper assumptions are made about the base frame, it should display only the motion. The SRAM will be used to capture, and continually read out the base frame, and the RGB to grayscale allows each pixel to be represented as one number, making subtraction possible.

### Hardware Used

1.  Altera DE2 board
2.  VGA cable
3.  Acer LED monitor with a VGA port
4.  Mini CCD Digital Camera (outputs NTSC video on an RCA cable)
