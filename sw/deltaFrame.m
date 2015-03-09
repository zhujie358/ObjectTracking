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

function [delta] = deltaFrame(curr, base, select)

	%Compute delta frame
    	delta = abs(curr - base);
    
	 %Update filter
	if (strcmp(select, 'constant'))
		THRESH = 90;
	elseif (strcmp(select, 'mean'))
		THRESH = myMean(delta);
	elseif (strcmp(select, 'median'));
        	THRESH = myMedian(delta);
	else
		disp('You did not select a filter type, no filter applied.');
		THRESH = 0;
	end
    
    	%Filter by removing all elements that meet the condition below
    	deltaP = delta(:,:) < THRESH;
    	delta = delta - delta.*deltaP;
end
