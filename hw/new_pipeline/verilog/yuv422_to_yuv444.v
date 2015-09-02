////////////////////////////////////////////////////////////////
// File:   yuv422_to_yuv444.v
// Author: Tersaic, modified by BBB
// Source: YUV422_to_444.v
// About:  Removed VGA dependency. Minor syntax changes.	 
////////////////////////////////////////////////////////////////

module yuv422_to_yuv444
(
	input 			iCLK,
	input 			iRST_N,	

	input 	[15:0] 	iYCbCr,

	output	[7:0]	oY,
	output	[7:0]	oCb,
	output	[7:0]	oCr
);

//	Internal Registers
reg 			every_other;
reg		[7:0]	mY;
reg		[7:0]	mCb;
reg		[7:0]	mCr;

assign	oY	=	mY;
assign	oCb	=	mCb;
assign	oCr	=	mCr;

always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
		begin
			every_other <=  0;
			mY			<=	0;
			mCb			<=	0;
			mCr			<=	0;
		end
	else
		begin
			every_other = ~every_other;

			if(every_other)
				{mY,mCr}	<=	iYCbCr;
			else
				{mY,mCb}	<=	iYCbCr;
		end
end

endmodule