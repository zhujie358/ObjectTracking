%% HEADER
% @file deltaFrame.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to compute and filter the delta fame.
% @param curr_fi: MxN current frame
% @param base_fi: MxN base frame
% @param INIT_THRESH_fi: Threshold from previous iteration
% @retval NEW_THRESH_fi: Threshold from current iteration
% @retval delta_fi: MxN delta frame

function [delta_fi, NEW_THRESH_fi] = deltaFrame(curr_fi, base_fi, INIT_THRESH_fi)
    %% INPUT FIXED-POINT INFO
    % curr_fi --> F = 0
    % base_fi --> F = 0
    % INIT_THRESH_fi --> F = 0
    
	%% COMPUTE DELTA FRAME
    delta_fi = abs(curr_fi - base_fi); %F = 0
    
    %% MEAN-FILTER DELTA FRAME
    deltaP = delta_fi(:,:) < INIT_THRESH_fi; %F = 0
    deltaP = uint16(deltaP); %Covert boolean to uint16 for MATLAB
    deltaX = delta_fi(:,:) >= INIT_THRESH_fi; %F = 0
    deltaX = uint16(deltaX); %Covert boolean to uint16 for MATLAB
    delta_fi = delta_fi - delta_fi.*deltaP; %F = 0
    back_fi = delta_fi - delta_fi.*deltaX; %F = 0
    delta_avg_fi = myMean(delta_fi); %F = 14
    back_avg_fi = myMean(back_fi); %F = 14

    %% UPDATE THRESHOLD IN FIXED-POINT
    oneHalf_fi = floatToFix(.5, 1); %F = 1
    [result_fi_1, F] = fixedMult(delta_avg_fi, 14, oneHalf_fi, 1); %F = 15
    [result_fi_2, ~] = fixedMult(back_avg_fi, 14, oneHalf_fi, 1); %F = 15
    %Now add two results, no need to normalize since same F
    NEW_THRESH_fi = result_fi_1 + result_fi_2; %F = 15

    %% NORMALIZE
    NEW_THRESH_fi = floatToFix(NEW_THRESH_fi, -F); %Normalize to F = 0

end
