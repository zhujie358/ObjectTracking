////////////////////////////////////////////////////////////////
// File: vga_sync.v
// Author: BBB
// About: Controls VGA signals
////////////////////////////////////////////////////////////////

module vga_sync(

input wire clock,
input wire aresetn,

input wire [7:0] R_in,
input wire [7:0] G_in,
input wire [7:0] B_in,

output wire vga_clk,

output reg [7:0] R,
output reg [7:0] G,
output reg [7:0] B,

output reg h_sync,
output reg v_sync,

output wire blank_n,
output wire sync_n
);

/*
	VGA Frequency:   72Hz
	VGA Resolution:  800x600
	VGA Pixel Clock: 50MHz
*/

//Horizontal Parameters
localparam	H_FRONT		  =	56;
localparam	H_SYNC		  =	120;
localparam	H_BACK		  =	64;
localparam	H_ACT	   	  =	800;
localparam	H_BLANK		  =	H_FRONT+H_SYNC+H_BACK;
localparam	H_TOTAL		  =	H_FRONT+H_SYNC+H_BACK+H_ACT;
localparam  H_TOTAL_WIDTH =   10;

//Vertical Parameters
localparam	V_FRONT		  =	37;
localparam	V_SYNC		  =	6;
localparam	V_BACK		  =	23;
localparam	V_ACT	   	  =	600;
localparam	V_BLANK		  =	V_FRONT+V_SYNC+V_BACK;
localparam	V_TOTAL		  =	V_FRONT+V_SYNC+V_BACK+V_ACT;
localparam  V_TOTAL_WIDTH =   10;

//Clock
assign vga_clk = ~clock;

//Position Info
reg [(H_TOTAL_WIDTH-1):0] hor_pos;
reg [(V_TOTAL_WIDTH-1):0] ver_pos;

//Horizontal Data
always @(posedge clock) begin
	if (~aresetn)	
		begin
			hor_pos <= 'd0;
			h_sync  <= 1'b0;
		end
	else
		begin
			if (hor_pos < H_TOTAL)	hor_pos <= hor_pos + 1;
			else 					hor_pos <= 0;
			
			if (hor_pos == H_FRONT-1) 		 h_sync <= 1'b1;
			if (hor_pos == H_FRONT+H_SYNC-1) h_sync <= 1'b0;
		
		end
end

//Vertical Data
always @(posedge h_sync) begin
	if (~aresetn)	
		begin
			ver_pos <= 'd0;
			v_sync  <= 1'b0;
		end
	else
		begin
			if (ver_pos < V_TOTAL)	ver_pos <= ver_pos + 1;
			else 					ver_pos <= 0;
			
			if (ver_pos == V_FRONT-1) 		 v_sync <= 1'b1;
			if (ver_pos == V_FRONT+V_SYNC-1) v_sync <= 1'b0;
		
		end
end

//RGB Data
always @(posedge clock) begin
	if (~aresetn) 
		begin
			R <= 8'd0;
			B <= 8'd0;
			G <= 8'd0;
		end
	else if ((hor_pos < H_BLANK) | (ver_pos < V_BLANK))
		begin
			R <= 8'd0;
			B <= 8'd0;
			G <= 8'd0;		
		end
	else 
		begin
			R <= R_in;
			B <= B_in;
			G <= G_in;
		end
end

//Blank (ADV7123)
assign blank_n = ~((hor_pos < H_BLANK)||(ver_pos < V_BLANK));

//Sync (ADV7123)
assign sync_n  = 1'b1; 

endmodule
