///////////////////////////////////////////////////////////////////
// File:   video_input.v
// Author: B. Brown (all modules are from Terasic DE2-115 TV demo)
// About:  Top-level module for the video decoding pipeline.
///////////////////////////////////////////////////////////////////

module video_input
(
		input wire 			aresetn,

		// TV Decoder
		input wire 			TD_CLK27,
		input wire  [7:0]	TD_DATA,
		input wire 			TD_HS,
		output wire 		TD_RESET_N,
		input wire 			TD_VS,

		// Output RGB
		output wire [9:0]	R_out,
		output wire [9:0]	B_out,
		output wire [9:0]	G_out,
		output wire 		RGB_valid
);

// ITU-R 656 Decoder
wire	[15:0]	YCbCr;
wire			YCbCr_valid_1;
wire	[9:0]	decoder_x;

// Down Sample
wire	[3:0]	Remain;
wire	[9:0]	Quotient;

// YUV 4:2:2 to YUV 4:4:4
wire	[7:0]	mY;
wire	[7:0]	mCb;
wire	[7:0]	mCr;
wire 			YCbCr_valid_2;

// TV Decoder Turned On
assign	TD_RESET_N	=	1'b1;
							
//	ITU-R 656 to YUV 4:2:2
ITU_656_Decoder	u4	
(	
	.iCLK_27 		(TD_CLK27),
	.iRST_N 		(aresetn),
	
	.iTD_DATA 		(TD_DATA),
	.iSwap_CbCr 	(Quotient[0]),
	.iSkip 			(Remain==4'h0),

	.oTV_X 			(decoder_x),
	.oYCbCr 		(YCbCr),
	.oDVAL 			(YCbCr_valid_1)
);

// Divide Megafuncion (Used to Down Sample)
DIV u5	
(	
	.clock 			(TD_CLK27),
	.aclr 			(~aresetn),	
	
	.numer 			(decoder_x),
	.denom 			(4'h9),			// 720 - 640 = 80, 720/80 = 9. Skip a sample once every 9 pixels.

	.quotient 		(Quotient),
	.remain 		(Remain)
);

// YUV 4:2:2 to YUV 4:4:4
yuv422_to_yuv444 u7 
(	
	.iCLK 			(TD_CLK27),
	.iRST_N 		(aresetn),

	.iYCbCr 		(YCbCr),
	.iYCbCr_valid   (YCbCr_valid_1),	
	
	.oY 			(mY),
	.oCb 			(mCb),
	.oCr  			(mCr),
	.oYCbCr_valid   (YCbCr_valid_2)
);

// YCbCr 8-bit to RGB-10 bit 
YCbCr2RGB u8
(
	.iCLK 			(TD_CLK27),
	.iRESET 		(~aresetn),

	.iY 			(mY),
	.iCb  			(mCb),
	.iCr 			(mCr),
	.iDVAL 			(YCbCr_valid_2),

	.Red 			(R_out),
	.Green 			(G_out),
	.Blue 			(B_out),
	.oDVAL 			(RGB_valid)
);

endmodule
