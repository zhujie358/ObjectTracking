# Implementing the Kalman Filter Equations in Hardware
### Overview
The goal of this experiment is to implement the `sw/applyKalman.m` software in hardware. This software essentially just applys the Kalman filter equations outlined in `doc/kalman_notes.pdf` to the measured position in order to produce an improved position. The challenges with this implementation are:

1. Only some equations can be done in parallel, some must be done in series. This means this pipeline module will have more than 1 clock cycle overhead.
2. Matrix math requires tons of calculations when you actually expand the equations.
3. The module must be implemented using fixed-point math.

### Hardware Used
1.  Altera DE2 board
2.  VGA cable
3.  Acer LED monitor with a VGA port
4.  Mini CCD Digital Camera (outputs NTSC video on an RCA cable)


### Results

