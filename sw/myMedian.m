%% HEADER
% @file myMedian.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 28th, 2015
% @brief Function to compute the median value of the current delta frame
% @param frame: MxN current delta frame
% @retval delta: Median of the current delta frame

function [median]= myMedian(frame)

[m,n] = size(frame);
isOrdered = false;
howMany = 0;

while (!isOrdered)
	for i = 1 : m
		for j = 1 : n
			if (j ~= n)
				if (frame(i,j) < frame(i,j+1))
					temp = frame(i,j);
					frame(i,j) = frame(i,j+1);
					frame(i,j+1) = temp;
					howMany = howMany + 1;
				end
			elseif (j == n && i~= m)
				if (frame(i,j) < frame(i+1, 1))
					temp = frame(i,j);
					frame(i,j) = frame(i+1,1);
					frame(i+1,1) = temp;
					howMany = howMany + 1;
				end
			else
				%This last case is if j == n && i == m in which case do nothing because it's the last pixel
			end	
		end
	end
	if (howMany == 0)
		isOrdered = true;
	else
		howMany = 0;
	end
end

end