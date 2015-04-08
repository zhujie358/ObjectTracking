%% HEADER
% @file fixedAdd.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 30th, 2015
% @brief Addition of two fixed-point numbers.
% @param fix1: Fixed-point operand
% @param F1: Fractional portion of fix1
% @param fix2: Fixed-point operand
% @param F2: Fractional portion of fix2
% @retval result: Fixed-point sum
% @retval F: Fractional portion of result

function [result, F] = fixedAdd(fix1, F1, fix2, F2)

    global archW;
    
    if(F1 > F2)
        fix2 = fix2.* 2^(F1-F2);
        F = F1;
    else
        fix1 = fix1.* 2^(F2-F1);
        F = F2;
    end

    result = fix1 + fix2;

    %Verify that the value is not too large for the desired architecture
    binaryString = length(dec2bin(abs(result(1,1))));
    if (binaryString > archW)
        disp('ERROR: Value larger than desired architecture.');
    end   
    
end
