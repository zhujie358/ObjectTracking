%% HEADER
% @file myMedian.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 11th, 2015
% @brief Function to compute the median of a vector without sorting it
% @param a: Mx1 input vector
% @retval median: Median of vec
% @cite This algorithm was implemented by following the C code written by
% N. Devillard in his paper "Fast median search: an ANSI C implementation".
% The algorithm itself was developed by N. Wirth and presented in his book 
% "Algorithms+Data structures = programs"

function [median]= myMedian(a)

%Verify the input is a vector
[rows,cols] = size(a);
if (cols ~= 1)
    disp('This median function is built for vectors only, not matrices.');
    return;
end

%Following the notation in the algorithm
n = rows;
k = floor(n/2);

%Start kth-smallest algorithm
l = 1;
m = n;
while (l < m)
    x = a(k);
    i = l;
    j = m;
    doItAtLeastOnce = true;
    while(doItAtLeastOnce || i<= j)
        doItAtLeastOnce = false;
        while(a(i) < x) 
            i = i + 1;
        end
        while(x < a(j))
            j = j - 1;
        end
        if (i<=j)
            temp = a(i);
            a(i) = a(j);
            a(j) = temp;
            i = i + 1;
            j = j - 1;
        end
    end
    if (j < k)
        l = i;
    end
    if (k < i)
        m = j;
    end  
end

%Grab the median from the sorted a
if (mod(n,2) == 0)
    median = (a(n/2) + a((n/2)+1))/2;
else
    median = a(round(n/2));
end

end
