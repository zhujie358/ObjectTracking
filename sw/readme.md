# Phase I: Software Development
### Overview
Phase I of the __ObjectTracking__ project is focused on software implementation of a Kalman filter based motion tracking algorithm. The algorithm will be used on static video files in order to prove out the algorithm for hardware implementation in the next phase. MATLAB was chosen for software development since it has easy to use VideoReader and VideoWriter classes for I/O as well as a matrix based data structure which meshes well with data representation of an image.

### Running the Software
The top-level M file is called `ObjectTracking_FI`. To use it, simply modify lines 10 and 11 of this file to set the input and output filepaths and then run it in MATLAB.

This is fixed-point software, written in order to make hardware implementation easier. There is also floating-point software on the `floating_point_stable` branch of repository, with a top-level M file called `ObjectTracking_FP_v3`.