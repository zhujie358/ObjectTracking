%% HEADER
% @file RGB2GRAY.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to perform colorimetric RGB24 to grayscale conversion
% @param RGB_FRAME: An MxNx3 matrix of the frame to be converted
% @retval GS_FRAME_fi: Converted grayscale frame

function [GS_FRAME_fi]= RGB2GRAY(RGB_FRAME)
    %% INPUT FIXED-POINT INFO
    % RGB_FRAME --> F = 0

    %% COLOR FACTORS (FLOATING-POINT)
    R = .2126; %Red coefficient for colorimetric RGB-Grayscale conversion 
    G = .7152; %Green coefficient for colorimetric RGB-Grayscale conversion 
    B = .0722; %Blue coefficient for colorimetric RGB-Grayscale conversion 

    %% FIXED-POINT CONVERSION
    F_color = 6;

    %Convert all values to fixed point representation
    R_fi = floatToFix(R, F_color);
    R_frame_fi = floatToFix(RGB_FRAME(:,:,1), 0);
    G_fi = floatToFix(G, F_color);
    G_frame_fi = floatToFix(RGB_FRAME(:,:,2), 0);
    B_fi = floatToFix(B, F_color);
    B_frame_fi = floatToFix(RGB_FRAME(:,:,3), 0);

    %% GRAYSCALE CONVERSION
    %Perform fixed point multiplication
    RR_frame = fixedMult(R_fi, F_color, R_frame_fi, 0); %F = F_color
    GG_frame = fixedMult(G_fi, F_color, G_frame_fi, 0); %F = F_color
    BB_frame = fixedMult(B_fi, F_color, B_frame_fi, 0); %F = F_color

    %Apply the RGB to Grayscale formula, no need to normalize since F same
    GS_FRAME_fi = RR_frame + GG_frame + BB_frame; %F = F_color
    
    %% NORMALIZE
    GS_FRAME_fi = floatToFix(GS_FRAME_fi, -F_color); %Normalize to F = 0

end