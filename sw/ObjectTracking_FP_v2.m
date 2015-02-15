%% HEADER
% @file ObjectTracking_FP_v2.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Second attempt at implementing the object tracking algorithm
% outlined in source [8] in high-level, floating point software

%% LOAD SAMPLE INPUT VIDEO
vidObj = VideoReader('sample_input_1.mp4');
vidObj2 = VideoWriter('./ECSE 456/ObjectTracking/sw/sample_output_1');
open(vidObj2);

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
GS_BASE = double(GS_BASE);

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
    
    %Read current frame
    currFrameRGB = read(vidObj, i);
    
	%Convert current frame
	GS_CURR = RGB2GRAY(currFrameRGB, 'efficient');
	GS_CURR = double(GS_CURR);
    
	%Compute and filter delta frame
	[delta, THRESH] = deltaFrame(GS_CURR, GS_BASE, THRESH, 'constant');
    
    %Locate edges of object (remove any pixels with non-zero neighbours)
    modDelta = findEdges(delta);
    
%     %TODO: Make this faster version using matrix math, remove for loops  
%     %This section replaces all the edge points of the object with red
%     modDeltaP = modDelta(:,:) ~= 0; %Array with 1's at border of object
%     %Create new array with 3 1's at every point 
%     
%     modCurrFrameRGB = zeros(numRows, numCols, 3);
%     for j = 1 : numRows
%         for k = 1 : numCols
%             if (modDelta ~= 0)
%                 modCurrFrameRGB(j,k,1) = 256;
%                 modCurrFrameRGB(j,k,2) = 0;
%                 modCurrFrameRGB(j,k,3) = 0;
%             else
%                 modCurrFrameRGB(j,k,:) = currFrameRGB(j,k,:);
%             end
%         end
%     end
%     
%     %For output purposes
%     modCurrFrameRGB = modCurrFrameRGB / 256;
%     writeVideo(vidObj2, modCurrFrameRGB);

    modDelta = modDelta / 256;
    writeVideo(vidObj2, modDelta);
	
end

toc;

close(vidObj2);