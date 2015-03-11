%% HEADER
% @file ObjectTracking_FP_v3.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 20th, 2015
% @brief Floating point software attempt number 3. This version uses the
% Delta Frame generation from v2 with Kalman filtering for predictions.

%% INPUT-OUTPUT VIDEO OBJECTS
vidObj = VideoReader('sample_input_1.mp4');
vidObj2 = VideoWriter('./ECSE 456/ObjectTracking/sw/sample_output_1');
open(vidObj2);

%% INITIALIZE VIDEO CONSTANTS
numFrames = vidObj.NumberOfFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;

%% INITIALIZE KALMAN VARIABLES
x_old = [numCols/2, 0, 0, 0]';
P_old = eye(4);
t_step = vidObj.Duration / numFrames;

%% INITIALIZE FILTER VARIABLE
THRESH = 90;

%% ALGORITHM
tic;

%Compute the base frame grayscale, all other frames will use this to look for motion
baseFrameRGB = read(vidObj, 1);
GS_BASE = RGB2GRAY(baseFrameRGB);

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
       
    %Read current frame
    currFrameRGB = read(vidObj, i);
    currFrameRGB = double(currFrameRGB);
    
	%Convert current frame
	GS_CURR = RGB2GRAY(currFrameRGB);
    
	%Compute and filter delta frame
	[delta, THRESH] = deltaFrame(GS_CURR, GS_BASE, THRESH);
    
    %Use edge detection to apply a median filter and reduce noise
    filteredDelta = medianFilter(delta, THRESH);
    
    %Based on the delta frame, detemine its (x,y) position
    z = measure(filteredDelta);
  
    %Perform a Kalman filter iteration based on this measurement
    [x_new, P_new] = applyKalman(z, x_old, P_old, t_step);
    
    %Save for next iteration
    P_old = P_new;
    x_old = x_new;
    
    %Draw a red box dot at the post-Kalman filtered position
    x = fix(x_new(1));
    y = fix(x_new(2));
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
    
	%For output purposes
	currFrameRGB = currFrameRGB / 256;
	writeVideo(vidObj2, currFrameRGB);
end

toc;

close(vidObj2);