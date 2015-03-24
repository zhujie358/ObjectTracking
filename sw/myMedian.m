%% HEADER
% @file myMedian.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 11th, 2015
% @brief Function to compute the median of a vector without sorting it
% @param a: Mx1 input vector
% @retval median_fi: Median of vec
% @cite This algorithm was implemented by following the C code written by
% N. Devillard in his paper "Fast median search: an ANSI C implementation".
% The algorithm itself was developed by N. Wirth and presented in his book 
% "Algorithms+Data structures = programs"

function [median_fi]= myMedian(a)

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

%Up to here no floating point math happened, we now have n, which is the
%index of the middle value. 
oneHalf_fi = floatToFix(.5, 2); %F = 2
%Multiplication of 2 fixed point numbers
middlePoint_fi = n * oneHalf_fi; %F = 2

%Now we grab the middle point by chopping F bits from middlePoint_fi. So if
%it's an odd number we just chop off the .5 essentially. Again, note that
%in VHDL we won't really be doing the next three steps, which in this case
%actually produce a floating point number.
middlePoint = middlePoint_fi * 2^(-2);
middlePoint = dec2bin(middlePoint);
middlePoint = bin2dec(middlePoint);
median_fi = a(middlePoint);

end
