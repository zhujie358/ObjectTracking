%% HEADER
% @file medianFilter.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 10th, 2015
% @brief Function to filter delta frame based on median of neighbors
% @param delta_fi: MxN delta frame
% @param THRESH_fi: Threshold for filtering
% @retval modDelta_fi: MxN filtered delta frame

function [modDelta_fi]= medianFilter(delta_fi, THRESH_fi)

%Delta comes in in FI with F = 0 
%Thresh also comes in FI with F = 0

%Result matrix
[m,n] = size(delta_fi);
modDelta_fi = delta_fi;

%Iterate through all points
for i = 1 : m
	for j = 1 : n
	
		%Identify an object point
		if (delta_fi(i,j) ~= 0)
		
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
                    neighborhood_fi = [delta_fi(i,j+q);
					delta_fi(i+p,j+q);
					delta_fi(i+p,j);
					delta_fi(i+p,j-q);
					delta_fi(i,j-q)];
				
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
					neighborhood_fi = [delta_fi(i-p,j);
					delta_fi(i-p,j+q);
					delta_fi(i,j+q);
					delta_fi(i+p,j+q);			
					delta_fi(i+p,j)];
				
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
                neighborhood_fi = [delta_fi(i+p,j); 
                    delta_fi(i,j+q);
                    delta_fi(i+p,j+q)];
			else 
                neighborhood_fi = zeros(24, 1);
                p = 1;
                for k = -2 : 2
                    for l = -2 : 2
                        if (k == 0 && l ==0)
                            %Do nothing
                        else
                            neighborhood_fi(p,1) = delta_fi(i+k, j-l);
                            p = p + 1;
                        end
                    end
                end
            end
            %So we replaced the point with the median of its neighbors
            %neighborbood is just a collecion of points from delta (which
            %is fixed point), so it is also fixed point. However the median
            %might not be if we are taking the average of two middle points
            modDelta_fi(i,j) = myMedian(neighborhood_fi);
        end
	end
end

%Since modDelta just takes a median of the neighborhood, it's just
%replacing a fixed point value with another fixed point value, so we're
%good here. F = 0 for result.
temp = modDelta_fi(:,:) < THRESH_fi;
modDelta_fi = modDelta_fi - modDelta_fi.*temp;
	
end
