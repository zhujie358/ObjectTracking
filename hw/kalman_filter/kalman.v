////////////////////////////////////////////////////////////////////////////////////////////
// File:   kalman.v
// Author: B. Brown, T. Dotsikas
// About:  Hardware implementation of Kalman filter equations.
////////////////////////////////////////////////////////////////////////////////////////////

/*
	Comments:

	The static matrices and initializations can be scaled modularly for a different Kalman 
	filter without 4 states and 2 measurements The rest of the code cannot be. The matrix 
	equations are written out with the specific lengths in mind to avoid non-synth code. 

	Furthemore, the H matrix has been removed entirely to provide unnecessary math. Since the
	H matrix is just converting 4 states --> 2 measurements, it just plucks out specific values
	when it is multiplied by another matrix. To make life, hardware, and coding easier - the 
	plucking is hard coded, and not done with multiplication.

	A simple description of the FSM is as follows: The Kalman filter chills in idle state, constantly
	pumping out the most recent (x,y) value. When the valid signal goes high, it signifies that a new
	measurement has arrived - and starts the computations. The FSM walks through the computations, since
	only some can be done in parallel, and the rest have to be done in series. When its finished, it updates
	the (x,y) value and goes back to chilling in idle.
*/

module kalman #(
	parameter DISP_WIDTH  = 11
)(
	input wire 						clk,
	input wire 						aresetn,

	input wire  [(DISP_WIDTH-1):0]	z_x,
	input wire  [(DISP_WIDTH-1):0]	z_y,
	input wire 						valid,
	output wire 					ready,

	output wire [(DISP_WIDTH-1):0]	z_x_new,
	output wire [(DISP_WIDTH-1):0]	z_y_new
);

////////////////////////////////////// PARAMETERS //////////////////////////////////////////////

// Finite State Machine
localparam FSM_WIDTH 	 = 4;
localparam FSM_INIT		 = 0;
localparam FSM_IDLE      = 1;
localparam FSM_PREDICT_1 = 2;
localparam FSM_PREDICT_2 = 3;
localparam FSM_INTERM_1  = 4;
localparam FSM_INTERM_2  = 5;
localparam FSM_INTERM_3  = 6;
localparam FSM_UPDATE    = 7;
localparam FSM_NORMAL    = 8;

// Architecture
localparam ARCH_W 		 = 32;

// Kalman State Space
localparam NUM_STATES 	 = 4;
localparam NUM_MEASUR 	 = 2;

// Fixed Point Values
localparam FRAC   	 	 = 6;
localparam ONE_FI 		 = 1 << FRAC;
localparam T_STEP_FI 	 = 1; 		   // round(0.0155 << FRAC)

/////////////////////////////// INTERNAL SIGNALS & VARIABLES ///////////////////////////////////

// Finite State Machine
reg [(FSM_WIDTH-1):0]	fsm_curr;
reg [(FSM_WIDTH-1):0]	fsm_next;
wire 					fsm_clear_all;
wire 					fsm_clear_tmp;

