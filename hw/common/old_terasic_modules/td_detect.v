////////////////////////////////////////////////////////////////
// File:   td_detect.v
// Author: Tersaic, modified by BBB
// Source: TD_Detect.v
// About:  Removed PAL and NTSC outputs. Minor syntax changes.	   
////////////////////////////////////////////////////////////////

module td_detect
(	
  output oTD_Stable,
  input iTD_VS,
  input iTD_HS,
  input iRST_N	
);
reg			NTSC;
reg			PAL;
reg			Pre_VS;
reg	[7:0]	Stable_Cont;

assign	oTD_Stable	=	NTSC || PAL;

always@(posedge iTD_HS or negedge iRST_N) begin
	if(!iRST_N)
		begin
			Pre_VS		  <=	1'b0;
			Stable_Cont	  <=	4'h0;
			NTSC		  <=	1'b0;
			PAL  		  <=	1'b0;
		end
	else
		begin
			
			Pre_VS	<=	iTD_VS;

			if(!iTD_VS) 											Stable_Cont	<=	Stable_Cont+1'b1;
			else 													Stable_Cont	<=	0;
			
			if({Pre_VS,iTD_VS}==2'b01)
				begin
					if((Stable_Cont>=4 && Stable_Cont<=14))  		NTSC <=	1'b1;
					else									 		NTSC <=	1'b0;
				
					if((Stable_Cont>=8'h14 && Stable_Cont<=8'h1f)) 	PAL	 <=	1'b1;
					else 											PAL	 <=	1'b0;
				end
		end
end

endmodule
