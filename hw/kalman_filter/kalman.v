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

	Furthermore, the H matrix has been removed entirely to provide unnecessary math. Since the
	H matrix is just converting 4 states --> 2 measurements, it just plucks out specific values
	when it is multiplied by another matrix. To make life, hardware, and coding easier - the 
	plucking is hard coded, and not done with multiplication.

	A simple description of the FSM is as follows: 
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
localparam FSM_INTERIM_1 = 4;
localparam FSM_INTERIM_2 = 5;
localparam FSM_DIVIDE    = 6;
localparam FSM_INTERIM_3 = 7;
localparam FSM_UPDATE    = 8;

// Architecture
localparam ARCH_W 		= 38;
localparam ARCH_F 		= 15;

// Kalman State Space
localparam NUM_STATES 	= 4;
localparam NUM_MEASUR 	= 2;

// Fixed Point Values - sign | integer | fraction
localparam FLIP_SIGN    = {1'b1, {(ARCH_W-1){1'b0}}};
localparam ONE_FI 		= ('b0 << (ARCH_W-1)) | ('b1 << ARCH_F) | 'b0;
localparam TSTEP_FI 	= ('b0 << (ARCH_W-1)) | ('b0 << ARCH_F) | 'b000000111111100;
localparam RDIAG_FI     = ('b0 << (ARCH_W-1)) | ('d1000 << ARCH_F) | 'b0; 

/////////////////////////////// INTERNAL SIGNALS & VARIABLES ///////////////////////////////////

// Finite State Machine
reg  [(FSM_WIDTH-1):0]	fsm_curr;
reg  [(FSM_WIDTH-1):0]	fsm_next;
wire 					fsm_clear_all;
wire 					fsm_clear_tmp;
wire					division_done;
wire 					division 	[0:NUM_MEASUR-1][0:NUM_MEASUR-1];

// Output Wrappers
wire [(ARCH_W-1):0] 	z_x_new_int; 
wire [(ARCH_W-1):0] 	z_y_new_int; 

// Static Matrices
wire [(ARCH_W-1):0]		x_init	    [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_init	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0] 	f_mat 	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		q_mat 	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0] 	r_mat 	    [0:NUM_MEASUR-1][0:NUM_MEASUR-1];

// Measurement Vector
reg  [(ARCH_W)-1:0]		z_vec		[0:NUM_MEASUR-1];

