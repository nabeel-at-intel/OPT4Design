module count_ones #(
	parameter WIDTH=32
) (
	input wire [WIDTH-1:0] in,
	output reg [$clog2(WIDTH)-1:0] num_ones
);

integer i;

always @(in) begin
	num_ones = 0;
	for(i=0; i<WIDTH; i++) begin
		if (in[i] == 1'b1) begin
			num_ones = num_ones + 1'b1;
		end
	end	

end

endmodule