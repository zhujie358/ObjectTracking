%% HEADER
% @file findEdges.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to perform edge detection on the object of interest
% @param delta: MxN frame consisting of only the object (rest is 0 values)
% @retval modDelta: MxN frame consisting only of border pixels of said object (rest is 0 values)

function [modDelta]= findEdges(delta)

%Result matrix
[m,n] = size(delta);
modDelta = delta;

%Number of neighbouring points that must be non-zero to be considered an non edge point
CORNER_THRESH = 2;
BORDER_THRESH = 4;
POINTS_THRESH = 5;

%Iterate through all points
for i = 1 : m
	for j = 1 : n
	
		%Identify an object point
		if (delta(i,j) ~= 0)
		
			%Point ID values
			info_score = 0;
			score = 0;
			flag = 0;
			
			%Determine type of point (border, corner, regular)
			if (i == 1 || i == m)
				info_score = info_score + 1;
				flag = 1;
			end
			if (j == 1 || j == n)
				info_score = info_score + 1;
				flag = 2;
			end
		
			%Depending on the type of point, the neighbourhood will change
			if (info_score == 1) 
				THRESH = BORDER_THRESH;
				
				%Top/bottom border case
				if (flag == 1)
				
					%Flip signs if it's the bottom
					p = 1;
					q = 1;
					if (i == m)
						p = -1;
						q = -1;
					end
					
					%Check the neighbouring 5 points 
					if (delta(i,j+q) ~= 0)
						score = score + 1;
					end
					if (delta(i+p,j+q) ~= 0)
						score = score + 1;
					end
					if (delta(i+p,j) ~= 0)
						score = score + 1;
					end
					if (delta(i+p,j-q) ~= 0)
						score = score + 1;
					end				
					if (delta(i,j-q) ~= 0)
						score = score + 1;
					end	
				
				%Left/right border case
				elseif(flag == 2)
				
					%Flip signs if it's the right
					p = 1;
					q = 1;
					if (j == n)
						p = -1;
						q = -1;
					end
					
					%Check the neighbouring 5 points 
					if (delta(i-p,j) ~= 0)
					score = score + 1;
					end
					if (delta(i-p,j+q) ~= 0)
						score = score + 1;
					end
					if (delta(i,j+q) ~= 0)
						score = score + 1;
					end
					if (delta(i+p,j+q) ~= 0)
						score = score + 1;
					end				
					if (delta(i+p,j) ~= 0)
						score = score + 1;
					end	
				
				end			
				
			elseif (info_score == 2) 
				THRESH = CORNER_THRESH;
				
				%Sign change for various corners
				p = -1;
				q = -1;
				if (i == 1)
					p = 1;
				end
				if (j == 1)
					q = 1;
				end
				
				%Check the neighbouring 3 points
				if (delta(i+p,j) ~= 0)
					score = score + 1;
				end
				if (delta(i,j+q) ~= 0)
					score = score + 1;
				end
				if (delta(i+p,j+q) ~= 0)
					score = score + 1;
				end
				
			else 
				THRESH = POINTS_THRESH;
				
				%Check the neighbouring 8 points 
				if (delta(i-1,j) ~= 0)
					score = score + 1;
				end
				if (delta(i,j-1) ~= 0)
					score = score + 1;
				end
				if (delta(i+1,j) ~= 0)
					score = score + 1;
				end
				if (delta(i,j+1) ~= 0)
					score = score + 1;
				end
				if (delta(i-1,j-1) ~= 0)
					score = score + 1;
				end				
				if (delta(i+1,j-1) ~= 0)
					score = score + 1;
				end					
				if (delta(i-1,j+1) ~= 0)
					score = score + 1;
				end
				if (delta(i+1,j+1) ~= 0)
					score = score + 1;
				end
				
			end
			
			%Remove the object point if is surrounded by other object points
			if (score > THRESH)
				modDelta(i,j) = 0;
			end
			
		end
		
	end
end
	
end
