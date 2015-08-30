
//=======================================================
//  Ports generated by Terasic System Builder
//=======================================================

module vid_io_demo(

	//////////// CLOCK //////////
	input 		          		CLOCK_50,
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,

	//////////// LED //////////
	output		     [8:0]		LEDG,
	output		    [17:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// VGA //////////
	output		     [7:0]		VGA_B,
	output		          		VGA_BLANK_N,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS,

	//////////// I2C for Tv-Decoder  //////////
	output		          		I2C_SCLK,
	inout 		          		I2C_SDAT,

	//////////// TV Decoder //////////
	input 		          		TD_CLK27,
	input 		     [7:0]		TD_DATA,
	input 		          		TD_HS,
	output		          		TD_RESET_N,
	input 		          		TD_VS,

	//////////// SDRAM //////////
	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [31:0]		DRAM_DQ,
	output		     [3:0]		DRAM_DQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_WE_N
);

//Global Reset
wire aresetn;

//YCbCr to RGB results
wire [7:0] R_to_output;
wire [7:0] B_to_output;
wire [7:0] G_to_output;

//Rightmost key is global reset, other keys unused
assign aresetn = KEY[0:0];

//Test minor changes to vga_sync
assign R_to_output = 'd0;
assign B_to_output = 'd0;
assign G_to_output = 'd255;

vga_sync
(

	//Control Signals
	.clock (CLOCK_50),
	.aresetn(aresetn),
	
	//YCbCr to RGB results
	.R_in (R_to_output),
	.B_in (B_to_output),
	.G_in (G_to_output),
	
	//VGA Signals
	.vga_clk(VGA_CLK),
	.R (VGA_R),
	.G (VGA_G),
	.B (VGA_B),
	.h_sync(VGA_HS),
	.v_sync(VGA_VS),
	.blank_n(VGA_BLANK_N),
	.sync_n(VGA_SYNC_N)
);

endmodule