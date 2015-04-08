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

function [x_fi] = applyKalman(z_fi, t_step_fi, i)
    %% INPUT FIXED-POINT INFO
    %z_fi --> F = 0
    %t_step_fi --> F = 6
    
    global divisorF;
    
    persistent x_p P_p x_precision p_precision
    if (i == 2)
        x_p = [0, 0, 0, 0]';
        P_p = eye(4);
        x_precision = 0;
        p_precision = 0;
    end
    
    %% FIXED-POINT CONSTANTS
    inv_precision = divisorF;
    z_precision = 0;
    t_precision = 6;
    h_precision = 0;
    q_precision = 0; 
    r_precision = 0;
    
    %% INITIALIZE USER DETERMINED, STATIC VARIABLES
    oneFI = floatToFix(1, t_precision); 
    F_fi = [oneFI 0 t_step_fi 0; 0 oneFI 0 t_step_fi; 0 0 oneFI 0; 0 0 0 oneFI]; 
    f_precision = t_precision;
    
    H = [1 0 0 0; 0 1 0 0]; 
    H_fi = floatToFix(H, h_precision); 
    
    Q = eye(4);
    Q_fi = floatToFix(Q, q_precision);
    
    R = 1000 * eye(2); 
    R_fi = floatToFix(R, r_precision);

    %% PREDICTION EQUATIONS
    [x_new_pred_fi, xnewp_precision] = fixedMult(F_fi, f_precision, x_p, x_precision);
    
    [temp_fi_1, t1_precision] = fixedMult(F_fi, f_precision, P_p, p_precision);
    [temp_fi_2, t2_precision] = fixedMult(temp_fi_1, t1_precision, F_fi', f_precision); 
    [P_new_pred_fi, pnewp_precision] = fixedAdd(temp_fi_2, t2_precision, Q_fi, q_precision);
    
    %% INTERMEDIATE CALCULATIONS
    [temp_fi_3, t3_precision] = fixedMult(H_fi, h_precision, x_new_pred_fi, xnewp_precision); 
    [y_fi, y_precision] = fixedAdd(z_fi, z_precision, -temp_fi_3, t3_precision);
    
    [temp_fi_4, t4_precision] = fixedMult(H_fi, h_precision, P_new_pred_fi, pnewp_precision); 
    [temp_fi_5, t5_precision] = fixedMult(temp_fi_4, t4_precision, H_fi', h_precision);
    [S_fi, s_precision] = fixedAdd(temp_fi_5, t5_precision, R_fi, r_precision); 
    
    %% NORMALIZE
    S_fi = floatToFix(S_fi, -s_precision);
    s_precision = 0;
    
    %% INVERT S
    [temp_fi_6, t6_precision] = fixedMult(S_fi(1), s_precision, S_fi(4), s_precision); 
    [temp_fi_7, t7_precision] = fixedMult(S_fi(2), s_precision, S_fi(3), s_precision); 
    [detS_fi, detS_precision] = fixedAdd(temp_fi_6, t6_precision, -temp_fi_7, t7_precision);
    
    %Floating-point 
    detS = detS_fi*2^(-detS_precision);
    inv_detS = 1 / detS;
    
    %Back to fixed-point
    inv_detS_fi = floatToFix(inv_detS, inv_precision); 
    swapped_S_fi = [S_fi(4) -S_fi(2); -S_fi(3) S_fi(1)]; 
    [S_inv_fi, sinv_precision] = fixedMult(swapped_S_fi, s_precision, inv_detS_fi, inv_precision);
    
    %% INTERMEDIATE CALCULATIONS
    [temp_fi_8, t8_precision] = fixedMult(P_new_pred_fi, pnewp_precision, H_fi', h_precision); 
    [K_fi, k_precision] = fixedMult(temp_fi_8, t8_precision, S_inv_fi, sinv_precision); 
    
    %% UPDATE EQUATIONS
    [temp_fi_9, t9_precision] = fixedMult(K_fi, k_precision, y_fi, y_precision); 
    [x_p, x_precision] = fixedAdd(x_new_pred_fi, xnewp_precision, temp_fi_9, t9_precision); 
    
    [temp_fi_10, t10_precision] = fixedMult(K_fi, k_precision, H_fi, h_precision); 
    [temp_fi_11, t11_precision] = fixedAdd(eye(4), 0, -temp_fi_10, t10_precision); 
    [P_p, p_precision] = fixedMult(temp_fi_11, t11_precision, P_new_pred_fi, pnewp_precision);
    
    %% NORMALIZE
    x_fi = floatToFix(x_p, -x_precision);
end

