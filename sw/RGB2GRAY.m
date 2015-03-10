%% HEADER
% @file RGB2GRAY.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to perform colorimetric RGB24 to grayscale conversion
% @param RGB_FRAME: An MxNx3 matrix of the frame to be converted
% @retval GS_FRAME: Converted grayscale frame

function [GS_FRAME]= RGB2GRAY(RGB_FRAME)

%% INITIALIZE
R = .2126; %Red coefficient for colorimetric RGB-Grayscale conversion 
G = .7152; %Green coefficient for colorimetric RGB-Grayscale conversion 
B = .0722; %Blue coefficient for colorimetric RGB-Grayscale conversion 

%% CONVERSION
GS_FRAME = R*RGB_FRAME(:,:,1) + G*RGB_FRAME(:,:,2) + B*RGB_FRAME(:,:,3);
GS_FRAME = double(GS_FRAME);
GS_FRAME = fix(GS_FRAME);

end