%% HEADER
% @file deltaFrame.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to compute and filter the delta fame
% @param curr: MxN current frame
% @param base: MxN base frame
% @param THRESH: Floating point threshold for filtering
% @param select: String for filter type to use (constant, mean, median1, median2)
% @retval delta: MxN delta frame

function [delta, NEW_THRESH]= deltaFrame(curr, base, THRESH, select)

	%Compute delta frame
    delta = abs(curr - base);
    
    %Filter delta frame
    deltaP = delta(:,:) < THRESH;
    delta = delta - delta.*deltaP;
    
    %Update filter
    deltaVec = delta(:);
	if (select == 'constant')
		NEW_THRESH = THRESH;
	elseif (select == 'mean')
		NEW_THRESH = mean(deltaVec(deltaVec~=0));  %MEAN FILTER WITHOUT ZERO ELEMENTS
	elseif (select == 'median1')
		NEW_THRESH = median(deltaVec(deltaVec~=0)); %MEDIAN FILTER WITHOUT ZERO ELEMENTS
    elseif (select == 'median2')
		NEW_THRESH = median(deltaVec); %MEDIAN FILTER 
	else
		disp('You did not select a filter type, no filter applied.')
		NEW_THRESH = 0;
	end
end