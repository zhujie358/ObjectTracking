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
    %% INPUT FIXED-POINT INFO
    % delta_fi --> F = 0
    % THRESH_fi --> F = 0
    
    %% NOTE:
    % This function has no real arthimetic operations. Only logical tests 
    % and loop indexing. Since everything in this function is already an
    % integer with F = 0, there is nothing to do here.

    %% MEDIAN FILTER ALGORITHM
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
                modDelta_fi(i,j) = myMedian(neighborhood_fi); %F = 0
            end
        end
    end
    temp = modDelta_fi(:,:) < THRESH_fi; %F = 0
    temp = int16(temp); %Covert boolean to uint16 for MATLAB
    modDelta_fi = modDelta_fi - modDelta_fi.*temp; %F = 0
	
end
