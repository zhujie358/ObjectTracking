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

    global divisorF;
    global archW;

    result = fix1*fix2;
    F = F1 + F2;
    
    %Normalize any values that need more than the max fractional bits
    X = divisorF;
    if (F > X)
      norm = F - X;
      result = floatToFix(result, -norm);
      F = X;
    end
   
    %Verify that the value is not too large for the desired architecture
    binaryString = length(dec2bin(abs(result(1,1))));
    if (binaryString > archW)
        disp('ERROR: Value larger than desired architecture.');
    end
    
end
