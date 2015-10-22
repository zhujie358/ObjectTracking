////////////////////////////////////////////////////////////////////////////////////////////
// File:   kalman.v
// Author: B. Brown, T. Dotsikas
// About:  Hardware implementation of Kalman filter update equations.
////////////////////////////////////////////////////////////////////////////////////////////

module kalman #(
	parameter DISP_WIDTH  = 11
)(
	input wire 						clk,
	input wire 						aresetn,

	input wire  [(DISP_WIDTH-1):0]	z_x,
	input wire  [(DISP_WIDTH-1):0]	z_y,

	output wire [(DISP_WIDTH-1):0]	z_x_new,
	output wire [(DISP_WIDTH-1):0]	z_y_new
);

// Architecture parameters (determined in SW)
localparam ARCH_W 		= 31;
localparam DIVS_F 		= 20;

// Kalman state space parameters
localparam NUM_STATES 	= 4;
localparam NUM_MEASUR 	= 2;

// Static matrices that don't change 
wire [(ARCH_W-1):0] f_mat 	  [NUM_STATES][NUM_STATES];
wire [(ARCH_W-1):0]	q_mat 	  [NUM_STATES][NUM_STATES];
wire [(ARCH_W-1):0] r_mat 	  [NUM_MEASUR][NUM_MEASUR];
wire [(ARCH_W-1):0] h_mat 	  [NUM_MEASUR][NUM_STATES];

// Dynamic matrices that change every frame
reg  [(ARCH_W-1):0]	x_vec 	  [NUM_STATES];
reg  [(ARCH_W-1):0]	x_vec_new [NUM_STATES];
reg  [(ARCH_W-1):0]	p_mat 	  [NUM_STATES][NUM_STATES];
reg  [(ARCH_W-1):0]	p_mat_tmp1[NUM_STATES][NUM_STATES];
reg  [(ARCH_W-1):0]	p_mat_tmp2[NUM_STATES][NUM_STATES];
reg  [(ARCH_W-1):0]	p_mat_new [NUM_STATES][NUM_STATES];
reg  [(ARCH_W-1):0] y_vec 	  [NUM_MEASUR];
reg  [(ARCH_W-1):0] s_mat 	  [NUM_MEASUR][NUM_MEASUR];
reg  [(ARCH_W-1):0] s_mat_inv [NUM_MEASUR][NUM_MEASUR];
wire [(ARCH_W-1):0] s_mat_det;
reg  [(ARCH_W-1):0] k_mat	  [NUM_STATES][NUM_MEASUR];
 
// Loop  and generate variables
integer q, r, y;
genvar i, j, k, l, m, n, o, p, s, t;

// Create the F matrix
generate 
	for (i = 0; i < NUM_STATES; i = i + 1) begin: f_mat_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin : f_mat_cols
			if (i == j) 											 assign f_mat[i][j] = 'd1;
			else if (((i == 0) & (j == 2)) | ((i == 1) & (j == 3)))  assign f_mat[i][j] = 0.01552;
			else 													 assign f_mat[i][j] = 'd0;
		end
	end
endgenerate

// Create the Q matrix
generate 
	for (k = 0; k < NUM_STATES; k = k + 1) begin: q_mat_rows
		for (l = 0; l < NUM_STATES; l = l + 1) begin : q_mat_cols
			if (k == l) assign q_mat[k][l] = 'd1;
			else 		assign q_mat[k][l] = 'd0;
		end
	end
endgenerate

// Create the R matrix
assign r_mat[0][0] = 'd1000;
assign r_mat[0][1] = 'd0;
assign r_mat[1][0] = 'd0;
assign r_mat[1][1] = 'd1000;

// Create the H matrix
generate
	for (s = 0; s < NUM_MEASUR; s = s + 1) begin: h_mat_init_rows
		for (t = 0; t < NUM_MEASUR; t = t + 1) begin: h_mat_init_cols
			if (s == t)	assign h_mat[s][t] = 'd1;
			else		assign h_mat[s][t] = 'd0;
		end
	end
endgenerate


// Initialize the state vector
generate
	for (m = 0; m < NUM_STATES; m = m + 1) begin: x_vec_init
		initial x_vec[m] = 'd0;
	end
endgenerate

// Initialize the covariance matrix
generate 
	for (n = 0; n < NUM_STATES; n = n + 1) begin: p_mat_init_rows
		for (o = 0; o < NUM_STATES; o = o + 1) begin: p_mat_init_cols
			if (n == o) initial p_mat[n][o] = 'd1;
			else 		initial p_mat[n][o] = 'd0;
		end
	end
endgenerate

// Predict the state vector
always @(posedge clk or negedge aresetn) begin
	// On reset, return to initial values
	if (~aresetn) 
		begin
			x_vec_new[0] <= 'd0;
			x_vec_new[1] <= 'd0; 
			x_vec_new[2] <= 'd0;
			x_vec_new[3] <= 'd0;
		end
	// Otherwise do matrix multiplication
	else
		begin
			x_vec_new[0] <= f_mat[0][0]*x_vec[0] + f_mat[0][1]*x_vec[1] + f_mat[0][2]*x_vec[2] + f_mat[0][3]*x_vec[3];
			x_vec_new[1] <= f_mat[1][0]*x_vec[0] + f_mat[1][1]*x_vec[1] + f_mat[1][2]*x_vec[2] + f_mat[1][3]*x_vec[3]; 
			x_vec_new[2] <= f_mat[2][0]*x_vec[0] + f_mat[2][1]*x_vec[1] + f_mat[2][2]*x_vec[2] + f_mat[2][3]*x_vec[3];
			x_vec_new[3] <= f_mat[3][0]*x_vec[0] + f_mat[3][1]*x_vec[1] + f_mat[3][2]*x_vec[2] + f_mat[3][3]*x_vec[3];
		end
