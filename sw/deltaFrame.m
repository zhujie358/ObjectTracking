%% HEADER
% @file deltaFrame.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to compute and filter the delta fame
% @param curr: MxN current frame
% @param base: MxN base frame
% @param select: String for filter type to use (constant, mean, median1, median2)
% @retval delta: MxN delta frame

function [delta, NEW_THRESH] = deltaFrame(curr, base, INIT_THRESH)

	%Compute delta frame
    delta = abs(curr - base);
    
    %Filter by removing all elements that meet the condition below
    deltaP = delta(:,:) < INIT_THRESH;
    deltaX = delta(:,:) >= INIT_THRESH;
    delta = delta - delta.*deltaP;
    back = delta - delta.*deltaX;
    delta_avg = myMean(delta);
    back_avg = myMean(back);

    %Update threshold
    NEW_THRESH = (delta_avg + back_avg)/2;
end
