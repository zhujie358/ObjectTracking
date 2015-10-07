////////////////////////////////////////////////////////////////
// File:   rgb_to_grayscale.v
// Author: T. Dotsikas, B. Brown
// About:  Fixed point RGB to grayscale conversion.
////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module rgb_to_grayscale #(
	parameter rgb_width = 10
)(
	//////////// CLOCK //////////
	input 		          					clk,

	//////////// DATA ///////////
	input wire		    [(rgb_width-1):0]	RED,
	input wire			[(rgb_width-1):0]	GREEN,
	input wire			[(rgb_width-1):0]	BLUE,
	output wire 		[(rgb_width-1):0]	GRAYSCALE,

	//////////// CONTROL ///////////
	input									valid_in,
	input									aresetn,
	output									valid_out
);

// RGB-Grayscale Coefficients (See Wikipedia)
localparam frac_width  = 6;
localparam fixed_width = frac_width + rgb_width;
localparam red_coeff   = 13; // floor(.2126 << 6)
localparam green_coeff = 45; // floor(.7152 << 6)
localparam blue_coeff  = 4;  // floor(.0722 << 6)

// Internal signals
reg [(fixed_width-1):0] int_gray;
reg 	   			  	int_valid_out;

// Slice fractional portion of grayscale (i.e. rounding)
assign GRAYSCALE = int_gray[(fixed_width-1):frac_width];

// Wire to reg
assign valid_out = int_valid_out;

// Apply equation when valid data is available
always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 		int_gray <= 0;
	else if (valid_in)	int_gray <= red_coeff*RED + green_coeff*GREEN + blue_coeff*BLUE;
	else 				int_gray <= int_gray;
end

// Flop the valid signal
always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 	int_valid_out <= 0;
	else 			int_valid_out <= valid_in;
end

endmodule
