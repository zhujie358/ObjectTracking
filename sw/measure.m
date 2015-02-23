%% HEADER
% @file measure.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 20th, 2015
% @brief Function to perform edge detection on the object of interest
% @param edges: MxN frame matrix containing all zeros except at object(s)
% edges (note that there could be multiple objects in this frame)
% @retval z: 2x1 measurement vector (x,y) containing object position

function [z] = measure(edges)

%Assume 1 object in frame
%Find the 4 points that represent the outermost locations of the object on all 4 sides
%Test to see if the lines are parallel
%Find intersection of lines and store in z if they are not parallel
%If they are parallel, find the midpoint of one line and store in z.

[m,n] = size(edges);

%Initialize variables in case the object is not in the current frame

x1=0; 
y1=0; 
x2=0; 
y2=0; 
x3=0; 
y3=0; 
x4=0; 
y4=0;

%Find the top of the object (x1,y1)

for i = 1 : m
	for j = 1 : n
		if (edges(i,j) ~= 0)
			x1 = j;
			y1 = i;
			break;
		end
	end
	if (edges(i,j) ~= 0)
		break;
	end
end

%Find the bottom of the object (x2,y2)

for i = m : -1 : 1
	for j = 1 : n
		if (edges(i,j) ~= 0)
			x2 = j;
			y2 = i;
			break;
		end
	end
	if (edges(i,j) ~= 0)
		break;
	end
end

%Find the most left point of the object (x3,y3)

for j = 1 : n
	for i = 1 : m
		if (edges(i,j) ~= 0)
			x3 = j;
			y3 = i;
			break;
		end
	end
	if (edges(i,j) ~= 0)
		break;
	end
end

%Find the most right point of the object (x4,y4)

for j = n : -1 : 1
	for i = 1 : m
		if (edges(i,j) ~= 0)
			x4 = j;
			y4 = i;
			break;
		end
	end
	if (edges(i,j) ~= 0)
		break;
	end
end

%check if the lines are parallel
denom = (x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4);

if (denom == 0)
	%The lines are parallel
	x = (x1 + x2)/2 ;
	y = (y1 + y2)/2 ;
else
	x = (((x1*y2) - (y1*x2))*(x3 - x4) - (x1 - x2)*((x3*y4) - (y3*x4)))/(denom);
	y = (((x1*y2) - (y1*x2))*(y3 - y4) - (y1 - y2)*((x3*y4) - (y3*x4)))/(denom);
end

%construct z matrix
z_decimals = [x; y];
z = fix(z_decimals);

end

