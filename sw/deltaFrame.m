%% HEADER
% @file deltaFrame.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to compute and filter the delta fame.
% @param curr_fi: MxN current frame
% @param base_fi: MxN base frame
% @param THRESH_fi: Threshold for filtering
% @retval delta_fi: MxN delta frame

function [delta_fi] = deltaFrame(curr_fi, base_fi, THRESH_fi)
    %% INPUT FIXED-POINT INFO
    % curr_fi --> F = 0
    % base_fi --> F = 0
    % THRESH_fi --> F = 0
    
	%% COMPUTE DELTA FRAME
    delta_fi = abs(curr_fi - base_fi); %F = 0
    
    %% THRESHOLD FILTER DELTA FRAME
    deltaP = delta_fi(:,:) < THRESH_fi; %F = 0
    deltaP = int16(deltaP); %Covert boolean to uint16 for MATLAB
    delta_fi = delta_fi - delta_fi.*deltaP; %F = 0
end
