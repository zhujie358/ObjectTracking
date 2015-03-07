%   Copyright 2010 The MathWorks, Inc.
function y=kalman_loop(z)
% Call Kalman estimator in the loop for large data set testing
%#codegen
[DIM, LEN]=size(z);
y=zeros(DIM,LEN);           % Initialize output
for n=1:LEN                     % Output in the loop
    y(:,n)=kalmanfilter(z(:,n));
end;