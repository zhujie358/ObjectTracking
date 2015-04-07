%% HEADER
% @file myMean.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 26th, 2015
% @brief Mean function to reduce dependency on MATLAB built-in function
% @param frame: MxN delta frame
% @retval delta: The mean value of the frame [0,256]

function [mean_fi] = myMean(frame_fi)
    %% INPUT FIXED-POINT INFO
    % frame_fi --> F = 0

    %% MEAN ALGORITHM
    [m,n] = size(frame_fi);
    sum_fi = 0;
    numNonZeroTerms = 0;

    for i = 1 : m
        for j = 1 : n
            if (frame_fi(i,j) ~= 0)
                sum_fi = sum_fi + frame_fi(i,j); %F = 0
                numNonZeroTerms = numNonZeroTerms + 1; %F = 0
            end
        end
    end

    if (numNonZeroTerms ~= 0)
        F = 20;
        numNonZeroTermsInv = 1/numNonZeroTerms; %Floating-Point
        numNonZeroTerms_fi = floatToFix(numNonZeroTermsInv, F); %F = 20
        mean_fi = fixedMult(sum_fi, 0, numNonZeroTerms_fi, F); %F = 20
    else
        mean_fi = 0;
    end

end

