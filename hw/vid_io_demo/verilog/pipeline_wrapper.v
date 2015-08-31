////////////////////////////////////////////////////////////////
// File:   pipeline_wrapper.v
// Author: Terasic, modified by BBB
// Source: DE2_115_TV.v
// About:  Gutted the original file to determine bare minimum
// 		   needed to perform video input/output on DE2 board.
//		   Also modified syntax and simplified some modules.
////////////////////////////////////////////////////////////////

module pipeline_wrapper
(
		input wire 			clk,
		input wire 			aresetn,

		//////// VGA //////////
		output wire [7:0]	VGA_B,
		output wire 		VGA_BLANK_N,
		output wire 		VGA_CLK,
		output wire [7:0]	VGA_G,
		output wire 		VGA_HS,
		output wire [7:0] 	VGA_R,
		output wire 		VGA_SYNC_N,
		output wire 		VGA_VS,

		//////// TV Decoder //////////
		input wire 			TD_CLK27,
		input wire  [7:0]	TD_DATA,
		input wire 			TD_HS,
		output wire 		TD_RESET_N,
		input wire 			TD_VS,

		//////// SDRAM //////////
		output wire [12:0] 	DRAM_ADDR,
		output wire [1:0] 	DRAM_BA,
		output wire 		DRAM_CAS_N,
		output wire 		DRAM_CKE,
		output wire 		DRAM_CLK,
		output wire 		DRAM_CS_N,
		inout  wire [31:0]	DRAM_DQ,
		output wire [3:0] 	DRAM_DQM,
		output wire 		DRAM_RAS_N,
		output wire 		DRAM_WE_N
);

// Cascade Resets
wire			true_reset;
wire			true_reset0_n;
wire			true_reset1_n;
wire			true_reset2_n;

// ITU-R 656 Decoder
wire	[15:0]	YCbCr;
wire			YCbCr_valid;
wire	[9:0]	decoder_x;

// Down Sample
wire	[3:0]	Remain;
wire	[9:0]	Quotient;

// For VGA Controller
wire	[9:0]	mRed;
wire	[9:0]	mGreen;
wire	[9:0]	mBlue;
wire	[10:0]	vga_x;
wire	[10:0]	vga_y;
wire			VGA_Read;	//	VGA data request
wire			m1VGA_Read;	//	Read odd field
wire			m2VGA_Read;	//	Read even field

// For YUV 4:2:2 to YUV 4:4:4
wire	[7:0]	mY;
wire	[7:0]	mCb;
wire	[7:0]	mCr;

//VGA Controller
wire 	[9:0] 	vga_r10;
wire 	[9:0] 	vga_g10;
wire 	[9:0] 	vga_b10;

// For field select
wire	[15:0]	mYCbCr;
wire	[15:0]	mYCbCr_d;
wire	[15:0]	m1YCbCr;
wire	[15:0]	m2YCbCr;
wire	[15:0]	m3YCbCr;

wire			mDVAL;

wire	[15:0]	m4YCbCr;
wire	[15:0]	m5YCbCr;
wire	[8:0]	Tmp1,Tmp2;
wire	[7:0]	Tmp3,Tmp4;

assign	TD_RESET_N	=	1'b1;

//VGA Controller module is 10-bit but DAC only does 8-bit
assign VGA_R = vga_r10[9:2];
assign VGA_G = vga_g10[9:2];
assign VGA_B = vga_b10[9:2];

assign	m1VGA_Read	=	vga_y[0]		?	1'b0		:	VGA_Read	;
assign	m2VGA_Read	=	vga_y[0]		?	VGA_Read	:	1'b0		;
assign	mYCbCr_d	=	~vga_y[0]		?	m1YCbCr		:
											      m2YCbCr		;
assign	mYCbCr		=	m5YCbCr;

assign	Tmp1	=	m4YCbCr[7:0]+mYCbCr_d[7:0];
assign	Tmp2	=	m4YCbCr[15:8]+mYCbCr_d[15:8];
assign	Tmp3	=	Tmp1[8:2]+m3YCbCr[7:1];
assign	Tmp4	=	Tmp2[8:2]+m3YCbCr[15:9];
assign	m5YCbCr	=	{Tmp4,Tmp3};
							
//	TV Decoder Stable Check
td_detect u2	
(	
	.iRST_N			(aresetn),
	.iTD_VS			(TD_VS),
	.iTD_HS			(TD_HS),

	.oTD_Stable 	(true_reset)
);

//	Reset Delay
Reset_Delay	u3	
(	
	.iCLK 			(clk),
	.iRST 			(true_reset),

	.oRST_0 		(true_reset0_n),
	.oRST_1			(true_reset1_n),
	.oRST_2			(true_reset2_n)
);

