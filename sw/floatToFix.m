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

%Steps 1 and 2 in the process
d = float .* 2^(F);
fixed = round(d);

end

