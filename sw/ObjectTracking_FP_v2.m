%% HEADER
% @file ObjectTracking_FP_v2.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Second attempt at implementing the object tracking algorithm
% outlined in source [8] in high-level, floating point software

%% LOAD SAMPLE INPUT VIDEO
vidObj = VideoReader('sample_input_1.mp4');

%% INITIALIZE CONSTANTS
numFrames = vidObj.NumberOfFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;
THRESH = 120;

%% ALGORITHM
tic;
%Compute the base frame grayscale, all other frames will use this to look for motion
baseFrameRGB = read(vidObj, 1);
GS_BASE = RGB2GRAY(baseFrameRGB, 'efficient');

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
    
    %Read current frame
    currFrameRGB = read(vidObj, i);
    
	%Convert current frame
	GS_CURR = RGB2GRAY(currFrameRGB, 'efficient');
	
	%Compute and filter delta frame
	[delta, THRESH] = deltaFrame(GS_CURR, GS_BASE, THRESH, 'constant');
    
	%Perform edge detection on the delta frame to locate the object
	modDelta = findEdges(delta);
	
end
toc;