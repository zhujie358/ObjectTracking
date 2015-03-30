%% HEADER
% @file fixedAdd.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 30th, 2015
% @brief Fixed-point multiplication of two numbers.
% @param fix1: Fixed-point operand
% @param F1: Fractional portion of fix1
% @param fix2: Fixed-point operand
% @param F2: Fractional portion of fix2
% @retval result: Fixed-point product
% @retval F: Fractional portion of result

function [result, F] = fixedAdd(fix1, F1, fix2, F2)

if(F1 > F2)
    fix2 = fix2.* 2^(F1-F2);
    F = F1;
else
    fix1 = fix1.* 2^(F2-F1);
    F = F2;
end

result = fix1 + fix2;

end