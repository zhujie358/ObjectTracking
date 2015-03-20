%% HEADER
% @file ObjectTracking_FP_v3.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 20th, 2015
% @brief Floating point software attempt number 3. This version uses the
% Delta Frame generation from v2 with Kalman filtering for predictions.

%% FIXED-POINT FORMAT SPECIFICATIONS
global frac
global word;
frac = 10; %Trial and error for best results
word = 10; %Max value of script is 1000

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

%Convert to fixed point, F = frac for all
numFrames_fi = floatToFix(numFrames, frac);
numFramesInv_fi = floatToFix(numFramesInv, frac);
numRows_fi = floatToFix(numRows, frac);
numCols_fi = floatToFix(numCols, frac);
duration_fi = floatToFix(duration, frac);

%% INITIALIZE KALMAN VARIABLES
middle_fi = numCols_fi * floatToFix(.5, frac); %F = 2*frac
x_old_fi = [middle_fi, 0, 0, 0]'; %F = 2*frac
P_old_fi = floatToFix(eye(4), frac); %F = frac
t_step_fi = duration_fi * numFramesInv_fi; %F = 2*frac

%% INITIALIZE FILTER VARIABLE
THRESH_fi = 90; %F = 0

%% ALGORITHM
tic;

%Compute the base frame grayscale, all other frames will use this to look for motion
baseFrameRGB = read(vidObj, 1);
GS_BASE_fi = RGB2GRAY(baseFrameRGB); %F = 0

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
       
    %Read and convert current frame
    currFrameRGB = read(vidObj, i);
	GS_CURR_fi = RGB2GRAY(currFrameRGB); %F = 0
    
	%Compute and filter delta frame
	[delta_fi, THRESH_fi] = deltaFrame(GS_CURR_fi, GS_BASE_fi, THRESH_fi);
    
    %UP TO HERE IN FIXED-POINT CONVERSION
    
    %Use edge detection to apply a median filter and reduce noise
    filteredDelta = medianFilter(delta_fi, THRESH);
    
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