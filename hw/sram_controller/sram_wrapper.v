module sram_wrapper
(

	// Clock and Reset
	input wire		          		clk,
	input wire						aresetn,

	// Wrapper Signals
	input wire						wen,
	input wire			[19:0]		addr,
	input wire			[15:0]		din,
	output wire			[15:0]		dout,

	// SRAM Signals
	output wire	    	[19:0]		SRAM_ADDR,
	output wire		          		SRAM_CE_N,
	inout  wire		    [15:0]		SRAM_DQ,
	output wire		          		SRAM_LB_N,
	output wire		          		SRAM_OE_N,
	output wire		          		SRAM_UB_N,
	output wire		          		SRAM_WE_N

);

reg [15:0]	a;
reg [15:0]	b;
reg  		wen_latch;
reg [19:0]	addr_latch;
wire 		output_enable;

// Latch write enable and address to account for bidir delay
always @(posedge clk) wen_latch  <= wen;
always @(posedge clk) addr_latch <= addr;

// Enable the output if you're in read mode
assign output_enable = ~wen_latch;

// From Altera Bidirectional Example
// https://www.altera.com/support/support-resources/design-examples/design-software/verilog/ver_bidirec.tablet.highResolutionDisplay.html
always @(posedge clk) begin
	a <= din;
	b <= SRAM_DQ;
end

assign SRAM_DQ   = ~output_enable ? a : 16'bZ;

assign dout 	 = b;

// Write enable
assign SRAM_WE_N = ~wen_latch;

// If not resetting, enable the chip (invert for active-low)
assign SRAM_CE_N = ~aresetn;

// Invert signal described above for active-low
assign SRAM_OE_N = ~output_enable;

// Upper and Lower Byte: Set active-low for read or write
assign SRAM_LB_N = 1'b0;
assign SRAM_UB_N = 1'b0;

// Pass address for read or write
assign SRAM_ADDR = addr_latch;

endmodule