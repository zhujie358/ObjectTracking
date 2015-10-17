//////////////////////////////////////////////////////////////////////////////////////////////
// File:   delta_frame.v
// Author: B. Brown, T. Dotsikas
// About:  Produces the delta frame using grayscale pixels from two different frames.
//////////////////////////////////////////////////////////////////////////////////////////////

module delta_frame #(
	parameter INPUT_WIDTH   	  = 10,
	parameter FILTER_LENGTH 	  = 20,
	parameter CLOG2_FILTER_LENGTH = 5
)(
	// Control
	input wire 						clk,
	input wire 						aresetn,

	// Moving Average Filter
	input wire						is_filter,
	input wire 						is_not_blank,

	// Saturation Filter
	input wire [(INPUT_WIDTH-1):0]	threshold, 

	// Input Data
	input wire [(INPUT_WIDTH-1):0]	base_frame,
	input wire [(INPUT_WIDTH-1):0]	curr_frame,

	// Output Data
	output wire [(INPUT_WIDTH-1):0]	delta_frame
);

// Not totally sure if this is the right way, think its safe though
localparam SUM_LENGTH = CLOG2_FILTER_LENGTH + INPUT_WIDTH;

// Internal signals and variables
genvar 					 c;
integer 				 i;
reg  [2:0] 				 counter;
reg  [(INPUT_WIDTH-1):0] old [FILTER_LENGTH];
reg  [(SUM_LENGTH-1):0]  sum;
wire [(INPUT_WIDTH-1):0] avg;
reg  [(INPUT_WIDTH-1):0] int_delta_frame;
wire [(INPUT_WIDTH-1):0] comp_value;

// Saturation Filter
assign comp_value  = is_filter ? avg : int_delta_frame;
assign delta_frame = (comp_value > threshold) ? {INPUT_WIDTH{1'b1}} : {INPUT_WIDTH{1'b0}};

// Delta Frame
always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 							int_delta_frame <= 'd0;
	else if (~is_not_blank)					int_delta_frame <= 'd0;
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

generate 
	for (c = 0; c < FILTER_LENGTH; c = c + 1) begin: moving_avg_filter
		always @(posedge clk or negedge aresetn) begin
			if (~aresetn)			old[c] <= 'd0;
			else if (~is_not_blank)	old[c] <= 'd0;
			else if (counter == c)	old[c] <= int_delta_frame;
			else					old[c] <= old[c];
		end
	end
endgenerate

always @* begin
	sum = 'd0;
	for (i = 0; i < FILTER_LENGTH; i = i + 1)
		sum = sum + old[i];
end

assign avg = sum / FILTER_LENGTH;

endmodule