//////////////////////////////////////////////////////////////////////////////////////////////
// File:   delta_frame.v
// Author: B. Brown, T. Dotsikas
// About:  Produces the delta frame using grayscale pixels from two different frames.
//////////////////////////////////////////////////////////////////////////////////////////////

module delta_frame #(
	parameter INPUT_WIDTH = 10,
	parameter DISP_WIDTH  = 11
)(
	// Control
	input wire 						clk,
	input wire 						aresetn,

	// Moving Average Filter
	input wire 						is_not_blank,

	// Position hack for left side problem
	input wire [(DISP_WIDTH-1):0]	x_pos,

	// Saturation Filter
	input wire [(INPUT_WIDTH-1):0]	threshold, 

	// Input Data
	input wire [(INPUT_WIDTH-1):0]	base_frame,
	input wire [(INPUT_WIDTH-1):0]	curr_frame,

	// Output Data
	output wire [(INPUT_WIDTH-1):0]	delta_frame
);

// Moving Average Filter
localparam FILTER_LENGTH = 5;

// Position hack for left side problem
localparam POS_MAX 		 = 620;

// Internal Delta Result
reg  [(INPUT_WIDTH-1):0] int_delta_frame;

// Moving Average Filter
reg  [2:0] 				 counter;
reg  [(INPUT_WIDTH-1):0] old_0;
reg  [(INPUT_WIDTH-1):0] old_1;
reg  [(INPUT_WIDTH-1):0] old_2;
reg  [(INPUT_WIDTH-1):0] old_3;
reg  [(INPUT_WIDTH-1):0] old_4;
wire [(INPUT_WIDTH+1):0] sum;
wire [(INPUT_WIDTH+1):0] avg;

// Saturation Filter
assign delta_frame = ((avg[(INPUT_WIDTH-1):0] > threshold) ? {INPUT_WIDTH{1'b1}} : {INPUT_WIDTH{1'b0}});

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 							int_delta_frame <= 'd0;
	else if (x_pos > POS_MAX)				int_delta_frame <= 'd0;
	else
		begin
			// Poor man's absolute value
			if (curr_frame > base_frame)	int_delta_frame <= curr_frame - base_frame;
			else 							int_delta_frame <= base_frame - curr_frame;
		end
end


// Moving Average Filter

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 						counter <= 'd0;
	else if (~is_not_blank)				counter <= counter;
	else if (counter == FILTER_LENGTH)	counter <= 'd0;
	else 		  						counter <= counter + 1;
end

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 
		begin
			old_0 <= 'd0;
			old_1 <= 'd0;
			old_2 <= 'd0;
			old_3 <= 'd0;
			old_4 <= 'd0;
		end
	else if (counter == 0)
		begin
			old_0 <= int_delta_frame;
			old_1 <= old_1;
			old_2 <= old_2;
			old_3 <= old_3;
			old_4 <= old_4;
		end
	else if (counter == 1)
		begin
			old_0 <= old_0;
			old_1 <= int_delta_frame;
			old_2 <= old_2;
			old_3 <= old_3;
			old_4 <= old_4;
		end
	else if (counter == 2)
		begin
			old_0 <= old_0;
			old_1 <= old_1;
			old_2 <= int_delta_frame;
			old_3 <= old_3;
			old_4 <= old_4;
		end
	else if (counter == 3)
		begin
			old_0 <= old_0;
			old_1 <= old_1;
			old_2 <= old_2;
			old_3 <= int_delta_frame;
			old_4 <= old_4;
		end				
	else if (counter == 4)
		begin
			old_0 <= old_0;
			old_1 <= old_1;
			old_2 <= old_2;
			old_3 <= old_3;
			old_4 <= int_delta_frame;
		end		
	else 
		begin
			old_0 <= old_0;
			old_1 <= old_1;
			old_2 <= old_2;
			old_3 <= old_3;
			old_4 <= old_4;
		end
end

assign sum = old_0 + old_1 + old_2 + old_3 + old_4;

delta_divide moving_avg_div
(
	.aclr		(1'b0),
	.clock		(clk),
	.denom		(FILTER_LENGTH),
	.numer		(sum),
	.quotient	(avg),
);

endmodule