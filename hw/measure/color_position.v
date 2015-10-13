//////////////////////////////////////////////////////////////////////////////////////////////
// File:   color_position.v
// Author: B. Brown, T. Dotsikas
// About:  Colors a point on the display red if it is near the object.
//////////////////////////////////////////////////////////////////////////////////////////////

module color_position # (
	parameter COLOR_WIDTH = 10,
	parameter DISP_WIDTH  = 11
)(
	input wire clk, 
	input wire aresetn,

	input wire [(COLOR_WIDTH-1):0] red,
	input wire [(COLOR_WIDTH-1):0] green,
	input wire [(COLOR_WIDTH-1):0] blue,

	input wire [(DISP_WIDTH-1):0] x_pos,
	input wire [(DISP_WIDTH-1):0] y_pos,

	input wire [(DISP_WIDTH-1):0] x_obj,
	input wire [(DISP_WIDTH-1):0] y_obj,

	output wire [(COLOR_WIDTH-1):0] r_out,
	output wire [(COLOR_WIDTH-1):0] g_out,
	output wire [(COLOR_WIDTH-1):0] b_out
);

// Internal Parameters
localparam THRESHOLD = 3;

// Internal Signals
wire 					vga_is_object;
wire [(DISP_WIDTH-1):0] x_diff;
wire [(DISP_WIDTH-1):0] y_diff;
reg [(COLOR_WIDTH-1):0] int_r_out;
reg [(COLOR_WIDTH-1):0] int_g_out;
reg [(COLOR_WIDTH-1):0] int_b_out;

assign r_out = int_r_out;
assign g_out = int_g_out;
assign b_out = int_b_out;

// Logic
assign x_diff		 = (x_pos > x_obj) ? x_pos - x_obj : x_obj - x_pos;
assign y_diff		 = (y_pos > y_obj) ? y_pos - y_obj : y_obj - y_pos;
assign vga_is_object = (x_diff < THRESHOLD) & (y_diff < THRESHOLD);


// Drive RGB to red if the above point is near the object
always @(posedge clk or negedge aresetn) begin

	if (~aresetn)
		begin

		end
	else if (vga_is_object)
		begin
			int_r_out <= {COLOR_WIDTH {1'b1}};
			int_g_out <= {COLOR_WIDTH {1'b0}};
			int_b_out <= {COLOR_WIDTH {1'b0}};
		end
	else
		begin
			int_r_out <= red;
			int_g_out <= green;
			int_b_out <= blue;
		end
end

endmodule