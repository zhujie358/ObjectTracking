%% HEADER
% @file ObjectTracking_FP_v3.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 20th, 2015
% @brief Floating point software attempt number 3. This version uses the
% Detla Frame generation from v2 with Kalman filtering for predictions.

%% LOAD SAMPLE INPUT VIDEO
vidObj = VideoReader('sample_input_2.mp4');
vidObj2 = VideoWriter('./ECSE 456/ObjectTracking/sw/sample_output_2');
open(vidObj2);

%% INITIALIZE VIDEO CONSTANTS
numFrames = vidObj.NumberOfFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;
THRESH = 90;

%% INITIALIZE KALMAN VARIABLES
x_old = zeros(4,1);
P_old = eye(4);
t_step = vidObj.Duration / numFrames;

%% ALGORITHM
tic;

%Compute the base frame grayscale, all other frames will use this to look for motion
baseFrameRGB = read(vidObj, 1);
GS_BASE = RGB2GRAY(baseFrameRGB, 'efficient');
GS_BASE = double(GS_BASE);

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
    
    %Read current frame
    currFrameRGB = read(vidObj, i);
    currFrameRGB = double(currFrameRGB);
    
	%Convert current frame
	GS_CURR = RGB2GRAY(currFrameRGB, 'efficient');
	GS_CURR = double(GS_CURR);
    
	%Compute and filter delta frame
	[delta, THRESH] = deltaFrame(GS_CURR, GS_BASE, THRESH, 'constant');
    
    %Locate edges of object (remove any pixels with non-zero neighbours)
    modDelta = findEdges(delta);
    
    %Based on the edges of the object, detemine its (x,y) position
    z = measure(modDelta);
  
    %Perform a Kalman filter iteration based on this measurement
    [x_new, P_new] = applyKalman(z, x_old, P_old, t_step);
    
    %Save for next iteration
    P_old = P_new;
    x_old = x_new;
    
    %Using x_new = [x, y, v_x, v_y]' track the object
    %TODO: Draw crosshairs, or a box around the point (x,y). Have an MxN
    %matrix with all zeros except for the points where the box are and call
    %the matrix "object" for the below code to work
    
    %Replace existing pixels with the shape used to track it (in red)
	objectP = object(:,:) ~= 0; 
	objectP_3 = zeros(numRows,numCols,3);
	objectP_3(:,:,1) = objectP; 
	objectP_3(:,:,2) = objectP; 
	objectP_3(:,:,3) = objectP; 
	modCurrFrameRGB = currFrameRGB - currFrameRGB.*objectP_3;
	objectP_3(:,:,1) = objectP_3(:,:,1) * 256;
	objectP_3(:,:,2) = 0;
	objectP_3(:,:,3) = 0;
	modCurrFrameRGB = modCurrFrameRGB + objectP_3;
  
	%For output purposes
	modCurrFrameRGB = modCurrFrameRGB / 256;
	writeVideo(vidObj2, modCurrFrameRGB);
    
	
end

toc;

close(vidObj2);