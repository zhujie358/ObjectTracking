`timescale 1ns/1ns

module testbench();

reg clk;
reg rst_n; 

// Clock Generation
always 
	#5 clk = ~clk;

// Total Simulation Logic
initial begin
	clk 	= 0;
	rst_n 	= 0;

	#10;

	rst_n   = 1;

	#200;

	$stop;
end

endmodule 