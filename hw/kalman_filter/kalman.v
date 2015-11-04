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
localparam FSM_WIDTH 	 = 3;
localparam FSM_INIT		 = 0;
localparam FSM_IDLE      = 1;
localparam FSM_PREDICT_1 = 2;
localparam FSM_PREDICT_2 = 3;
localparam FSM_INTERIM_1 = 4;
localparam FSM_UPDATE    = 5;

// Architecture
localparam ARCH_W 		= 32;
localparam ARCH_F 		= 15;

// Kalman State Space
localparam NUM_STATES 	= 4;
localparam NUM_MEASUR 	= 2;

// Fixed Point Values - sign | integer | fraction
localparam ONE_FI 		= ('b0 << (ARCH_W-1)) | ('b1 << (ARCH_W-ARCH_F-2)) | 'b0;
localparam TSTEP_FI 	= ('b0 << (ARCH_W-1)) | ('b0 << (ARCH_W-ARCH_F-2)) | 'b000000111111100;
localparam RDIAG_FI     = ('b0 << (ARCH_W-1)) | ('d1000 << (ARCH_W-ARCH_F-2)) | 'b0; 

/////////////////////////////// INTERNAL SIGNALS & VARIABLES ///////////////////////////////////

// Finite State Machine
reg  [(FSM_WIDTH-1):0]	fsm_curr;
reg  [(FSM_WIDTH-1):0]	fsm_next;
wire 					fsm_clear_all;
wire 					fsm_clear_tmp;

// Static Matrices
wire [(ARCH_W-1):0]		x_init	    [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		p_init	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0] 	f_mat 	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		q_mat 	    [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0] 	r_mat 	    [0:NUM_MEASUR-1][0:NUM_MEASUR-1];

// Measurement Vector
reg  [(ARCH_W)-1:0]		z_vec		[0:NUM_MEASUR-1];

// State Vector
reg  [(ARCH_W-1):0]		x_curr		[0:NUM_STATES-1];

reg  [(ARCH_W-1):0]		x_next 	    [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_mult [0:NUM_STATES-1][0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_sum1 [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_sum2 [0:NUM_STATES-1];
wire [(ARCH_W-1):0]		x_next_sum3 [0:NUM_STATES-1];

// Covariance Matrix
reg  [(ARCH_W-1):0]		p_curr		[0:NUM_STATES-1][0:NUM_STATES-1];

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
		FSM_INTERIM_1 : fsm_next = FSM_UPDATE;
		FSM_UPDATE    : fsm_next = FSM_IDLE;
		default       : fsm_next = FSM_INIT;
	endcase 
end

// FSM Helper Logic
assign ready 		 = (fsm_curr == FSM_IDLE);
assign fsm_clear_all = (fsm_curr == FSM_INIT);
assign fsm_clear_tmp = (fsm_curr == FSM_INIT) | (fsm_curr == FSM_IDLE);

///////////////////////////////// STATIC MATRICES AND VECTORS //////////////////////////////////

// Set x_init to zeros, and p_init and q_mat to identity. Set f_mat to identity with t_step.
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_vec_init
		assign x_init[i] = ONE_FI;
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
 			z_vec[0] <= ('b0 << (ARCH_W-1)) | (z_x << (ARCH_W-ARCH_F-2)) | 'b0;
 			z_vec[1] <= ('b0 << (ARCH_W-1)) | (z_y << (ARCH_W-ARCH_F-2)) | 'b0;
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
			else if (fsm_curr == FSM_PREDICT_1)	x_next[i] <= x_next_sum3[i];
			else								x_next[i] <= x_next[i];
		end
	end
endgenerate

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

// Temp P Value - 4x4 matrix times a 4x4 matrix
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

// Next P Value - 4x4 matrix times a 4x4 transposed matrix, plus a 4x4 matrix
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

// Y Vector - 2x1 vector minus a 2x1 vector
generate
	for (i = 0; i < NUM_MEASUR; i = i + 1) begin: gen_y_sub
			qadd #(
				.Q 				(ARCH_F),
				.N 				(ARCH_W)
			) sub_y_vec (
				.a 				(z_vec[i]),
				// Flip the sign bit to get subtraction
				.b 				(x_next[i] ^ {1'b1, {(ARCH_W-1){1'b0}}}),
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

// Current X Value - Set to predicted value for initial testing
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_curr
		always @(posedge clk) begin
			if (fsm_clear_all)		 			x_curr[i] <= x_init[i];
			else if (fsm_curr == FSM_UPDATE)	x_curr[i] <= x_next[i];
			else 								x_curr[i] <= x_curr[i];
		end
	end
endgenerate

// Current P Value - Set to predicted value for initial testing
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_curr_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_curr_cols
			always @(posedge clk) begin
				if (fsm_clear_all)		 			p_curr[i][j] <= p_init[i][j];
				else if (fsm_curr == FSM_UPDATE) 	p_curr[i][j] <= p_next[i][j];
				else								p_curr[i][j] <= p_curr[i][j];
			end
		end
	end
endgenerate

// Generate Outputs
wire [(ARCH_W-1):0] strange_1 = x_curr[0];
wire [(ARCH_W-1):0] strange_2 = x_curr[1];
assign z_x_new = strange_1[(ARCH_F+DISP_WIDTH):ARCH_F];
assign z_y_new = strange_2[(ARCH_F+DISP_WIDTH):ARCH_F];

endmodule