// Static Matrices
wire [(ARCH_W-1):0]		x_init	   [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_init	   [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0] 	f_mat 	   [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		q_mat 	   [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0] 	r_mat 	   [0:NUM_MEASUR-1][0:NUM_MEASUR-1];
wire [(ARCH_W-1):0]		p_helper   [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		s_det;

// Dynamic Matrices and Vectors
reg  [(ARCH_W-1):0]		x_curr 	   [0:NUM_STATES-1];
reg  [(ARCH_W-1):0]		x_next 	   [0:NUM_STATES-1];
reg  [(ARCH_W-1):0]		p_curr 	   [0:NUM_STATES-1][0:NUM_STATES-1];
reg  [(ARCH_W-1):0]		p_next_tmp [0:NUM_STATES-1][0:NUM_STATES-1];
reg  [(ARCH_W-1):0]		p_next 	   [0:NUM_STATES-1][0:NUM_STATES-1];
reg  [(ARCH_W-1):0]		z_vec	   [0:NUM_MEASUR-1];
reg  [(ARCH_W-1):0] 	y_vec	   [0:NUM_MEASUR-1];
reg  [(ARCH_W-1):0]		s_mat	   [0:NUM_MEASUR-1][0:NUM_MEASUR-1];
reg  [(ARCH_W-1):0]		s_mat_inv  [0:NUM_MEASUR-1][0:NUM_MEASUR-1];
reg  [(ARCH_W-1):0]		k_mat 	   [0:NUM_STATES-1][0:NUM_MEASUR-1];

// Loops that get rolled out on compile time
genvar i, j;

////////////////////////////////// FINITE STATE MACHINE ////////////////////////////////////////

// FSM Current States
always @(posedge clk or negedge aresetn) begin
	if (~aresetn)	fsm_curr <= FSM_INIT;
	else			fsm_curr <= fsm_next;
end

// FSM Next States
always @* begin
	case(fsm_curr)
		FSM_INIT 	  : fsm_next = FSM_IDLE;
		FSM_IDLE 	  : fsm_next = valid ? FSM_PREDICT_1 : FSM_IDLE;
		FSM_PREDICT_1 : fsm_next = FSM_PREDICT_2;
		FSM_PREDICT_2 : fsm_next = FSM_INTERM_1;
		FSM_INTERM_1  : fsm_next = FSM_INTERM_2;
		FSM_INTERM_2  : fsm_next = FSM_INTERM_3;
		FSM_INTERM_3  : fsm_next = FSM_UPDATE;
		FSM_UPDATE    : fsm_next = FSM_NORMAL;
		FSM_NORMAL 	  : fsm_next = FSM_IDLE;
		default       : fsm_next = FSM_INIT;
	endcase 
end

// FSM Helper Logic
assign ready 		 = (fsm_curr == FSM_IDLE);
assign fsm_clear_all = (fsm_curr == FSM_INIT);
assign fsm_clear_tmp = (fsm_curr == FSM_INIT) | (fsm_curr == FSM_IDLE);

///////////////////////////////// STATIC MATRICES AND VECTORS //////////////////////////////////

// Fixed-Point Info: These are determined based on where the matrix gets incorporated into the FSM
// p_init : F = 0
// x_init : F = 0
// f_mat  : F = FRAC
// q_mat  : F = 2*FRAC
// r_mat  : F = 2*FRAC

// Set x_init to zeros, and p_init and q_mat to identity. Set f_mat to identity with t_step.
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_vec_init
		assign x_init[i] = 0;
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_mat_init
			if (i == j) 
				begin
					assign p_init[i][j] = 'd1;
					assign q_mat[i][j] = 'd1 << 2*FRAC;
					assign f_mat[i][j] = ONE_FI;
				end
			else if ((i == 0 & j == 2) | (i == 1 & j == 3))
				begin
					assign p_init[i][j] = 'd0;
					assign q_mat[i][j] = 'd0;
					assign f_mat[i][j] = T_STEP_FI;
				end
			else 
				begin
					assign p_init[i][j] = 'd0;
					assign q_mat[i][j] = 'd0;
					assign f_mat[i][j] = 'd0;
				end
		end
	end
endgenerate

// Set r_mat to initial values
generate 
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_r_mat_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_r_mat_cols
			if (i == j)	assign r_mat[i][j] = 'd1000 << 2*FRAC;
			else		assign r_mat[i][j] = 'd0;
		end
	end
endgenerate

// Init p_helper : This matrix just rearranges K into a (4,4) subtracted from the identity. Used in update state.
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_helper_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_helper_cols
			if ((i == j) & i < 2)	assign p_helper[i][j] = ('d1 << 5*FRAC) - k_mat[i][j];
			else if (i == j)		assign p_helper[i][j] = ('d1 << 5*FRAC);
			else if (j < 2)			assign p_helper[i][j] = k_mat[i][j];
			else					assign p_helper[i][j] = 'd0;
		end
	end
endgenerate

//////////////////////////////// DYNAMIC MATRICES AND VECTORS //////////////////////////////////

// Measurement Value - 2x1 vector latched when valid data arrives
always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 
		begin
			z_vec[0] <= 'd0;
			z_vec[1] <= 'd0;
		end
	// Latch values and scale to match x_next precision
 	else if (ready & valid)	
 		begin
 			z_vec[0] <= z_x << FRAC;
 			z_vec[1] <= z_y << FRAC;
 		end
 	else 
 		begin
 			z_vec[0] <= z_vec[0];
 			z_vec[1] <= z_vec[1];
 		end
end

// Next X Value - 4x4 matrix times a 4x1 vector
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_next
		always @(posedge clk) begin
			if (fsm_clear_tmp) 					x_next[i] <= 'd0;
			// Compute, F = FRAC + 0 = FRAC
			else if (fsm_curr == FSM_PREDICT_1)	x_next[i] <= f_mat[i][0]*x_curr[0] + f_mat[i][1]*x_curr[1] + f_mat[i][2]*x_curr[2] + f_mat[i][3]*x_curr[3];
			else								x_next[i] <= x_next[i];
		end
	end
endgenerate

// Temp P Value - 4x4 matrix times a 4x4 matrix (F = 6)
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_temp_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_temp_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)		 			p_next_tmp[i][j] <= 'd0;
				// Compute, F = FRAC + 0 = FRAC
				else if (fsm_curr == FSM_PREDICT_1) p_next_tmp[i][j] <= f_mat[i][0]*p_curr[0][j] + f_mat[i][1]*p_curr[1][j] + f_mat[i][2]*p_curr[2][j] + f_mat[i][3]*p_curr[3][j];
				else								p_next_tmp[i][j] <= p_next_tmp[i][j];
			end
		end
	end
endgenerate

// Next P Value - 4x4 matrix times a 4x4 transposed matrix, plus a 4x4 matrix
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_next_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_next_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)		 			p_next[i][j] <= 'd0;
				// Compute, F = FRAC + FRAC = 2*FRAC
				else if (fsm_curr == FSM_PREDICT_2)	p_next[i][j] <= (p_next_tmp[i][0]*f_mat[j][0] + p_next_tmp[i][1]*f_mat[j][1] + p_next_tmp[i][2]*f_mat[j][2] + p_next_tmp[i][3]*f_mat[j][3]) + q_mat[i][j];
				else								p_next[i][j] <= p_next[i][j];
			end
		end
	end
endgenerate

// Y Vector - 2x1 measurement vector (inputs) minus predicted position vector, the first two entries of the 4x1 vector x_next
generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_y_vec
		always @(posedge clk) begin
			if (fsm_clear_tmp) 					y_vec[i] <= 'd0;
			// Compute, F = FRAC
			else if (fsm_curr == FSM_INTERM_1)	y_vec[i] <= z_vec[i] - x_next[i];
			else 								y_vec[i] <= y_vec[i];
		end	
	end
endgenerate

// S Matrx - 2x2 matrix (top left corner of p_next) plus the R matrix
generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_s_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_s_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)					s_mat[i][j] <= 'd0;
				// Compute, F = 2*FRAC << FRAC = 3*FRAC. Scale to prep for division.
				else if (fsm_curr == FSM_INTERM_1)  s_mat[i][j] <= (p_next[i][j] + r_mat[i][j]) << FRAC;
				else 								s_mat[i][j] <= s_mat[i][j];
			end
		end
	end
endgenerate

// S Matrix Determinment - Normalize to F = 0 such that the determinent is much smaller than the s_mat values for fixed-point division
assign s_det = (s_mat[0][0] >> 3*FRAC)*(s_mat[1][1] >> 3*FRAC) - (s_mat[0][1] >> 3*FRAC)*(s_mat[1][0] >> 3*FRAC);

// S Matrix Inverse - Swap places of entries in s_mat, modify signs where necessary, and divide by determinant
always @(posedge clk) begin
	if (fsm_clear_tmp)								 s_mat_inv[0][0] <= 'd0;
	// Compute, F = 3*FRAC
	else if (fsm_curr == FSM_INTERM_2 & s_det != 0)  s_mat_inv[0][0] <= s_mat[1][1] / s_det;
	else 											 s_mat_inv[0][0] <= s_mat_inv[0][0];
end
always @(posedge clk) begin
	if (fsm_clear_tmp)								 s_mat_inv[1][1] <= 'd0;
	// Compute, F = 3*FRAC
	else if (fsm_curr == FSM_INTERM_2 & s_det != 0)  s_mat_inv[1][1] <= s_mat[0][0] / s_det;
	else 											 s_mat_inv[1][1] <= s_mat_inv[1][1];
end
always @(posedge clk) begin
	if (fsm_clear_tmp)								 s_mat_inv[0][1] <= 'd0;
	// Compute, F = 3*FRAC
	else if (fsm_curr == FSM_INTERM_2 & s_det != 0)  s_mat_inv[0][1] <= -1*s_mat[0][1] / s_det;
	else 											 s_mat_inv[0][1] <= s_mat_inv[0][1];
end
always @(posedge clk) begin
	if (fsm_clear_tmp)								 s_mat_inv[1][0] <= 'd0;
	// Compute, F = 3*FRAC
	else if (fsm_curr == FSM_INTERM_2 & s_det != 0)  s_mat_inv[1][0] <= -1*s_mat[1][0] / s_det;
	else 											 s_mat_inv[1][0] <= s_mat_inv[1][0];
end

// K Matrix - 4x2 matrix (left half of p_next) times 2x2 matrix (s_mat_inv)
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: k_gen_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: k_gen_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)					k_mat[i][j] <= 'd0;
				// Compute, F = 2*FRAC + 3*FRAC = 5*FRAC
				else if (fsm_curr == FSM_INTERM_3)  k_mat[i][j] <= p_next[i][0]*s_mat_inv[0][j] + p_next[i][1]*s_mat_inv[1][j];
				else 								k_mat[i][j] <= k_mat[i][j];
			end
		end
	end
endgenerate

// Current X Value - 4x1 vector plus a 4x2 matrix times a 2x1 vector
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_curr
		always @(posedge clk) begin
			if (fsm_clear_all)		 			x_curr[i] <= x_init[i];
			// Compute, F = 5*FRAC + FRAC = 6*FRAC. Scale x_next to satisfy matching fractional lengths.
			else if (fsm_curr == FSM_UPDATE)	x_curr[i] <= (x_next[i] << 5*FRAC) + (k_mat[i][0]*y_vec[0] + k_mat[i][1]*y_vec[1]);
			// Normalize, F = 0
			else if (fsm_curr == FSM_NORMAL) 	x_curr[i] <= x_curr[i] >> 6*FRAC;
			else 								x_curr[i] <= x_curr[i];
		end
	end
endgenerate


// Current P Value - 4x4 weird reconstruction of K matrix (done above in p_helper) times a 4x4 matrix
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_curr_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_curr_cols
			always @(posedge clk) begin
				if (fsm_clear_all)		 			p_curr[i][j] <= p_init[i][j];
				// Compute, F = 5*FRAC + 2*FRAC = 7*FRAC
				else if (fsm_curr == FSM_UPDATE) 	p_curr[i][j] <= p_helper[i][0]*p_next[0][j] + p_helper[i][1]*p_next[1][j] + p_helper[i][2]*p_next[2][j] + p_helper[i][3]*p_next[3][j];
				// Normalize, F = 0
				else if (fsm_curr == FSM_NORMAL)	p_curr[i][j] <= p_curr[i][j] >> 7*FRAC;
				else								p_curr[i][j] <= p_curr[i][j];
			end
		end
	end
endgenerate

// Drive Outputs
assign z_x_new = x_curr[0];
assign z_y_new = x_curr[1];

endmodule