// State Vector - Actual
reg  [(ARCH_W-1):0]		x_curr		[0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_curr_mult [0:NUM_STATES-1][0:NUM_MEASUR-1];
wire [(ARCH_W-1):0]		x_curr_sum1 [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_curr_sum2 [0:NUM_STATES-1];

// State Vector - Predicted
reg  [(ARCH_W-1):0]		x_next 	    [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_mult [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_sum1 [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_sum2 [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_sum3 [0:NUM_STATES-1];

// Covariance Matrix - Actual
reg  [(ARCH_W-1):0]		p_curr		[0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_curr_diff [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_curr_mult [0:NUM_STATES-1][0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_curr_sum1 [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_curr_sum2 [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_curr_sum3 [0:NUM_STATES-1][0:NUM_STATES-1];

// Covariance Matrix - Predicted
reg   [(ARCH_W-1):0]	p_next 	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_next_mult [0:NUM_STATES-1][0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_next_sum1 [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_next_sum2 [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_next_sum3 [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_next_sum4 [0:NUM_STATES-1][0:NUM_STATES-1];

reg   [(ARCH_W-1):0]	p_next_tmp  [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_temp_mult [0:NUM_STATES-1][0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_temp_sum1 [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_temp_sum2 [0:NUM_STATES-1][0:NUM_STATES-1];
wire  [(ARCH_W-1):0]	p_temp_sum3 [0:NUM_STATES-1][0:NUM_STATES-1];

// Measurement-Predictation Error
wire  [(ARCH_W-1):0]	y_sub		[0:NUM_MEASUR-1];
reg	  [(ARCH_W-1):0]	y_vec		[0:NUM_MEASUR-1];

// Residual Covariance
wire  [(ARCH_W-1):0]	s_add 		[0:NUM_MEASUR-1][0:NUM_MEASUR-1];
reg   [(ARCH_W-1):0]	s_mat 		[0:NUM_MEASUR-1][0:NUM_MEASUR-1];
wire  [(ARCH_W-1):0] 	s_det_prod_1;
wire 					s_det_prod_1_over;
wire  [(ARCH_W-1):0] 	s_det_prod_2;
wire 					s_det_prod_2_over;
wire  [(ARCH_W-1):0] 	s_det;
wire  [(ARCH_W-1):0]	s_inv_tmp 	[0:NUM_MEASUR-1][0:NUM_MEASUR-1];
wire  [(ARCH_W-1):0]	s_inv_tmp2 	[0:NUM_MEASUR-1][0:NUM_MEASUR-1];
reg   [(ARCH_W-1):0]	s_inv 	 	[0:NUM_MEASUR-1][0:NUM_MEASUR-1];

// Optimal Kalman Gain 
wire  [(ARCH_W-1):0]	k_mat_mult	[0:NUM_STATES-1][0:NUM_MEASUR-1][0:NUM_MEASUR-1];
wire  [(ARCH_W-1):0]	k_mat_sum	[0:NUM_STATES-1][0:NUM_MEASUR-1];
reg   [(ARCH_W-1):0]	k_mat		[0:NUM_STATES-1][0:NUM_MEASUR-1];
wire  [(ARCH_W-1):0]	k_special   [0:NUM_STATES-1][0:NUM_STATES-1];

// Loops that get rolled out on compile time
genvar i, j, k;

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
		FSM_PREDICT_2 : fsm_next = FSM_INTERIM_1;
		FSM_INTERIM_1 : fsm_next = FSM_INTERIM_2;
		FSM_INTERIM_2 : fsm_next = FSM_DIVIDE;
		FSM_DIVIDE    : fsm_next = division_done ? FSM_INTERIM_3 : FSM_DIVIDE;
		FSM_INTERIM_3 : fsm_next = FSM_UPDATE;
		FSM_UPDATE    : fsm_next = FSM_IDLE;
		default       : fsm_next = FSM_INIT;
	endcase 
end

// FSM Helper Logic
assign ready 		 = (fsm_curr == FSM_IDLE);
assign fsm_clear_all = (fsm_curr == FSM_INIT);
assign fsm_clear_tmp = (fsm_curr == FSM_INIT) | (fsm_curr == FSM_IDLE);
assign division_done = division[0][0] & division[0][1] & division[1][0] & division[1][1];

///////////////////////////////// STATIC MATRICES AND VECTORS //////////////////////////////////

// Set x_init to zeros, and p_init and q_mat to identity. Set f_mat to identity with t_step.
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_vec_init
		assign x_init[i] = 'd0;
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_mat_init
			if (i == j) 
				begin
					assign p_init[i][j] = ONE_FI;
					assign q_mat[i][j] = ONE_FI;
					assign f_mat[i][j] = ONE_FI;
				end
			else if ((i == 0 & j == 2) | (i == 1 & j == 3))
				begin
					assign p_init[i][j] = 'd0;
					assign q_mat[i][j] = 'd0;
					assign f_mat[i][j] = TSTEP_FI;
				end
			else 
				begin
					assign p_init[i][j] ='d0;
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
			if (i == j)	assign r_mat[i][j] = RDIAG_FI;
			else		assign r_mat[i][j] = 'd0;
		end
	end
endgenerate

// Set k_special to the reconstruction of k_mat
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: k_special_gen_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: k_special_gen_cols
			if (j < 2)	assign k_special[i][j] = k_mat[i][j];
			else		assign k_special[i][j] = 'd0;
		end
	end 
endgenerate

//////////////////////////////// DYNAMIC MATRICES AND VECTORS //////////////////////////////////

// Measurement Vector - 2x1 vector latched when valid data arrives
always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 
		begin
			z_vec[0] <= 'd0;
			z_vec[1] <= 'd0;
		end
	// Latch values and scale to match x_next precision - put in fixed-point format
 	else if (ready & valid)
 		begin
 			z_vec[0] <= ('b0 << (ARCH_W-1)) | (z_x << ARCH_F) | 'b0;
 			z_vec[1] <= ('b0 << (ARCH_W-1)) | (z_y << ARCH_F) | 'b0;
 		end
 	else 
 		begin
 			z_vec[0] <= z_vec[0];
 			z_vec[1] <= z_vec[1];
 		end
end

// Next X Value - 4x4 matrix times a 4x1 vector
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_mult_modules_row
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_x_mult_modules_col
			qmult #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) mult_x_next (
		 		.i_multiplicand (f_mat[i][j]),
		 		.i_multiplier	(x_curr[j]),
		 		.o_result		(x_next_mult[i][j])
			);
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_add_modules
		qadd #(
			.Q 				(ARCH_F),
			.N 				(ARCH_W)
		) add_x_next1 (
			.a 				(x_next_mult[i][0]),
			.b 				(x_next_mult[i][1]),
			.c 				(x_next_sum1[i])
		);
		qadd #(
			.Q 				(ARCH_F),
			.N 				(ARCH_W)
		) add_x_next2 (
			.a 				(x_next_mult[i][2]),
			.b 				(x_next_mult[i][3]),
			.c 				(x_next_sum2[i])
		);
		qadd #(
			.Q 				(ARCH_F),
			.N 				(ARCH_W)
		) add_x_next3 (
			.a 				(x_next_sum1[i]),
			.b 				(x_next_sum2[i]),
			.c 				(x_next_sum3[i])
		);			
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_next
		always @(posedge clk) begin
			if (fsm_clear_tmp) 					x_next[i] <= 'd0;
			else if (fsm_curr == FSM_PREDICT_1)	x_next[i] <= x_next_sum3[i];
			else								x_next[i] <= x_next[i];
		end
	end
endgenerate

// Temp P Value - 4x4 matrix times a 4x4 matrix
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_temp_mult_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_temp_mult_cols
			for (k = 0; k < NUM_STATES; k = k + 1) begin: gen_p_temp_mult
				qmult #(
					.Q 				(ARCH_F),
					.N 				(ARCH_W)
				) mult_p_temp (
			 		.i_multiplicand (f_mat[i][k]),
			 		.i_multiplier	(p_curr[k][j]),
			 		.o_result		(p_temp_mult[i][j][k])
				);
			end
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_temp_add_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_temp_add_cols
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_temp1 (
				.a 				(p_temp_mult[i][j][0]),
				.b 				(p_temp_mult[i][j][1]),
				.c 				(p_temp_sum1[i][j])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_temp2 (
				.a 				(p_temp_mult[i][j][2]),
				.b 				(p_temp_mult[i][j][3]),
				.c 				(p_temp_sum2[i][j])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_temp3 (
				.a 				(p_temp_sum1[i][j]),
				.b 				(p_temp_sum2[i][j]),
				.c 				(p_temp_sum3[i][j])
			);			
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_temp_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_temp_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)		 			p_next_tmp[i][j] <= 'd0;
				else if (fsm_curr == FSM_PREDICT_1) p_next_tmp[i][j] <= p_temp_sum3[i][j];
				else								p_next_tmp[i][j] <= p_next_tmp[i][j];
			end
		end
	end
endgenerate

// Next P Value - 4x4 matrix times a 4x4 transposed matrix, plus a 4x4 matrix
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_next_mult_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_next_mult_cols
			for (k = 0; k < NUM_STATES; k = k + 1) begin: gen_p_next_mult
				qmult #(
					.Q 				(ARCH_F),
					.N 				(ARCH_W)
				) mult_p_next (
			 		.i_multiplicand (p_next_tmp[i][k]),
			 		// Notice the indices are flipped from the last mult b/c we want f_mat transpose here
			 		.i_multiplier	(f_mat[j][k]),
			 		.o_result		(p_next_mult[i][j][k])
				);
			end
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_next_add_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_next_add_cols
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_next1 (
				.a 				(p_next_mult[i][j][0]),
				.b 				(p_next_mult[i][j][1]),
				.c 				(p_next_sum1[i][j])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_next2 (
				.a 				(p_next_mult[i][j][2]),
				.b 				(p_next_mult[i][j][3]),
				.c 				(p_next_sum2[i][j])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_next3 (
				.a 				(p_next_sum1[i][j]),
				.b 				(p_next_sum2[i][j]),
				.c 				(p_next_sum3[i][j])
			);		
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_next4 (
				.a 				(p_next_sum3[i][j]),
				.b 				(q_mat[i][j]),
				.c 				(p_next_sum4[i][j])
			);							
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_next_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_next_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)		 			p_next[i][j] <= 'd0;
				else if (fsm_curr == FSM_PREDICT_2)	p_next[i][j] <= p_next_sum4[i][j];
				else								p_next[i][j] <= p_next[i][j];
			end
		end
	end
endgenerate

// Y Vector - 2x1 vector minus a 2x1 vector
generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_y_sub
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) sub_y_vec (
				.a 				(z_vec[i]),
				// Flip the sign bit to get subtraction (unless its zero)
				.b 				(~(|x_next[i]) ? x_next[i] : x_next[i] ^ FLIP_SIGN),
				.c 				(y_sub[i])
			);
	end
endgenerate

generate 
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_y_vec
		always @(posedge clk) begin
			if (fsm_clear_tmp)					y_vec[i] <= 'd0;
			else if (fsm_curr == FSM_INTERIM_1) y_vec[i] <= y_sub[i];
			else								y_vec[i] <= y_vec[i];
		end
	end
endgenerate

// S Matrix - 2x2 matrix (top left corner of p_next) plus the R matrix
generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_s_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_s_cols
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) s_mat_add (
				.a 				(p_next[i][j]),
				.b 				(r_mat[i][j]),
				.c  			(s_add[i][j])
			);
		end
	end
endgenerate

generate 
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_s_mat_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_s_mat_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)					s_mat[i][j] <= 'd0;
				else if (fsm_curr == FSM_INTERIM_1) s_mat[i][j] <= s_add[i][j];
				else								s_mat[i][j] <= s_mat[i][j];
			end
		end
	end
endgenerate

// Invert S - 2x2 matrix so swap positions, flip signs, and divide by determinant
qmult #(
	.Q 				(ARCH_F),
	.N 				(ARCH_W)
) det_product_1 (
		.i_multiplicand (s_mat[0][0]),
		.i_multiplier	(s_mat[1][1]),
		.o_result		(s_det_prod_1),
		.ovr 			(s_det_prod_1_over)		
);
qmult #(
	.Q 				(ARCH_F),
	.N 				(ARCH_W)
) det_product_2 (
		.i_multiplicand (s_mat[0][1]),
		.i_multiplier	(s_mat[1][0]),
		.o_result		(s_det_prod_2),
		.ovr 			(s_det_prod_2_over)
);
qadd #(
	.Q 				(ARCH_F),
	.N 				(ARCH_W)
) det_sub (
	.a 				(s_det_prod_1),
	// Flip the sign bit to get subtraction (unless its zero)
	.b 				(~(|s_det_prod_2) ? s_det_prod_2 : s_det_prod_2 ^ FLIP_SIGN),
	.c  			(s_det)
);

assign s_inv_tmp[0][0] = s_mat[1][1];
assign s_inv_tmp[1][1] = s_mat[0][0];
assign s_inv_tmp[0][1] = ~(|s_mat[0][1]) ? s_mat[0][1] : s_mat[0][1] ^ FLIP_SIGN;
assign s_inv_tmp[1][0] = ~(|s_mat[1][0]) ? s_mat[1][0] : s_mat[1][0] ^ FLIP_SIGN;

generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: s_inv_tmp_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: s_inv_tmp_cols
		qdiv#(
			.Q 			(ARCH_F),
			.N 			(ARCH_W)
		) s_inv_div (
			// Input Control
			.i_clk      	(clk),
			.i_start 		(fsm_curr == FSM_INTERIM_2),

			// Input Data
			.i_dividend 	(s_inv_tmp[i][j]),
			.i_divisor  	(s_det),

			// Output Control
			.o_complete		(division[i][j]),

			// Output Data
			.o_quotient_out (s_inv_tmp2[i][j])

		);
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: s_inv_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: s_inv_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp) 									s_inv[i][j] <= 'd0;
				else if ((fsm_curr == FSM_DIVIDE) & division_done)  s_inv[i][j] <= s_inv_tmp2[i][j];
				else 												s_inv[i][j] <= s_inv[i][j];
			end
		end
	end
endgenerate

// K Matrix - 4x2 matrix (left half of p_next) times a 2x2 matrix (s inverse)
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_k_mult_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_k_mult_cols
			for (k = 0; k < NUM_MEASUR; k = k + 1) begin: gen_k_mult
				qmult #(
					.Q 				(ARCH_F),
					.N 				(ARCH_W)
				) mult_k (
			 		.i_multiplicand (p_next[i][k]),
			 		.i_multiplier	(s_inv[k][j]),
			 		.o_result		(k_mat_mult[i][j][k])
				);
			end
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_k_add_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_k_add_cols
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_k (
				.a 				(k_mat_mult[i][j][0]),
				.b 				(k_mat_mult[i][j][1]),
				.c 				(k_mat_sum[i][j])
			);
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_k_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: gen_k_cols
			always @(posedge clk) begin
				if (fsm_clear_tmp)		 			k_mat[i][j] <= 'd0;
				else if (fsm_curr == FSM_INTERIM_3) k_mat[i][j] <= k_mat_sum[i][j];
				else								k_mat[i][j] <= k_mat[i][j];
			end
		end
	end
endgenerate

// Current X Value - 4x2 matrix times a 2x2 matrix plus a 4x1 vector
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: x_curr_mult_gen_rows
		for (j = 0; j < NUM_MEASUR; j = j + 1) begin: x_curr_mult_gen_cols
			qmult #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) mult_x_curr (
		 		.i_multiplicand (k_mat[i][j]),
		 		.i_multiplier	(y_vec[j]),
		 		.o_result		(x_curr_mult[i][j])
			);			
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: x_curr_sum_gen
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) sum_x_curr1 (
				.a 				(x_curr_mult[i][0]),
				.b 				(x_curr_mult[i][1]),
				.c 				(x_curr_sum1[i])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) sum_x_curr2 (
				.a 				(x_next[i]),
				.b 				(x_curr_sum1[i]),
				.c 				(x_curr_sum2[i])
			);		
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_curr
		always @(posedge clk) begin
			// Hold value between iterations
			if (fsm_clear_all)		 			x_curr[i] <= x_init[i];
			else if (fsm_curr == FSM_UPDATE)	x_curr[i] <= x_curr_sum2[i];
			else 								x_curr[i] <= x_curr[i];
		end
	end
endgenerate

// Current P Value - 4x4 identity minus a 4x4 reconstruction of k_mat, multiplied by p_next
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: p_curr_diff_gen_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: p_curr_diff_gen_cols
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) diff_p_curr (
				// Since p_init is the 4x4 identity we can use it here instead of making a new identity
				.a 				(p_init[i][j]),
				// Flip sign to get subtraction (unless its zero)
				.b 				(~(|k_special[i][j]) ? k_special[i][j] : k_special[i][j] ^ FLIP_SIGN),
				.c 				(p_curr_diff[i][j])
			);
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_curr_mult_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_curr_mult_cols
			for (k = 0; k < NUM_STATES; k = k + 1) begin: gen_p_curr_mult
				qmult #(
					.Q 				(ARCH_F),
					.N 				(ARCH_W)
				) mult_p_curr (
			 		.i_multiplicand (p_curr_diff[i][k]),
			 		.i_multiplier	(p_next[k][j]),
			 		.o_result		(p_curr_mult[i][j][k])
				);
			end
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_curr_sum_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_curr_sum_cols
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_curr1 (
				.a 				(p_curr_mult[i][j][0]),
				.b 				(p_curr_mult[i][j][1]),
				.c 				(p_curr_sum1[i][j])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_curr2 (
				.a 				(p_curr_mult[i][j][2]),
				.b 				(p_curr_mult[i][j][3]),
				.c 				(p_curr_sum2[i][j])
			);
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) add_p_curr3 (
				.a 				(p_curr_sum1[i][j]),
				.b 				(p_curr_sum2[i][j]),
				.c 				(p_curr_sum3[i][j])
			);			
		end
	end
endgenerate

generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_curr_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_curr_cols
			always @(posedge clk) begin
				// Hold value between iterations
				if (fsm_clear_all)		 			p_curr[i][j] <= p_init[i][j];
				else if (fsm_curr == FSM_UPDATE) 	p_curr[i][j] <= p_curr_sum3[i][j];
				else								p_curr[i][j] <= p_curr[i][j];
			end
		end
	end
endgenerate

// Generate Outputs
assign z_x_new_int = x_curr[0];
assign z_y_new_int = x_curr[1];
assign z_x_new = z_x_new_int[(ARCH_F+DISP_WIDTH):ARCH_F];
assign z_y_new = z_y_new_int[(ARCH_F+DISP_WIDTH):ARCH_F];

endmodule
