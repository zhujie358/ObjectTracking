%% HEADER
% @file ObjectTracking_FP_v1.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 12th, 2015
% @brief First attempt at implementing the object tracking algorithm
% outlined in source [8] in high-level, floating point software

%% LOAD SAMPLE INPUT VIDEO
vidObj = VideoReader('Sample Input Video.mp4');

%% INITIALIZE CONSTANTS
numFrames = vidObj.NumberOfFrames;
numRows = vidObj.Height;
numCols = vidObj.Width;
R = .2126; %Red coefficient for colorimetric RGB-Grayscale conversion 
G = .7152; %Green coefficient for colorimetric RGB-Grayscale conversion 
B = .0722; %Blue coefficient for colorimetric RGB-Grayscale conversion 

%% HIGH-LEVEL ALGORITHM

GS_CURR = zeros(numRows, numCols);
GS_BASE = zeros(numRows, numCols);
deltaFrame = zeros(numRows, numCols);
THRESH = 120;

%Compute the base frame grayscale, all other frames will use this to look
%for motion
baseFrameRGB = read(vidObj, 1);
for j = 1 : numRows
    for k = 1 : numCols
        GS_BASE(j, k) = R*baseFrameRGB(j,k,1) + G*baseFrameRGB(j,k,2) + B*baseFrameRGB(j,k,3);
    end
end

%Iterate through the remaining frames looking for motion
for i = 2 : numFrames
    
    %Read current frame
    currFrameRGB = read(vidObj, i);
    
    %Raster scan through current frame
    for j = 1 : numRows
        for k = 1 : numCols
            %Convert RGB24 to Grayscale
            GS_CURR(j, k) = R*currFrameRGB(j,k,1) + G*currFrameRGB(j,k,2) + B*currFrameRGB(j,k,3);
        end
    end
    
    %Compute delta frame
    deltaFrame = abs(GS_CURR - GS_BASE);
    
    %Filter delta frame
    deltaFramePrime = deltaFrame(:,:) < THRESH;
    deltaFrame = deltaFrame - deltaFrame.*deltaFramePrime;
    
    imshow(deltaFrame/256);
    
    %Update filter
    %deltaFrame = deltaFrame(:);
    %THRESH = mean(deltaFrame(deltaFrame~=0));  %MEAN FILTER WITHOUT ZERO ELEMENTS
    %THRESH = median(deltaFrame(deltaFrame~=0)); %MEDIAN FILTER WITHOUT ZERO ELEMENTS
    %THRESH = median(deltaFrame); %MEDIAN FILTER 
    
end