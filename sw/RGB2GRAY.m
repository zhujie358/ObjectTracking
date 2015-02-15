%% HEADER
% @file RGB2GRAY.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 13th, 2015
% @brief Function to perform colorimetric RGB24 to grayscale conversion
% @param RGB_FRAME: An MxNx3 matrix of the frame to be converted
% @param select: Choose which method to use for conversion (efficient, naive)
% @retval GS_FRAME: Converted grayscale frame

function [GS_FRAME]= RGB2GRAY(RGB_FRAME, select)

%% INITIALIZE
R = .2126; %Red coefficient for colorimetric RGB-Grayscale conversion 
G = .7152; %Green coefficient for colorimetric RGB-Grayscale conversion 
B = .0722; %Blue coefficient for colorimetric RGB-Grayscale conversion 
[m,n,~] = size(RGB_FRAME);
GS_FRAME = zeros(m, n);

%% CONVERSION
if (strcmp(select, 'efficient'))
	GS_FRAME = R*RGB_FRAME(:,:,1) + G*RGB_FRAME(:,:,2) + B*RGB_FRAME(:,:,3);
elseif (strcmp(select, 'naive'))
	for j = 1 : m
        for k = 1 : n
            %Convert RGB24 to Grayscale
            GS_FRAME(j,k) = R*RGB_FRAME(j,k,1) + G*RGB_FRAME(j,k,2) + B*RGB_FRAME(j,k,3);
        end
    end
else
	disp('Did not choose a method for conversion, zeros returned');
end

end