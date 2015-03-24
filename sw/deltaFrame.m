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

function [delta_fi, NEW_THRESH_fi] = deltaFrame(curr_fi, base_fi, INIT_THRESH_fi)

    global frac;

	%Compute delta frame, F = 0
    delta_fi = abs(curr_fi - base_fi);
    
    %Filter by removing all elements that meet the condition below (F = 0)
    deltaP = delta_fi(:,:) < INIT_THRESH_fi; 
    deltaX = delta_fi(:,:) >= INIT_THRESH_fi; 
    delta_fi = delta_fi - delta_fi.*deltaP; 
    back_fi = delta_fi - delta_fi.*deltaX;
    %The average function spits out a fixed point result with F = 2*frac
    delta_avg_fi = myMean(delta_fi);
    back_avg_fi = myMean(back_fi);

    %Update threshold in fixed point
    oneHalf_fi = floatToFix(.5, 1); %F = 1
    result_fi_1 = delta_avg_fi * oneHalf_fi; %F = 2*frac + 1
    result_fi_2 = back_avg_fi * oneHalf_fi; %F = 2*frac + 1
    NEW_THRESH_fi = result_fi_1 + result_fi_2; %F = 2*frac + 1
    %Now lets get the threshold back into F =0 to match iteration in main
    %script. Chop extra bits for precision that aren't needed
    %In VHDL this is done by only taking bits left of 2*frac
    NEW_THRESH_fi = NEW_THRESH_fi * 2^(-(2*frac+1));
    NEW_THRESH_fi = dec2bin(NEW_THRESH_fi);
    NEW_THRESH_fi = bin2dec(NEW_THRESH_fi);
    %Now F = 0
end
