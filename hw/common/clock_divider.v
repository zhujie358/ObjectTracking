////////////////////////////////////////////////////////////////
// File: clock_divider.v
// Author: BBB
// About: Creates clock with half of input frequency
////////////////////////////////////////////////////////////////

module clock_divider(

input wire clock_in,
input wire aresetn,

output reg clock_out

);

reg counter;

always @(posedge clock_in) begin
	if (~aresetn) 
		begin
			counter   <= 1'b0;
			clock_out <= 1'b0;
		end
	else 
		begin
			if(counter) 
				begin
					counter <= 1'b0;
					clock_out <= ~clock_out;
				end	
			else 
				begin
					counter <= 1'b1;
					clock_out <= clock_out;
				end
		end
end

endmodule