//	ITU-R 656 to YUV 4:2:2
ITU_656_Decoder	u4	
(	
	.iCLK_27 		(TD_CLK27),
	.iRST_N 		(true_reset1_n),
	
	.iTD_DATA 		(TD_DATA),
	.iSwap_CbCr 	(Quotient[0]),
	.iSkip 			(Remain==4'h0),

	.oTV_X 			(decoder_x),
	.oYCbCr 		(YCbCr),
	.oDVAL 			(YCbCr_valid)
);

//	Divide Megafuncion (Used to Down Sample)
DIV u5	
(	
	.clock 			(TD_CLK27),
	.aclr 			(~true_reset0_n),	
	
	.numer 			(decoder_x),
	.denom 			(4'h9),			// 720 - 640 = 80, 720/80 = 9. Skip a sample every 9 pixels.

	.quotient 		(Quotient),
	.remain 		(Remain)
);

//	SDRAM Frame Buffer
Sdram_Control_4Port	u6	
(
    .REF_CLK 		(TD_CLK27),
    .RESET_N 		(true_reset0_n),

	//	FIFO Write Side 1
	.WR1_DATA 		(YCbCr),
	.WR1 			(YCbCr_valid), 		// Write Enable
	// .WR1_FULL 		(WR1_FULL),			
	.WR1_ADDR 		(0),				//TODO: What is this number?
	.WR1_MAX_ADDR 	(640*507),			//TODO: What is this number?						
	.WR1_LENGTH 	(9'h80), 			//TODO: What is this number?
	.WR1_LOAD 		(~true_reset0_n), 	// Clears FIFO
	.WR1_CLK 		(TD_CLK27),

	 // FIFO Read Side 1 (Odd Field, Bypass Blanking)
    .RD1_DATA 		(m1YCbCr),
	.RD1 			(m1VGA_Read), 		// Read Enable
	.RD1_ADDR 		(640*13),			//TODO: What is this number?
	.RD1_MAX_ADDR 	(640*253),			//TODO: What is this number?				
	.RD1_LENGTH 	(9'h80),  			//TODO: What is this number?
	.RD1_LOAD 		(~true_reset0_n),   // Clears FIFO
	.RD1_CLK 		(TD_CLK27),

	// FIFO Read Side 2 (Even Field, Bypass Blanking)
    .RD2_DATA 		(m2YCbCr),
	.RD2 			(m2VGA_Read),		// Read Enable
	.RD2_ADDR 		(640*267),			//TODO: What is this number?
	.RD2_MAX_ADDR 	(640*507),		 	//TODO: What is this number?				
	.RD2_LENGTH 	(9'h80),            //TODO: What is this number?
	.RD2_LOAD 		(!true_reset0_n),   // Clears FIFO
	.RD2_CLK  		(TD_CLK27),

	// SDRAM
    .SA 			(DRAM_ADDR),
    .BA 			(DRAM_BA),
    .CS_N 			(DRAM_CS_N),
    .CKE 			(DRAM_CKE),
    .RAS_N 			(DRAM_RAS_N),
    .CAS_N  		(DRAM_CAS_N),
    .WE_N 			(DRAM_WE_N),
    .DQ 			(DRAM_DQ),
    .DQM 			({DRAM_DQM[1], DRAM_DQM[0]}),
	.SDR_CLK 		(DRAM_CLK)	
);

//	YUV 4:2:2 to YUV 4:4:4
YUV422_to_444 u7 
(	
	.iCLK 			(TD_CLK27),
	.iRST_N 		(true_reset0_n),

	.iX 			(vga_x-160),				// postion_x - H_BLANK
	.iYCbCr 		(mYCbCr),
	
	.oY 			(mY),
	.oCb 			(mCb),
	.oCr  			(mCr)
);

//	YCbCr 8-bit to RGB-10 bit 
YCbCr2RGB u8
(
	.iCLK 			(TD_CLK27),
	.iRESET 		(~true_reset2_n),

	.iDVAL 			(VGA_Read),
	.iY 			(mY),
	.iCb  			(mCb),
	.iCr 			(mCr),

	.Red 			(mRed),
	.Green 			(mGreen),
	.Blue 			(mBlue),
	.oDVAL 			(mDVAL),
);

//	VGA Controller
VGA_Ctrl u9	
(
	.iCLK 			(TD_CLK27),
	.iRST_N 		(true_reset2_n),		

	//Input Data
	.iRed 			(mRed),
	.iGreen 		(mGreen),
	.iBlue 			(mBlue),

	//VGA Position
	.oCurrent_X 	(vga_x),
	.oCurrent_Y 	(vga_y),

	//VGA Ready
	.oRequest 		(VGA_Read),

	//Generate VGA Signals
	.oVGA_R 		(vga_r10),
	.oVGA_G 		(vga_g10),
	.oVGA_B 		(vga_b10),
	.oVGA_HS 		(VGA_HS),
	.oVGA_VS 		(VGA_VS),
	.oVGA_SYNC 		(VGA_SYNC_N),
	.oVGA_BLANK 	(VGA_BLANK_N),
	.oVGA_CLOCK 	(VGA_CLK)
);

//	Shift Register Megafunction
Line_Buffer u10	
(	
	.clock 			(TD_CLK27),
	.aclr 			(~true_reset0_n),
	.clken 			(VGA_Read),
	
	.shiftin  		(mYCbCr_d),

	.shiftout 		(m3YCbCr)
);

//	Shift Register Megafunction
Line_Buffer u11	
(	
	.clock 			(TD_CLK27),
	.aclr 			(~true_reset0_n),
	.clken 			(VGA_Read),
	
	.shiftin 		(m3YCbCr),

	.shiftout 		(m4YCbCr)
);

endmodule
