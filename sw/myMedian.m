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

countNonZero = 0;
for i = 1 : m
    for j = 1 : n
        if (frame(i,j)~=0)
            countNonZero = countNonZero + 1;
        end
    end
end
modFrame = zeros(1,countNonZero);
k = 1; 
for i = 1 : m
    for j = 1 : n
        if (frame(i,j)~=0)
            modFrame(1,k) = frame(i,j);
            k = k + 1;
        end
    end
end

Sort the non-zero elements by increasing order
isOrdered = false;
howMany = 0;

while (~isOrdered)
    for i = 1 : countNonZero-1
        if (modFrame(1,i) < modFrame(1,i+1))
            temp = modFrame(1,i);
            modFrame(1,i) = modFrame(1,i+1);
            modFrame(1,i+1) = temp;
            howMany = howMany + 1;
        end
    end
    if (howMany == 0)
        isOrdered = true;
    else
        howMany = 0;
    end
end

if (mod(countNonZero,2) == 0)
	middle_1 = countNonZero/2;
	middle_2 = middle_1 + 1;
	median = (modFrame(1, middle_1) + modFrame(1, middle_2))/2;

else
	middle = ceil(countNonZero/2);
	median = modFrame(1, middle);
end

end