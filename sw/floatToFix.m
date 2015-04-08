%% HEADER
% @file floatToFix.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date March 19th, 2015
% @brief Converts a floating point object to fixed point representation
% @param float: Floating point object
% @param F: Fractional portion length
% @retval fixed: Fixed point object

function [fixed] = floatToFix(float, F)

    global archW;
    
    d = float .* 2^(F);
    fixed = round(d);

    %Verify that enough fractional bits were used to represent this number
    if (float(1,1) ~= 0 && fixed(1,1) == 0 && F > 0)
        disp('ERROR: The chosen F is too small to represent this value.');
    end

    %Verify that the value is not too large for the desired architecture
    binaryString = length(dec2bin(abs(fixed(1,1))));
    if (binaryString > archW)
        disp('ERROR: Value larger than desired architecture.');
    end
end
