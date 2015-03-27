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
    %% INPUT FIXED-POINT INFO
    %z_fi --> F = 0
    %x_old_fi --> F = 2
    %P_old_fi --> F = 0
    %t_step_fi --> F = 6
    
    %% FIXED-POINT CONSTANTS
    inv_precision = 20;

    %% INITIALIZE USER DETERMINED, STATIC VARIABLES
    oneFI = floatToFix(1, 6); %F = 6
    F_fi = [oneFI 0 t_step_fi 0; 0 oneFI 0 t_step_fi; 0 0 oneFI 0; 0 0 0 oneFI]; %F = 6
    H = [1 0 0 0; 0 1 0 0]; 
    H_fi = floatToFix(H, 0); %F = 0

    %Here we copy the error matrices from the kalmanfilter.m example code since
    %we are currently unable to characterize the error vectors above
    Q = eye(4);
    R = 1000 * eye(2); 

    %% PREDICTION EQUATIONS
    x_new_pred_fi = fixedMult(F_fi, 6, x_old_fi, 2); %F = 8 
    
    Q_fi = floatToFix(Q, 12); %F = 12
    temp_fi_1 = fixedMult(F_fi, 6, P_old_fi, 0); %F = 6
    temp_fi_2 = fixedMult(temp_fi_1, 6, F_fi', 6); %F = 12
    P_new_pred_fi = temp_fi_2 + Q_fi; %F = 12
    
    %% NORMALIZE
    x_new_pred_fi = floatToFix(x_new_pred_fi, -2); %F = 6
    P_new_pred_fi = floatToFix(P_new_pred_fi, -6); %F = 6
    
    %% INTERMEDIATE CALCULATIONS
    z_fi_norm = floatToFix(z_fi, 6); 
    temp_fi_3 = fixedMult(H_fi, 0, x_new_pred_fi, 6); %F = 6
    y_fi = z_fi_norm - temp_fi_3; %F = 6
    
    R_fi = floatToFix(R, 6); %F = 6
    temp_fi_4 = fixedMult(H_fi, 0, P_new_pred_fi, 6); %F = 6
    temp_fi_5 = fixedMult(temp_fi_4, 6, H_fi', 0); %F = 6
    S_fi = temp_fi_5 + R_fi; %F = 6
    temp_fi_6 = fixedMult(S_fi(1), 6, S_fi(4), 6); %F = 12
    temp_fi_7 = fixedMult(S_fi(2), 6, S_fi(3), 6); %F = 12
    detS_fi = temp_fi_6 - temp_fi_7; %F = 12
    
    %% NORMALIZE
    detS_fi = floatToFix(detS_fi, -12); %F = 0
    
    %% INTERMEDIATE CALCULATIONS
    inv_detS_fi = floatToFix((1/detS_fi), inv_precision); %F = inv_precision
    swapped_S_fi = [S_fi(4) -S_fi(2); -S_fi(3) S_fi(1)]; %F = 6
    S_inv_fi = fixedMult(swapped_S_fi, 6, inv_detS_fi, inv_precision); %F = inv_precision+6
    
    %% NORMALIZE
    S_inv_fi = floatToFix(S_inv_fi, -inv_precision); %F = 6
    
    %% INTERMEDIATE CALCULATIONS
    temp_fi_8 = fixedMult(P_new_pred_fi, 6, H_fi', 0); %F = 6
    K_fi = fixedMult(temp_fi_8, 6, S_inv_fi, 6); %F = 12

    %% NORMALIZE
    K_fi = floatToFix(K_fi, -6); %F = 6
    
    %% UPDATE EQUATIONS
    temp_fi_9 = fixedMult(K_fi, 6, y_fi, 6); %F = 12
    
    %% NORMALIZE
    temp_fi_9 = floatToFix(temp_fi_9, -6); %F = 6
    
    %% UPDATE EQUATIONS
    x_new_fi = x_new_pred_fi + temp_fi_9; %F = 6
    
    temp_fi_10 = fixedMult(K_fi, 6, H_fi, 0); %F = 6
    eye4_fi = floatToFix(eye(4), 6); %F = 6
    temp_fi_11 = eye4_fi - temp_fi_10; %F = 6
    P_new_fi = fixedMult(temp_fi_11, 6, P_new_pred_fi, 6); %F = 12
    
    %% NORMALIZE
    x_new = floatToFix(x_new_fi, -6); %F = 0
    P_new = floatToFix(P_new_fi, -12); %F = 0
end

