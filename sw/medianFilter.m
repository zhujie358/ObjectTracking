%% HEADER
% @file medianFilter.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 10th, 2015
% @brief Function to filter delta frame based on median of neighbors
% @param delta: MxN delta frame
% @param THRESH: Threshold for filtering
% @retval modDelta: MxN filtered delta frame

function [modDelta]= medianFilter(delta, THRESH)

%Result matrix
[m,n] = size(delta);
modDelta = delta;

%Iterate through all points
for i = 1 : m
	for j = 1 : n
	
		%Identify an object point
		if (delta(i,j) ~= 0)
		
			%Point ID values
			info_score = 0;
			flag = 0;
			
			%Determine type of point (border, corner, regular)
			if (i == 1 || i == m || i == 2 || i == m-1)
				info_score = info_score + 1;
				flag = 1;
			end
			if (j == 1 || j == n || j == 2 || j == n-1)
				info_score = info_score + 1;
				flag = 2;
			end
		
			%Depending on the type of point, the neighbourhood will change
			if (info_score == 1) 
				
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
                    neighborhood = [delta(i,j+q);
					delta(i+p,j+q);
					delta(i+p,j);
					delta(i+p,j-q);
					delta(i,j-q)];
				
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
					neighborhood = [delta(i-p,j);
					delta(i-p,j+q);
					delta(i,j+q);
					delta(i+p,j+q);			
					delta(i+p,j)];
				
				end			
				
			elseif (info_score == 2) 
				
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
                neighborhood = [delta(i+p,j); 
                    delta(i,j+q);
                    delta(i+p,j+q)];
			else 
                neighborhood = zeros(24, 1);
                p = 1;
                for k = -2 : 2
                    for l = -2 : 2
                        if (k == 0 && l ==0)
                            %Do nothing
                        else
                            neighborhood(p,1) = delta(i+k, j-l);
                            p = p + 1;
                        end
                    end
                end
            end
            modDelta(i,j) = myMedian(neighborhood);
        end
	end
end

temp = modDelta(:,:) < THRESH;
modDelta = modDelta - modDelta.*temp;
	
end
