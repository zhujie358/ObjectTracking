`timescale 1ns/1ns

module rgb_to_grayscale(

	//////////// CLOCK //////////
	input 		          		clk,

	//////////// DATA ///////////
	input wire		    [4:0]		RED,
	input wire			[5:0]		GREEN,
	input wire			[4:0]		BLUE,
	output wire 		[11:0]		GRAYSCALE,

	//////////// CONTROL ///////////
	input						valid_in,
	input						aresetn,
	output						valid_out

);

//R: 31*14 = 434
//G: 63*46 = 2898
//B: 31*5 = 155
//SUM = 3487 = 12 BITS to hold the maximum value of the max rgb combination
localparam red_coeff   = 14;
localparam green_coeff = 46;
localparam blue_coeff  = 155; 

//=======================================================
//  REG/WIRE declarations
//=======================================================

reg [11:0] int_gray;
reg 	   int_valid_out;

assign GRAYSCALE = int_gray;
assign valid_out = int_valid_out;

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 	int_gray <= 0;
	else 			int_gray <= red_coeff*RED + green_coeff*GREEN + blue_coeff*BLUE;
end

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) 	int_valid_out <= 0;
	else 			int_valid_out <= valid_in;
end

endmodule
