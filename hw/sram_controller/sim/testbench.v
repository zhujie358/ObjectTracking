`timescale 1ns/1ns

module testbench();

reg clk;
reg rst; 

always 
	#5 clk = ~clk;

initial begin
	clk 	= 0;
	rst 	= 1;

	#10;

	rst     = 0;

	#200;

	$stop;
end

// Add modules here

endmodule 