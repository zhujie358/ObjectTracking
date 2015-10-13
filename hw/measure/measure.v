////////////////////////////////////////////////////////////////
// File:   measure.v
// Author: T. Dotsikas, B. Brown
// About:  Locate center (x,y) position of object
////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module measure #(
	parameter INPUT_WIDTH = 11,
	parameter COLOR_WIDTH = 10
)(	//////////// CLOCK //////////
	input 		          					clk,

	//////////// DATA ///////////
	input wire 		[(COLOR_WIDTH-1):0]		delta_frame,
	output wire		[26:0]					x_position,
	output wire		[26:0]					y_position,

	//////////// CONTROL ///////////
	input wire								aresetn,
	output wire								valid_position
);

reg [18:0]					total_count; //Total object pixels identified
reg [26:0] 					x_coordinate_sum;
reg [26:0]		   			y_coordinate_sum;
reg	[(INPUT_WIDTH-1):0]		x_counter; //Keep Track of what x value comes in
reg [(INPUT_WIDTH-1):0]		y_counter; //Keep track of what y value comes in

//Internal Coordinates
reg [26:0]					int_x_position;
reg [26:0]					int_y_position;
reg 						int_valid_position;

assign x_position = int_x_position; //Have to get rid of some bits
assign y_position = int_y_position;
assign valid_position = int_valid_position;

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 	
		begin
			total_count <= 'd0;
			x_coordinate_sum <= 'd0;
			y_coordinate_sum <= 'd0;
		end
	else if (&delta_frame)
		begin
			total_count <= total_count + 1;
			x_coordinate_sum <= x_counter + x_coordinate_sum;
			y_coordinate_sum <= y_counter + y_coordinate_sum;
		end
	else 
		begin
			total_count <= total_count;
			x_coordinate_sum <= x_coordinate_sum;
			y_coordinate_sum <= y_coordinate_sum;
		end
end

always @(posedge clk or negedge aresetn) begin
	if (~aresetn)
		begin
			int_x_position <= 'd0;
			int_y_position <= 'd0;
		end	
	else if (x_counter == 640 && y_counter == 480)
		begin
			int_valid_position <= 1;
			int_x_position <= x_coordinate_sum/total_count; 
			int_y_position <= y_coordinate_sum/total_count;
		end
	else 
		begin
			int_valid_position <= 0;
			int_x_position <= int_x_position;
			int_y_position <= int_y_position;
		end
end

always @(posedge clk or negedge aresetn) begin
	if (~aresetn)
		begin
			x_counter <= 'd0;
			y_counter <= 'd0;
		end
	else if (x_counter == 641)
		begin
			x_counter <= 'd0;
			y_counter <= y_counter + 1;
		end
	else 
		begin
			x_counter <= x_counter;
			y_counter <= y_counter;
		end

	x_counter <= x_counter + 1; 
end
endmodule
