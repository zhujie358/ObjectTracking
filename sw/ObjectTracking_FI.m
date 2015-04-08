%% HEADER
% @file ObjectTracking_FI.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 25th, 2015
% @brief Fixed-point software that performs object tracking 
% using delta frame generation and a Kalman filter. 

%% INPUT-OUTPUT VIDEO OBJECTS
vidObj = VideoReader('sample_input_1.mp4');
vidObj2 = VideoWriter('./ECSE 456/ObjectTracking/sw/sample_output_1');
open(vidObj2);

%% FIXED-POINT ARCHITECTURE
global divisorF;
global archW;
archW = 31;
divisorF = 20;

%% INITIALIZE VIDEO CONSTANTS (FLOATING-POINT)
numFrames = vidObj.NumberOfFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;
duration = vidObj.Duration;

%% CONVERT VIDEO CONSTANTS TO FIXED-POINT
numFramesInv_fi = floatToFix((1/numFrames), 9); %F = 9
duration_fi = floatToFix(duration, 3); %F = 3

%% INITIALIZE KALMAN VARIABLES IN FIXED-POINT
t_step_fi = fixedMult(duration_fi, 3, numFramesInv_fi, 9); %F = 12
t_step_fi = floatToFix(t_step_fi, -6); %Normalize to F = 6

%% INITIALIZE FILTER VARIABLE
THRESH_fi = floatToFix(90, 0); %F = 0

%% ALGORITHM
tic;

%Compute the base frame grayscale, all other frames will use this to look for motion
baseFrameRGB = read(vidObj, 1); %8-bit integers (0-255)
baseFrameRGB = int16(baseFrameRGB); %Extend to 16-bit integers (0-65535)
GS_BASE_fi = RGB2GRAY(baseFrameRGB); %F = 0

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
    
    disp(i);
    
    %Read and convert current frame
    currFrameRGB = read(vidObj, i); %8-bit integers (0-255)
    currFrameRGB = int16(currFrameRGB); %Extend to 16-bit integers (0-65535)
	GS_CURR_fi = RGB2GRAY(currFrameRGB); %F = 0
    
	%Compute and filter delta frame
	delta_fi = deltaFrame(GS_CURR_fi, GS_BASE_fi, THRESH_fi); %F = 0
    
    %Use edge detection to apply a median filter and reduce noise
    %filteredDelta_fi = medianFilter(delta_fi, THRESH_fi); %F = 0
    filteredDelta_fi = medfilt2(delta_fi);
    
    %Based on the delta frame, detemine its (x,y) position
    z_fi = measure(filteredDelta_fi); %F = 0
      
    %Perform a Kalman filter iteration based on this measurement
    x_fi = applyKalman(z_fi, t_step_fi, i); %F = 0
    
    %NO FLOATING-POINT OPERATIONS AFTER THIS POINT
    
    %Draw a red box dot at the post-Kalman filtered position
    x = fix(x_fi(1));
    y = fix(x_fi(2));
    if (x <= 0)
        x = 1;
    elseif (x > numCols)
        x = numCols;
    end
    if (y <= 0)
        y = 1;
    elseif (y > numRows)
        y = numRows;
    end
    currFrameRGB(y, x, :) = [256,0,0];
    
    %Draw a red box around that position (space permitting)
    bottomClear = false;
    topClear = false;
    if (y+1 <= numRows)
        currFrameRGB(y+1, x, :) = [256,0,0];
        bottomClear = true;
    end
    if(y-1 > 0)
        currFrameRGB(y-1, x, :) = [256,0,0];
        topClear = true;
    end
    if (x+1 <= numCols)
        currFrameRGB(y, x+1, :) = [256,0,0];
        if (topClear)
            currFrameRGB(y-1, x+1, :) = [256,0,0];
        end
        if (bottomClear)
            currFrameRGB(y+1, x+1, :) = [256,0,0];
        end
    end
    if (x-1 > 0)
        currFrameRGB(y, x-1, :) = [256,0,0];
        if (topClear)
            currFrameRGB(y-1, x-1, :) = [256,0,0];
        end
        if (bottomClear)
            currFrameRGB(y+1, x-1, :) = [256,0,0];
        end
    end
    
	%IGNORE FOR FIXED-POINT CONVERSION, THIS IS JUST FOR MATLAB
	currFrameRGB = double(currFrameRGB) / 256;
	writeVideo(vidObj2, currFrameRGB);
end

toc;

close(vidObj2);