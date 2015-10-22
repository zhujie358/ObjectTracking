////////////////////////////////////////////////////////////////////////////////////////////
// File:   kalman.v
// Author: B. Brown, T. Dotsikas
// About:  Hardware implementation of Kalman filter equations.
////////////////////////////////////////////////////////////////////////////////////////////

module kalman #(
	parameter DISP_WIDTH  = 11
)(
	input wire 						clk,
	input wire 						aresetn,

	input wire  [(DISP_WIDTH-1):0]	z_x,
	input wire  [(DISP_WIDTH-1):0]	z_y,
	input wire 						valid,

	output wire [(DISP_WIDTH-1):0]	z_x_new,
	output wire [(DISP_WIDTH-1):0]	z_y_new
);

////////////////////////////////////// PARAMETERS //////////////////////////////////////////////

// Finite State Machine
localparam FSM_WIDTH 	 = 3;
localparam FSM_IDLE      = 0;
localparam FSM_PREDICT_1 = 1;
localparam FSM_PREDICT_2 = 2;
localparam FSM_INTERM_1  = 3;
localparam FSM_INTERM_2  = 4;
localparam FSM_INTERM_3  = 5;
localparam FSM_UPDATE    = 6;

// Architecture
localparam ARCH_W 		= 31;

// Kalman State Space
localparam NUM_STATES 	= 4;
localparam NUM_MEASUR 	= 2;

/////////////////////////////// INTERNAL SIGNALS & VARIABLES ///////////////////////////////////

// Finite State Machine
reg [(FSM_WIDTH-1):0]	fsm_curr;
reg [(FSM_WIDTH-1):0]	fsm_next;

// Static Matrices
wire [(ARCH_W-1):0] 	f_mat 	   [NUM_STATES][NUM_STATES];
wire [(ARCH_W-1):0]		q_mat 	   [NUM_STATES][NUM_STATES];
wire [(ARCH_W-1):0] 	r_mat 	   [NUM_MEASUR][NUM_MEASUR];
wire [(ARCH_W-1):0] 	h_mat 	   [NUM_MEASUR][NUM_STATES];

// Dynamic Matrices and Vectors
reg  [(ARCH_W-1):0]		x_curr 	   [NUM_STATES];
reg  [(ARCH_W-1):0]		x_next 	   [NUM_STATES];
reg  [(ARCH_W-1):0]		p_curr 	   [NUM_STATES][NUM_STATES];
reg  [(ARCH_W-1):0]		p_next_tmp [NUM_STATES][NUM_STATES];
reg  [(ARCH_W-1):0]		p_next 	   [NUM_STATES][NUM_STATES];

reg  [(ARCH_W-1):0] 	y_vec	   [NUM_MEASUR];
reg  [(ARCH_W-1):0]		k_mat 	   [NUM_STATES][NUM_MEASUR];

// Loops that get rolled out on compile time
genvar i, j;

////////////////////////////////// FINITE STATE MACHINE ////////////////////////////////////////

// FSM Current States
always @(posedge clk or negedge aresetn) begin
	if (~aresetn)	fsm_curr <= FSM_IDLE;
	else			fsm_curr <= fsm_next;
end

// FSM Next States
always @* begin
	case(fsm_curr)

	FSM_IDLE 	  : fsm_next = valid ? FSM_PREDICT_1 : FSM_IDLE;
	FSM_PREDICT_1 : fsm_next = FSM_PREDICT_2;
	FSM_PREDICT_2 : fsm_next = FSM_INTERM_1;
	FSM_INTERM_1  : fsm_next = FSM_INTERM_2;
	FSM_INTERM_2  : fsm_next = FSM_INTERM_3;
	FSM_INTERM_3  : fsm_next = FSM_UPDATE;
	FSM_UPDATE    : fsm_next = FSM_PREDICT_1;
	default       : fsm_next = FSM_IDLE;

	endcase 
end

///////////////////////////////// STATIC MATRICES AND VECTORS //////////////////////////////////



//////////////////////////////// DYNAMIC MATRICES AND VECTORS //////////////////////////////////

// Next X Value
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_next
		always @(posedge clk or negedge aresetn) begin
			if (fsm_curr == FSM_IDLE) 			x_next[i] <= 'd0;
			else if (fsm_curr == FSM_PREDICT_1)	x_next[i] <= f_mat[i][0]*x_curr[0] + f_mat[i][1]*x_curr[1] + f_mat[i][2]*x_curr[2] + f_mat[i][3]*x_curr[3];
			else								x_next[i] <= x_next[i];
		end
	end
endgenerate

// Temp P Value
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_temp_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_temp_cols
			always @(posedge clk or negedge aresetn) begin
				if (fsm_curr == FSM_IDLE) 			p_next_tmp[i][j] <= 'd0;
				else if (fsm_curr == FSM_PREDICT_1) p_next_tmp[i][j] <= // TODO: Verify the equation
				else								p_next_tmp[i][j] <= 'd0;
			end
		end
	end
endgenerate

// Next P Value
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_p_next_rows
		for (j = 0; j < NUM_STATES; j = j + 1) begin: gen_p_next_cols
			always @(posedge clk or negedge aresetn) begin
				if (fsm_curr == FSM_IDLE) 			p_next[i][j] <= 'd0;
				else if (fsm_curr == FSM_PREDICT_2)	p_next[i][j] <= // TODO: Verify the equation
				else								p_next[i][j] <= 'd0;
			end
		end
	end
endgenerate

// TODO: The rest of the code

// Current X Value
generate
	for (i = 0; i < NUM_STATES; i = i + 1) begin: gen_x_curr
		always @(posedge clk or negedge aresetn) begin
			if (fsm_curr == FSM_IDLE) 			x_curr[i] <= 'd0;
			else if (fsm_curr == FSM_UPDATE)	x_curr[i] <= x_next[i] + (k_mat[i][0]*y_vec[0] + k_mat[i][1]*y_vec[1]);
			else 								x_curr[i] <= x_curr[i];
		end
	end
endgenerate


endmodule