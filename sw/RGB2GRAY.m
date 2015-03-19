%% HEADER
% @file RGB2GRAY.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to perform colorimetric RGB24 to grayscale conversion
% @param RGB_FRAME: An MxNx3 matrix of the frame to be converted
% @retval GS_FRAME: Converted grayscale frame

function [GS_FRAME]= RGB2GRAY(RGB_FRAME)

RGB_FRAME = double(RGB_FRAME);

%% INITIALIZE
R = .2126; %Red coefficient for colorimetric RGB-Grayscale conversion 
G = .7152; %Green coefficient for colorimetric RGB-Grayscale conversion 
B = .0722; %Blue coefficient for colorimetric RGB-Grayscale conversion 

%% FIXED-POINT CONVERSION
global frac;

%Convert all values to fixed point representation, F = frac
R_fi = floatToFix(R, frac);
R_frame_fi = floatToFix(RGB_FRAME(:,:,1), frac);
G_fi = floatToFix(G, frac);
G_frame_fi = floatToFix(RGB_FRAME(:,:,2), frac);
B_fi = floatToFix(B, frac);
B_frame_fi = floatToFix(RGB_FRAME(:,:,3), frac);

%Perform fixed point multiplication, F = 2*frac 
RR_frame = R_fi * R_frame_fi;
GG_frame = G_fi * G_frame_fi;
BB_frame = B_fi * B_frame_fi;

%Apply the RGB to Grayscale formula, F = 2*frac
GS_FRAME = RR_frame + GG_frame + BB_frame;

end