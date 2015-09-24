////////////////////////////////////////////////////////////////
// File:   new_pipeline_2.v
// Author: B. Brown, T. Dotsikas
// About:  Top-level module for experiment.
////////////////////////////////////////////////////////////////

//=======================================================
//  Ports generated by Terasic System Builder
//=======================================================
module new_pipeline_2(

	//////////// CLOCK //////////
	input 		          		CLOCK_50,
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,

	//////////// LED //////////
	output		     [8:0]		LEDG,
	output		    [17:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		    [17:0]		SW,

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
	output		          		DRAM_WE_N,

	//////////// SRAM //////////
	output		    [19:0]		SRAM_ADDR,
	output		          		SRAM_CE_N,
	inout 		    [15:0]		SRAM_DQ,
	output		          		SRAM_LB_N,
	output		          		SRAM_OE_N,
	output		          		SRAM_UB_N,
	output		          		SRAM_WE_N
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

// Global Reset
wire 			aresetn;

// TV Decode Pipeline Output
wire	[9:0]	Red; 				// RGB data after YCbCr conversion
wire	[9:0]	Green;				// RGB data after YCbCr conversion
wire	[9:0]	Blue;				// RGB data after YCbCr conversion
wire			RGB_valid; 			// Valid RGB data after YCbCr conversion, unused

// Field Select
wire [15:0] 	rgb_packed_write;	// SDRAM write data
wire [15:0] 	rgb_packed_read;	// SDRAM read data muxed for odd or even field
wire [15:0] 	rgb_packed_odd;		// SDRAM data odd field
wire [15:0] 	rgb_packed_even;	// SDRAM data even field
wire			vga_odd_ready;		// VGA data request odd field
wire			vga_even_ready;		// VGA data request even field

// VGA Controller Output
wire	[10:0]	vga_x;				// VGA position, used in 422:444 converter
wire	[10:0]	vga_y;				// VGA vertical position, used to determine odd or even field
wire			vga_ready;			// VGA data request

// Reset to Key
assign aresetn = KEY[0];

// Video Input Decode Pipeline
video_input video_input_inst
(
	.aresetn 		(aresetn),

	// TV Decoder
	.TD_CLK27 		(TD_CLK27),
	.TD_DATA 		(TD_DATA),
	.TD_HS 			(TD_HS),
	.TD_RESET_N 	(TD_RESET_N),
	.TD_VS 			(TD_VS),

	// RGB
	.R_out 			(Red), 
	.B_out 			(Blue),
	.G_out 			(Green),
	.RGB_valid  	(RGB_valid)
);

// RGB 30-bit to RGB 16-bit
assign rgb_packed_write = {Red[9:5], Green[9:4], Blue[9:5]};

//	SDRAM Frame Buffer
Sdram_Control_4Port	sdram_control_inst	
(
    .REF_CLK 		(TD_CLK27),
    .RESET_N 		(aresetn),

	//	FIFO Write Side 1
	.WR1_DATA 		(rgb_packed_write),
	.WR1 			(RGB_valid), 					// Write Enable
	.WR1_ADDR 		(0),							// Base address
	.WR1_MAX_ADDR 	(VGA_RES_H_ACT*LINES_EVEN_END),	// Store every pixel of every line. Blanking lines, odd lines, blanking lines, and even lines.
	.WR1_LENGTH 	(9'h80), 						// The valid signal drops low every 8 samples, 16*8 = 128 bits per burst?
	.WR1_LOAD 		(~aresetn), 				// Clears FIFO
	.WR1_CLK 		(TD_CLK27),

	 // FIFO Read Side 1 (Odd Field, Bypass Blanking)
    .RD1_DATA 		(rgb_packed_odd),
	.RD1 			(vga_odd_ready), 					 // Read Enable
	.RD1_ADDR 		(VGA_RES_H_ACT*LINES_ODD_START), 	// Bypass the blanking lines
	.RD1_MAX_ADDR 	(VGA_RES_H_ACT*LINES_ODD_END  ),	// Read out of the valid odd lines
	.RD1_LENGTH 	(9'h80),  							// Just being consistent with write length?
	.RD1_LOAD 		(~aresetn),   				// Clears FIFO
	.RD1_CLK 		(TD_CLK27),

	// FIFO Read Side 2 (Even Field, Bypass Blanking)
    .RD2_DATA 		(rgb_packed_even),
	.RD2 			(vga_even_ready),					// Read Enable
	.RD2_ADDR 		(VGA_RES_H_ACT*LINES_EVEN_START),	// Bypass the blanking lines
	.RD2_MAX_ADDR 	(VGA_RES_H_ACT*LINES_EVEN_END  ),	// Read out of the valid even lines
	.RD2_LENGTH 	(9'h80),            				// Just being consistent with write length?
	.RD2_LOAD 		(~aresetn),   				// Clears FIFO
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

// Field Select Logic (Odd/Even)
assign	vga_odd_ready	= vga_y[0]  ? 1'b0	 			:  vga_ready;
assign	vga_even_ready	= vga_y[0]  ? vga_ready  		:  1'b0;
assign	rgb_packed_read	= ~vga_y[0] ? rgb_packed_odd	:  rgb_packed_even;

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
	.aresetn 		(aresetn),

	// Input Data
	.R_in 			({rgb_packed_read[15:11], 5'b00000}),
	.G_in 			({rgb_packed_read[10: 5], 4'b0000 }),
	.B_in 			({rgb_packed_read[ 4: 0], 5'b00000}),

	// Output Control Logic
	.current_x 		(vga_x),
	.current_y		(vga_y),
	.ready			(vga_ready),

	// Output VGA Signals
	.vga_clk		(VGA_CLK),
	.R_out			(VGA_R),
	.G_out			(VGA_G),
	.B_out			(VGA_B),
	.h_sync			(VGA_HS),
	.v_sync			(VGA_VS),
	.blank_n		(VGA_BLANK_N),
	.sync_n			(VGA_SYNC_N)
);

endmodule
