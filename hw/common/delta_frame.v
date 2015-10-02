//////////////////////////////////////////////////////////////////////////////////////////////
// File:   delta_frame.v
// Author: B. Brown, T. Dotsikas
// About:  Produces the delta frame using grayscale pixels from two different frames.
//////////////////////////////////////////////////////////////////////////////////////////////

module delta_frame #(
	parameter INPUT_WIDTH = 10
)(
	// Control
	input wire 						clk,
	input wire 						aresetn,
	input wire 						enable,

	input wire [(INPUT_WIDTH-1):0]	threshold,

	// Input Data
	input wire [(INPUT_WIDTH-1):0]	base_frame,
	input wire [(INPUT_WIDTH-1):0]	curr_frame,

	// Output Data
	output wire [(INPUT_WIDTH-1):0]	delta_frame
);

// Internal Signals
reg [(INPUT_WIDTH-1):0] int_delta_frame;

// Wrapper for the register
assign delta_frame = enable ? ((int_delta_frame > threshold) ? {INPUT_WIDTH{1'b1}} : {INPUT_WIDTH{1'b0}}) : int_delta_frame;

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 							int_delta_frame <= 'd0;
	// Only produce delta if enable is high
	else if (enable) 
		begin
			// Poor man's absolute value
			if (curr_frame > base_frame)	int_delta_frame <= curr_frame - base_frame;
			else 							int_delta_frame <= base_frame - curr_frame;
		end
	// Otherwise just pump the current frame through
	else 									int_delta_frame <= curr_frame;
end

endmodule