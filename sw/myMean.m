%% HEADER
% @file myMean.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 26th, 2015
% @brief Mean function to reduce dependency on MATLAB built-in function
% @param frame: MxN delta frame
% @retval delta: The mean value of the frame [0,256]

function [mean_fi] = myMean(frame_fi)

global frac;

%Variable sum_fi is F1 = 0, just a sum of fixed point numbers with F = 0

[m,n] = size(frame_fi);
sum_fi = 0;
numNonZeroTerms = 0;

for i = 1 : m
	for j = 1 : n
        if (frame_fi(i,j) ~= 0)
            sum_fi = sum_fi + frame_fi(i,j);
            numNonZeroTerms = numNonZeroTerms + 1;
        end
    end
end

if (numNonZeroTerms ~= 0)
    %The next step is to divide sum_fi by numNonZeroTerms, this will
    %produce a floating point number. So instead we invert the value,
    %convert it to fixed point, and then multiple two fixed point numbers
    numNonZeroTerms_fi = floatToFix(1/numNonZeroTerms, 2*frac); 
    %Note that we needed precision > 14 to get a non-zero value here.
    %The result is F = F1 + F2 = 0 + 2*frac = 2*frac
    mean_fi = sum_fi * numNonZeroTerms_fi; 
else
    mean_fi = 0;
end

end

