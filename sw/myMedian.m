%% HEADER
% @file myMedian.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 28th, 2015
% @brief Function to compute the median value of the current delta frame
% @param frame: MxN current delta frame
% @retval delta: Median of the current delta frame

function [median]= myMedian(frame)

%Put all non-zero elements into a vector
[m,n] = size(frame);

if(n ~= 1)
    countNonZero = 0;
    for i = 1 : m
        for j = 1 : n
            if (frame(i,j)~=0)
                countNonZero = countNonZero + 1;
            end
        end
    end
    modFrame = zeros(countNonZero,1);
    k = 1; 
    for i = 1 : m
        for j = 1 : n
            if (frame(i,j)~=0)
                modFrame(k,1) = frame(i,j);
                k = k + 1;
            end
        end
    end
else
    countNonZero = m;
    modFrame = frame;
end

%Sort the non-zero elements by increasing order
isOrdered = false;
howMany = 0;

while (~isOrdered)
    for i = 1 : countNonZero-1
        if (modFrame(i,1) < modFrame(i+1,1))
            temp = modFrame(i,1);
            modFrame(i,1) = modFrame(i+1,1);
            modFrame(i+1,1) = temp;
            howMany = howMany + 1;
        end
    end
    if (howMany == 0)
        isOrdered = true;
    else
        howMany = 0;
    end
end

%Locate the median
if (mod(countNonZero,2) == 0)
	middle_1 = countNonZero/2;
	middle_2 = middle_1 + 1;
	median = (modFrame(middle_1, 1) + modFrame(middle_2, 1))/2;

else
	middle = ceil(countNonZero/2);
	median = modFrame(middle, 1);
end

end
