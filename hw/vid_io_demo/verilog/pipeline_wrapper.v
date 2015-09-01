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

// Input Resolution Parameters (units: pixels)
localparam NTSC_RES_H 	   		= 720;

// Output Resolution Parameters (units: pixels)
localparam VGA_RES_POLAR   		= 1'b0; // HS and VS are active-low for these settings
localparam VGA_RES_H_FRONT 		= 16;   // Horizontal Front Porch
localparam VGA_RES_H_SYNC  		= 98;   // Horizontal Sync Length
localparam VGA_RES_H_BACK  		= 46;   // Horizontal Back Porch
localparam VGA_RES_H_ACT   		= 640;  // Horizontal Actual (Visible)
localparam VGA_RES_V_FRONT 		= 11;   // Vertical Front Porch
localparam VGA_RES_V_SYNC  		= 2;    // Vertical Sync Length
localparam VGA_RES_V_BACK  		= 31;   // Vertical Back Porch
localparam VGA_RES_V_ACT   		= 480;  // Vertical Actual (Visible)
localparam VGA_RES_V_ACT_2 		= 240;  // Just divide the above number by 2

// SDRAM Parameters (units: pixels)
localparam LINES_ODD_START 		= VGA_RES_V_FRONT  + VGA_RES_V_SYNC;
localparam LINES_ODD_END    	= LINES_ODD_START  + VGA_RES_V_ACT_2;
localparam LINES_EVEN_START 	= LINES_ODD_END    + LINES_ODD_START + 1;  
localparam LINES_EVEN_END   	= LINES_EVEN_START + VGA_RES_V_ACT_2;

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

// For field select
wire	[15:0]	m1YCbCr;    // SDRAM data odd field
wire	[15:0]	m2YCbCr;    // SDRAM data even field
wire	[15:0]	mYCbCr_d;   // SDRAM data muxed for odd or even field
wire	[15:0]	m3YCbCr;    // SDRAM data post one shift reg
wire	[15:0]	m4YCbCr;    // SDRAM data post two shift reg
wire	[15:0]	m5YCbCr;    // SDRAM data post all shift regs and mystery logic
wire	[15:0]	mYCbCr;		// Final result for conversion

wire	[8:0]	Tmp1,Tmp2;  // Used in mystery logic
wire	[7:0]	Tmp3,Tmp4;	// Used in mystery logic

// For YUV 4:2:2 to YUV 4:4:4
wire	[7:0]	mY;
wire	[7:0]	mCb;
wire	[7:0]	mCr;

// For VGA Controller
wire	[9:0]	mRed; 		// RGB data after YCbCr conversion
wire	[9:0]	mGreen;		// RGB data after YCbCr conversion
wire	[9:0]	mBlue;		// RGB data after YCbCr conversion
wire			mDVAL; 		// Valid RGB data after YCbCr conversion, unused
wire	[10:0]	vga_x;		// VGA position, used in 422:444 converter
wire	[10:0]	vga_y;		// VGA vertical position, used to determine odd or even field
wire			VGA_Read;	// VGA data request
wire			m1VGA_Read;	// VGA data request odd field
wire			m2VGA_Read;	// VGA data request even field

// Setting this high turns on the TV Decoder
assign	TD_RESET_N	=	1'b1;

// Field Select Logic (Odd/Even)
assign	m1VGA_Read	=	vga_y[0]		?	1'b0		:	VGA_Read	;
assign	m2VGA_Read	=	vga_y[0]		?	VGA_Read	:	1'b0		;
assign	mYCbCr_d	=	~vga_y[0]		?	m1YCbCr		:   m2YCbCr		;

// Mystery Logic
assign	Tmp1		=	m4YCbCr[7:0]+mYCbCr_d[7:0];
assign	Tmp2		=	m4YCbCr[15:8]+mYCbCr_d[15:8];
assign	Tmp3		=	Tmp1[8:2]+m3YCbCr[7:1];
assign	Tmp4		=	Tmp2[8:2]+m3YCbCr[15:9];
assign	m5YCbCr		=	{Tmp4,Tmp3};
assign	mYCbCr		=	m5YCbCr;
							
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
	.denom 			(4'h9),			// 720 - 640 = 80, 720/80 = 9. Skip a sample once every 9 pixels.

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
	.WR1 			(YCbCr_valid), 					// Write Enable
	.WR1_ADDR 		(0),							// Base address
	.WR1_MAX_ADDR 	(VGA_RES_H_ACT*LINES_EVEN_END),	// Store every pixel of every line. Blanking lines, odd lines, blanking lines, and even lines.
	.WR1_LENGTH 	(9'h80), 						// The valid signal drops low every 8 samples, 16*8 = 128 bits per burst?
	.WR1_LOAD 		(~true_reset0_n), 				// Clears FIFO
	.WR1_CLK 		(TD_CLK27),

	 // FIFO Read Side 1 (Odd Field, Bypass Blanking)
    .RD1_DATA 		(m1YCbCr),
	.RD1 			(m1VGA_Read), 					 	// Read Enable
	.RD1_ADDR 		(VGA_RES_H_ACT*LINES_ODD_START), 	// Bypass the blanking lines
	.RD1_MAX_ADDR 	(VGA_RES_H_ACT*LINES_ODD_END  ),	// Read out of the valid odd lines
	.RD1_LENGTH 	(9'h80),  							// Just being consistent with write length?
	.RD1_LOAD 		(~true_reset0_n),   				// Clears FIFO
	.RD1_CLK 		(TD_CLK27),

	// FIFO Read Side 2 (Even Field, Bypass Blanking)
    .RD2_DATA 		(m2YCbCr),
	.RD2 			(m2VGA_Read),						// Read Enable
	.RD2_ADDR 		(VGA_RES_H_ACT*LINES_EVEN_START),	// Bypass the blanking lines
	.RD2_MAX_ADDR 	(VGA_RES_H_ACT*LINES_EVEN_END  ),	// Read out of the valid even lines
	.RD2_LENGTH 	(9'h80),            				// Just being consistent with write length?
	.RD2_LOAD 		(!true_reset0_n),   				// Clears FIFO
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
vga_sync #(
	.H_TOTAL_WIDTH 	(11),
	.V_TOTAL_WIDTH 	(11),

	.POLARITY 		(VGA_RES_POLAR),

	.H_FRONT 		(VGA_RES_H_FRONT),
	.H_SYNC 		(VGA_RES_H_SYNC),
	.H_BACK 		(VGA_RES_H_BACK),
	.H_ACT 			(VGA_RES_H_ACT),

	.V_FRONT 		(VGA_RES_V_FRONT),
	.V_SYNC 		(VGA_RES_V_SYNC),
	.V_BACK 		(VGA_RES_V_BACK),
	.V_ACT 			(VGA_RES_V_ACT)
) vga_sync_inst (

	.clock			(TD_CLK27),
	.aresetn 		(true_reset2_n),

	//Input Data
	.R_in 			(mRed),
	.G_in 			(mGreen),
	.B_in 			(mBlue),

	//Output Control Logic
	.current_x 		(vga_x),
	.current_y		(vga_y),
	.ready			(VGA_Read),

	//Output VGA Signals
	.vga_clk		(VGA_CLK),
	.R_out			(VGA_R),
	.G_out			(VGA_G),
	.B_out			(VGA_B),
	.h_sync			(VGA_HS),
	.v_sync			(VGA_VS),
	.blank_n		(VGA_BLANK_N),
	.sync_n			(VGA_SYNC_N)
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
