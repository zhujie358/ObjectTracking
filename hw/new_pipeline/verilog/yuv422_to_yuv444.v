////////////////////////////////////////////////////////////////
// File:   yuv422_to_yuv444.v
// Author: Tersaic, modified by BBB
// Source: YUV422_to_444.v
// About:  Removed VGA dependency. Minor syntax changes.	 
////////////////////////////////////////////////////////////////

module yuv422_to_yuv444
(
	input 	wire			iCLK,
	input 	wire			iRST_N,	

	input 	wire [15:0] 	iYCbCr,
	input	wire 			iYCbCr_valid,

	output	wire [7:0]		oY,
	output	wire [7:0]		oCb,
	output	wire [7:0]		oCr,
	output	wire			oYCbCr_valid
);

//	Internal Registers
reg 			every_other;
reg		[7:0]	mY;
reg		[7:0]	mCb;
reg		[7:0]	mCr;
reg 			mValid;

assign	oY			 =	mY;
assign	oCb			 =	mCb;
assign	oCr			 =	mCr;
assign  oYCbCr_valid = mValid;

always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
		begin
			every_other  <= 0;
			mY			 <=	0;
			mCb			 <=	0;
			mCr			 <=	0;
			mValid 		 <= 0;
		end
	else
		begin
			every_other  <= ~every_other;

			mValid <= iYCbCr_valid;

			if(every_other)
				{mY,mCr}	<=	iYCbCr;
			else
				{mY,mCb}	<=	iYCbCr;
		end
end

endmodule