end

// Predict the covariance matrix
always @(posedge clk or negedge aresetn) begin
	// On reset, return to initial values
	if (~aresetn) 
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat_tmp1[q][r] <= 'd0;
				end
			end
		end
	// Otherwise do matrix multiplication
	else
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat_tmp1[q][r] <= f_mat[q][0]*p_mat[0][r] + f_mat[q][1]*p_mat[1][r] + f_mat[q][2]*p_mat[2][r] + f_mat[q][3]*p_mat[3][r];  
				end
			end
		end
end

always @(posedge clk or negedge aresetn) begin
	// On reset, return to initial values
	if (~aresetn) 
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat_new[q][r] <= 'd0;
				end
			end
		end
	// Otherwise do matrix multiplication
	else
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat_new[q][r] <=  (p_mat_tmp1[q][0]*f_mat[r][0] + p_mat_tmp1[q][1]*f_mat[r][1] + p_mat_tmp1[q][2]*f_mat[r][2] + p_mat_tmp1[q][3]*f_mat[r][3]) +  q_mat[q][r];
				end
			end
		end
end

// Intermediate calculation of y-vector - hard coded to avoid multiplication
always @(posedge clk or negedge aresetn) begin
	if (~aresetn)
		begin
			y_vec[0] = 'd0;
			y_vec[1] = 'd0;
		end
	else 
		begin
			y_vec[0] = z_x - x_vec_new[0];
			y_vec[1] = z_y - x_vec_new[1];
		end
end

// Intermediate calculation of s-matrx - hard coded to avoid multiplication
always @(posedge clk or negedge aresetn) begin
	if (~aresetn)
		begin
			s_mat[0][0] <= 'd0;
			s_mat[0][1] <= 'd0;
			s_mat[1][0] <= 'd0;
			s_mat[1][1] <= 'd0;
		end
	else 
		begin
			s_mat[0][0] <= p_mat_new[0][0] + r_mat[0][0];
			s_mat[0][1] <= p_mat_new[0][1] + r_mat[0][1];
			s_mat[1][0] <= p_mat_new[1][0] + r_mat[1][0];
			s_mat[1][1] <= p_mat_new[1][1] + r_mat[1][1];
			
		end
end

// Intermediate calculation of s-matrix inverse 
assign s_mat_det = s_mat[0][0]*s_mat[1][1] - s_mat[0][1]*s_mat[1][0];

always @(posedge clk or negedge aresetn) begin
	if (~aresetn)
		begin
			s_mat_inv[0][0] <= 'd0;
			s_mat_inv[0][1] <= 'd0;
			s_mat_inv[1][0] <= 'd0;
			s_mat_inv[1][1] <= 'd0;
		end
	else 
		begin
			s_mat_inv[0][0] <= s_mat[1][1] / s_mat_det;
			s_mat_inv[0][1] <= -s_mat[1][0] / s_mat_det;
			s_mat_inv[1][0] <= -s_mat[0][1] / s_mat_det;
			s_mat_inv[1][1] <= s_mat[0][0] / s_mat_det;		
		end
end

// Intermediate calculation of k-matrix
always @(posedge clk or negedge aresetn) begin
	if (~aresetn)
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_MEASUR; r = r + 1) begin
					 k_mat[q][r] <= 'd0;
				end
			end					
		end
	else 
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_MEASUR; r = r + 1) begin
					 k_mat[q][r] <= p_mat_new[q][0]*s_mat_inv[0][r] + p_mat_new[q][1]*s_mat_inv[1][r];
				end
			end			
		end
end

// Update the state vector
always @(posedge clk or negedge aresetn) begin
	// On reset, return to initial values
	if (~aresetn) 
		begin
			x_vec[0] <= 'd0;
			x_vec[1] <= 'd0; 
			x_vec[2] <= 'd0;
			x_vec[3] <= 'd0;
		end
	// Otherwise do matrix multiplication
	else
		begin
			for (y = 0; y < NUM_STATES; y = y + 1) begin: x_create
				x_vec[y] <= x_vec_new[y] + (k_mat[y][0]*y_vec[0] + k_mat[y][1]*y_vec[1]);
			end		
		end
end

// Update the covariance matrix
always @(posedge clk or negedge aresetn) begin
	// On reset, return to initial values
	if (~aresetn) 
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat_tmp2[q][r] <= 'd0;
				end
			end
		end
	// Otherwise do matrix multiplication
	else
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					if ((q == 0 & r == 0) | (q == 1 & r == 1)) 		p_mat_tmp2[q][r] <= 'd1 - k_mat[q][r];
					else if ((q == 2 & r == 2) | (q == 3 & r == 3)) p_mat_tmp2[q][r] <= 'd1;
					else if (r == 0 | r == 1)						p_mat_tmp2[q][r] <= k_mat[q][r];
					else											p_mat_tmp2[q][r] <= 'd0;
				end
			end
		end
end

always @(posedge clk or negedge aresetn) begin
	// On reset, return to initial values
	if (~aresetn) 
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat[q][r] <= 'd0;
				end
			end
		end
	// Otherwise do matrix multiplication
	else
		begin
			for (q = 0; q < NUM_STATES; q = q + 1) begin
				for (r = 0; r < NUM_STATES; r = r + 1) begin
					p_mat[q][r] <= p_mat_tmp2[q][0]*p_mat_new[0][r] + p_mat_tmp2[q][1]*p_mat_new[1][r] + p_mat_tmp2[q][2]*p_mat_new[2][r] + p_mat_tmp2[q][3]*p_mat_new[3][r];  
				end
			end
		end
end

assign z_x_new = x_vec[0];
assign z_y_new = x_vec[1];

endmodule