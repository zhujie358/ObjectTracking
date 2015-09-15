`timescale 1ns/1ns

module testbench();

reg 					clk;
reg 					rst_n; 

// BRAM Signals: Test Basic Read and Write Sequences
reg 					wen;
reg 		[15:0] 		addr;
reg 		[15:0] 		din;
reg 		[15:0] 		dout;

// SRAM Signals: Observe in sim and check with datasheet
wire	    [19:0]		SRAM_ADDR;
wire		          	SRAM_CE_N;
wire		[15:0]		SRAM_DQ;
wire		          	SRAM_LB_N;
wire		          	SRAM_OE_N;
wire		          	SRAM_UB_N;
wire		          	SRAM_WE_N;


// Mailbox Used To Manage BRAM Signals
mailbox mb = new();
reg     mb_test;

always @(posedge clk) begin
	if (~rst_n) 
		begin
			addr <= 'd0;
			din  <= 'd0;
			wen  <= 'd0;
		end
	else 
		begin
			if(mb.try_peek(mb_test)) 
				begin
					wen <= 1'b1;
					mb.get(din);
					mb.get(addr);
				end
			else 
				begin
					addr <= 'd0;
					din  <= 'd0;
					wen  <= 'd0;
				end
		end
end

// Clock Generation
always 
	#5 clk = ~clk;

// Total Simulation Logic
initial begin
	// Packet 1
	mb.put(16'h600D);
	mb.put(16'hAAAA);

	// Packet 2
	mb.put(16'hBEEF);
	mb.put(16'hBBBB);

	// Packet 3
	mb.put(16'hBADD);
	mb.put(16'hCCCC);

	clk 	= 0;
	rst_n 	= 0;

	#10;

	rst_n   = 1;

	#200;

	$stop;
end

// SRAM Controller
sram_wrapper sram_wrapper_inst
(

	// Clock and Reset
	.clk 	 	(clk),
	.aresetn 	(rst_n),

	// Wrapper Signals
	.wen 		(wen),
	.addr 		({4'h0, addr}),
	.din		(din),
	.dout 		(dout),

	// SRAM Signals
	.SRAM_ADDR 	(SRAM_ADDR),
	.SRAM_CE_N 	(SRAM_CE_N),
	.SRAM_DQ   	(SRAM_DQ),
	.SRAM_LB_N 	(SRAM_LB_N),
	.SRAM_OE_N 	(SRAM_OE_N),
	.SRAM_UB_N 	(SRAM_UB_N),
	.SRAM_WE_N 	(SRAM_WE_N)

);

endmodule 