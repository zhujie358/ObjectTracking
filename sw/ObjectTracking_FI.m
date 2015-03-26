%% HEADER
% @file ObjectTracking_FI.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 25th, 2015
% @brief Fixed-point software that performs object tracking 
% using delta frame generation and a Kalman filter. 

%16-BIT ARCHITECTURE: W = 16 FOR ALL NUMBERS UNLESS STATED OTHERWISE

%% INPUT-OUTPUT VIDEO OBJECTS
vidObj = VideoReader('sample_input_1.mp4');
vidObj2 = VideoWriter('./ECSE 456/ObjectTracking/sw/sample_output_1');
open(vidObj2);

%% INITIALIZE VIDEO CONSTANTS
numFrames = vidObj.NumberOfFrames;
numFramesInv = 1 / numFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;
duration = vidObj.Duration;

% CONVERT VIDEO CONSTANTS TO FI
numFrames_fi = floatToFix(numFrames, 0); %F = 0
numFramesInv_fi = floatToFix(numFramesInv, 14); %F = 14
numRows_fi = floatToFix(numRows, 0); %F = 0
numCols_fi = floatToFix(numCols, 0); %F = 0
duration_fi = floatToFix(duration, 3); %F = 3

%% INITIALIZE KALMAN VARIABLES IN FI
oneHalf_fi = floatToFix(.5, 2); %F = 2
middle_fi = numCols_fi * oneHalf_fi; %F = 2
x_old_fi = [middle_fi, 0, 0, 0]'; %W = 32, F = 2
P_old_fi = floatToFix(eye(4), 0); %F = 0
t_step_fi = duration_fi * numFramesInv_fi; 

%% INITIALIZE FILTER VARIABLE
THRESH_fi = 90; %F = 0

%% ALGORITHM
tic;

%Compute the base frame grayscale, all other frames will use this to look for motion
baseFrameRGB = read(vidObj, 1);
baseFrameRGB = double(baseFrameRGB);
GS_BASE_fi = RGB2GRAY(baseFrameRGB); %F = 0

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
       
    %Read and convert current frame
    currFrameRGB = read(vidObj, i);
    currFrameRGB = double(currFrameRGB);
	GS_CURR_fi = RGB2GRAY(currFrameRGB); %F = 0
    
	%Compute and filter delta frame
	[delta_fi, THRESH_fi] = deltaFrame(GS_CURR_fi, GS_BASE_fi, THRESH_fi);
    
    %Use edge detection to apply a median filter and reduce noise
    filteredDelta_fi = medianFilter(delta_fi, THRESH_fi);
    
    %Based on the delta frame, detemine its (x,y) position
    z_fi = measure(filteredDelta_fi);
      
    %Perform a Kalman filter iteration based on this measurement
    [x_new, P_new] = applyKalman(z_fi, x_old_fi, P_old_fi, t_step_fi);
    
    %Save for next iteration
    P_old_fi = P_new;
    x_old_fi = x_new;
    
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