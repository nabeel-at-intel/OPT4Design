module top #(
	parameter DATA_INPUT_WIDTH=64,
	parameter DATA_OUTPUT_WIDTH=64,
	parameter NUM_STAMPS=60
) (
	input wire clk,
	input wire pwr_save,
	input reset_n,
	input wire [DATA_INPUT_WIDTH-1:0] data_input,
	output reg [DATA_OUTPUT_WIDTH-1:0] data_output
);

wire clk_gated;
wire [NUM_STAMPS-1:0] valid;
wire [NUM_STAMPS-1:0] busy;
wire [NUM_STAMPS-1:0] divide_by_zero;
wire [DATA_INPUT_WIDTH-1:0] ram_q_out;

assign clk_gated = pwr_save ? clk : 1'b0;

wire [DATA_INPUT_WIDTH-1:0] quotient[NUM_STAMPS-1:0];
wire [DATA_INPUT_WIDTH-1:0] remainder[NUM_STAMPS-1:0];

wire [NUM_STAMPS-1:0] quotient_transpose[DATA_INPUT_WIDTH-1:0];
wire [NUM_STAMPS-1:0] remainder_transpose[DATA_INPUT_WIDTH-1:0];

wire [DATA_INPUT_WIDTH-1:0] quotient_combined;
wire [DATA_INPUT_WIDTH-1:0] remainder_combined;

wire [DATA_OUTPUT_WIDTH-1:0] ones_w;
reg reset_int;

always @(posedge clk_gated or negedge reset_n) begin
	if ( !reset_n) begin
		reset_int <= 1'b0;
	end
	else begin
		reset_int <= 1'b1;
	end
end

genvar stamp, data_bit;
generate

	for(stamp = 0; stamp < NUM_STAMPS; stamp=stamp+1) begin: LOOP
	div_int #(
		.WIDTH(32)
	) my_div (
		.clk(clk_gated),
		.busy(busy[stamp]),
		.start(reset_int),
		.valid(valid[stamp]),
		.dbz(divide_by_zero[stamp]),
		.x(data_input[63:32]),
		.y(data_input[31:0]),
		.q(quotient[stamp]),
		.r(remainder[stamp])
	);

		for(data_bit=0; data_bit < DATA_INPUT_WIDTH; data_bit=data_bit+1) begin: LOOP2
			assign quotient_transpose[data_bit][stamp] = quotient[stamp][data_bit];
			assign remainder_transpose[data_bit][stamp] = remainder[stamp][data_bit];
		end
	
	end
	
	for(data_bit=0; data_bit < DATA_INPUT_WIDTH; data_bit=data_bit+1) begin: LOOP3
		assign quotient_combined[data_bit] = |quotient_transpose[data_bit];
		assign remainder_combined[data_bit] = |remainder_transpose[data_bit];
	end
	
endgenerate


single_port_ram #(
	.DATA_WIDTH(DATA_INPUT_WIDTH),
	.ADDR_WIDTH(14)
) my_ram (
	.clk(clk_gated),
	.data(quotient_combined),
	.addr(remainder_combined[13:0]),
	.we(|valid & |busy),
	.q(ram_q_out)
);

count_ones #(
	.WIDTH(2*DATA_INPUT_WIDTH)
) count_ones (
	.in({ram_q_out,ram_q_out}),
	.num_ones(ones_w)
);

always @(posedge clk_gated or negedge reset_int) begin
	if (! reset_int) begin
		data_output <= {DATA_OUTPUT_WIDTH{1'b0}};
	end
	else begin
		data_output <= ones_w;
	end
end

endmodule

module combine #(
	parameter WIDTH=10
) (
	input wire [WIDTH-1:0] in,
	output wire out
);
	assign out = &in;
endmodule
