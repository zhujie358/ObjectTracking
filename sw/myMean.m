%% HEADER
% @file myMean.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 26th, 2015
% @brief Mean function to reduce dependency on MATLAB built-in function
% @param frame: MxN delta frame
% @retval delta: The mean value of the frame [0,256]

function [mean] = myMean(frame)

[m,n] = size(frame);
sum = 0;
numNonZeroTerms = 0;

for i = 1 : m
	for j = 1 : n
        if (frame(i,j) ~= 0)
            sum = sum + frame(i,j);
            numNonZeroTerms = numNonZeroTerms + 1;
        end
    end
end

if (numNonZeroTerms ~= 0)
    mean = sum / numNonZeroTerms;
else
    mean = 0;
end

end

