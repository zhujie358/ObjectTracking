%% HEADER
% @file applyKalman.m
% @author Benjamin Brown (bbrown1867@gmail.com)
% @author Taylor Dotsikas (taylor.dotsikas@mail.mcgill.ca)
% @date February 20th, 2015
% @brief Function to apply Kalman filter equations for improved position
% @param z_fi: 2x1 measurment vector containing (x,y) position
% @param x_old_fi: 4x1 state vector containing (x,y) position and velocity
% from the previous iteration (k-1)
% @param P_old_fi: 4x4 covariance matrix containing Kalman confidence from the
% previous iteration (k-1)
% @param t_step_fi: A value containing the time between measurements
% @retval x_new: 4x1 state vector containing (x,y) position and velocity
% from the current iteration (k)
% @retval P_new: 4x4 covariance matrix containing Kalman confidence from the
% current iteration (k)

function [x_new, P_new] = applyKalman(z_fi, x_old_fi, P_old_fi, t_step_fi)

%The four inputs come in fixed-point with the following fracational
%portions:
global frac;
%z_fi ----> F = 0
%x_old_fi ----> F = 2
%P_old_fi ----> F = 0
%t_step_fi ----> F = 2*frac

%% INITIALIZE USER DETERMINED, STATIC VARIABLES
oneFI = floatToFix(1, 2*frac);
%Since F (the matrix) consists of numbers with F = 2*frac it has F = 2*frac
F_fi = [oneFI 0 t_step_fi 0; 0 oneFI 0 t_step_fi; 0 0 oneFI 0; 0 0 0 oneFI];
H_fi = [1 0 0 0; 0 1 0 0]; %F = 0

%Here we copy the error matrices from the kalmanfilter.m example code since
%we are currently unable to characterize the error vectors above
Q = eye(4);
R = 1000 * eye(2); 

%% PREDICTION EQUATIONS
x_new_pred_fi = F_fi * x_old_fi; %F = 2*frac + 2
%So for the next equation have to give Q the same F as the product. The
%product will have F = 2*frac + 0 + 2*frac = 4*frac.
Q_fi = floatToFix(Q, 4*frac);
P_new_pred_fi = F_fi*P_old_fi*F_fi' + Q_fi; %F = 4*frac

%% INTERMEDIATE CALCULATIONS
%So the product in the y equation will have F = 0 + 2*frac + 2, so we will
%need to normalize z_fi to have the same, which currently has F = 0\
z_fi_norm = floatToFix(z_fi, 2*frac+2); %F = 2*frac + 2
y_fi = z_fi_norm - H_fi*x_new_pred_fi; %F = 2*frac + 2
%The product in the S equation will have F = 0 + 4*frac + 0, so need to
%normalize R to the same value
R_fi = floatToFix(R, 4*frac); %F = 4*frac
S_fi = H_fi*P_new_pred_fi*H_fi' + R_fi; %F = 4*frac
detS = (S_fi(1)*S_fi(4) - S_fi(2)*S_fi(3)); %F = 4*frac
inv_detS_fi = floatToFix((1/detS), frac);
S_inv_fi = inv_detS_fi * [S_fi(4) -S_fi(2); -S_fi(3) S_fi(1)]; %F = frac + 4*frac = 5*frac
K_fi = P_new_pred_fi*H_fi'*S_inv_fi; %F = 4*frac + 0 + 5*frac = 9*frac

%% UPDATE EQUATIONS
x_new = x_new_pred_fi + K_fi*y_fi;
P_new = (eye(4) - K_fi*H_fi)*P_new_pred_fi;

end

