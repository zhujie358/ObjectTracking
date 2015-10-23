`timescale 1ns/1ns

module testbench();

localparam DISP_WIDTH = 11;

reg clk;
reg rst_n; 
reg [(DISP_WIDTH-1):0] x_pos;
reg [(DISP_WIDTH-1):0] y_pos;
reg 				   valid;
reg					   ready;
reg [(DISP_WIDTH-1):0] x_res;
reg [(DISP_WIDTH-1):0] y_res;

integer c;

// Mailbox Used To Manage (x,y) Packets
mailbox mb = new();
reg     mb_test;

always @(posedge clk) begin
	if (~rst_n) 
		begin
			x_pos  <= 'd0;
			y_pos  <= 'd0;
			valid  <= 'd0;
		end
	else 
		begin
			if(mb.try_peek(mb_test) & ready) 
				begin
					mb.get(x_pos);
					mb.get(y_pos);					
					valid <= 1'b1;
				end
			else 
				begin
					x_pos  <= 'd0;
					y_pos  <= 'd0;
					valid  <= 'd0;
				end
		end
end

// Clock Generation
always
	#5 clk = ~clk;

// Total Simulation Logic
initial begin
	clk 	= 0;
	rst_n 	= 0;

	#10;

	rst_n   = 1;
 
	for (c = 0; c < 10; c = c + 1) begin: gen_loop
		mb.put('d370);
		mb.put('d350);
		#150;
	end

	$stop;
end

kalman # (
	.DISP_WIDTH(DISP_WIDTH)
) myKalman (
	.clk 		(clk),
	.aresetn	(rst_n),
	.z_x		(x_pos),
	.z_y		(y_pos),
	.valid		(valid),
	.ready 		(ready),
	.z_x_new    (x_res),
	.z_y_new 	(y_res)
);

endmodule 