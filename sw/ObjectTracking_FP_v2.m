%% HEADER
% @file ObjectTracking_FP_v2.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Second attempt at implementing the object tracking algorithm
% outlined in source [8] in high-level, floating point software

%% LOAD SAMPLE INPUT VIDEO
vidObj = VideoReader('sample_input_2.mp4');
vidObj2 = VideoWriter('./ECSE 456/ObjectTracking/sw/sample_output_2');
open(vidObj2);

%% INITIALIZE CONSTANTS
numFrames = vidObj.NumberOfFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;
THRESH = 90;

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
    
	%Replace the outline of the object with red pixels in the current frame
	modDeltaP = modDelta(:,:) ~= 0; 
	modDeltaP_3 = zeros(numRows,numCols,3);
	modDeltaP_3(:,:,1) = modDeltaP; 
	modDeltaP_3(:,:,2) = modDeltaP; 
	modDeltaP_3(:,:,3) = modDeltaP; 
	modCurrFrameRGB = currFrameRGB - currFrameRGB.*modDeltaP_3;
	modDeltaP_3(:,:,1) = modDeltaP_3(:,:,1) * 256;
	modDeltaP_3(:,:,2) = 0;
	modDeltaP_3(:,:,3) = 0;
	modCurrFrameRGB = modCurrFrameRGB + modDeltaP_3;
  
	%For output purposes
	modCurrFrameRGB = modCurrFrameRGB / 256;
	writeVideo(vidObj2, modCurrFrameRGB);
	
end

toc;

close(vidObj2);