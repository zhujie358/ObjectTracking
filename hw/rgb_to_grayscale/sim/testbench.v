`timescale 1ns/1ns

module testbench();

reg  clk;
reg  rst; 
reg  v_in;
wire  v_out;

wire [11:0] grayscale1;
wire [4:0]  red1;
wire [5:0]  green1;
wire [4:0]  blue1;

always 
	#5 clk = ~clk;

initial begin
	clk 	= 0;
	rst 	= 1;
	v_in 	= 1;


	#10;

	rst     = 0;

	#200;

	$stop;
end

assign	red1 	= 30;
assign	green1  = 50;
assign	blue1 	= 30;

// Add modules here
rgb_to_grayscale my_rgb_to_grayscale
(
	.clk		(clk),
	.RED		(red1),
	.GREEN  	(green1),
	.BLUE 		(blue1),
	.GRAYSCALE 	(grayscale1),

	.valid_in 	(v_in),
	.valid_out  (v_out),
	.aresetn 	(~rst)

);

endmodule 