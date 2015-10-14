////////////////////////////////////////////////////////////////
// File:   measure_position.v
// Author: T. Dotsikas, B. Brown
// About:  Locate center (x,y) position of object
////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module measure_position #(
	parameter INPUT_WIDTH = 11,
	parameter COLOR_WIDTH = 10,
	parameter FRAME_X_MAX = 640,
	parameter FRAME_Y_MAX = 480
)(	//////////// CLOCK //////////
	input 		          					clk,

	//////////// DATA ///////////
	input wire		[(INPUT_WIDTH-1):0]		vga_x,
	input wire		[(INPUT_WIDTH-1):0]		vga_y,
	input wire 		[(COLOR_WIDTH-1):0]		delta_frame,

	output wire		[(INPUT_WIDTH-1):0]		x_position,
	output wire		[(INPUT_WIDTH-1):0]		y_position,

	//////////// CONTROL ///////////
	input wire								aresetn,
	input wire								enable
);

// Internal Signals (widths determined based on max x and y values)
reg [18:0]				total_count;
reg [26:0] 				x_coordinate_sum;
reg [26:0]		   		y_coordinate_sum;

// Wrappers
reg [(INPUT_WIDTH-1):0]	int_x_position;
reg [(INPUT_WIDTH-1):0]	int_y_position;
assign x_position     = int_x_position;
assign y_position 	  = int_y_position;

// These are the three values used in the algorithm
always @(posedge clk or negedge aresetn) begin
	// Reset 
	if (~aresetn) 	
		begin
			total_count 	 <= 'd0;
			x_coordinate_sum <= 'd0;
			y_coordinate_sum <= 'd0;
		end
	// Enable
	else if (~enable) 	
		begin
			total_count 	 <= 'd0;
			x_coordinate_sum <= 'd0;
			y_coordinate_sum <= 'd0;
		end		
	// Clear at end of frame
	else if (vga_x == FRAME_X_MAX & vga_y == FRAME_Y_MAX)
		begin
			total_count		 <= 'd0;
			x_coordinate_sum <= 'd0;
			y_coordinate_sum <= 'd0;
		end		
	// Check if all bits are 1, if so apply algorithm
	else if (&delta_frame)
		begin
			total_count		 <= total_count + 1;
			x_coordinate_sum <= x_coordinate_sum + vga_x;
			y_coordinate_sum <= y_coordinate_sum + vga_y;
		end
	// Otherwise latch the values
	else 
		begin
			total_count 	 <= total_count;
			x_coordinate_sum <= x_coordinate_sum;
			y_coordinate_sum <= y_coordinate_sum;
		end
end

// Generate the algorithm result using the above values
always @(posedge clk or negedge aresetn) begin
	// Reset
	if (~aresetn)
		begin
			int_x_position      <= 'd0;
			int_y_position      <= 'd0;
		end	
	// Enable
	else if (~enable)
		begin
			int_x_position 	    <= 'd0;
			int_y_position 	    <= 'd0;		
		end
	// Pulse result at end of frame
	else if (vga_x == FRAME_X_MAX & vga_y == FRAME_Y_MAX)
		begin
			int_x_position 	    <= x_coordinate_sum / total_count; 
			int_y_position 	    <= y_coordinate_sum / total_count;
		end
	else 
		begin
			int_x_position 		<= int_x_position;
			int_y_position 		<= int_y_position;
		end
end

endmodule
