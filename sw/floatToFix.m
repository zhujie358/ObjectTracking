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

    d = float .* 2^(F);
    fixed = round(d);

    %Verify that enough fractional bits were used to represent this number
    while (float(1,1) ~= 0 && fixed(1,1) == 0)
        %disp('ERROR: The chosen F is too small to represent this value.');
        old_F = F;
        F = F+1;
        new_F = F;
        d = float .* 2^(F);
        fixed = round(d);
        str = sprintf('Old F: %d ------ New F: %d', old_F, new_F);
        disp(str);
    end

end
