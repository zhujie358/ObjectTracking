%% HEADER
% @file fixedMult.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 26th, 2015
% @brief Fixed-point multiplication of two numbers.
% @param fix1: Fixed-point operand
% @param F1: Fractional portion of fix1
% @param fix2: Fixed-point operand
% @param F2: Fractional portion of fix2
% @retval result: Fixed-point product
% @retval F: Fractional portion of result

function [result, F] = fixedMult(fix1, F1, fix2, F2)

%Algorithm
result = fix1*fix2;
F = F1 + F2;

%Error checking
testBin = dec2bin(result(1,1));
if (length(testBin) > 16)
    disp('ERROR: More than 16 bits are needed to represent this number.');
    disp(result);
    disp(length(testBin));
end
    

end
