%% HEADER
% @file lin2mat.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @date March 8th, 2015
% @brief Helper function for median filter
% @param linear_index: Linear index of position in some matrix A
% @param m: Number of rows in A
% @param n: Number of cols in A
% @retval row: Row of linear index in A
% @retval col: Col of linear index in A

function [row, col] = lin2mat(linear_index, m, n)

if (linear_index <= n)
	row = 1;
	col = linear_index;
else
	row = ceil(linear_index / n);
	col = mod(linear_index, n); 
	 if (col == 0)
		col = n;
	end
end

end